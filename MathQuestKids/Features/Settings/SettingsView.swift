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

private enum ParentPINEditorMode: String, Identifiable {
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
                        parentPINUnlockView
                    } else {
                        parentPINSetupView
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            parentSettingsHero

                            settingsSection(
                                title: "Learning Journey",
                                subtitle: "Review the child's current path and jump to the detailed progress report."
                            ) {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 10) {
                                        metricPill(
                                            title: "Current trail",
                                            value: appState.adaptivePath.placedGrade.title
                                        )
                                        metricPill(
                                            title: "Quest check",
                                            value: diagnosticSummary
                                        )
                                    }

                                    VStack(spacing: 10) {
                                        metricPill(
                                            title: "Current trail",
                                            value: appState.adaptivePath.placedGrade.title
                                        )
                                        metricPill(
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

                            settingsSection(
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

                            settingsSection(
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

                            settingsSection(
                                title: "Privacy & Controls",
                                subtitle: "All learning data stays on this device. Legal details, the parent PIN, and local delete tools live here."
                            ) {
                                Text("Sprout Math does not use ads, analytics SDKs, telemetry, crash-reporting services, or cloud sync in version 1. Parent Settings are protected by a 4-digit PIN stored securely on this device.")
                                    .foregroundStyle(.secondary)

                                Button {
                                    pinEditorMode = .change
                                } label: {
                                    settingsLinkLabel(
                                        title: "Change Parent PIN",
                                        subtitle: "Update the 4-digit PIN used to unlock parent settings and reports.",
                                        symbol: "key.fill"
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    LegalDocumentView(document: .privacyPolicy)
                                } label: {
                                    settingsLinkLabel(
                                        title: "Privacy Policy",
                                        subtitle: "How local data is stored on-device, what Sprout Math does not collect, and how deletion works.",
                                        symbol: "lock.doc"
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    LegalDocumentView(document: .termsOfUse)
                                } label: {
                                    settingsLinkLabel(
                                        title: "Terms of Use",
                                        subtitle: "Educational use, disclaimers, and contact details.",
                                        symbol: "doc.text"
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(role: .destructive) {
                                    pendingDataAction = .resetProgress
                                } label: {
                                    settingsLinkLabel(
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
                                    settingsLinkLabel(
                                        title: "Delete Child Profile & Data",
                                        subtitle: "Remove the child name and all local learning data from this device.",
                                        symbol: "trash",
                                        tint: DesignTokens.incorrect
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            settingsSection(
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

    private var parentPINUnlockView: some View {
        VStack(spacing: 16) {
            Text("Enter Parent PIN")
                .font(.title2.bold())

            Text("Use the 4-digit PIN to open parent settings, reports, and privacy controls.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("4-digit PIN", text: $parentAnswer)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: parentAnswer) { _, newValue in
                    parentAnswer = ParentPINPolicy.sanitize(newValue)
                }
                .accessibilityLabel("Parent PIN")

            Button("Unlock Settings") {
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
            .buttonStyle(SecondaryButtonStyle())
            .disabled(appState.isParentGateLocked || parentAnswer.count != ParentPINPolicy.requiredLength)

            if let seconds = appState.parentGateCooldownSecondsRemaining {
                Text("Too many attempts. Try again in about \(seconds) seconds.")
                    .foregroundStyle(DesignTokens.incorrect)
                    .multilineTextAlignment(.center)
            }

            if !gateMessage.isEmpty {
                Text(gateMessage)
                    .foregroundStyle(DesignTokens.incorrect)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
    }

    private var parentPINSetupView: some View {
        VStack(spacing: 16) {
            Text("Create Parent PIN")
                .font(.title2.bold())

            Text("Choose a 4-digit PIN to protect parent settings, reports, and local data controls.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("New 4-digit PIN", text: $setupPIN)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .textContentType(.newPassword)
                .onChange(of: setupPIN) { _, newValue in
                    setupPIN = ParentPINPolicy.sanitize(newValue)
                }
                .accessibilityLabel("New parent PIN")

            SecureField("Confirm 4-digit PIN", text: $confirmSetupPIN)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .textContentType(.newPassword)
                .onChange(of: confirmSetupPIN) { _, newValue in
                    confirmSetupPIN = ParentPINPolicy.sanitize(newValue)
                }
                .accessibilityLabel("Confirm parent PIN")

            Button("Save Parent PIN") {
                saveNewParentPIN()
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(setupPIN.count != ParentPINPolicy.requiredLength || confirmSetupPIN.count != ParentPINPolicy.requiredLength)

            if !gateMessage.isEmpty {
                Text(gateMessage)
                    .foregroundStyle(DesignTokens.incorrect)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
    }

    private var diagnosticSummary: String {
        if let result = appState.diagnosticResult {
            return "\(Int(result.overallScore * 100))%"
        }
        return "Not finished yet"
    }

    private var parentSettingsHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parent Settings")
                .kidText(.display)

            Text("Review progress, tune the app experience, and manage local data from one place.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .kidText(.h2)

            Text(subtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            content()
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func settingsLinkLabel(title: String, subtitle: String, symbol: String, tint: Color = AppTheme.textPrimary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
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
}

private struct ParentPINEditorSheet: View {
    let mode: ParentPINEditorMode
    let onSave: (String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Use a 4-digit PIN that only the parent or guardian knows.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SecureField("New 4-digit PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                        .textContentType(.newPassword)
                        .onChange(of: newPIN) { _, newValue in
                            newPIN = ParentPINPolicy.sanitize(newValue)
                        }

                    SecureField("Confirm 4-digit PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                        .textContentType(.newPassword)
                        .onChange(of: confirmPIN) { _, newValue in
                            confirmPIN = ParentPINPolicy.sanitize(newValue)
                        }

                    if !message.isEmpty {
                        Text(message)
                            .foregroundStyle(DesignTokens.incorrect)
                    }
                }
            }
            .navigationTitle(mode == .change ? "Change Parent PIN" : "Create Parent PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(newPIN.count != ParentPINPolicy.requiredLength || confirmPIN.count != ParentPINPolicy.requiredLength)
                }
            }
        }
    }

    private func save() {
        message = ""

        guard ParentPINPolicy.isValid(newPIN), ParentPINPolicy.isValid(confirmPIN) else {
            message = "Use exactly 4 digits for the parent PIN."
            return
        }

        guard newPIN == confirmPIN else {
            message = "The PIN entries do not match."
            return
        }

        do {
            try onSave(newPIN)
            dismiss()
        } catch {
            message = "Couldn't update the parent PIN right now."
        }
    }
}

private struct ThemeCard: View {
    let theme: VisualTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Image(theme.backgroundAssetName)
                        .resizable()
                        .scaledToFill()
                    LinearGradient(
                        colors: [Color.black.opacity(0.05), Color.black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Image(systemName: theme.heroSymbol)
                        .font(.system(size: 26, weight: .black)) // SF Symbol icon size
                        .foregroundStyle(.white.opacity(0.98))
                }
                .frame(width: 170, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(theme.name)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(8)
            .background(isSelected ? theme.primary.opacity(0.18) : AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(theme.name) theme")
    }
}

private struct CompanionCard: View {
    let companion: ThemeCompanion
    let isSelected: Bool
    let theme: VisualTheme
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.22))
                        Circle()
                            .stroke(theme.primary.opacity(0.45), lineWidth: 1.5)
                        if !companion.imageName.isEmpty {
                            Image(companion.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: companion.symbol)
                                .font(.system(size: 28, weight: .black)) // SF Symbol icon size
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(companion.name)
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(companion.title)
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textPrimary.opacity(0.78))
                    }

                    Spacer(minLength: 8)
                }

                Text(companion.tagline)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.84))
                    .lineLimit(3)

                if isSelected {
                    Label("Selected", systemImage: "checkmark.seal.fill")
                        .kidText(.caption)
                        .foregroundStyle(theme.primary)
                }
            }
            .padding(14)
            .frame(width: min(280, UIScreen.main.bounds.width - 80), alignment: .leading)
            .background {
                Group {
                    if isSelected {
                        ZStack {
                            Image(theme.backgroundAssetName)
                                .resizable()
                                .scaledToFill()
                            AppTheme.card.opacity(0.92)
                        }
                    } else {
                        AppTheme.card
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? theme.primary : Color.black.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.14 : 0.07), radius: isSelected ? 10 : 5, x: 0, y: isSelected ? 6 : 3)
        }
        .buttonStyle(.plain)
    }
}
