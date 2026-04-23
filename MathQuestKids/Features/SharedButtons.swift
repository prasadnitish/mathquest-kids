import SwiftUI

// MARK: - CTA (primary action; ONE per screen)

struct CTAButtonStyle: ButtonStyle {
    let theme: VisualTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .kidText(.h2)
            .foregroundStyle(theme.ctaText)
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
            .frame(minHeight: DesignTokens.Layout.minTapTarget)
            .background {
                Capsule()
                    .fill(theme.cta)
                    .overlay(alignment: .topLeading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.34), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay(alignment: .trailing) {
                        Image(systemName: theme.decorativeSymbols.first ?? "sparkles")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(theme.ctaText.opacity(0.16))
                            .padding(.trailing, 18)
                    }
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.32), lineWidth: 1.5)
                    }
            }
            .shadow(color: .black.opacity(configuration.isPressed ? 0.10 : 0.18),
                    radius: configuration.isPressed ? 6 : 20, x: 0, y: configuration.isPressed ? 2 : 6)
            .shadow(color: theme.primary.opacity(configuration.isPressed ? 0.14 : 0.24),
                    radius: configuration.isPressed ? 10 : 18, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Secondary (white pill)

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .kidText(.body)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .frame(minHeight: DesignTokens.Layout.minTapTarget)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.98), Color.white.opacity(0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        Capsule()
                            .stroke(Color.black.opacity(0.08), lineWidth: 2)
                    }
            }
            .shadow(color: .black.opacity(configuration.isPressed ? 0.06 : 0.1),
                    radius: configuration.isPressed ? 4 : 12, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Play (used inside lesson cards)

struct PlayButtonStyle: ButtonStyle {
    let theme: VisualTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .kidText(.body)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(minHeight: DesignTokens.Layout.minTapTarget)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.primary, theme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.28), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.24), lineWidth: 1.2)
                    }
            }
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 3)
            .shadow(color: theme.primary.opacity(0.22), radius: 16, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}
