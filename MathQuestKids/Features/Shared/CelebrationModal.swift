import SwiftUI

/// Reusable modal for reward/celebration moments.
/// Implements the Sproutmath Design System §Modals spec:
/// themed bg1→bg2 gradient backdrop, white 95% card, sticker pop-in, MascotBlock, CTA pill.
///
/// Usage: present full-screen via `.fullScreenCover` or as an overlay.
/// The caller is responsible for the dismiss transition.
struct CelebrationModal<StickerContent: View>: View {
    let theme: VisualTheme
    let companion: ThemeCompanion
    let mascotContext: MascotVoice.Context
    let eyebrow: String?
    let title: String
    let subtitle: String?
    let ctaTitle: String
    let onDismiss: () -> Void
    @ViewBuilder let stickerContent: () -> StickerContent

    @State private var hasPopped = false
    @State private var haloAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Themed gradient backdrop (spec: bg1 → bg2, topLeading → bottomTrailing).
                LinearGradient(
                    colors: [theme.bg1, theme.bg2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                rewardBackdrop(theme: theme, size: geo.size)

                ScrollView(showsIndicators: false) {
                    // White card (spec: 95% white, 24pt corner radius, responsive width).
                    VStack(spacing: DesignTokens.Spacing.sp4) {
                        // Sticker content — pop-in spring animation (spec: 64pt, centered, spring).
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.18))
                                .frame(width: 156, height: 156)
                                .blur(radius: 8)
                            Circle()
                                .stroke(Color.white.opacity(0.85), lineWidth: 4)
                                .frame(width: haloAnimating ? 162 : 144, height: haloAnimating ? 162 : 144)
                                .opacity(haloAnimating ? 0.22 : 0.78)
                                .animation(
                                    reduceMotion ? nil : Motion.kidCelebratePulse,
                                    value: haloAnimating
                                )
                            starburst
                            stickerContent()
                                .scaleEffect(hasPopped ? 1 : 0)
                                .animation(
                                    reduceMotion
                                        ? .easeIn(duration: 0.2)
                                        : Motion.kidPopIn,
                                    value: hasPopped
                                )
                        }

                        if let eyebrow {
                            Text(eyebrow)
                                .kidText(.caption)
                                .foregroundStyle(theme.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(theme.primary.opacity(0.10), in: Capsule())
                        }

                        Text(title)
                            .kidText(.h1)
                            .multilineTextAlignment(.center)

                        if let subtitle {
                            Text(subtitle)
                                .kidText(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        MascotBlock(companion: companion, context: mascotContext, theme: theme)

                        Button(ctaTitle, action: onDismiss)
                            .buttonStyle(CTAButtonStyle(theme: theme))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(DesignTokens.Spacing.sp8)
                    .frame(maxWidth: min(max(geo.size.width - 48, 0), 380))
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white.opacity(0.95))
                            .overlay(alignment: .topLeading) {
                                LinearGradient(
                                    colors: [Color.white.opacity(0.65), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            }
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [theme.primary.opacity(0.24), Color.white.opacity(0.7), theme.accent.opacity(0.24)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: .black.opacity(0.2), radius: 60, x: 0, y: 20)
                    .padding(DesignTokens.Spacing.sp6)
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        hasPopped = true
                        haloAnimating = true
                    }
                }
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    private var starburst: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), theme.accent.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 8, height: 58)
                    .offset(y: -56)
                    .rotationEffect(.degrees(Double(index) * 36))
                    .opacity(0.48)
            }
        }
    }
}

private func rewardBackdrop(theme: VisualTheme, size: CGSize) -> some View {
    ZStack {
        Circle()
            .fill(theme.primary.opacity(0.22))
            .frame(width: size.width * 0.55)
            .blur(radius: 46)
            .offset(x: -size.width * 0.22, y: -size.height * 0.16)
        Circle()
            .fill(theme.accent.opacity(0.24))
            .frame(width: size.width * 0.48)
            .blur(radius: 44)
            .offset(x: size.width * 0.24, y: size.height * 0.12)

        if theme == .starsSpace {
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 3) ? "sparkles" : "star.fill")
                    .font(.system(size: CGFloat(10 + (index % 3) * 4), weight: .bold))
                    .foregroundStyle(index.isMultiple(of: 2) ? Color.white.opacity(0.55) : theme.accent.opacity(0.55))
                    .position(
                        x: starX(index: index, width: size.width),
                        y: starY(index: index, height: size.height)
                    )
            }
        } else if theme == .candyland {
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.34) : theme.accent.opacity(0.38))
                    .frame(width: CGFloat(index.isMultiple(of: 2) ? 14 : 10), height: CGFloat(index.isMultiple(of: 2) ? 14 : 10))
                    .overlay(
                        Circle()
                            .fill(index.isMultiple(of: 2) ? theme.primary.opacity(0.48) : Color.white.opacity(0.18))
                            .frame(width: CGFloat(index.isMultiple(of: 2) ? 6 : 4), height: CGFloat(index.isMultiple(of: 2) ? 6 : 4))
                    )
                    .position(
                        x: starX(index: index, width: size.width),
                        y: starY(index: index, height: size.height)
                    )
            }
        }
    }
}

private func starX(index: Int, width: CGFloat) -> CGFloat {
    let normalized = CGFloat((index * 29) % 100) / 100
    return 24 + normalized * max(width - 48, 1)
}

private func starY(index: Int, height: CGFloat) -> CGFloat {
    let normalized = CGFloat((index * 41) % 100) / 100
    return 20 + normalized * max(height - 40, 1)
}
