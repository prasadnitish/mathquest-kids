import SwiftUI

private enum ParentDataAction: String, Identifiable {
    case resetProgress
    case deleteProfile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .resetProgress:
            return "Reset Learning Progress?"
        case .deleteProfile:
            return "Delete Child Profile?"
        }
    }

    var message: String {
        switch self {
        case .resetProgress:
            return "This clears local practice history, diagnostic placement, mastery progress, rewards, and reports on this device. The child name stays in the app."
        case .deleteProfile:
            return "This removes the child name and all local learning data from this device. This action cannot be undone."
        }
    }

    var confirmTitle: String {
        switch self {
        case .resetProgress:
            return "Reset Progress"
        case .deleteProfile:
            return "Delete Profile"
        }
    }
}

enum ParentPINEditorMode: String, Identifiable {
    case change

    var id: String { rawValue }
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var parentAnswer = ""
    @State private var setupPIN = ""
    @State private var confirmSetupPIN = ""
    @State private var gateMessage = ""
    @State private var pendingDataAction: ParentDataAction?
    @State private var pinEditorMode: ParentPINEditorMode?

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackgroundView(theme: appState.selectedTheme, mode: .gradientOnly)
                    .ignoresSafeArea()

                Group {
                if appState.parentGateRequired {
                    if appState.parentPINConfigured {
                        ParentPINUnlockCard(
                            parentAnswer: $parentAnswer,
                            gateMessage: gateMessage,
                            cooldownSeconds: appState.parentGateCooldownSecondsRemaining,
                            isLocked: appState.isParentGateLocked,
                            onSubmit: unlockParentSettings
                        )
                    } else {
                        ParentPINSetupCard(
                            setupPIN: $setupPIN,
                            confirmSetupPIN: $confirmSetupPIN,
                            gateMessage: gateMessage,
                            onSave: saveNewParentPIN
                        )
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ParentSettingsHeroCard()

                            SettingsSectionCard(
                                title: "Learning Journey",
                                subtitle: "Review the child's current path and jump to the detailed progress report."
                            ) {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 10) {
                                        MetricPillView(
                                            title: "Current trail",
                                            value: appState.adaptivePath.placedGrade.title
                                        )
                                        MetricPillView(
                                            title: "Quest check",
                                            value: diagnosticSummary
                                        )
                                    }

                                    VStack(spacing: 10) {
                                        MetricPillView(
                                            title: "Current trail",
                                            value: appState.adaptivePath.placedGrade.title
                                        )
                                        MetricPillView(
                                            title: "Quest check",
                                            value: diagnosticSummary
                                        )
                                    }
                                }

                                Button("Retake Quest Check") {
                                    appState.scheduleDiagnosticRetakeAfterSettingsDismissal()
                                    dismiss()
                                }
                                .buttonStyle(SecondaryButtonStyle())

                                Button("View Progress Report") {
                                    appState.showParentDashboard = true
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .accessibilityLabel("View child progress report")
                            }

                            SettingsSectionCard(
                                title: "Look & Feel",
                                subtitle: "Pick the visual world and coaching buddy the child sees in the app."
                            ) {
                                Text("Themes")
                                    .kidText(.h2)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(VisualTheme.allCases) { theme in
                                            ThemeCard(theme: theme, isSelected: appState.selectedTheme == theme) {
                                                appState.setTheme(theme)
                                            }
                                        }
                                    }
                                }

                                Text("Buddies")
                                    .kidText(.h2)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(appState.availableCompanions) { companion in
                                            CompanionCard(
                                                companion: companion,
                                                isSelected: appState.selectedCompanionID == companion.id,
                                                theme: appState.selectedTheme
                                            ) {
                                                appState.setCompanion(companion.id)
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsSectionCard(
                                title: "Voice & Sound",
                                subtitle: "Tune narration and reward sounds without changing the learning flow."
                            ) {
                                Toggle(
                                    "Read question aloud automatically",
                                    isOn: Binding(
                                        get: { appState.autoReadQuestions },
                                        set: { appState.setAutoReadQuestions($0) }
                                    )
                                )

                                Picker(
                                    "Voice style",
                                    selection: Binding(
                                        get: { appState.narrationStyle },
                                        set: { appState.setNarrationStyle($0) }
                                    )
                                ) {
                                    ForEach(NarrationStyle.allCases) { style in
                                        Text(style.title).tag(style)
                                    }
                                }
                                .pickerStyle(.segmented)

                                Button("Preview Voice") {
                                    appState.previewNarrationStyle()
                                }
                                .buttonStyle(SecondaryButtonStyle())

                                Divider()

                                Toggle(
                                    "Enable sound effects",
                                    isOn: Binding(
                                        get: { appState.soundEffectsEnabled },
                                        set: { appState.setSoundEffectsEnabled($0) }
                                    )
                                )

                                Button("Preview Reward Sound") {
                                    appState.previewSoundEffects()
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }

                            SettingsSectionCard(
                                title: "Privacy & Controls",
                                subtitle: "All learning data stays on this device. Legal details, the parent PIN, and local delete tools live here."
                            ) {
                                Text("Sprout Math does not use ads, analytics SDKs, telemetry, crash-reporting services, or cloud sync in version 1. Parent Settings are protected by a 4-digit PIN stored securely on this device.")
                                    .foregroundStyle(.secondary)

                                Button {
                                    pinEditorMode = .change
                                } label: {
                                    SettingsLinkRow(
                                        title: "Change Parent PIN",
                                        subtitle: "Update the 4-digit PIN used to unlock parent settings and reports.",
                                        symbol: "key.fill"
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    LegalDocumentView(document: .privacyPolicy)
                                } label: {
                                    SettingsLinkRow(
                                        title: "Privacy Policy",
                                        subtitle: "How local data is stored on-device, what Sprout Math does not collect, and how deletion works.",
                                        symbol: "lock.doc"
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    LegalDocumentView(document: .termsOfUse)
                                } label: {
                                    SettingsLinkRow(
                                        title: "Terms of Use",
                                        subtitle: "Educational use, disclaimers, and contact details.",
                                        symbol: "doc.text"
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    LegalDocumentView(document: .support)
                                } label: {
                                    SettingsLinkRow(
                                        title: "Support",
                                        subtitle: "Contact support@sproutmath.app for help, questions, or privacy requests.",
                                        symbol: "questionmark.circle"
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(role: .destructive) {
                                    pendingDataAction = .resetProgress
                                } label: {
                                    SettingsLinkRow(
                                        title: "Reset Learning Progress",
                                        subtitle: "Clear local practice history, placement, rewards, and reports while keeping the child name.",
                                        symbol: "arrow.counterclockwise.circle",
                                        tint: DesignTokens.incorrect
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(role: .destructive) {
                                    pendingDataAction = .deleteProfile
                                } label: {
                                    SettingsLinkRow(
                                        title: "Delete Child Profile & Data",
                                        subtitle: "Remove the child name and all local learning data from this device.",
                                        symbol: "trash",
                                        tint: DesignTokens.incorrect
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            SettingsSectionCard(
                                title: "Safety Notes",
                                subtitle: "Short sessions, supportive feedback, and deterministic offline content."
                            ) {
                                Text("This version keeps the experience simple: local progress, predictable hints, and parent-controlled settings.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(20)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $appState.showParentDashboard) {
                ParentDashboardView()
                    .environmentObject(appState)
            }
            .sheet(item: $pinEditorMode) { mode in
                ParentPINEditorSheet(mode: mode) { newPIN in
                    try appState.saveParentPIN(newPIN)
                }
            }
            .alert(item: $pendingDataAction) { action in
                Alert(
                    title: Text(action.title),
                    message: Text(action.message),
                    primaryButton: .destructive(Text(action.confirmTitle)) {
                        performParentDataAction(action)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var navigationTitle: String {
        if appState.parentGateRequired {
            return appState.parentPINConfigured ? "Enter Parent PIN" : "Create Parent PIN"
        }
        return "Parent Settings"
    }

    private var diagnosticSummary: String {
        if let result = appState.diagnosticResult {
            return "\(Int(result.overallScore * 100))%"
        }
        return "Not finished yet"
    }

    private func performParentDataAction(_ action: ParentDataAction) {
        switch action {
        case .resetProgress:
            appState.resetLearningData()
        case .deleteProfile:
            appState.deleteProfileAndData()
            dismiss()
        }
    }

    private func saveNewParentPIN() {
        gateMessage = ""

        guard ParentPINPolicy.isValid(setupPIN), ParentPINPolicy.isValid(confirmSetupPIN) else {
            gateMessage = "Use exactly 4 digits for the parent PIN."
            return
        }

        guard setupPIN == confirmSetupPIN else {
            gateMessage = "The PIN entries do not match."
            return
        }

        do {
            try appState.saveParentPIN(setupPIN)
            setupPIN = ""
            confirmSetupPIN = ""
        } catch {
            gateMessage = "Couldn't save the parent PIN right now."
        }
    }

    private func unlockParentSettings() {
        switch appState.submitParentGate(answer: parentAnswer) {
        case .unlocked:
            gateMessage = ""
            parentAnswer = ""
        case .incorrect(let remainingAttempts):
            gateMessage = remainingAttempts == 1
                ? "Incorrect PIN. One try left before a short cooldown."
                : "Incorrect PIN. \(remainingAttempts) tries left."
        case .cooldown:
            parentAnswer = ""
            gateMessage = ""
        case .pinNotConfigured:
            gateMessage = "Create a parent PIN first."
        }
    }
}
