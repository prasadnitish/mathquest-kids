import Foundation

enum CompanionTone: String {
    case encouraging // warm, supportive
    case energetic   // punchy, action-oriented
    case calm        // gentle, patient
}

struct ThemeCompanion: Identifiable, Equatable {
    let id: String
    let name: String
    let title: String
    let symbol: String
    let imageName: String
    let tagline: String
    let tone: CompanionTone
}

enum CharacterPackLibrary {
    static func companions(for theme: VisualTheme) -> [ThemeCompanion] {
        switch theme {
        case .candyland:
            return [
                ThemeCompanion(id: "candy-benny", name: "Benny", title: "Candy Sky Pilot", symbol: "birthday.cake.fill", imageName: "CandyBenny", tagline: "Every puzzle unlocks a candy cloud.", tone: .energetic),
                ThemeCompanion(id: "candy-sprinkle", name: "Sprinkle", title: "Sweet Strategy Coach", symbol: "wand.and.stars", imageName: "CandySprinkle", tagline: "Tiny steps make giant math wins.", tone: .encouraging),
                ThemeCompanion(id: "candy-taffy", name: "Taffy", title: "Challenge Ranger", symbol: "sparkles", imageName: "CandyTaffy", tagline: "Try, adjust, and level up your thinking.", tone: .calm)
            ]
        case .axolotl:
            return [
                ThemeCompanion(id: "reef-coral", name: "Coral", title: "Lagoon Explorer", symbol: "fish.fill", imageName: "ReefCoral", tagline: "Let's glide through this one with calm focus.", tone: .calm),
                ThemeCompanion(id: "reef-finn", name: "Finn", title: "Pattern Hunter", symbol: "drop.fill", imageName: "ReefFinn", tagline: "Patterns show us the shortcut route.", tone: .energetic),
                ThemeCompanion(id: "reef-pearl", name: "Pearl", title: "Reasoning Guide", symbol: "leaf.fill", imageName: "ReefPearl", tagline: "Explain your thinking like a math scientist.", tone: .encouraging)
            ]
        case .rainbowUnicorn:
            return [
                ThemeCompanion(id: "unicorn-sparkle", name: "Sparkle", title: "Rainbow Pathfinder", symbol: "rainbow", imageName: "UnicornSparkle", tagline: "Big ideas start with one brave attempt.", tone: .encouraging),
                ThemeCompanion(id: "unicorn-clover", name: "Clover", title: "Fraction Fairy", symbol: "star.fill", imageName: "UnicornClover", tagline: "Compare parts by seeing the whole.", tone: .calm),
                ThemeCompanion(id: "unicorn-dizzy", name: "Dizzy", title: "Number Whisperer", symbol: "cloud.fill", imageName: "UnicornDizzy", tagline: "Tens, ones, and patterns always tell the story.", tone: .energetic)
            ]
        case .starsSpace:
            return [
                ThemeCompanion(id: "space-cosmo", name: "Cosmo", title: "Galaxy Navigator", symbol: "moon.stars.fill", imageName: "SpaceCosmo", tagline: "Plot the steps, then launch your answer.", tone: .energetic),
                ThemeCompanion(id: "space-luna", name: "Luna", title: "Array Engineer", symbol: "sparkles", imageName: "SpaceLuna", tagline: "Rows and columns power up multiplication.", tone: .calm),
                ThemeCompanion(id: "space-zip", name: "Zip", title: "Mission Analyst", symbol: "target", imageName: "SpaceZip", tagline: "Compare, justify, and verify every result.", tone: .encouraging)
            ]
        case .superhero:
            return [
                ThemeCompanion(id: "hero-captain", name: "Captain Calc", title: "Number Champion", symbol: "bolt.shield.fill", imageName: "HeroCaptainCalc", tagline: "Every problem is a mission. Let's solve it!", tone: .energetic),
                ThemeCompanion(id: "hero-nova", name: "Nova Shield", title: "Strategy Defender", symbol: "shield.fill", imageName: "HeroNovaShield", tagline: "Think before you act. Strategy wins the day.", tone: .calm),
                ThemeCompanion(id: "hero-dash", name: "Dash Digit", title: "Speed Solver", symbol: "bolt.fill", imageName: "HeroDashDigit", tagline: "Fast thinking starts with strong foundations.", tone: .encouraging)
            ]
        case .turboCars:
            return [
                ThemeCompanion(id: "turbo-rev", name: "Rev", title: "Racing Engineer", symbol: "car.fill", imageName: "TurboRevRacer", tagline: "Precision counts on the racetrack of math.", tone: .energetic),
                ThemeCompanion(id: "turbo-axle", name: "Axle", title: "Pit Crew Chief", symbol: "wrench.fill", imageName: "TurboAxleAce", tagline: "Check your work, then floor it.", tone: .calm),
                ThemeCompanion(id: "turbo-tread", name: "Tread", title: "Track Analyst", symbol: "flag.checkered", imageName: "TurboTurboTread", tagline: "Every lap gets faster with practice.", tone: .encouraging)
            ]
        }
    }

    static func defaultCompanion(for theme: VisualTheme) -> ThemeCompanion {
        companions(for: theme).first ?? ThemeCompanion(
            id: "default-guide",
            name: "Quest Guide",
            title: "Math Companion",
            symbol: "sparkles",
            imageName: "",
            tagline: "You can do hard things one step at a time.",
            tone: .encouraging
        )
    }
}
