import SwiftUI

struct RewardSplashView: View {
    let sticker: Sticker
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false
    @State private var showParticles = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 22) {
                Text("You earned a sticker!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                stickerIconView(sticker.icon(for: appState.selectedTheme))
                    .frame(width: 120, height: 120)
                .scaleEffect(appeared ? 1.0 : (reduceMotion ? 0.95 : 0.2))
                .opacity(appeared ? 1.0 : 0.0)
                .animation(
                    reduceMotion
                        ? .easeIn(duration: 0.25)
                        : .spring(response: 0.5, dampingFraction: 0.65),
                    value: appeared
                )

                Text(sticker.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                companionCelebration

                Button("Awesome!") { onDismiss() }
                    .font(.title3.bold())
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent, in: Capsule())
                    .foregroundStyle(.white)
                    .accessibilityLabel("Dismiss sticker reward")
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            if showParticles && !reduceMotion {
                ParticleBurstView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            appeared = true
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showParticles = true
                }
            }
            let companionPhrase = CompanionPhrases.stickerEarned(tone: appState.activeCompanion.tone)
            // Pass just the companion phrase for pre-generated audio match;
            // sticker title and companion name are shown on screen.
            appState.narrationService.speakFeedback(companionPhrase, style: appState.narrationStyle, interrupt: true)
        }
        .accessibilityAddTraits(.isModal)
    }

    private func stickerIconView(_ icon: StickerIcon) -> some View {
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

    private var companionCelebration: some View {
        let companion = appState.activeCompanion
        let phrase = CompanionPhrases.stickerEarned(tone: companion.tone)

        return HStack(spacing: 10) {
            Group {
                if !companion.imageName.isEmpty {
                    Image(companion.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Image(systemName: companion.symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(appState.selectedTheme.primary.opacity(0.85), in: Circle())
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(companion.name)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))
                Text(phrase)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
        }
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
