import Foundation

struct ThemeCompanion: Identifiable, Equatable {
    let id: String
    let name: String
    let title: String
    let symbol: String
    let tagline: String
}

enum CharacterPackLibrary {
    static func companions(for theme: VisualTheme) -> [ThemeCompanion] {
        switch theme {
        case .candyland:
            return [
                ThemeCompanion(id: "candy-captain", name: "Captain Sprinkle", title: "Candy Sky Pilot", symbol: "birthday.cake.fill", tagline: "Every puzzle unlocks a candy cloud."),
                ThemeCompanion(id: "lollipop-luna", name: "Luna Lollipop", title: "Sweet Strategy Coach", symbol: "wand.and.stars", tagline: "Tiny steps make giant math wins."),
                ThemeCompanion(id: "fizz-mint", name: "Fizz Mint", title: "Challenge Ranger", symbol: "sparkles", tagline: "Try, adjust, and level up your thinking.")
            ]
        case .axolotl:
            return [
                ThemeCompanion(id: "axi-wave", name: "Axi Wave", title: "Lagoon Explorer", symbol: "fish.fill", tagline: "Let's glide through this one with calm focus."),
                ThemeCompanion(id: "bloop", name: "Bloop", title: "Pattern Hunter", symbol: "drop.fill", tagline: "Patterns show us the shortcut route."),
                ThemeCompanion(id: "kelly-reef", name: "Kelly Reef", title: "Reasoning Guide", symbol: "leaf.fill", tagline: "Explain your thinking like a math scientist.")
            ]
        case .rainbowUnicorn:
            return [
                ThemeCompanion(id: "nova-horn", name: "Nova Horn", title: "Rainbow Pathfinder", symbol: "rainbow", tagline: "Big ideas start with one brave attempt."),
                ThemeCompanion(id: "starlace", name: "Starlace", title: "Fraction Fairy", symbol: "star.fill", tagline: "Compare parts by seeing the whole."),
                ThemeCompanion(id: "cloudlet", name: "Cloudlet", title: "Number Whisperer", symbol: "cloud.fill", tagline: "Tens, ones, and patterns always tell the story.")
            ]
        case .starsSpace:
            return [
                ThemeCompanion(id: "orbit-ace", name: "Orbit Ace", title: "Galaxy Navigator", symbol: "moon.stars.fill", tagline: "Plot the steps, then launch your answer."),
                ThemeCompanion(id: "quanta", name: "Quanta", title: "Array Engineer", symbol: "sparkles", tagline: "Rows and columns power up multiplication."),
                ThemeCompanion(id: "vega-vox", name: "Vega Vox", title: "Mission Analyst", symbol: "target", tagline: "Compare, justify, and verify every result.")
            ]
        }
    }

    static func defaultCompanion(for theme: VisualTheme) -> ThemeCompanion {
        companions(for: theme).first ?? ThemeCompanion(
            id: "default-guide",
            name: "Quest Guide",
            title: "Math Companion",
            symbol: "sparkles",
            tagline: "You can do hard things one step at a time."
        )
    }
}
