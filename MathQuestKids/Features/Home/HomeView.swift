import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    private var featuredLesson: LessonPlanItem? {
        appState.adaptivePath.recommendedLessons.first
    }

    private var missionChipTitles: [String] {
        Array(appState.adaptivePath.recommendedLessons.prefix(3).map(\.title))
    }

    private var nextSticker: Sticker? {
        appState.stickerCollection.stickers.first(where: { !$0.isUnlocked })
    }

    private var streakMessage: String {
        switch appState.dashboard.streakDays {
        case 5...:
            return "Your sparkle streak is glowing bright."
        case 2...:
            return "You're building a shiny streak."
        case 1:
            return "You played today. That's a great start."
        default:
            return "One quest today starts your streak."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp6) {
                heroSection

                MascotBlock(
                    companion: appState.activeCompanion,
                    context: appState.dashboard.streakDays >= 3 ? .streakMilestone : .homeGreeting,
                    theme: appState.selectedTheme
                )
                .padding(.horizontal, DesignTokens.Spacing.sp4)

                missionSection
                progressSection
                companionSection

                SkillTrailView(trail: appState.skillTrail)
                    .environmentObject(appState)

                stickerSection
            }
            .padding(.horizontal, DesignTokens.Spacing.sp6)
            .padding(.top, 84)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .overlay(alignment: .top) {
            if let message = appState.statusMessage {
                Text(message)
                    .kidText(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    private var heroSection: some View {
        AppCard(theme: appState.selectedTheme) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                Text("\(greeting), \(appState.profile?.displayName ?? "Explorer")")
                    .kidText(.display)
                    .foregroundStyle(AppTheme.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)

                Text("Ready for your next math adventure?")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(streakMessage)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 10) {
                    FriendlyStatPill(
                        emoji: "✨",
                        value: "\(appState.stickerCollection.earnedCount)",
                        label: "stickers"
                    )
                    FriendlyStatPill(
                        emoji: "🔥",
                        value: "\(appState.dashboard.streakDays)",
                        label: "day glow"
                    )
                }
            }
        }
    }

    private var missionSection: some View {
        AppCard(theme: appState.selectedTheme) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                Text("Today's Mission")
                    .kidText(.caption)
                    .foregroundStyle(appState.selectedTheme.primary)

                Text(featuredLesson?.title ?? "Find your just-right quest")
                    .kidText(.h1)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(missionDescription)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !missionChipTitles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(missionChipTitles, id: \.self) { title in
                                Text(title)
                                    .kidText(.caption)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(appState.selectedTheme.primary.opacity(0.12), in: Capsule())
                            }
                        }
                    }
                }

                if let nextSticker {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .kidText(.h2)
                            .foregroundStyle(appState.selectedTheme.accent)
                        Text("Next shiny surprise: \(nextSticker.unitType.title)")
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(appState.selectedTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        missionStartButton
                        roadmapButton
                    }
                    VStack(spacing: 8) {
                        missionStartButton
                        roadmapButton
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        AppCard(theme: appState.selectedTheme) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                Text("Your Garden")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(progressMessage)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: appState.dashboard.rewardProgress)
                    .tint(appState.selectedTheme.primary)

                HStack(spacing: 10) {
                    FriendlyStatPill(
                        emoji: "🎯",
                        value: "\(appState.dashboard.completedSessions)",
                        label: "quests played"
                    )
                    FriendlyStatPill(
                        emoji: "🌟",
                        value: "\(max(0, 5 - min(5, appState.dashboard.streakDays)))",
                        label: "to next badge"
                    )
                }
            }
        }
    }

    private var companionSection: some View {
        AppCard(theme: appState.selectedTheme) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                Text("Pick Your Buddy")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(alignment: .top, spacing: 12) {
                    companionAvatar(appState.activeCompanion, size: 92)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.activeCompanion.name)
                            .kidText(.h2)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(appState.activeCompanion.title)
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\"\(appState.activeCompanion.tagline)\"")
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(appState.availableCompanions) { companion in
                            Button(action: { appState.setCompanion(companion.id) }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    companionAvatar(companion, size: 44)

                                    Text(companion.name)
                                        .kidText(.body)
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .lineLimit(1)

                                    Text(companion.title)
                                        .kidText(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                .padding(12)
                                .frame(width: 170, height: 122, alignment: .leading)
                                .background(
                                    appState.selectedCompanionID == companion.id
                                        ? appState.selectedTheme.primary.opacity(0.18)
                                        : Color.white.opacity(0.68),
                                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                        .stroke(
                                            appState.selectedCompanionID == companion.id ? appState.selectedTheme.primary : Color.white.opacity(0.6),
                                            lineWidth: appState.selectedCompanionID == companion.id ? 2 : 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var stickerSection: some View {
        AppCard(theme: appState.selectedTheme) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                Text("Sticker Treasure")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(stickerMessage)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Sticker Book") {
                    appState.openStickerBook()
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityLabel("Open Sticker Book")
            }
        }
    }

    private var missionStartButton: some View {
        Button(appState.isRecommendationPersonalized ? "Start Quest" : "Find My Starting Quest") {
            if appState.isRecommendationPersonalized {
                appState.startRecommendedSession()
            } else {
                appState.startDiagnosticIfNeeded()
                appState.route = .diagnostic
            }
        }
        .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
    }

    private var roadmapButton: some View {
        Button("Explore Quest Trail") {
            appState.openLessonPlans()
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var missionDescription: String {
        if let featuredLesson {
            return featuredLesson.activityPrompt
        }
        return "Take a quick quest check so I can pick adventures that feel just right."
    }

    private var progressMessage: String {
        switch appState.dashboard.completedSessions {
        case 0:
            return "Your garden is waiting for its first sparkle."
        case 1:
            return "You planted your first win. Keep growing."
        default:
            return "Every quest adds more sparkle to your garden."
        }
    }

    private var stickerMessage: String {
        if let nextSticker {
            return "You're \(appState.stickerCollection.earnedCount) stickers in. One more quest gets you closer to \(nextSticker.title)."
        }
        return "You found every sticker in this book. That's amazing."
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    @ViewBuilder
    private func companionAvatar(_ companion: ThemeCompanion, size: CGFloat) -> some View {
        ThemeCompanionArtworkView(
            companion: companion,
            theme: appState.selectedTheme,
            size: size,
            highlighted: companion.id == appState.selectedCompanionID
        )
    }
}

private struct FriendlyStatPill: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(label)
                    .kidText(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
    }
}
