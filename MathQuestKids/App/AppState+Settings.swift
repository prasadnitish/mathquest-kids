import Foundation

extension AppState {
    func setTheme(_ theme: VisualTheme) {
        selectedTheme = theme
        VisualTheme.persist(theme)
        selectedCompanionID = loadCompanion(for: theme)
        defaults.set(selectedCompanionID, forKey: PreferenceKey.selectedCompanion(for: theme))
    }

    func setCompanion(_ companionID: String) {
        guard availableCompanions.contains(where: { $0.id == companionID }) else { return }
        selectedCompanionID = companionID
        defaults.set(companionID, forKey: PreferenceKey.selectedCompanion(for: selectedTheme))
    }

    func setAutoReadQuestions(_ enabled: Bool) {
        autoReadQuestions = enabled
        if !enabled {
            cancelQuestionReadTask()
        }
        defaults.set(enabled, forKey: PreferenceKey.autoReadQuestions)
    }

    func setNarrationStyle(_ style: NarrationStyle) {
        narrationStyle = style
        defaults.set(style.rawValue, forKey: PreferenceKey.narrationStyle)
    }

    func previewNarrationStyle() {
        narrationService.preview(style: narrationStyle)
    }

    func setSoundEffectsEnabled(_ enabled: Bool) {
        soundEffectsEnabled = enabled
        defaults.set(enabled, forKey: PreferenceKey.soundEffectsEnabled)
    }

    func previewSoundEffects() {
        playSFX(.reward)
    }

    func showParentGate() {
        clearExpiredParentGateCooldown()
        parentGateRequired = true
    }

    func submitParentGate(answer: String, now: Date = .now) -> ParentGateResult {
        clearExpiredParentGateCooldown(now: now)

        guard parentPINConfigured else {
            return .pinNotConfigured
        }

        if let lockedUntil = parentGateLockedUntil, lockedUntil > now {
            return .cooldown(seconds: cooldownSeconds(until: lockedUntil, now: now))
        }

        let sanitizedAnswer = ParentPINPolicy.sanitize(answer.trimmingCharacters(in: .whitespacesAndNewlines))
        let isCorrect = parentPINStore.verify(pin: sanitizedAnswer)
        if isCorrect {
            parentGateFailureCount = 0
            parentGateLockedUntil = nil
            parentGateRequired = false
            return .unlocked
        }

        parentGateFailureCount += 1
        let remainingAttempts = max(0, ParentGatePolicy.maxAttempts - parentGateFailureCount)
        if remainingAttempts == 0 {
            let lockedUntil = now.addingTimeInterval(ParentGatePolicy.cooldownSeconds)
            parentGateFailureCount = 0
            parentGateLockedUntil = lockedUntil
            return .cooldown(seconds: cooldownSeconds(until: lockedUntil, now: now))
        }

        return .incorrect(remainingAttempts: remainingAttempts)
    }

    func saveParentPIN(_ pin: String) throws {
        try parentPINStore.save(pin: pin)
        parentPINConfigured = parentPINStore.isConfigured
        parentGateFailureCount = 0
        parentGateLockedUntil = nil
        parentGateRequired = false
    }

    var isParentGateLocked: Bool {
        guard let lockedUntil = parentGateLockedUntil else { return false }
        return lockedUntil > .now
    }

    var parentGateCooldownSecondsRemaining: Int? {
        guard let lockedUntil = parentGateLockedUntil, lockedUntil > .now else { return nil }
        return cooldownSeconds(until: lockedUntil, now: .now)
    }

    func scheduleDiagnosticRetakeAfterSettingsDismissal() {
        pendingSettingsDismissAction = .retakeDiagnostic
    }

    func handleSettingsDismissal() {
        guard let action = pendingSettingsDismissAction else { return }
        pendingSettingsDismissAction = nil

        switch action {
        case .retakeDiagnostic:
            retakeDiagnostic()
        }
    }

    func resetLearningData() {
        guard let profile else { return }

        do {
            try repository.deleteLearningData(childID: profile.id, deleteProfile: false)
            clearDiagnosticResult(childID: profile.id)
            clearLearningRuntimeState()
            refreshDashboard()
            route = .home
            setStatus("Learning progress reset on this device.")
        } catch {
            setStatus("Couldn't reset local learning data.")
        }
    }

    func deleteProfileAndData() {
        guard let profile else { return }

        do {
            try repository.deleteLearningData(childID: profile.id, deleteProfile: true)
            clearDiagnosticResult(childID: profile.id)
            clearLearningRuntimeState()
            clearParentGateState()
            dashboard = .empty
            stickerCollection = StickerCollection(stickers: [])
            adaptivePath = adaptivePlanner.buildPath(result: nil, catalog: curriculumCatalog)
            self.profile = nil
            route = .profileSetup
            setStatus("Child profile and local learning data deleted.")
        } catch {
            setStatus("Couldn't delete the child profile.")
        }
    }

    func loadCompanion(for theme: VisualTheme) -> String {
        let stored = defaults.string(forKey: PreferenceKey.selectedCompanion(for: theme))
        let available = CharacterPackLibrary.companions(for: theme)
        return available.first(where: { $0.id == stored })?.id
            ?? CharacterPackLibrary.defaultCompanion(for: theme).id
    }

    func clearExpiredParentGateCooldown(now: Date = .now) {
        guard let lockedUntil = parentGateLockedUntil, lockedUntil <= now else { return }
        parentGateLockedUntil = nil
    }

    func cooldownSeconds(until lockedUntil: Date, now: Date) -> Int {
        max(1, Int(ceil(lockedUntil.timeIntervalSince(now))))
    }

    func clearParentGateState() {
        parentGateFailureCount = 0
        parentGateLockedUntil = nil
        parentGateRequired = false
    }
}
