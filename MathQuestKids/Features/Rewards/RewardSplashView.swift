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

            VStack(spacing: 28) {
                Text("You earned a sticker!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                let icon = sticker.icon(for: appState.selectedTheme)
                Image(systemName: icon.systemName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(
                        LinearGradient(colors: icon.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: icon.gradient.first?.opacity(0.6) ?? .clear, radius: 12, y: 4)
                    .frame(width: 160, height: 160)
                .scaleEffect(appeared ? 1.0 : (reduceMotion ? 0.95 : 0.2))
                .opacity(appeared ? 1.0 : 0.0)
                .animation(
                    reduceMotion
                        ? .easeIn(duration: 0.25)
                        : .spring(response: 0.5, dampingFraction: 0.65),
                    value: appeared
                )

                Text(sticker.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Button("Awesome!") { onDismiss() }
                    .font(.title3.bold())
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent, in: Capsule())
                    .foregroundStyle(.white)
                    .accessibilityLabel("Dismiss sticker reward")
            }
            .padding(40)

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
            appState.narrationService.speakFeedback("You earned the \(sticker.title)!", style: appState.narrationStyle, interrupt: true)
        }
        .accessibilityAddTraits(.isModal)
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
