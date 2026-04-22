import SwiftUI

enum MotionDuration {
    static let feedback:   Double = 0.12   // button press, tap highlight
    static let state:      Double = 0.25   // answer selection, card reveal
    static let transition: Double = 0.5    // screen transition, modal entrance
    static let idle:       Double = 2.0    // mascot bounce, particle float
}

enum Motion {
    static let press:       Animation = .easeInOut(duration: MotionDuration.feedback)
    static let stateChange: Animation = .easeInOut(duration: MotionDuration.state)
    static let transition:  Animation = .easeInOut(duration: MotionDuration.transition)

    /// Idle mascot bounce — loop forever, auto-reverses.
    static let kidBounceIdle: Animation = .easeInOut(duration: MotionDuration.idle).repeatForever(autoreverses: true)

    /// Pop-in spring: sticker reveal, correct answer. ~0.5s spring.
    static let kidPopIn: Animation = .spring(response: 0.4, dampingFraction: 0.55)

    /// Short celebration pulse used on summary/reward accents.
    static let kidCelebratePulse: Animation = .spring(response: 0.5, dampingFraction: 0.7).repeatCount(2, autoreverses: true)

    /// Wiggle / shake: wrong answer feedback. 0.4s, keyframe via View modifier below.
    static let kidWiggle: Animation = .easeInOut(duration: 0.4)

    /// Float: sticker book decorative. 3s loop.
    static let kidFloat: Animation = .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
}

// MARK: - Keyframe wiggle helper

extension View {
    /// Apply a wiggle animation whose `trigger` value changing kicks off one shake.
    func wiggle(trigger: some Hashable) -> some View {
        modifier(WiggleModifier(trigger: AnyHashable(trigger)))
    }
}

private struct WiggleModifier: ViewModifier {
    let trigger: AnyHashable
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onChange(of: trigger) { _, _ in
                withAnimation(Motion.kidWiggle) { angle = -8 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(Motion.kidWiggle) { angle = 8 } }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { withAnimation(Motion.kidWiggle) { angle = -5 } }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { withAnimation(Motion.kidWiggle) { angle = 0 } }
            }
    }
}
