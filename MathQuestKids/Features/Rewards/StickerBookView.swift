import SwiftUI

struct StickerBookView: View {
    @EnvironmentObject private var appState: AppState
    @State private var lockedTapMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 16)]
    private let maxVisibleLocked = 3

    private var nextSticker: Sticker? {
        appState.stickerCollection.stickers.first(where: { !$0.isUnlocked })
    }

    var body: some View {
        ZStack {
            ThemedBackgroundView(theme: appState.selectedTheme, mode: .gradientOnly)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Button(action: { appState.goHome() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .kidText(.body)
                            Text("Done")
                                .kidText(.body)
                        }
                    }
                    .accessibilityLabel("Close sticker book")

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 4)

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp6) {
                        MascotBlock(
                            companion: appState.activeCompanion,
                            context: .rewardEarned,
                            theme: appState.selectedTheme
                        )
                        .padding(.horizontal, DesignTokens.Spacing.sp4)

                        AppCard(theme: appState.selectedTheme) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                                Text(bookTitle)
                                    .kidText(.display)
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(headerMessage)
                                    .kidText(.body)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: 10) {
                                    StickerBookStatPill(
                                        emoji: "✨",
                                        value: "\(appState.stickerCollection.earnedCount)",
                                        label: "earned"
                                    )
                                    StickerBookStatPill(
                                        emoji: "🎁",
                                        value: "\(max(0, appState.stickerCollection.totalCount - appState.stickerCollection.earnedCount))",
                                        label: "waiting"
                                    )
                                }

                                if let nextSticker {
                                    Text("Next surprise: \(nextSticker.unitType.title)")
                                        .kidText(.caption)
                                        .foregroundStyle(appState.selectedTheme.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(appState.selectedTheme.primary.opacity(0.12), in: Capsule())
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text(shelfTitle)
                                .kidText(.h2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)

                            LazyVGrid(columns: columns, spacing: 16) {
                                let unlocked = appState.stickerCollection.stickers.filter(\.isUnlocked)
                                let locked = appState.stickerCollection.stickers.filter { !$0.isUnlocked }
                                let visibleLocked = Array(locked.prefix(maxVisibleLocked))
                                let hiddenLockedCount = max(0, locked.count - visibleLocked.count)

                                ForEach(unlocked + visibleLocked) { sticker in
                                    StickerSlotView(
                                        sticker: sticker,
                                        theme: appState.selectedTheme
                                    ) {
                                        if !sticker.isUnlocked {
                                            if appState.isUnitUnlocked(sticker.unitType) {
                                                appState.startSession(for: sticker.unitType)
                                            } else {
                                                lockedTapMessage = "Play earlier quests to unlock \(sticker.unitType.title)."
                                            }
                                        }
                                    }
                                }

                                if hiddenLockedCount > 0 {
                                    MysteryTile(count: hiddenLockedCount, theme: appState.selectedTheme)
                                }
                            }
                            .padding(16)
                            .background(shelfBackground, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .stroke(shelfBorder, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
                .scrollContentBackground(.hidden)
            }

            if let message = lockedTapMessage {
                VStack {
                    Text(message)
                        .kidText(.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.72), in: Capsule())
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            Task {
                                try? await Task.sleep(nanoseconds: 2_500_000_000)
                                withAnimation(.easeOut(duration: 0.3)) {
                                    lockedTapMessage = nil
                                }
                            }
                        }

                    Spacer()
                }
                .padding(.top, 60)
                .animation(Motion.stateChange, value: lockedTapMessage != nil)
            }
        }
    }

    private var headerMessage: String {
        if appState.selectedTheme == .starsSpace {
            if appState.stickerCollection.earnedCount == 0 {
                return "Your first star badge is waiting in the galaxy vault."
            }
            if let nextSticker {
                return "You charted \(appState.stickerCollection.earnedCount) badges. One more mission gets you closer to \(nextSticker.title)."
            }
            return "The whole star vault is glowing. You collected every badge."
        }
        if appState.selectedTheme == .candyland {
            if appState.stickerCollection.earnedCount == 0 {
                return "Your first candy treasure is waiting on the treat shelf."
            }
            if let nextSticker {
                return "You collected \(appState.stickerCollection.earnedCount) sweet stickers. One more quest brings you \(nextSticker.title)."
            }
            return "Every treat shelf is full. You found every candy treasure."
        }
        if appState.stickerCollection.earnedCount == 0 {
            return "Your first shiny sticker is waiting for you."
        }
        if let nextSticker {
            return "You found \(appState.stickerCollection.earnedCount) stickers. Keep going for \(nextSticker.title)."
        }
        return "You filled the whole shelf with stickers. Amazing work."
    }

    private var bookTitle: String {
        switch appState.selectedTheme {
        case .starsSpace:
            return "Galaxy Sticker Atlas"
        case .candyland:
            return "Sweet Sticker Pantry"
        default:
            return "Sticker Book"
        }
    }

    private var shelfTitle: String {
        switch appState.selectedTheme {
        case .starsSpace:
            return "Orbital Display"
        case .candyland:
            return "Treat Shelf"
        default:
            return "Treasure Shelf"
        }
    }

    private var shelfBackground: some ShapeStyle {
        if appState.selectedTheme == .starsSpace {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        appState.selectedTheme.primary.opacity(0.16),
                        appState.selectedTheme.accent.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        if appState.selectedTheme == .candyland {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color(red: 1.00, green: 0.86, blue: 0.92).opacity(0.28),
                        Color(red: 1.00, green: 0.83, blue: 0.64).opacity(0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(Color.white.opacity(0.16))
    }

    private var shelfBorder: Color {
        switch appState.selectedTheme {
        case .starsSpace:
            return appState.selectedTheme.accent.opacity(0.34)
        case .candyland:
            return Color.white.opacity(0.46)
        default:
            return Color.white.opacity(0.3)
        }
    }
}

struct StickerSlotView: View {
    let sticker: Sticker
    let theme: VisualTheme
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showDate = false
    @State private var floating = false

    var body: some View {
        let icon = sticker.icon(for: theme)

        Button(action: {
            if sticker.isUnlocked { showDate.toggle() } else { onTap() }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(slotBackground)
                        .frame(width: 110, height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(slotBorder, lineWidth: sticker.isUnlocked ? 1.5 : 1)
                        )

                    if sticker.isUnlocked {
                        Image(icon.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 84, height: 84)
                            .offset(y: floating ? -4 : 4)
                            .rotationEffect(.degrees(floating ? -1.5 : 1.5))
                            .shadow(color: .black.opacity(0.16), radius: 10, y: 6)
                            .animation(reduceMotion ? nil : Motion.kidFloat, value: floating)

                        sparkleOverlay
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                Text(sticker.unitType.title)
                    .kidText(.caption)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 112)

                if showDate, let date = sticker.dateEarned {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .kidText(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(sticker.isUnlocked ? 1 : 0.72)
        .accessibilityLabel(sticker.isUnlocked
            ? "\(sticker.title) earned"
            : "Locked. Complete \(sticker.unitType.title) to unlock.")
        .onAppear {
            floating = sticker.isUnlocked
        }
    }

    private var slotBackground: Color {
        if theme == .starsSpace {
            return sticker.isUnlocked
                ? Color(red: 0.25, green: 0.23, blue: 0.54).opacity(0.84)
                : Color(red: 0.20, green: 0.20, blue: 0.36).opacity(0.72)
        }
        if theme == .candyland {
            return sticker.isUnlocked
                ? Color(red: 1.00, green: 0.84, blue: 0.92).opacity(0.84)
                : Color(red: 1.00, green: 0.79, blue: 0.86).opacity(0.44)
        }
        return sticker.isUnlocked
            ? Color.white.opacity(0.24)
            : Color.white.opacity(0.12)
    }

    private var slotBorder: Color {
        if theme == .starsSpace {
            return sticker.isUnlocked
                ? theme.accent.opacity(0.58)
                : Color.white.opacity(0.20)
        }
        if theme == .candyland {
            return sticker.isUnlocked
                ? theme.primary.opacity(0.40)
                : Color.white.opacity(0.34)
        }
        return sticker.isUnlocked
            ? Color.white.opacity(0.45)
            : Color.white.opacity(0.22)
    }

    @ViewBuilder
    private var sparkleOverlay: some View {
        ZStack {
            if theme == .starsSpace, sticker.isUnlocked {
                Circle()
                    .stroke(theme.accent.opacity(0.65), lineWidth: 3)
                    .frame(width: 92, height: 92)
                    .scaleEffect(x: 1.06, y: 0.62)
                    .rotationEffect(.degrees(-15))
            } else if theme == .candyland, sticker.isUnlocked {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(theme.accent.opacity(0.72), style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(-8))
            }

            VStack {
                HStack {
                    Spacer()
                    Text(theme == .starsSpace ? "🌠" : (theme == .candyland ? "🍬" : "✨"))
                        .font(.system(size: 18))
                        .opacity(0.9)
                }
                Spacer()
            }
            .frame(width: 96, height: 96)
        }
    }
}

private struct StickerBookStatPill: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 18))
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
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

private struct MysteryTile: View {
    let count: Int
    let theme: VisualTheme

    var body: some View {
        VStack(spacing: 6) {
            Text(theme == .starsSpace ? "🪐" : (theme == .candyland ? "🍭" : "❔"))
                .font(.system(size: 34))
            Text(theme == .starsSpace ? "Mystery capsules" : (theme == .candyland ? "Wrapped surprises" : "More surprises"))
                .kidText(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 122)
        .background(tileBackground, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(
                    borderColor,
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
        )
        .foregroundStyle(.white)
        .accessibilityLabel("More surprises coming — \(count) sticker\(count == 1 ? "" : "s") still to earn")
    }

    private var tileBackground: Color {
        if theme == .starsSpace {
            return Color(red: 0.18, green: 0.18, blue: 0.34).opacity(0.86)
        }
        if theme == .candyland {
            return Color(red: 1.00, green: 0.78, blue: 0.86).opacity(0.42)
        }
        return Color.white.opacity(0.14)
    }

    private var borderColor: Color {
        if theme == .starsSpace {
            return theme.accent.opacity(0.45)
        }
        if theme == .candyland {
            return theme.primary.opacity(0.34)
        }
        return Color.white.opacity(0.35)
    }
}
