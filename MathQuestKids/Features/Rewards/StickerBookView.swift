import SwiftUI

struct StickerBookView: View {
    @EnvironmentObject private var appState: AppState
    @State private var lockedTapMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140))]

    /// Maximum number of locked-but-not-yet-earned sticker slots shown in the grid.
    /// The rest collapse into a single MysteryTile to keep the reward loop feeling achievable.
    private let maxVisibleLocked = 4

    var body: some View {
        ZStack {
            ThemedBackgroundView(theme: appState.selectedTheme, mode: .gradientOnly)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header — Done on leading side to avoid gear icon overlap
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
                    VStack(alignment: .leading, spacing: 16) {
                        MascotBlock(
                            companion: appState.activeCompanion,
                            context: .rewardEarned,
                            theme: appState.selectedTheme
                        )
                        .padding(.horizontal, DesignTokens.Spacing.sp4)
                        .padding(.bottom, DesignTokens.Spacing.sp4)

                        Text("Sticker Book")
                            .kidText(.display)
                            .padding(.horizontal, 20)

                        Text("\(appState.stickerCollection.earnedCount) of \(appState.stickerCollection.totalCount) stickers earned")
                            .kidText(.body)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: columns, spacing: 16) {
                            // All unlocked stickers — shown in full
                            let unlocked = appState.stickerCollection.stickers.filter { $0.isUnlocked }
                            // Locked stickers — preserved in learning-path order
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
                                            lockedTapMessage = "Complete earlier quests to unlock \(sticker.unitType.title)."
                                        }
                                    }
                                }
                            }

                            if hiddenLockedCount > 0 {
                                MysteryTile(count: hiddenLockedCount)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
                .scrollContentBackground(.hidden)
            }

            // Feedback overlay for locked sticker taps
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
}

struct StickerSlotView: View {
    let sticker: Sticker
    let theme: VisualTheme
    let onTap: () -> Void
    @State private var showDate = false

    var body: some View {
        let icon = sticker.icon(for: theme)

        Button(action: {
            if sticker.isUnlocked { showDate.toggle() } else { onTap() }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemFill).opacity(sticker.isUnlocked ? 0.3 : 1))
                        .frame(width: 100, height: 100)

                    if sticker.isUnlocked {
                        Image(icon.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(sticker.unitType.title)
                    .kidText(.caption)
                    .foregroundStyle(sticker.isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 100)

                if showDate, let date = sticker.dateEarned {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .kidText(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sticker.isUnlocked
            ? "\(sticker.title) earned"
            : "Locked. Complete \(sticker.unitType.title) to unlock.")
        .opacity(sticker.isUnlocked ? 1 : 0.6)
    }
}

/// Collapses all remaining locked stickers into a single encouraging tile
/// so children see a bounded reward loop rather than an endless wall of grey locks.
private struct MysteryTile: View {
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("✨")
                .font(.system(size: 32))
            Text("More coming!")
                .kidText(.caption)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(
                    Color.white.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
        )
        .foregroundStyle(.white)
        .accessibilityLabel("More surprises coming — \(count) sticker\(count == 1 ? "" : "s") still to earn")
    }
}
