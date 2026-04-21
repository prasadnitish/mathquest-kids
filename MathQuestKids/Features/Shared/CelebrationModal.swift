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
    let title: String
    let subtitle: String?
    let ctaTitle: String
    let onDismiss: () -> Void
    @ViewBuilder let stickerContent: () -> StickerContent

    // NOTE: .spring inline values intentional — WS10 will replace with Motion.kidPopIn.
    @State private var hasPopped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Themed gradient backdrop (spec: bg1 → bg2, topLeading → bottomTrailing).
            LinearGradient(
                colors: [theme.bg1, theme.bg2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // White card (spec: 95% white, 24pt corner radius, max 300pt wide).
            VStack(spacing: DesignTokens.Spacing.sp4) {
                // Sticker content — pop-in spring animation (spec: 64pt, centered, spring).
                stickerContent()
                    .scaleEffect(hasPopped ? 1 : 0)
                    .animation(
                        reduceMotion
                            ? .easeIn(duration: 0.2)
                            : .spring(response: 0.5, dampingFraction: 0.55),
                        value: hasPopped
                    )

                Text(title)
                    .kidText(.h1)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .kidText(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                MascotBlock(companion: companion, context: .rewardEarned, theme: theme)

                Button(ctaTitle, action: onDismiss)
                    .buttonStyle(CTAButtonStyle(theme: theme))
                    .frame(maxWidth: .infinity)
            }
            .padding(DesignTokens.Spacing.sp8)
            .frame(maxWidth: 300)
            .background(Color.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 60, x: 0, y: 20)
            .padding(DesignTokens.Spacing.sp6)
            .onAppear { hasPopped = true }
        }
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Emoji convenience initialiser

extension CelebrationModal where StickerContent == Text {
    /// Convenience init for emoji stickers (the common design-system case).
    init(
        theme: VisualTheme,
        companion: ThemeCompanion,
        sticker: String,
        title: String,
        subtitle: String? = nil,
        ctaTitle: String,
        onDismiss: @escaping () -> Void
    ) {
        self.theme = theme
        self.companion = companion
        self.title = title
        self.subtitle = subtitle
        self.ctaTitle = ctaTitle
        self.onDismiss = onDismiss
        self.stickerContent = {
            Text(sticker)
                .font(.system(size: 64))
        }
    }
}
