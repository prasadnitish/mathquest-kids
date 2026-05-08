import SwiftUI

struct SessionSummaryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateBadge = false

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()

                SummaryTitlePill(title: summaryTitle)

                if let summary = appState.latestSummary {
                    MascotBlock(
                        companion: appState.activeCompanion,
                        context: summaryContext(for: summary),
                        theme: appState.selectedTheme
                    )
                    .padding(.horizontal, DesignTokens.Spacing.sp4)
                    .padding(.bottom, DesignTokens.Spacing.sp4)

                    SessionSummaryCard(
                        summary: summary,
                        nextLessonTitle: appState.adaptivePath.recommendedLessons.first?.title,
                        badgeSymbol: summaryBadgeSymbol,
                        animateBadge: animateBadge,
                        reduceMotion: reduceMotion,
                        theme: appState.selectedTheme
                    )

                    if !summary.missedItems.isEmpty {
                        ReviewItemsCard(missedItems: summary.missedItems)
                    }
                }

                SummaryActionButtons(
                    theme: appState.selectedTheme,
                    startNextQuest: appState.startRecommendedSession,
                    goHome: appState.goHome
                )

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
            } else if let chapterCelebration = appState.pendingChapterCelebration {
                ChapterCelebrationOverlay(celebration: chapterCelebration) {
                    appState.pendingChapterCelebration = nil
                }
                .transition(.opacity)
                .zIndex(9)
            }
        }
        .animation(
            Motion.stateChange,
            value: appState.pendingStickerReward != nil || appState.pendingChapterCelebration != nil
        )
    }

    private var summaryTitle: String {
        appState.latestSummary?.chapterCelebration != nil ? "Quest and Chapter Complete" : "Quest Complete"
    }

    private var summaryBadgeSymbol: String {
        appState.latestSummary?.chapterCelebration != nil ? "sparkles.rectangle.stack.fill" : "star.circle.fill"
    }

    private func summaryContext(for summary: SessionSummary) -> MascotVoice.Context {
        if summary.chapterCelebration != nil {
            return .chapterUnlocked
        }
        return appState.dashboard.streakDays > 0 ? .streakMilestone : .rewardEarned
    }
}

private struct SummaryTitlePill: View {
    let title: String

    var body: some View {
        Text(title)
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
    }
}

private struct SessionSummaryCard: View {
    let summary: SessionSummary
    let nextLessonTitle: String?
    let badgeSymbol: String
    let animateBadge: Bool
    let reduceMotion: Bool
    let theme: VisualTheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: badgeSymbol)
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.accent)
                .scaleEffect(animateBadge ? 1.0 : 0.82)
                .opacity(animateBadge ? 1.0 : 0.7)
                .animation(
                    reduceMotion ? nil : Motion.kidCelebratePulse,
                    value: animateBadge
                )

            if let chapterCelebration = summary.chapterCelebration {
                ChapterCelebrationBanner(celebration: chapterCelebration, theme: theme)
            }

            Text("\(summary.correctItems) of \(summary.totalItems) correct")
                .kidText(.h2)
            Text("Reward: \(summary.rewardTitle)")
                .kidText(.h2)
            Text(summary.nextRecommendation)
                .kidText(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let nextLessonTitle {
                Text("Next quest: \(nextLessonTitle)")
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summaryAccessibilityLabel)
    }

    private var summaryAccessibilityLabel: String {
        var parts = [
            "Session summary",
            "\(summary.correctItems) of \(summary.totalItems) correct",
            "Reward: \(summary.rewardTitle)",
            summary.nextRecommendation
        ]

        if let nextLessonTitle {
            parts.append("Next quest: \(nextLessonTitle)")
        }

        return parts.joined(separator: ", ")
    }
}

