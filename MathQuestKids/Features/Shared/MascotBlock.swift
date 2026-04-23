import SwiftUI

struct MascotBlock: View {
    let companion: ThemeCompanion          // existing type from CharacterPacks.swift
    let context: MascotVoice.Context
    let theme: VisualTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false
    @State private var orbit = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sp3) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(companion.name).kidText(.caption).foregroundStyle(.secondary)
                bubble
            }
            Spacer(minLength: 0)
        }
        .onAppear {
            bob = true
            orbit = true
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(theme.primary.opacity(0.12))
                .frame(width: 74, height: 74)
                .blur(radius: 10)

            orbitToken

            ThemeCompanionArtworkView(
                companion: companion,
                theme: theme,
                size: 56,
                highlighted: true
            )
        }
        .frame(width: 60, height: 60)
        .offset(y: bob ? -4 : 4)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
        .animation(reduceMotion ? nil : Motion.kidBounceIdle, value: bob)
    }

    private var orbitToken: some View {
        Circle()
            .fill(Color.white.opacity(0.92))
            .frame(width: 10, height: 10)
            .overlay {
                Image(systemName: theme.decorativeSymbols.first ?? "sparkles")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(theme.primary)
            }
            .offset(x: orbit ? 19 : -19, y: orbit ? -16 : 16)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                value: orbit
            )
    }

    private var bubble: some View {
        Text(MascotVoice.phrase(for: context, tone: companion.tone))
            .kidText(.body)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.sp4)
            .padding(.vertical, DesignTokens.Spacing.sp3)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.98), theme.accent.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: SpeechBubbleShape(cornerRadius: DesignTokens.Radius.md)
            )
            .overlay {
                SpeechBubbleShape(cornerRadius: DesignTokens.Radius.md)
                    .stroke(theme.primary.opacity(0.16), lineWidth: 1.5)
            }
            .shadow(color: theme.primary.opacity(0.08), radius: 14, x: 0, y: 4)
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 2)
    }
}

// Rounded rectangle with a tail pointing left toward the avatar.
private struct SpeechBubbleShape: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: cornerRadius)
        let tipY = rect.minY + 16
        var tail = Path()
        tail.move(to: CGPoint(x: rect.minX, y: tipY - 6))
        tail.addLine(to: CGPoint(x: rect.minX - 8, y: tipY))
        tail.addLine(to: CGPoint(x: rect.minX, y: tipY + 6))
        tail.closeSubpath()
        path.addPath(tail)
        return path
    }
}
