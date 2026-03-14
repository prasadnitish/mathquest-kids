import Foundation

enum CompanionPhrases {

    // MARK: - Correct answer

    static func correct(tone: CompanionTone) -> String {
        pool(for: tone, from: correctPools).randomElement()!
    }

    private static let correctPools: [CompanionTone: [String]] = [
        .encouraging: [
            "Awesome job!",
            "You got it!",
            "Way to go!",
            "Super!",
            "You did it!"
        ],
        .energetic: [
            "Boom! Nailed it!",
            "Yes! Crushed it!",
            "Woo-hoo!",
            "Incredible!",
            "Amazing!"
        ],
        .calm: [
            "Well done.",
            "Nicely solved.",
            "That is correct.",
            "Good work.",
            "Right answer."
        ]
    ]

    // MARK: - Incorrect answer

    static func incorrect(tone: CompanionTone) -> String {
        pool(for: tone, from: incorrectPools).randomElement()!
    }

    private static let incorrectPools: [CompanionTone: [String]] = [
        .encouraging: [
            "Almost there!",
            "Try again!",
            "You can do it!",
            "Keep going!",
            "Nice try!"
        ],
        .energetic: [
            "Oops! Try once more!",
            "So close! Give it another shot!",
            "Not quite! You got this!"
        ],
        .calm: [
            "Not quite. Try again.",
            "Close. Think it through.",
            "Let us try once more."
        ]
    ]

    // MARK: - Hint intro

    static func hintIntro(tone: CompanionTone) -> String {
        pool(for: tone, from: hintIntroPools).randomElement()!
    }

    private static let hintIntroPools: [CompanionTone: [String]] = [
        .encouraging: [
            "Here is a hint.",
            "Want a clue?",
            "How about a little help?"
        ],
        .energetic: [
            "Let me help.",
            "Try thinking about it this way.",
            "Here is a hint."
        ],
        .calm: [
            "Here is a hint.",
            "Let me help.",
            "Try thinking about it this way."
        ]
    ]

    // MARK: - Sticker earned

    static func stickerEarned(tone: CompanionTone) -> String {
        pool(for: tone, from: stickerPools).randomElement()!
    }

    private static let stickerPools: [CompanionTone: [String]] = [
        .encouraging: [
            "You earned a sticker!",
            "A sticker just for you!"
        ],
        .energetic: [
            "New sticker unlocked!",
            "Check out your new sticker!"
        ],
        .calm: [
            "You earned a sticker!",
            "A sticker just for you!"
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
