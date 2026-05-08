import Foundation

extension AppState {
    func startSession(for unit: UnitType) {
        guard let profile else { return }
        guard isUnitUnlocked(unit) else {
            setStatus("Complete the previous quest to unlock this unit.")
            return
        }

        do {
            cancelQuestionReadTask()
            pendingChapterCelebration = nil
            let targetItemCount = FeatureFlags.adaptiveSessionItems(
                for: unit,
                placedGrade: diagnosticResult?.placedGrade
            )
            let blueprint = try sessionComposer.composeSession(
                childID: profile.id,
                focusUnit: unit,
                targetItemCount: targetItemCount
            )
            currentSession = SessionRuntime(blueprint: blueprint)
            route = .session
            playSFX(.tap)
        } catch {
            setStatus("Unable to start that quest right now.")
        }
    }

    func startRecommendedSession() {
        guard let unit = recommendedUnit() else {
            setStatus("No playable lesson is available yet for this path.")
            return
        }
        startSession(for: unit)
    }

    var isRecommendationPersonalized: Bool {
        guard !adaptivePath.recommendedLessons.isEmpty else { return false }
        let completedUnits = Set(
            dashboard.unitProgress
                .filter { $0.completedSessions > 0 }
                .map(\.unit)
        )

        return adaptivePath.recommendedLessons.contains { lesson in
            guard let linkedUnit = lesson.linkedUnit else { return false }
            return lesson.isPlayableInApp
                && isUnitUnlocked(linkedUnit)
                && !completedUnits.contains(linkedUnit)
        }
    }

    func openLessonPlans() {
        route = .lessonPlans
    }

    func closeLessonPlans() {
        route = .home
    }

    func submitAnswer(answer: String, inputMode: InputMode, latencyMs: Double) {
        guard let profile, var runtime = currentSession else { return }
        cancelQuestionReadTask()
        let item = runtime.currentItem
        let isCorrect = runtime.evaluate(answer: answer)

        let attempt = AttemptInput(
            childID: profile.id,
            skillID: item.skillID,
            unit: item.unit,
            itemID: item.id,
            sessionID: runtime.sessionID,
            response: answer,
            correct: isCorrect,
            latencyMs: latencyMs,
            hintsUsed: Int16(runtime.hintsUsedForCurrentItem),
            inputMode: inputMode
        )

        do {
            let masteryState = try masteryEngine.recordAttempt(attempt)
            runtime.recordSubmission(correct: isCorrect)
            currentSession = runtime
            playSFX(isCorrect ? .correct : .incorrect)
            setStatus(masteryState.status == .mastered ? "Skill mastered!" : nil)

            if runtime.pendingCorrection {
                let correctionPhrase = CompanionPhrases.correction(tone: activeCompanion.tone)
                narrationService.speakFeedback(correctionPhrase, style: narrationStyle)
            } else {
                speakSessionFeedback(isCorrect: isCorrect)
                scheduleSessionAdvance(
                    after: isCorrect ? Timing.correctAnswerAdvanceDelayNs : Timing.incorrectAnswerAdvanceDelayNs,
                    lastItem: item,
                    lastCorrect: isCorrect
                )
            }
        } catch {
            setStatus("We couldn't save that attempt.")
        }
    }

    func acknowledgeCorrection() {
        guard profile != nil, var runtime = currentSession, runtime.pendingCorrection else { return }
        cancelQuestionReadTask()
        runtime.acknowledgeCorrection()

        if runtime.isComplete {
            guard let lastItem = runtime.items.last else { return }
            finishSession(runtime, lastItem: lastItem, lastCorrect: false)
        } else {
            currentSession = runtime
        }
    }

    func requestHint() -> HintAction? {
        guard var runtime = currentSession else { return nil }
        cancelQuestionReadTask()
        let context = AttemptContext(
            unit: runtime.currentItem.unit,
            skillID: runtime.currentItem.skillID,
            prompt: runtime.currentItem.prompt,
            payload: runtime.currentItem.payload,
            incorrectAttempts: runtime.incorrectAttemptsForCurrentItem,
            recentMisconceptions: runtime.recentMisconceptions,
            supports: runtime.currentItem.supports
        )

        let hint = hintEngine.nextHint(for: context)
        runtime.registerHintUse()
        currentSession = runtime
        narrationService.speakFeedback(hint.encouragementLine, style: narrationStyle, interrupt: true)
        playSFX(.hint)
        return hint
    }

    func replayPrompt() {
        guard let item = currentSession?.currentItem else { return }
        narrationService.speakQuestion(
            item.narrationText,
            style: narrationStyle,
            interrupt: true,
            itemID: item.audioLookupID
        )
    }

