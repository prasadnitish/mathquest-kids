import Foundation

enum MascotVoice {
    enum Context: CaseIterable {
        case homeGreeting
        case lessonStart
        case questionHint
        case answerCorrect
        case answerWrong
        case answerIdk
        case rewardEarned
        case chapterUnlocked
        case streakMilestone
    }

    /// Short (<=12 words) phrase for a given context + companion tone.
    static func phrase(for ctx: Context, tone: CompanionTone) -> String {
        switch ctx {
        case .homeGreeting:
            switch tone {
            case .calm:        return "Good to see you. Ready for a new adventure?"
            case .energetic:   return "Hey hey! Let's jump into something awesome today!"
            case .encouraging: return "You're back! I knew you'd come. Let's go!"
            }
        case .lessonStart:
            switch tone {
            case .calm:        return "Let's take this one step at a time."
            case .energetic:   return "New lesson! Buckle up, this is going to be fun!"
            case .encouraging: return "You've got this. I'm right here with you."
            }
        case .questionHint:
            switch tone {
            case .calm:        return "Take your time. Look at the picture first."
            case .energetic:   return "Try counting with me! One, two, three..."
            case .encouraging: return "You can do it. Let's try together."
            }
        case .answerCorrect:
            switch tone {
            case .calm:        return "Lovely. That's exactly right."
            case .energetic:   return "YES! You nailed it! High five!"
            case .encouraging: return "Wonderful! I'm so proud of you!"
            }
        case .answerWrong:
            switch tone {
            case .calm:        return "That's okay. Let's try another way."
            case .energetic:   return "Oops! Let's go again. You've got this!"
            case .encouraging: return "Mistakes help us grow. Try again!"
            }
        case .answerIdk:
            switch tone {
            case .calm:        return "That's brave to say. Let's look together."
            case .energetic:   return "No worries! Let's crack it together!"
            case .encouraging: return "It's okay to pause. I'll help."
            }
        case .rewardEarned:
            switch tone {
            case .calm:        return "You earned a sticker. Beautifully done."
            case .energetic:   return "WOW! New sticker! You're on fire!"
            case .encouraging: return "Amazing! A shiny new sticker for you!"
            }
        case .chapterUnlocked:
            switch tone {
            case .calm:        return "A new chapter is open. Nicely earned."
            case .energetic:   return "New route unlocked! Let's blast off!"
            case .encouraging: return "You opened a new chapter. Let's keep going!"
            }
        case .streakMilestone:
            switch tone {
            case .calm:        return "A steady streak. Lovely consistency."
            case .energetic:   return "STREAK! You're unstoppable!"
            case .encouraging: return "Look at you! Showing up every day!"
            }
        }
    }
}
