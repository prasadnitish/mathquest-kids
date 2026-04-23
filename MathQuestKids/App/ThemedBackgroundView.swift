import SwiftUI

struct ThemedBackgroundView: View {
    let theme: VisualTheme
    var mode: Mode = .imageWithGradient

    enum Mode { case imageWithGradient, gradientOnly }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                switch mode {
                case .imageWithGradient:
                    Image(theme.backgroundAssetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .overlay(darkOverlay)
                        .ignoresSafeArea()
                case .gradientOnly:
                    LinearGradient(
                        colors: [theme.bg1, theme.bg2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }

                atmosphericGlow(proxy: proxy)
                themedSceneProps(proxy: proxy)
                accentBlobs(proxy: proxy)
                floatingParticles(size: proxy.size)
                edgeVignette
            }
            .onAppear { drift = true }
        }
    }

    private var darkOverlay: some View {
        LinearGradient(
            colors: overlayColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func atmosphericGlow(proxy: GeometryProxy) -> some View {
        ZStack {
            Circle()
                .fill(theme.primary.opacity(0.18))
                .frame(width: proxy.size.width * 0.75)
                .blur(radius: 70)
                .offset(x: proxy.size.width * 0.26, y: -proxy.size.height * 0.22)
            Circle()
                .fill(theme.accent.opacity(0.16))
                .frame(width: proxy.size.width * 0.62)
                .blur(radius: 64)
                .offset(x: -proxy.size.width * 0.3, y: proxy.size.height * 0.34)
        }
    }

    private func accentBlobs(proxy: GeometryProxy) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.24))
                .frame(width: proxy.size.width * 0.85).blur(radius: 60)
                .offset(x: -proxy.size.width * 0.35, y: -proxy.size.height * 0.38)
            Circle().fill(theme.accent.opacity(0.20))
                .frame(width: proxy.size.width * 0.9).blur(radius: 76)
                .offset(x: proxy.size.width * 0.28, y: proxy.size.height * 0.45)
        }
    }

    private func themedSceneProps(proxy: GeometryProxy) -> some View {
        ZStack {
            ForEach(Array(theme.decorativeSymbols.enumerated()), id: \.offset) { index, symbol in
                Image(systemName: symbol)
                    .font(.system(size: propSize(index: index), weight: .black))
                    .foregroundStyle(propGradient(index: index))
                    .opacity(scenePropOpacity)
                    .rotationEffect(.degrees(propRotation(index: index) + (drift ? 4 : -4)))
                    .offset(
                        x: propX(index: index, width: proxy.size.width) + (drift ? 8 : -8),
                        y: propY(index: index, height: proxy.size.height) + (drift ? -6 : 6)
                    )
                    .blur(radius: index == 0 ? 0 : 0.3)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 5.0 + Double(index)).repeatForever(autoreverses: true),
                        value: drift
                    )
            }

            Capsule()
                .fill(theme.primary.opacity(sceneGlowOpacity))
                .frame(width: proxy.size.width * 0.52, height: 110)
                .blur(radius: 16)
                .rotationEffect(.degrees(-18))
                .offset(x: -proxy.size.width * 0.26, y: proxy.size.height * 0.26)

            Capsule()
                .fill(theme.accent.opacity(sceneAccentOpacity))
                .frame(width: proxy.size.width * 0.46, height: 96)
                .blur(radius: 18)
                .rotationEffect(.degrees(24))
                .offset(x: proxy.size.width * 0.3, y: -proxy.size.height * 0.2)
        }
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
                    .animation(reduceMotion ? nil : .easeInOut(duration: 3.8 + Double(index) * 0.2).repeatForever(autoreverses: true), value: drift)
            }
        }
    }

    private var edgeVignette: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.12),
                .clear,
                .clear,
                Color.black.opacity(0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.multiply)
        .ignoresSafeArea()
    }

    private var overlayColors: [Color] {
        if theme == .starsSpace {
            return [
                Color.black.opacity(0.02),
                Color.black.opacity(0.08),
                Color.black.opacity(0.16)
            ]
        }
        if theme == .candyland {
            return [
                Color.white.opacity(0.02),
                Color(red: 0.56, green: 0.16, blue: 0.34).opacity(0.06),
                Color(red: 0.35, green: 0.10, blue: 0.18).opacity(0.14)
            ]
        }
        return [
            Color.black.opacity(0.06),
            Color.black.opacity(0.14),
            Color.black.opacity(0.24)
        ]
    }

    private var scenePropOpacity: Double {
        if mode == .gradientOnly { return 0.22 }
        if theme == .candyland { return 0.09 }
        return theme == .starsSpace ? 0.08 : 0.14
    }

    private var sceneGlowOpacity: Double {
        if mode == .gradientOnly { return 0.16 }
        if theme == .candyland { return 0.07 }
        return theme == .starsSpace ? 0.06 : 0.10
    }

    private var sceneAccentOpacity: Double {
        if mode == .gradientOnly { return 0.18 }
        if theme == .candyland { return 0.10 }
        return theme == .starsSpace ? 0.08 : 0.12
    }

    private func particleX(index: Int, width: CGFloat) -> CGFloat {
        let normalized = CGFloat((index * 37) % 100) / 100
        return (normalized - 0.5) * width * 0.9
    }

    private func particleY(index: Int, height: CGFloat) -> CGFloat {
        let normalized = CGFloat((index * 53) % 100) / 100
        return (normalized - 0.5) * height * 0.9
    }

    private func propSize(index: Int) -> CGFloat {
        CGFloat(92 - index * 12)
    }

    private func propRotation(index: Int) -> Double {
        switch index {
        case 0: return -14
        case 1: return 12
        default: return 26
        }
    }

    private func propX(index: Int, width: CGFloat) -> CGFloat {
        switch index {
        case 0: return -width * 0.34
        case 1: return width * 0.33
        default: return width * 0.06
        }
    }

    private func propY(index: Int, height: CGFloat) -> CGFloat {
        switch index {
        case 0: return -height * 0.24
        case 1: return height * 0.26
        default: return -height * 0.04
        }
    }

    private func propGradient(index: Int) -> LinearGradient {
        let colors: [Color]
        switch index {
        case 0:
            colors = [theme.accent.opacity(0.95), theme.primary.opacity(0.72)]
        case 1:
            colors = [Color.white.opacity(0.82), theme.accent.opacity(0.64)]
        default:
            colors = [theme.primary.opacity(0.74), theme.accent.opacity(0.58)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
