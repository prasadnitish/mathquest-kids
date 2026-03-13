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
                ThemeCompanion(id: "candy-benny", name: "Benny the Bear", title: "Candy Sky Pilot", symbol: "birthday.cake.fill", imageName: "CandyBenny", tagline: "Every puzzle unlocks a candy cloud.", tone: .energetic),
                ThemeCompanion(id: "candy-sprinkle", name: "Sprinkle the Fox", title: "Sweet Strategy Coach", symbol: "wand.and.stars", imageName: "CandySprinkle", tagline: "Tiny steps make giant math wins.", tone: .encouraging),
                ThemeCompanion(id: "candy-taffy", name: "Taffy the Bunny", title: "Challenge Ranger", symbol: "sparkles", imageName: "CandyTaffy", tagline: "Try, adjust, and level up your thinking.", tone: .calm)
            ]
        case .axolotl:
            return [
                ThemeCompanion(id: "reef-coral", name: "Coral the Axolotl", title: "Lagoon Explorer", symbol: "fish.fill", imageName: "ReefCoral", tagline: "Let's glide through this one with calm focus.", tone: .calm),
                ThemeCompanion(id: "reef-finn", name: "Finn the Seahorse", title: "Pattern Hunter", symbol: "drop.fill", imageName: "ReefFinn", tagline: "Patterns show us the shortcut route.", tone: .energetic),
                ThemeCompanion(id: "reef-pearl", name: "Pearl the Jellyfish", title: "Reasoning Guide", symbol: "leaf.fill", imageName: "ReefPearl", tagline: "Explain your thinking like a math scientist.", tone: .encouraging)
            ]
        case .rainbowUnicorn:
            return [
                ThemeCompanion(id: "unicorn-sparkle", name: "Sparkle the Unicorn", title: "Rainbow Pathfinder", symbol: "rainbow", imageName: "UnicornSparkle", tagline: "Big ideas start with one brave attempt.", tone: .encouraging),
                ThemeCompanion(id: "unicorn-clover", name: "Clover the Pegasus", title: "Fraction Fairy", symbol: "star.fill", imageName: "UnicornClover", tagline: "Compare parts by seeing the whole.", tone: .calm),
                ThemeCompanion(id: "unicorn-dizzy", name: "Dizzy the Cloud Pup", title: "Number Whisperer", symbol: "cloud.fill", imageName: "UnicornDizzy", tagline: "Tens, ones, and patterns always tell the story.", tone: .energetic)
            ]
        case .starsSpace:
            return [
                ThemeCompanion(id: "space-cosmo", name: "Cosmo the Robot", title: "Galaxy Navigator", symbol: "moon.stars.fill", imageName: "SpaceCosmo", tagline: "Plot the steps, then launch your answer.", tone: .energetic),
                ThemeCompanion(id: "space-luna", name: "Luna the Space Cat", title: "Array Engineer", symbol: "sparkles", imageName: "SpaceLuna", tagline: "Rows and columns power up multiplication.", tone: .calm),
                ThemeCompanion(id: "space-zip", name: "Zip the Alien", title: "Mission Analyst", symbol: "target", imageName: "SpaceZip", tagline: "Compare, justify, and verify every result.", tone: .encouraging)
            ]
        case .superhero:
            return [
                ThemeCompanion(id: "hero-captain-calc", name: "Captain Calc", title: "Number Hero", symbol: "bolt.shield.fill", imageName: "HeroCaptainCalc", tagline: "Every correct answer powers up your shield.", tone: .energetic),
                ThemeCompanion(id: "hero-dash-digit", name: "Dash Digit", title: "Speed Solver", symbol: "figure.run", imageName: "HeroDashDigit", tagline: "Think fast, check twice, and save the day.", tone: .encouraging),
                ThemeCompanion(id: "hero-nova-shield", name: "Nova Shield", title: "Strategy Defender", symbol: "shield.checkered", imageName: "HeroNovaShield", tagline: "A strong plan beats speed every time.", tone: .calm)
            ]
        case .turboCars:
            return [
                ThemeCompanion(id: "turbo-rev-racer", name: "Rev Racer", title: "Pit Crew Chief", symbol: "car.fill", imageName: "TurboRevRacer", tagline: "Tune your thinking, then floor it.", tone: .energetic),
                ThemeCompanion(id: "turbo-axle-ace", name: "Axle Ace", title: "Track Engineer", symbol: "wrench.and.screwdriver.fill", imageName: "TurboAxleAce", tagline: "Every problem is a pit stop to get faster.", tone: .calm),
                ThemeCompanion(id: "turbo-tread", name: "Turbo Tread", title: "Lap Analyst", symbol: "flag.checkered", imageName: "TurboTurboTread", tagline: "Study the pattern, then take the fastest line.", tone: .encouraging)
            ]
        }
    }

    static func defaultCompanion(for theme: VisualTheme) -> ThemeCompanion {
        companions(for: theme).first ?? ThemeCompanion(
            id: "default-guide",
            name: "Quest Guide",
            title: "Math Companion",
            symbol: "sparkles",
            imageName: "CandyBenny",
            tagline: "You can do hard things one step at a time.",
            tone: .encouraging
        )
    }
}
