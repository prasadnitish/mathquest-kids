import SwiftUI

struct SessionSummaryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateBadge = false

    var body: some View {
        ZStack {
        VStack(spacing: 20) {
            Spacer()

            Text("Quest Complete")
                .kidText(.display)
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )

            if let summary = appState.latestSummary {
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 72)) // SF Symbol decorative icon — intentional size
                        .foregroundStyle(AppTheme.accent)
                        .scaleEffect(animateBadge ? 1.0 : 0.82)
                        .opacity(animateBadge ? 1.0 : 0.7)
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7).repeatCount(2, autoreverses: true),
                            value: animateBadge
                        )
                    Text("\(summary.correctItems) of \(summary.totalItems) correct")
                        .kidText(.h2)
                    Text("Reward: \(summary.rewardTitle)")
                        .kidText(.h2)
                    Text(summary.nextRecommendation)
                        .kidText(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    if let nextLesson = appState.adaptivePath.recommendedLessons.first {
                        Text("Next adaptive lesson: \(nextLesson.title)")
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
                .accessibilityLabel("Session summary")

                if !summary.missedItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.orange)
                            Text("Questions to Review")
                                .kidText(.body)
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        ForEach(summary.missedItems) { missed in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "arrow.turn.down.right")
                                    .kidText(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.top, 3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(missed.prompt)
                                        .kidText(.body)
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    HStack(spacing: 4) {
                                        Text("Answer:")
                                            .kidText(.body)
                                            .foregroundStyle(AppTheme.textSecondary)
                                        Text(missed.correctAnswer)
                                            .kidText(.body)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
                    .accessibilityLabel("Questions to review")
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    Button("Start Next Quest") { appState.startRecommendedSession() }
                        .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
                        .accessibilityLabel("Start next recommended quest")
                    Button("Back to Home") { appState.goHome() }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityLabel("Back to Home")
                }
                VStack(spacing: 8) {
                    Button("Start Next Quest") { appState.startRecommendedSession() }
                        .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
                        .accessibilityLabel("Start next recommended quest")
                    Button("Back to Home") { appState.goHome() }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityLabel("Back to Home")
                }
            }

            Spacer()
        }
        .padding(24)
        .background(.clear)
        .onAppear {
            animateBadge = true
        }

            if let sticker = appState.pendingStickerReward {
                RewardSplashView(sticker: sticker) {
                    appState.pendingStickerReward = nil
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.pendingStickerReward != nil)
    }
}