    func readQuestionIfEnabled() {
        questionReadTask?.cancel()
        guard autoReadQuestions, let runtime = currentSession else { return }
        let expectedSessionID = runtime.sessionID
        let expectedItemID = runtime.currentItem.id
        let narrationText = runtime.currentItem.narrationText
        let audioLookupID = runtime.currentItem.audioLookupID

        questionReadTask = Task { [weak self] in
            for _ in 0..<Timing.narrationPollCount {
                guard !Task.isCancelled else { return }
                if self?.narrationService.isSpeaking != true { break }
                try? await Task.sleep(nanoseconds: Timing.narrationPollIntervalNs)
            }

            guard !Task.isCancelled, self?.narrationService.isSpeaking != true else { return }
            try? await Task.sleep(nanoseconds: Timing.questionReadPauseDelayNs)
            guard
                !Task.isCancelled,
                let self,
                let current = self.currentSession,
                current.sessionID == expectedSessionID,
                current.currentItem.id == expectedItemID
            else {
                return
            }

            self.narrationService.speakQuestion(
                narrationText,
                style: self.narrationStyle,
                interrupt: true,
                itemID: audioLookupID
            )
        }
    }

    func goHome() {
        sessionAdvanceTask?.cancel()
        sessionAdvanceTask = nil
        cancelQuestionReadTask()
        route = profile == nil ? .profileSetup : .home
        currentSession = nil
        latestSummary = nil
        pendingStickerReward = nil
        pendingChapterCelebration = nil
        refreshDashboard()
    }

    func cancelQuestionReadTask() {
        questionReadTask?.cancel()
        questionReadTask = nil
    }

    func playSFX(_ event: SFXEvent) {
        guard soundEffectsEnabled else { return }
        sfxService.play(event, theme: selectedTheme)
    }

    private func recommendedUnit() -> UnitType? {
        let completedUnits = Set(
            dashboard.unitProgress
                .filter { $0.completedSessions > 0 }
                .map(\.unit)
        )

        for lesson in adaptivePath.recommendedLessons where lesson.isPlayableInApp {
            if let linked = lesson.linkedUnit,
               isUnitUnlocked(linked),
               !completedUnits.contains(linked) {
                return linked
            }
        }

        if let next = dashboard.unitProgress.last(where: { $0.unlocked && $0.completedSessions == 0 }) {
            return next.unit
        }

        if let highestUnlocked = dashboard.unitProgress.last(where: { $0.unlocked }) {
            return highestUnlocked.unit
        }

        for lesson in adaptivePath.recommendedLessons where lesson.isPlayableInApp {
            if let linked = lesson.linkedUnit, isUnitUnlocked(linked) {
                return linked
            }
        }

        return .kCountObjects
    }

    private func finishSession(_ runtime: SessionRuntime, lastItem: PracticeItem, lastCorrect: Bool) {
        guard let profile else { return }
        cancelQuestionReadTask()
        let previousDashboard = dashboard
        let reward = contentPack.rewards.randomElement()?.title ?? "Explorer Sticker"

        do {
            try repository.finishSession(
                sessionID: runtime.sessionID,
                childID: profile.id,
                unit: runtime.focusUnit,
                totalItems: Int16(runtime.items.count),
                correctItems: Int16(runtime.correctCount),
                rewardTitle: reward
            )
        } catch {
            // Keep UI flow moving even if summary persistence fails.
        }

        currentSession = nil
        refreshDashboard()
        let unlockedChapter = chapterCelebration(
            from: previousDashboard,
            to: dashboard,
            finishedUnit: runtime.focusUnit
        )
        latestSummary = SessionSummary(
            sessionID: runtime.sessionID,
            unit: runtime.focusUnit,
            totalItems: runtime.items.count,
            correctItems: runtime.correctCount,
            rewardTitle: reward,
            nextRecommendation: masteryEngine.nextRecommendation(for: lastItem.skillID, childID: profile.id),
            missedItems: runtime.missedItems,
            chapterCelebration: unlockedChapter
        )
        pendingChapterCelebration = unlockedChapter
        checkAndAwardSticker(for: runtime.focusUnit)
        route = .summary
        narrationService.speakFeedback(
            lastCorrect ? "Great finish!" : "Nice persistence. You did it!",
            style: narrationStyle,
            interrupt: true
        )
        playSFX(.reward)
    }

    private func scheduleSessionAdvance(
        after delayNanoseconds: UInt64,
        lastItem: PracticeItem,
        lastCorrect: Bool
    ) {
        sessionAdvanceTask?.cancel()
        sessionAdvanceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled, let self else { return }
            guard var runtime = currentSession, runtime.pendingAdvance else { return }
            runtime.advanceIfPending()

            if runtime.isComplete {
                finishSession(runtime, lastItem: lastItem, lastCorrect: lastCorrect)
            } else {
                currentSession = runtime
            }
        }
    }

    private func speakSessionFeedback(isCorrect: Bool) {
        let feedback = isCorrect ? PraiseLibrary.randomCorrectPraise() : PraiseLibrary.randomRetryPrompt()
        narrationService.speakFeedback(feedback, style: narrationStyle)
    }
}
