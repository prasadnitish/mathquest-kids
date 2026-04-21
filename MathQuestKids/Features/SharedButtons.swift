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
            .background(theme.cta, in: Capsule())
            .shadow(color: .black.opacity(configuration.isPressed ? 0.10 : 0.18),
                    radius: configuration.isPressed ? 6 : 20, x: 0, y: configuration.isPressed ? 2 : 6)
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
            .background(Color.white, in: Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 2))
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
            .background(theme.primary, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Ghost (translucent; used on themed backgrounds)

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .kidText(.body)
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .frame(minHeight: DesignTokens.Layout.minTapTarget)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Icon (circular 52x52)

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .kidText(.h2)
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 52, height: 52)
            .background(Color.white, in: Circle())
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Disabled / Loading

struct DisabledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .kidText(.h2)
            .foregroundStyle(Color.white.opacity(0.4))
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
            .frame(minHeight: DesignTokens.Layout.minTapTarget)
            .background(Color.white.opacity(0.3), in: Capsule())
    }
}

// MARK: - Motion stub (temporary — removed when WS10 lands real Motion.swift)

#if !WS10_MOTION_AVAILABLE
enum Motion {
    static let press: Animation = .easeInOut(duration: 0.12)
}
#endif
