import SwiftUI

struct ThemedBackgroundView: View {
    let theme: VisualTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { proxy in
            let fullWidth = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            let fullHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom

            ZStack {
                Image(theme.backgroundAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: fullWidth, height: fullHeight)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.04),
                                Color.black.opacity(0.10),
                                Color.black.opacity(0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Circle()
                    .fill(Color.white.opacity(0.24))
                    .frame(width: proxy.size.width * 0.85)
                    .blur(radius: 60)
                    .offset(x: -proxy.size.width * 0.35, y: -proxy.size.height * 0.38)

                Circle()
                    .fill(theme.accent.opacity(0.20))
                    .frame(width: proxy.size.width * 0.9)
                    .blur(radius: 76)
                    .offset(x: proxy.size.width * 0.28, y: proxy.size.height * 0.45)

                floatingParticles(size: proxy.size)
            }
            .onAppear { drift = true }
        }
        .ignoresSafeArea()
    }

    private func floatingParticles(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: CGFloat(8 + (index % 4) * 7), height: CGFloat(8 + (index % 4) * 7))
                    .blur(radius: index % 3 == 0 ? 1.2 : 0)
                    .offset(
                        x: particleX(index: index, width: size.width) + (drift ? 6 : -6),
                        y: particleY(index: index, height: size.height) + (drift ? -8 : 8)
                    )
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 3.8 + Double(index) * 0.2).repeatForever(autoreverses: true),
                        value: drift
                    )
            }
        }
    }

    private func particleX(index: Int, width: CGFloat) -> CGFloat {
        let normalized = CGFloat((index * 37) % 100) / 100
        return (normalized - 0.5) * width * 0.9
    }

    private func particleY(index: Int, height: CGFloat) -> CGFloat {
        let normalized = CGFloat((index * 53) % 100) / 100
        return (normalized - 0.5) * height * 0.9
    }
}
