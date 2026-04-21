import SwiftUI

struct AppCard<Content: View>: View {
    let theme: VisualTheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(DesignTokens.Spacing.sp6)
            .background(theme.cardSurface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 4)
    }
}
