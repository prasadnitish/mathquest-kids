import Foundation

extension AppState {
    func createProfile(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let created = try repository.createOrLoadProfile(name: trimmed)
            profile = created
            refreshDashboard()

            diagnosticResult = loadDiagnosticResult(childID: created.id)
            adaptivePath = adaptivePlanner.buildPath(result: diagnosticResult, catalog: curriculumCatalog)
            refreshDashboard()

            if shouldRequireDiagnostic(for: created.id) {
                route = .diagnostic
                startDiagnosticIfNeeded()
                setStatus("Great. Quick diagnostic next to personalize lessons.")
            } else {
                route = .home
                setStatus("Welcome, \(created.displayName)!")
            }
        } catch {
            setStatus("Couldn't save profile. Please try again.")
        }
    }

    func startDiagnosticIfNeeded() {
        guard diagnosticSession == nil else { return }
        cancelQuestionReadTask()
        clearDiagnosticFeedbackState()
        diagnosticSession = diagnosticService.makeSession()
    }

    func submitDiagnosticChoice(_ choiceIndex: Int) {
        guard let session = diagnosticSession, !diagnosticInteractionDisabled else { return }
        let question = session.currentQuestion
        var updatedSession = session
        updatedSession.submit(choiceIndex: choiceIndex)
        playSFX(.tap)
        diagnosticFeedbackMessage = diagnosticFeedback(for: question, selectedIndex: choiceIndex)
        diagnosticInteractionDisabled = true
        narrationService.speakFeedback(
            diagnosticFeedbackMessage ?? "Thanks for showing your thinking.",
            style: narrationStyle,
            interrupt: true
        )

        diagnosticAdvanceTask?.cancel()
        diagnosticAdvanceTask = Task {
            try? await Task.sleep(nanoseconds: Timing.diagnosticAdvanceDelayNs)
            guard !Task.isCancelled else { return }
            if updatedSession.isComplete {
                finishDiagnostic(updatedSession)
            } else {
                diagnosticSession = updatedSession
                diagnosticFeedbackMessage = nil
                diagnosticInteractionDisabled = false
            }
        }
    }

    func submitDiagnosticDontKnow() {
        submitDiagnosticChoice(-1)
    }

    func skipDiagnosticForNow() {
        cancelQuestionReadTask()
        clearDiagnosticFeedbackState()
        temporarilySkippedDiagnostic = true
        diagnosticSession = nil
        route = .home
        setStatus("You can run the diagnostic anytime in Parent Settings.")
    }

    func retakeDiagnostic() {
        cancelQuestionReadTask()
        clearDiagnosticFeedbackState()
        diagnosticSession = diagnosticService.makeSession()
        route = .diagnostic
    }

    func replayDiagnosticPrompt() {
        guard let question = diagnosticSession?.currentQuestion else { return }
        narrationService.speakQuestion(question.prompt, style: narrationStyle, interrupt: true, itemID: question.id)
    }

    func readDiagnosticPromptIfEnabled() {
        guard autoReadQuestions else { return }
        replayDiagnosticPrompt()
    }

    func clearDiagnosticFeedbackState() {
        diagnosticAdvanceTask?.cancel()
        diagnosticAdvanceTask = nil
        diagnosticFeedbackMessage = nil
        diagnosticInteractionDisabled = false
    }

    func shouldRequireDiagnostic(for childID: UUID) -> Bool {
        guard !skipDiagnosticOnboarding else { return false }
        guard !temporarilySkippedDiagnostic else { return false }
        return loadDiagnosticResult(childID: childID) == nil
    }

    func loadDiagnosticResult(childID: UUID) -> DiagnosticResult? {
        guard let data = defaults.data(forKey: PreferenceKey.diagnosticResult(for: childID)) else {
            return nil
        }
        return try? JSONDecoder().decode(DiagnosticResult.self, from: data)
    }

    func clearDiagnosticResult(childID: UUID) {
        defaults.removeObject(forKey: PreferenceKey.diagnosticResult(for: childID))
    }

    func saveDiagnosticResult(_ result: DiagnosticResult) {
        guard let encoded = try? JSONEncoder().encode(result) else { return }
        defaults.set(encoded, forKey: PreferenceKey.diagnosticResult(for: result.childID))
    }

    private func finishDiagnostic(_ session: DiagnosticSessionRuntime) {
        guard let profile else { return }
        clearDiagnosticFeedbackState()

        let result = diagnosticService.evaluate(session: session, childID: profile.id, catalog: curriculumCatalog)
        saveDiagnosticResult(result)

        diagnosticSession = nil
        diagnosticResult = result
        adaptivePath = adaptivePlanner.buildPath(result: result, catalog: curriculumCatalog)
        refreshDashboard()
        route = .home
        setStatus("Placement complete: \(result.placedGrade.title).")
        playSFX(.reward)
    }

    private func diagnosticFeedback(for question: DiagnosticQuestion, selectedIndex: Int) -> String {
        if selectedIndex == -1 {
            return "Thanks for telling me. I will use that to find a better starting point."
        }

        if selectedIndex == question.correctIndex {
            switch question.domain {
            case .numberSense:
                return "Nice number sense. I am noting how confidently that was solved."
            case .operations:
                return "Strong thinking. I am using that strategy signal for the next question."
            case .placeValue:
                return "Nice place-value thinking. That helps tune the next level."
            case .problemSolving:
                return "Good reasoning. I am checking how stories and equations connect."
            case .geometry:
                return "Nice noticing. That helps me place the next shape or measurement task."
            case .measurement:
                return "Careful measurement thinking. I am using that to shape the next task."
            case .fractions:
                return "Nice fraction reasoning. That gives me a clearer picture of the right level."
            }
        }

        return "Thanks for showing your thinking. I will use that to choose the next challenge."
    }
}
