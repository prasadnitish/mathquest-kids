import Foundation

enum CompanionPhrases {

    // MARK: - Correct answer

    static func correct(tone: CompanionTone) -> String {
        pool(for: tone, from: correctPools).randomElement()!
    }

    private static let correctPools: [CompanionTone: [String]] = [
        .encouraging: [
            "You've got this!",
            "That's the way!",
            "So proud of you!",
            "Look at you go!",
            "Wonderful work!"
        ],
        .energetic: [
            "Boom! Nailed it!",
            "Yes yes yes!",
            "Crushed it!",
            "On fire!",
            "Let's gooo!"
        ],
        .calm: [
            "Well done.",
            "Nicely solved.",
            "Steady and strong.",
            "That's right.",
            "Smooth thinking."
        ]
    ]

    // MARK: - Incorrect answer

    static func incorrect(tone: CompanionTone) -> String {
        pool(for: tone, from: incorrectPools).randomElement()!
    }

    private static let incorrectPools: [CompanionTone: [String]] = [
        .encouraging: [
            "Almost there!",
            "You're so close!",
            "Try once more!",
            "Keep going!",
            "Don't give up!"
        ],
        .energetic: [
            "Shake it off!",
            "Power through!",
            "Next try wins!",
            "Bounce back!",
            "Not done yet!"
        ],
        .calm: [
            "Take your time.",
            "Try again gently.",
            "No rush at all.",
            "Think it through.",
            "Almost there."
        ]
    ]

    // MARK: - Hint intro

    static func hintIntro(tone: CompanionTone) -> String {
        pool(for: tone, from: hintIntroPools).randomElement()!
    }

    private static let hintIntroPools: [CompanionTone: [String]] = [
        .encouraging: [
            "Here's a clue!",
            "A little help!",
            "Try this idea!"
        ],
        .energetic: [
            "Check this out!",
            "Hint incoming!",
            "Secret weapon!"
        ],
        .calm: [
            "A gentle nudge.",
            "Consider this.",
            "One small hint."
        ]
    ]

    // MARK: - Sticker earned

    static func stickerEarned(tone: CompanionTone) -> String {
        pool(for: tone, from: stickerPools).randomElement()!
    }

    private static let stickerPools: [CompanionTone: [String]] = [
        .encouraging: [
            "You earned it!",
            "So well deserved!",
            "What a star!"
        ],
        .energetic: [
            "Sticker time!",
            "Epic reward!",
            "Woohoo!"
        ],
        .calm: [
            "A fine reward.",
            "Well earned.",
            "You did it."
        ]
    ]

    // MARK: - Correction (shown after 2 wrong answers with the correct answer)

    static func correction(tone: CompanionTone) -> String {
        pool(for: tone, from: correctionPools).randomElement()!
    }

    private static let correctionPools: [CompanionTone: [String]] = [
        .encouraging: [
            "Let's learn this together!",
            "Now you know for next time!",
            "Every mistake helps you grow!",
            "This is how we learn!",
            "You'll get it next time!"
        ],
        .energetic: [
            "Ooh, tricky one! Now you know!",
            "Level up! You learned something new!",
            "Brain power unlocked!",
            "Knowledge boost!",
            "Now that's in your toolkit!"
        ],
        .calm: [
            "Now you've seen the answer.",
            "Take a moment to remember this.",
            "Learning takes practice.",
            "This will click soon.",
            "A good thing to know."
        ]
    ]

    // MARK: - Helper

    private static func pool(for tone: CompanionTone, from pools: [CompanionTone: [String]]) -> [String] {
        pools[tone] ?? pools[.encouraging]!
    }
}
