import SwiftUI

struct DiagnosticView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let session = appState.diagnosticSession {
                content(session: session)
            } else {
                ProgressView("Preparing diagnostic...")
                    .kidText(.h2)
                    .task {
                        appState.startDiagnosticIfNeeded()
                    }
            }
        }
        .padding(24)
    }

    private func content(session: DiagnosticSessionRuntime) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Learning Level Check")
                    .kidText(.display)
                    .foregroundStyle(AppTheme.textPrimary)
                    .minimumScaleFactor(0.7)

                Text("12 quick questions. This places your child at the right level and builds a personalized K-5 path.")
                    .kidText(.question)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.88))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: session.progress)
                    .tint(appState.selectedTheme.accent)

                Text("Question \(min(session.index + 1, session.questions.count)) of \(session.questions.count)")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.8))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )

            let question = session.currentQuestion

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    chip(title: question.targetGrade.title)
                    chip(title: question.domain.title)
                }

                Text(question.prompt)
                    .kidText(.question)
                    .foregroundStyle(AppTheme.textPrimary)
                    .minimumScaleFactor(0.65)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                if let feedback = appState.diagnosticFeedbackMessage {
                    Text(feedback)
                        .kidText(.h2)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(appState.selectedTheme.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(appState.selectedTheme.primary.opacity(0.18), lineWidth: 1)
                        )
                }

                ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                    Button {
                        appState.submitDiagnosticChoice(index)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(optionLetter(index))
                                .kidText(.answer)
                                .foregroundStyle(appState.selectedTheme.primary)
                            Text(choice)
                                .kidText(.answer)
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                            Spacer()
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(appState.selectedTheme.primary.opacity(0.24), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.diagnosticInteractionDisabled)
                    .accessibilityLabel("Option \(optionLetter(index)): \(choice)")
                }

                Button {
                    appState.submitDiagnosticDontKnow()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle.fill")
                            .kidText(.answer)
                            .foregroundStyle(appState.selectedTheme.primary)
                        Text("I don't know yet")
                            .kidText(.answer)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(appState.selectedTheme.primary.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    )
                }
                .buttonStyle(.plain)
                .disabled(appState.diagnosticInteractionDisabled)
                .accessibilityLabel("I don't know yet")
            }
            .padding(20)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 14, x: 0, y: 8)

            HStack {
                Button("Read Aloud") {
                    appState.replayDiagnosticPrompt()
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(appState.diagnosticInteractionDisabled)

                Button("Skip for Now") {
                    appState.skipDiagnosticForNow()
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(appState.diagnosticInteractionDisabled)

                Spacer()
            }
        }
        .onAppear {
            appState.readDiagnosticPromptIfEnabled()
        }
        .onChange(of: session.index) { _, _ in
            appState.readDiagnosticPromptIfEnabled()
        }
    }

    private func optionLetter(_ index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E"]
        return letters.indices.contains(index) ? letters[index] : "A"
    }

    private func chip(title: String) -> some View {
        Text(title)
            .kidText(.caption)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(appState.selectedTheme.primary.opacity(0.22), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(appState.selectedTheme.primary.opacity(0.42), lineWidth: 1)
            )
    }
}