private struct ChapterCelebrationBanner: View {
    let celebration: ChapterCelebration
    let theme: VisualTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: celebration.summaryBadgeSymbol)
                    .foregroundStyle(theme.primary)
                Text(celebration.summaryHeadline)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(celebration.summarySubtitle)
                .kidText(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(theme.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.primary.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct ReviewItemsCard: View {
    let missedItems: [MissedItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                Text("Questions to Review")
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            ForEach(missedItems) { missed in
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

private struct SummaryActionButtons: View {
    let theme: VisualTheme
    let startNextQuest: () -> Void
    let goHome: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                nextQuestButton
                homeButton
            }
            VStack(spacing: 8) {
                nextQuestButton
                homeButton
            }
        }
    }

    private var nextQuestButton: some View {
        Button("Start Next Quest", action: startNextQuest)
            .buttonStyle(CTAButtonStyle(theme: theme))
            .accessibilityLabel("Start next recommended quest")
    }

    private var homeButton: some View {
        Button("Back to Home", action: goHome)
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Back to Home")
    }
}

private struct ChapterCelebrationOverlay: View {
    let celebration: ChapterCelebration
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            CelebrationModal(
                theme: appState.selectedTheme,
                companion: appState.activeCompanion,
                mascotContext: .chapterUnlocked,
                eyebrow: eyebrow,
                title: title,
                subtitle: subtitle,
                ctaTitle: ctaTitle,
                onDismiss: onDismiss
            ) {
                chapterBadge
            }

            if !reduceMotion {
                ParticleBurstView(theme: appState.selectedTheme)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            let phrase = CompanionPhrases.chapterUnlocked(tone: appState.activeCompanion.tone)
            appState.narrationService.speakFeedback(phrase, style: appState.narrationStyle, interrupt: true)
        }
    }

    private var eyebrow: String? {
        if celebration.isFinale {
            return appState.selectedTheme == .starsSpace ? "Galaxy complete" : "Big finish"
        }
        if let cleared = celebration.clearedChapter {
            return "\(cleared.chapterLabel) cleared"
        }
        return celebration.unlockedChapter?.chapterLabel
    }

    private var title: String {
        if celebration.isFinale {
            return appState.selectedTheme == .starsSpace ? "Every launch is shining!" : "Every treat path is glowing!"
        }
        if let unlocked = celebration.unlockedChapter {
            return "\(unlocked.title) unlocked!"
        }
        if let cleared = celebration.clearedChapter {
            return "\(cleared.title) complete!"
        }
        return "New chapter ready!"
    }

    private var subtitle: String? {
        if celebration.isFinale {
            return "You finished the full K-5 journey and lit up the whole adventure map."
        }
        if let cleared = celebration.clearedChapter, let unlocked = celebration.unlockedChapter {
            return "You finished \(cleared.title) and opened \(unlocked.title) for your next quest."
        }
        if let unlocked = celebration.unlockedChapter {
            return "\(unlocked.subtitle)"
        }
        if let cleared = celebration.clearedChapter {
            return "\(cleared.title) is complete and sparkling on your trail."
        }
        return nil
    }

    private var ctaTitle: String {
        celebration.unlockedChapter != nil ? "See My Route" : "Keep Going"
    }

    private var chapterBadge: some View {
        ZStack {
            Circle()
                .fill(appState.selectedTheme.primary.opacity(0.14))
                .frame(width: 150, height: 150)
                .blur(radius: 10)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            appState.selectedTheme.primary.opacity(0.24),
                            Color.white.opacity(0.92),
                            appState.selectedTheme.accent.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 144, height: 144)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 2)
                )

            VStack(spacing: 10) {
                Image(systemName: celebrationSymbol)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(appState.selectedTheme.primary)

                Text(chapterLabel)
                    .kidText(.caption)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.78), in: Capsule())
            }
        }
    }

    private var chapterLabel: String {
        celebration.unlockedChapter?.chapterLabel
            ?? celebration.clearedChapter?.chapterLabel
            ?? "New chapter"
    }

    private var celebrationSymbol: String {
        if celebration.isFinale {
            return "crown.fill"
        }
        return celebration.unlockedChapter?.landmark
            ?? celebration.clearedChapter?.landmark
            ?? appState.selectedTheme.heroSymbol
    }
}

private extension ChapterCelebration {
    var summaryHeadline: String {
        if isFinale {
            return "You cleared the final chapter."
        }
        if let unlocked = unlockedChapter {
            return "\(unlocked.title) is now open."
        }
        if let cleared = clearedChapter {
            return "You cleared \(cleared.title)."
        }
        return "A new route is ready."
    }

    var summarySubtitle: String {
        if isFinale {
            return "You made it all the way through the full adventure trail."
        }
        if let cleared = clearedChapter, let unlocked = unlockedChapter {
            return "You wrapped up \(cleared.chapterLabel) and unlocked \(unlocked.chapterLabel)."
        }
        if let unlocked = unlockedChapter {
            return "\(unlocked.chapterLabel) is glowing on your map now."
        }
        if let cleared = clearedChapter {
            return "\(cleared.chapterLabel) is complete and ready to shine on your trail."
        }
        return "Your adventure map just opened a new path."
    }

    var summaryBadgeSymbol: String {
        if isFinale {
            return "crown.fill"
        }
        return unlockedChapter != nil ? "map.fill" : "checkmark.seal.fill"
    }
}
