import SwiftUI

struct StickerBookView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        let count = sizeClass == .compact ? 2 : 3
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    var body: some View {
        ZStack {
            ThemedBackgroundView(theme: appState.selectedTheme)
                .ignoresSafeArea()

            // Translucent overlay for readability
            Color(.systemBackground).opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header — Done on leading side to avoid gear icon overlap
                HStack(alignment: .center) {
                    Button(action: { appState.goHome() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Done")
                                .font(.body.weight(.semibold))
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
                        Text("Sticker Book")
                            .font(.largeTitle.bold())
                            .padding(.horizontal, 20)

                        Text("\(appState.stickerCollection.earnedCount) of \(appState.stickerCollection.totalCount) stickers earned")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(appState.stickerCollection.stickers) { sticker in
                                StickerSlotView(
                                    sticker: sticker,
                                    theme: appState.selectedTheme
                                ) {
                                    if !sticker.isUnlocked {
                                        appState.startSession(for: sticker.unitType)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
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
                        .fill(
                            sticker.isUnlocked
                                ? AnyShapeStyle(LinearGradient(
                                    colors: icon.gradient.map { $0.opacity(0.18) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color(.secondarySystemFill))
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    sticker.isUnlocked
                                        ? icon.gradient.first?.opacity(0.3) ?? .clear
                                        : .clear,
                                    lineWidth: 1.5
                                )
                        )

                    if sticker.isUnlocked {
                        Image(systemName: icon.systemName)
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: icon.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: icon.gradient.first?.opacity(0.3) ?? .clear, radius: 3, y: 2)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(sticker.unitType.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(sticker.isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 100)

                if showDate, let date = sticker.dateEarned {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
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
