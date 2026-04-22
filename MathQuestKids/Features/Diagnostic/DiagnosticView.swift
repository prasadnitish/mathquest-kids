import SwiftUI

struct DiagnosticView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if let session = appState.diagnosticSession {
                content(session: session)
            } else {
                ProgressView("Preparing your questions...")
                    .kidText(.h2)
                    .task {
                        appState.startDiagnosticIfNeeded()
                    }
            }
        }
        .padding(24)
    }

    private func content(session: DiagnosticSessionRuntime) -> some View {
        let question = session.currentQuestion

        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp6) {
                headerCluster(session: session)

                AppCard(theme: appState.selectedTheme) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                        Text(question.prompt)
                            .kidText(.question)
                            .foregroundStyle(AppTheme.textPrimary)
                            .minimumScaleFactor(0.65)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("Diagnostic problem prompt")

                        Button {
                            appState.replayDiagnosticPrompt()
                        } label: {
                            Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
                        .disabled(appState.diagnosticInteractionDisabled)

                        if let feedback = appState.diagnosticFeedbackMessage {
                            Text(feedback)
                                .kidText(.body)
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(appState.selectedTheme.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                        .stroke(appState.selectedTheme.primary.opacity(0.18), lineWidth: 1)
                                )
                        }

                        VStack(spacing: DesignTokens.Spacing.sp2) {
                            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                                AnswerButton(
                                    index: index,
                                    title: choice,
                                    state: .default,
                                    theme: appState.selectedTheme,
                                    action: { appState.submitDiagnosticChoice(index) }
                                )
                                .disabled(appState.diagnosticInteractionDisabled)
                            }

                            AnswerButton(
                                index: 0,
                                title: "I don't know yet",
                                state: .idk,
                                theme: appState.selectedTheme,
                                action: handleDefer
                            )
                            .disabled(appState.diagnosticInteractionDisabled)
                        }

                        HStack {
                            Spacer()

                            Button("Maybe later") {
                                appState.skipDiagnosticForNow()
                            }
                            .buttonStyle(.plain)
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textPrimary.opacity(0.75))
                            .disabled(appState.diagnosticInteractionDisabled)

                            Spacer()
                        }
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.bottom, 18)
        .onAppear {
            appState.readDiagnosticPromptIfEnabled()
        }
        .onChange(of: session.index) { _, _ in
            appState.readDiagnosticPromptIfEnabled()
        }
    }

    private func handleDefer() {
        appState.submitDiagnosticDontKnow()
    }

    @ViewBuilder
    private func headerCluster(session: DiagnosticSessionRuntime) -> some View {
        if sizeClass == .regular {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sp4) {
                headerCard(session: session)

                MascotBlock(
                    companion: appState.activeCompanion,
                    context: .questionHint,
                    theme: appState.selectedTheme
                )
                .frame(maxWidth: 320)
                .padding(.top, DesignTokens.Spacing.sp2)
            }
        } else {
            headerCard(session: session)

            MascotBlock(
                companion: appState.activeCompanion,
                context: .questionHint,
                theme: appState.selectedTheme
            )
            .padding(.horizontal, DesignTokens.Spacing.sp4)
        }
    }

    private func headerCard(session: DiagnosticSessionRuntime) -> some View {
        AppCard(theme: appState.selectedTheme) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                Text("Quest Check")
                    .kidText(.display)
                    .foregroundStyle(AppTheme.textPrimary)
                    .minimumScaleFactor(0.7)

                Text("A few quick questions help me find a just-right starting trail for today.")
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: session.progress)
                    .tint(appState.selectedTheme.accent)
                    .accessibilityLabel("Quest check progress")
                    .accessibilityValue("\(min(session.index + 1, session.questions.count)) of \(session.questions.count)")

                Text("Question \(min(session.index + 1, session.questions.count)) of \(session.questions.count)")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }
}
