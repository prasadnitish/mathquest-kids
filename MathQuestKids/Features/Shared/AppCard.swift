import SwiftUI

struct AppCard<Content: View>: View {
    let theme: VisualTheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(DesignTokens.Spacing.sp6)
            .background {
                cardBackground
            }
            .overlay {
                cardOverlay
            }
            .shadow(color: theme.primary.opacity(0.08), radius: 22, x: 0, y: 8)
            .shadow(color: .black.opacity(0.08), radius: 30, x: 0, y: 10)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
    }

    private var cardBackground: some View {
        cardShape
            .fill(theme.cardSurface)
            .overlay(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.24),
                        Color.white.opacity(0.06),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(cardShape)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(theme.accent.opacity(0.08))
                    .frame(width: 160, height: 160)
                    .blur(radius: 36)
                    .offset(x: 34, y: 34)
                    .clipShape(cardShape)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: theme.decorativeSymbols.first ?? "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(theme.primary.opacity(0.16))
                    .padding(16)
            }
            .overlay(alignment: .bottomLeading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.14), theme.accent.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 120, height: 10)
                    .blur(radius: 10)
                    .offset(x: -12, y: 18)
                    .clipShape(cardShape)
            }
    }

    private var cardOverlay: some View {
        cardShape
            .stroke(Color.white.opacity(0.62), lineWidth: 1)
            .overlay {
                cardShape
                    .stroke(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.18), .clear, theme.accent.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
    }
}
