import SwiftUI

struct RewardSplashView: View {
    let sticker: Sticker
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            CelebrationModal(
                theme: appState.selectedTheme,
                companion: appState.activeCompanion,
                mascotContext: .rewardEarned,
                eyebrow: rewardEyebrow,
                title: rewardTitle,
                subtitle: sticker.title,
                ctaTitle: rewardCTA,
                onDismiss: onDismiss
            ) {
                // Sticker asset image (64pt, centred, themed background tile).
                stickerImageView(sticker.icon(for: appState.selectedTheme))
            }

            // Particle burst — preserved from original view; layered above modal.
            if !reduceMotion {
                ParticleBurstView(theme: appState.selectedTheme)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // TTS narration — preserved from original view.
            let phrase = CompanionPhrases.stickerEarned(tone: appState.activeCompanion.tone)
            appState.narrationService.speakFeedback(phrase, style: appState.narrationStyle, interrupt: true)
        }
        .accessibilityAddTraits(.isModal)
    }

    private var rewardTitle: String {
        switch appState.selectedTheme {
        case .starsSpace:
            return "New Star Badge!"
        case .candyland:
            return "Sweet Surprise!"
        default:
            return "You earned a sticker!"
        }
    }

    private var rewardCTA: String {
        switch appState.selectedTheme {
        case .starsSpace:
            return "Launch On!"
        case .candyland:
            return "So Sweet!"
        default:
            return "Awesome!"
        }
    }

    private var rewardEyebrow: String? {
        let count = appState.stickerCollection.earnedCount
        if count <= 1 {
            return appState.selectedTheme == .starsSpace ? "First badge" : "First treasure"
        }
        if count.isMultiple(of: 10) {
            return appState.selectedTheme == .starsSpace ? "Galaxy milestone" : "Candy kingdom milestone"
        }
        if count.isMultiple(of: 5) {
            return appState.selectedTheme == .starsSpace ? "Mission milestone" : "Sweet streak"
        }
        return appState.selectedTheme == .starsSpace ? "Fresh discovery" : "Fresh find"
    }

    private func stickerImageView(_ icon: StickerIcon) -> some View {
        ZStack {
            if appState.selectedTheme == .starsSpace {
                Circle()
                    .stroke(appState.selectedTheme.accent.opacity(0.85), lineWidth: 5)
                    .frame(width: 162, height: 162)
                    .scaleEffect(x: 1.08, y: 0.56)
                    .rotationEffect(.degrees(-18))

                Circle()
                    .fill(appState.selectedTheme.primary.opacity(0.18))
                    .frame(width: 152, height: 152)
                    .blur(radius: 12)
            } else if appState.selectedTheme == .candyland {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 166, height: 166)
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(appState.selectedTheme.accent.opacity(0.82), lineWidth: 4)
                    )
                    .rotationEffect(.degrees(-8))

                Circle()
                    .fill(appState.selectedTheme.primary.opacity(0.14))
                    .frame(width: 150, height: 150)
                    .blur(radius: 12)
            }

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: stickerTileColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 142, height: 142)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(tileStrokeColor, lineWidth: 2)
                }

            Image(icon.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 118, height: 118)
                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        }
    }

    private var stickerTileColors: [Color] {
        if appState.selectedTheme == .starsSpace {
            return [
                Color(red: 0.19, green: 0.18, blue: 0.46),
                Color(red: 0.30, green: 0.28, blue: 0.62),
                appState.selectedTheme.accent.opacity(0.42)
            ]
        }
        if appState.selectedTheme == .candyland {
            return [
                Color(red: 1.00, green: 0.95, blue: 0.98),
                Color(red: 1.00, green: 0.82, blue: 0.90),
                Color(red: 1.00, green: 0.87, blue: 0.62)
            ]
        }
        return [
            appState.selectedTheme.primary.opacity(0.22),
            Color.white.opacity(0.92),
            appState.selectedTheme.accent.opacity(0.18)
        ]
    }

    private var tileStrokeColor: Color {
        switch appState.selectedTheme {
        case .starsSpace:
            return Color.white.opacity(0.52)
        case .candyland:
            return appState.selectedTheme.primary.opacity(0.24)
        default:
            return Color.white.opacity(0.65)
        }
    }
}

struct ParticleBurstView: View {
    let theme: VisualTheme
    @State private var animate = false
    private var particles: [(angle: Double, color: Color)] {
        let palette: [Color]
        if theme == .starsSpace {
            palette = [theme.accent, Color.white, Color.cyan, Color.pink, Color.indigo]
        } else if theme == .candyland {
            palette = [theme.primary, theme.accent, Color(red: 1.00, green: 0.84, blue: 0.92), Color.white, Color(red: 1.00, green: 0.70, blue: 0.55)]
        } else {
            palette = [Color.yellow, .pink, .mint, .orange, .purple]
        }
        return (0..<20).map { i in
            (angle: Double(i) * 18.0, color: palette[i % palette.count])
        }
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<particles.count, id: \.self) { i in
                    let p = particles[i]
                    let radian = p.angle * .pi / 180
                    let distance: CGFloat = animate ? 180 : 0
                    Group {
                        if theme == .starsSpace, i.isMultiple(of: 4) {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [p.color, p.color.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 22, height: 6)
                                .rotationEffect(.degrees(p.angle))
                        } else if theme == .candyland, i.isMultiple(of: 4) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(p.color)
                                .frame(width: 18, height: 8)
                                .rotationEffect(.degrees(p.angle))
                        } else if i.isMultiple(of: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(p.color)
                        } else {
                            Circle()
                                .fill(p.color)
                                .frame(width: 10, height: 10)
                        }
                    }
                        .position(
                            x: center.x + cos(radian) * distance,
                            y: center.y + sin(radian) * distance
                        )
                        .scaleEffect(animate ? 0.55 : 1.0)
                        .opacity(animate ? 0 : 1)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                animate = true
            }
        }
    }
}
