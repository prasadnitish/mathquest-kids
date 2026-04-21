import SwiftUI
import Testing
@testable import MathQuestKids

struct MotionTests {
    @Test
    func motionNamesResolve() {
        _ = Motion.kidBounceIdle
        _ = Motion.kidPopIn
        _ = Motion.kidWiggle
        _ = Motion.kidFloat
        _ = Motion.press
        _ = Motion.stateChange
        _ = Motion.transition
    }

    @Test
    func durationScaleMatchesSpec() {
        #expect(MotionDuration.feedback == 0.12)
        #expect(MotionDuration.state == 0.25)
        #expect(MotionDuration.transition == 0.5)
        #expect(MotionDuration.idle == 2.0)
    }
}
