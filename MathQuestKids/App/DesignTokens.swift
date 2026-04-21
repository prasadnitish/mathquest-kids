import SwiftUI

enum DesignTokens {
    // ── Fixed semantic colors (never theme-overridden) ──
    static let correct       = Color(red: 0x16/255, green: 0xa3/255, blue: 0x4a/255)
    static let incorrect     = Color(red: 0xdc/255, green: 0x26/255, blue: 0x26/255)
    static let streakWarning = Color(red: 0xf5/255, green: 0x9e/255, blue: 0x0b/255)
    static let parentSlate   = Color(red: 0x1e/255, green: 0x29/255, blue: 0x3b/255)
    static let parentCard    = Color(red: 0x33/255, green: 0x41/255, blue: 0x55/255)
    static let parentMuted   = Color(red: 0x94/255, green: 0xa3/255, blue: 0xb8/255)

    // Result state backgrounds (answer buttons)
    static let correctBg     = Color(red: 0xdc/255, green: 0xfc/255, blue: 0xe7/255)
    static let correctText   = Color(red: 0x16/255, green: 0x65/255, blue: 0x34/255)
    static let incorrectBg   = Color(red: 0xfe/255, green: 0xe2/255, blue: 0xe2/255)
    static let incorrectText = Color(red: 0x99/255, green: 0x1b/255, blue: 0x1b/255)

    enum Spacing {
        static let sp1:  CGFloat = 4
        static let sp2:  CGFloat = 8
        static let sp3:  CGFloat = 12
        static let sp4:  CGFloat = 16
        static let sp6:  CGFloat = 24
        static let sp8:  CGFloat = 32
        static let sp12: CGFloat = 48
    }

    enum Radius {
        static let sm:   CGFloat = 6
        static let md:   CGFloat = 14
        static let lg:   CGFloat = 20
        static let pill: CGFloat = 999
    }

    enum Layout {
        static let minTapTarget: CGFloat = 48
    }
}
