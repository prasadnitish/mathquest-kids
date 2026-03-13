import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var parentAnswer = ""
    @State private var gateMessage = ""
    @State private var failedAttempts = 0
    @State private var diagnosticsExportURL: URL?
    @State private var diagnosticsExportStatus = ""

    var body: some View {
        NavigationStack {
            Group {
                if appState.parentGateRequired {
                    VStack(spacing: 14) {
                        Text(appState.parentGatePrompt.prompt)
                            .font(.title3.bold())

                        TextField("Answer", text: $parentAnswer)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Parent gate answer")

                        Button("Unlock Settings") {
                            if appState.validateParentGate(answer: parentAnswer) {
                                gateMessage = "Unlocked"
                                failedAttempts = 0
                            } else {
                                failedAttempts += 1
                                gateMessage = "Incorrect. Try again."
                                if failedAttempts >= 3 {
                                    appState.parentGatePrompt = ParentGateChallenge.newChallenge()
                                    parentAnswer = ""
                                    failedAttempts = 0
                                    gateMessage = "New question generated."
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        if !gateMessage.isEmpty {
                            Text(gateMessage)
                                .foregroundStyle(gateMessage == "Unlocked" ? AppTheme.primary : AppTheme.error)
                        }
                    }
                    .padding(24)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Parent Settings")
                                .font(.largeTitle.bold())

                            Text("Themes")
                                .font(.title2.bold())
                            Text("Choose a visual world with custom background art and colors.")
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(VisualTheme.allCases) { theme in
                                        ThemeCard(theme: theme, isSelected: appState.selectedTheme == theme) {
                                            appState.setTheme(theme)
                                        }
                                    }
                                }
                            }

                            Text("Character Packs")
                                .font(.title2.bold())
                            Text("Each theme includes mentor characters with unique coaching style.")
                                .foregroundStyle(.secondary)

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

                            Divider()

                            Text("Adaptive Learning")
                                .font(.title2.bold())
                            Text("Placement: \(appState.adaptivePath.placedGrade.title)")
                                .foregroundStyle(.secondary)

                            if let result = appState.diagnosticResult {
                                Text("Last diagnostic score: \(Int(result.overallScore * 100))%")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Diagnostic not completed yet.")
                                    .foregroundStyle(.secondary)
                            }

                            Button("Retake Diagnostic") {
                                dismiss()
                                appState.retakeDiagnostic()
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button("View Progress Report") {
                                appState.showParentDashboard = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .accessibilityLabel("View child progress report")

                            Divider()

                            Text("Narration")
                                .font(.title2.bold())
                            Text("Make the voice more lively and auto-read each new question.")
                                .foregroundStyle(.secondary)

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

                            Text("Sound Effects")
                                .font(.title2.bold())
                            Text("Theme-based layered sound cues for tap, hint, success, and rewards.")
                                .foregroundStyle(.secondary)

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

                            Divider()

                            Text("Privacy")
                                .font(.title2.bold())
                            Text("Sprout Math stores progress only on this iPad in v1. No third-party ads, analytics, or cloud sync are enabled by default.")
                                .foregroundStyle(.secondary)

                            Text("Safety")
                                .font(.title2.bold())
                            Text("Supportive feedback, short sessions, and deterministic offline content.")
                                .foregroundStyle(.secondary)

                            Divider()

                            Text("Diagnostics")
                                .font(.title2.bold())
                            Text("Local-only diagnostics are stored on-device. Generate a snapshot file to share for troubleshooting.")
                                .foregroundStyle(.secondary)

                            Button("Prepare Diagnostics Export") {
                                do {
                                    diagnosticsExportURL = try appState.exportDiagnosticsFile()
                                    diagnosticsExportStatus = "Diagnostics file ready."
                                } catch {
                                    diagnosticsExportStatus = "Couldn't prepare diagnostics export."
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            if let diagnosticsExportURL {
                                ShareLink(item: diagnosticsExportURL) {
                                    Label("Share Diagnostics File", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(PrimaryButtonStyle())

                                Text(diagnosticsExportURL.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !diagnosticsExportStatus.isEmpty {
                                Text(diagnosticsExportStatus)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $appState.showParentDashboard) {
                ParentDashboardView()
                    .environmentObject(appState)
            }
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
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white.opacity(0.98))
                }
                .frame(width: 170, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(theme.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(8)
            .background(isSelected ? theme.primary.opacity(0.18) : Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
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
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(companion.name)
                            .font(.headline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(companion.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary.opacity(0.78))
                    }

                    Spacer(minLength: 8)
                }

                Text(companion.tagline)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.84))
                    .lineLimit(3)

                if isSelected {
                    Label("Selected", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundStyle(theme.primary)
                }
            }
            .padding(14)
            .frame(width: 280, alignment: .leading)
            .background {
                Group {
                    if isSelected {
                        ZStack {
                            Image(theme.backgroundAssetName)
                                .resizable()
                                .scaledToFill()
                            Color.white.opacity(0.84)
                        }
                    } else {
                        Color.white.opacity(0.92)
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
