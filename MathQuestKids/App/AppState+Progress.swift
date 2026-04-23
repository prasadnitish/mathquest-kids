import Foundation

extension AppState {
    func isUnitUnlocked(_ unit: UnitType) -> Bool {
        dashboard.unitProgress.first(where: { $0.unit == unit })?.unlocked ?? (unit == .kCountObjects)
    }

    func setStatus(_ message: String?, autoClearSeconds: Double = 4.0) {
        statusClearTask?.cancel()
        statusMessage = message
        guard message != nil else { return }

        statusClearTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(autoClearSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            statusMessage = nil
        }
    }

    func clearLearningRuntimeState() {
        cancelQuestionReadTask()
        clearDiagnosticFeedbackState()
        sessionAdvanceTask?.cancel()
        sessionAdvanceTask = nil
        pendingSettingsDismissAction = nil
        currentSession = nil
        latestSummary = nil
        pendingStickerReward = nil
        pendingChapterCelebration = nil
        diagnosticSession = nil
        diagnosticResult = nil
        temporarilySkippedDiagnostic = false
        showParentDashboard = false
    }

    func refreshDashboard() {
        guard let profile else {
            dashboard = .empty
            return
        }

        let unitCounts = repository.unitSessionCounts(childID: profile.id)
        let unlockedUnits = buildUnlockedUnits(
            from: unitCounts,
            placementIndex: placementUnlockIndex(for: diagnosticResult?.placedGrade)
        )
        let progress = UnitType.learningPath.map { unit in
            UnitProgress(
                unit: unit,
                completedSessions: unitCounts[unit] ?? 0,
                unlocked: unlockedUnits.contains(unit)
            )
        }

        dashboard = DashboardSnapshot(
            completedSessions: repository.completedSessionCount(childID: profile.id),
            averageAccuracy: repository.averageAccuracy(childID: profile.id),
            streakDays: repository.streakDays(childID: profile.id),
            unitProgress: progress
        )
        refreshStickerCollection()
        adaptivePath = adaptivePlanner.buildPath(result: diagnosticResult, catalog: curriculumCatalog)
    }

    func openStickerBook() {
        route = .stickerBook
    }

    func checkAndAwardSticker(for unit: UnitType) {
        guard let profile else { return }
        let progress = dashboard.unitProgress.first(where: { $0.unit == unit })
        guard let progress, progress.completedSessions >= 1 else { return }
        let alreadyEarned = stickerCollection.stickers.first(where: { $0.unitType == unit })
        guard alreadyEarned?.isUnlocked != true else { return }

        try? repository.saveStickerEarned(childID: profile.id, unitRaw: unit.rawValue, dateEarned: .now)
        refreshStickerCollection()
        pendingStickerReward = Sticker(unitType: unit, dateEarned: .now)
    }

    func refreshStickerCollection() {
        guard let profile else { return }
        let records = repository.fetchStickers(childID: profile.id)
        stickerCollection = StickerCollection.build(from: records)
    }

    var progressReport: ProgressReport {
        guard let profile else { return .empty }
        return progressReportService.buildReport(
            for: profile,
            dashboard: dashboard,
            placedGrade: adaptivePath.placedGrade
        )
    }

    var skillTrail: SkillTrail {
        SkillTrail.build(
            dashboard: dashboard,
            stickerCollection: stickerCollection
        )
    }

    func chapterCelebration(
        from previousDashboard: DashboardSnapshot,
        to currentDashboard: DashboardSnapshot,
        finishedUnit: UnitType
    ) -> ChapterCelebration? {
        let chapters = TrailChapterCatalog.chapters(for: selectedTheme)
        guard
            let finishedChapterIndex = UnitType.chapterIndex(for: finishedUnit),
            chapters.indices.contains(finishedChapterIndex)
        else {
            return nil
        }

        let clearedChapter = chapters[finishedChapterIndex]
        let didClearChapter = !isChapterComplete(clearedChapter, in: previousDashboard)
            && isChapterComplete(clearedChapter, in: currentDashboard)

        var unlockedChapter: TrailChapterInfo?
        let nextChapterIndex = finishedChapterIndex + 1
        if chapters.indices.contains(nextChapterIndex) {
            let candidate = chapters[nextChapterIndex]
            let wasUnlocked = isChapterUnlocked(candidate, in: previousDashboard)
            let isUnlockedNow = isChapterUnlocked(candidate, in: currentDashboard)
            if !wasUnlocked && isUnlockedNow {
                unlockedChapter = candidate
            }
        }

        guard didClearChapter || unlockedChapter != nil else { return nil }
        return ChapterCelebration(
            clearedChapter: didClearChapter ? clearedChapter : nil,
            unlockedChapter: unlockedChapter
        )
    }

    private func placementUnlockIndex(for grade: GradeBand?) -> Int {
        guard let grade else { return 0 }
        switch grade {
        case .kindergarten: return 7
        case .grade1: return 12
        case .grade2: return 20
        case .grade3: return 26
        case .grade4: return 32
        case .grade5: return 37
        }
    }

    private func buildUnlockedUnits(
        from unitCounts: [UnitType: Int],
        placementIndex: Int
    ) -> Set<UnitType> {
        var unlockedUnits: Set<UnitType> = [.kCountObjects]
        let path = UnitType.learningPath

        if placementIndex >= 0 {
            for index in 0...min(placementIndex, path.count - 1) {
                unlockedUnits.insert(path[index])
            }
        }

        for (index, unit) in path.enumerated() where index > 0 {
            let previousUnit = path[index - 1]
            if (unitCounts[previousUnit] ?? 0) > 0 {
                unlockedUnits.insert(unit)
            }
        }

        return unlockedUnits
    }

    private func isChapterComplete(_ chapter: TrailChapterInfo, in dashboard: DashboardSnapshot) -> Bool {
        chapter.units.allSatisfy { unit in
            dashboard.unitProgress.first(where: { $0.unit == unit })?.completedSessions ?? 0 > 0
        }
    }

    private func isChapterUnlocked(_ chapter: TrailChapterInfo, in dashboard: DashboardSnapshot) -> Bool {
        chapter.units.contains { unit in
            dashboard.unitProgress.first(where: { $0.unit == unit })?.unlocked == true
        }
    }
}
