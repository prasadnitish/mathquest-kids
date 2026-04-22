import SwiftUI

struct MascotBlock: View {
    let companion: ThemeCompanion          // existing type from CharacterPacks.swift
    let context: MascotVoice.Context
    let theme: VisualTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sp3) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(companion.name).kidText(.caption).foregroundStyle(.secondary)
                bubble
            }
            Spacer(minLength: 0)
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [theme.primary, theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: companion.symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 52, height: 52)
        .offset(y: bob ? -4 : 4)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
        .animation(reduceMotion ? nil : Motion.kidBounceIdle, value: bob)
        .onAppear { bob = true }
    }

    private var bubble: some View {
        Text(MascotVoice.phrase(for: context, tone: companion.tone))
            .kidText(.body)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.sp4)
            .padding(.vertical, DesignTokens.Spacing.sp3)
            .background(Color.white, in: SpeechBubbleShape(cornerRadius: DesignTokens.Radius.md))
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
