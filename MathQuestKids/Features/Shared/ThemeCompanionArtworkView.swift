import SwiftUI

struct ThemeCompanionArtworkView: View {
    let companion: ThemeCompanion
    let theme: VisualTheme
    let size: CGFloat
    var highlighted = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.accent.opacity(highlighted ? 0.30 : 0.20),
                            theme.primary.opacity(highlighted ? 0.24 : 0.14),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.75
                    )
                )
                .frame(width: size * 1.14, height: size * 1.14)
                .blur(radius: highlighted ? 10 : 8)

            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(Color.white.opacity(theme == .starsSpace ? 0.10 : 0.16))
                .frame(width: size * 0.96, height: size * 0.96)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.64),
                                    theme.accent.opacity(0.48),
                                    theme.primary.opacity(0.42)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: highlighted ? 2 : 1.5
                        )
                }

            if !companion.imageName.isEmpty {
                Image(companion.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.03)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 4)
            } else {
                Circle()
                    .fill(LinearGradient(colors: [theme.primary, theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size * 0.82, height: size * 0.82)
                Image(systemName: companion.symbol)
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size * 1.18, height: size * 1.18)
    }
}
