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
                title: "You earned a sticker!",
                subtitle: sticker.title,
                ctaTitle: "Awesome!",
                onDismiss: onDismiss
            ) {
                // Sticker asset image (64pt, centred, themed background tile).
                stickerImageView(sticker.icon(for: appState.selectedTheme))
            }

            // Particle burst — preserved from original view; layered above modal.
            if !reduceMotion {
                ParticleBurstView()
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

    private func stickerImageView(_ icon: StickerIcon) -> some View {
        Image(icon.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
    }
}

struct ParticleBurstView: View {
    @State private var animate = false
    private let particles: [(angle: Double, color: Color)] = (0..<20).map { i in
        (angle: Double(i) * 18.0,
         color: [Color.yellow, .pink, .mint, .orange, .purple][i % 5])
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<particles.count, id: \.self) { i in
                    let p = particles[i]
                    let radian = p.angle * .pi / 180
                    let distance: CGFloat = animate ? 180 : 0
                    Circle()
                        .fill(p.color)
                        .frame(width: 10, height: 10)
                        .position(
                            x: center.x + cos(radian) * distance,
                            y: center.y + sin(radian) * distance
                        )
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
