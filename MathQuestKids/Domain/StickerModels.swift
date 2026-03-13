import Foundation
import SwiftUI

struct Sticker: Identifiable, Equatable {
    let unitType: UnitType
    let dateEarned: Date?   // nil = locked

    var id: String { unitType.rawValue }
    var isUnlocked: Bool { dateEarned != nil }

    var title: String { unitType.title + " Sticker" }

    func icon(for theme: VisualTheme) -> StickerIcon {
        StickerIcon.icon(for: unitType, theme: theme)
    }
}

struct StickerIcon: Equatable {
    let systemName: String
    let gradient: [Color]
    let imageName: String?  // Custom sticker art (nil = use SF Symbol)

    init(systemName: String, gradient: [Color], imageName: String? = nil) {
        self.systemName = systemName
        self.gradient = gradient
        self.imageName = imageName
    }

    static func icon(for unit: UnitType, theme: VisualTheme) -> StickerIcon {
        switch theme {
        case .candyland:    return candyland(unit)
        case .axolotl:      return axolotl(unit)
        case .rainbowUnicorn: return rainbowUnicorn(unit)
        case .starsSpace:   return starsSpace(unit)
        case .superhero:    return superhero(unit)
        case .turboCars:    return turboCars(unit)
        }
    }

    // MARK: - Candyland (sweets & treats)

    private static func candyland(_ unit: UnitType) -> StickerIcon {
        switch unit {
        case .kCountObjects:        return StickerIcon(systemName: "cube.fill", gradient: [.pink, .orange], imageName: "CandySticker01")
        case .kComposeDecompose:    return StickerIcon(systemName: "puzzlepiece.fill", gradient: [.red, .pink], imageName: "CandySticker02")
        case .kAddWithin5:          return StickerIcon(systemName: "heart.circle.fill", gradient: [.pink, .purple], imageName: "CandySticker03")
        case .kAddWithin10:         return StickerIcon(systemName: "star.circle.fill", gradient: [.orange, .red], imageName: "CandySticker04")
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.pink, .red], imageName: "CandySticker05")
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.orange, .pink], imageName: "CandySticker06")
        case .subtractionStories:   return StickerIcon(systemName: "heart.rectangle.fill", gradient: [.red, .pink], imageName: "CandySticker07")
        case .teenPlaceValue:       return StickerIcon(systemName: "star.square.fill", gradient: [.orange, .pink], imageName: "CandySticker08")
        case .g1AddWithin20:        return StickerIcon(systemName: "diamond.circle.fill", gradient: [.red, .orange], imageName: "CandySticker09")
        case .g1FactFamilies:       return StickerIcon(systemName: "gift.fill", gradient: [.purple, .pink], imageName: "CandySticker10")
        case .twoDigitComparison:   return StickerIcon(systemName: "tag.circle.fill", gradient: [.purple, .red], imageName: "CandySticker11")
        case .g1AddSub100:          return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.red, .purple], imageName: "CandySticker12")
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.pink, .orange], imageName: "CandySticker13")
        case .g2AddWithin100:       return StickerIcon(systemName: "crown.fill", gradient: [.yellow, .orange], imageName: "CandySticker14")
        case .g2SubWithin100:       return StickerIcon(systemName: "wand.and.stars", gradient: [.pink, .yellow], imageName: "CandySticker15")
        case .threeDigitComparison: return StickerIcon(systemName: "rosette", gradient: [.yellow, .pink], imageName: "CandySticker16")
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.purple, .pink], imageName: "CandySticker17")
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.swap", gradient: [.orange, .red], imageName: "CandySticker18")
        case .g2EqualGroups:        return StickerIcon(systemName: "square.grid.2x2.fill", gradient: [.pink, .purple], imageName: "CandySticker19")
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.yellow, .pink], imageName: "CandySticker20")
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.red, .orange], imageName: "CandySticker21")
        case .multiplicationArrays: return StickerIcon(systemName: "seal.fill", gradient: [.orange, .purple], imageName: "CandySticker22")
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.purple, .red], imageName: "CandySticker23")
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.pink, .purple], imageName: "CandySticker24")
        case .g3FractionCompare:    return StickerIcon(systemName: "lessthan.circle.fill", gradient: [.orange, .purple], imageName: "CandySticker25")
        case .fractionComparison:   return StickerIcon(systemName: "circle.grid.2x2.fill", gradient: [.pink, .red], imageName: "CandySticker26")
        case .g3AreaConcept:        return StickerIcon(systemName: "square.dashed", gradient: [.red, .pink], imageName: "CandySticker27")
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.purple, .orange], imageName: "CandySticker28")
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.pink, .red], imageName: "CandySticker29")
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.orange, .purple], imageName: "CandySticker30")
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.red, .pink], imageName: "CandySticker31")
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.circle.fill", gradient: [.purple, .pink], imageName: "CandySticker32")
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.yellow, .red], imageName: "CandySticker33")
        case .fractionOfWhole:      return StickerIcon(systemName: "chart.pie.fill", gradient: [.red, .yellow], imageName: "CandySticker34")
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.fill", gradient: [.yellow, .orange], imageName: "CandySticker35")
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "plusminus.circle.fill", gradient: [.pink, .orange])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.red, .purple])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.orange, .pink])
        }
    }

    // MARK: - Axolotl Lagoon (aquatic & nature)

    private static func axolotl(_ unit: UnitType) -> StickerIcon {
        switch unit {
        case .kCountObjects:        return StickerIcon(systemName: "fish.fill", gradient: [.teal, .cyan])
        case .kComposeDecompose:    return StickerIcon(systemName: "tortoise.fill", gradient: [.green, .teal])
        case .kAddWithin5:          return StickerIcon(systemName: "leaf.circle.fill", gradient: [.green, .mint])
        case .kAddWithin10:         return StickerIcon(systemName: "drop.circle.fill", gradient: [.cyan, .blue])
        case .g1AddWithin20:        return StickerIcon(systemName: "water.waves", gradient: [.teal, .green])
        case .g1FactFamilies:       return StickerIcon(systemName: "hare.fill", gradient: [.mint, .teal])
        case .g2AddWithin100:       return StickerIcon(systemName: "bird.fill", gradient: [.blue, .teal])
        case .g2SubWithin100:       return StickerIcon(systemName: "lizard.fill", gradient: [.green, .blue])
        case .subtractionStories:   return StickerIcon(systemName: "ladybug.fill", gradient: [.teal, .mint])
        case .teenPlaceValue:       return StickerIcon(systemName: "tree.fill", gradient: [.green, .teal])
        case .twoDigitComparison:   return StickerIcon(systemName: "globe.americas.fill", gradient: [.blue, .green])
        case .threeDigitComparison: return StickerIcon(systemName: "mountain.2.fill", gradient: [.teal, .blue])
        case .multiplicationArrays: return StickerIcon(systemName: "ant.fill", gradient: [.green, .cyan])
        case .fractionComparison:   return StickerIcon(systemName: "leaf.fill", gradient: [.mint, .green])
        case .fractionOfWhole:      return StickerIcon(systemName: "camera.macro", gradient: [.teal, .green])
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.fill", gradient: [.cyan, .teal])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.green, .teal])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.teal, .mint])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.cyan, .green])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.green, .cyan])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.teal, .blue])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.swap", gradient: [.mint, .teal])
        case .g2EqualGroups:        return StickerIcon(systemName: "square.grid.2x2.fill", gradient: [.green, .mint])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.cyan, .teal])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.teal, .green])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.blue, .teal])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.green, .teal])
        case .g3FractionCompare:    return StickerIcon(systemName: "lessthan.circle.fill", gradient: [.teal, .cyan])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.dashed", gradient: [.mint, .green])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.blue, .mint])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.teal, .blue])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.green, .teal])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.cyan, .green])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.circle.fill", gradient: [.teal, .mint])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.blue, .teal])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "plusminus.circle.fill", gradient: [.green, .cyan])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.teal, .blue])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.mint, .teal])
        }
    }

    // MARK: - Rainbow Unicorn (magic & sparkle)

    private static func rainbowUnicorn(_ unit: UnitType) -> StickerIcon {
        switch unit {
        case .kCountObjects:        return StickerIcon(systemName: "sparkle", gradient: [.purple, .pink])
        case .kComposeDecompose:    return StickerIcon(systemName: "wand.and.stars", gradient: [.pink, .purple])
        case .kAddWithin5:          return StickerIcon(systemName: "heart.fill", gradient: [.pink, .red])
        case .kAddWithin10:         return StickerIcon(systemName: "moon.stars.fill", gradient: [.purple, .indigo])
        case .g1AddWithin20:        return StickerIcon(systemName: "rainbow", gradient: [.pink, .orange])
        case .g1FactFamilies:       return StickerIcon(systemName: "star.fill", gradient: [.yellow, .pink])
        case .g2AddWithin100:       return StickerIcon(systemName: "crown.fill", gradient: [.purple, .pink])
        case .g2SubWithin100:       return StickerIcon(systemName: "wand.and.rays", gradient: [.indigo, .purple])
        case .subtractionStories:   return StickerIcon(systemName: "bird.fill", gradient: [.pink, .purple])
        case .teenPlaceValue:       return StickerIcon(systemName: "cloud.rainbow.half.fill", gradient: [.purple, .pink])
        case .twoDigitComparison:   return StickerIcon(systemName: "diamond.fill", gradient: [.indigo, .purple])
        case .threeDigitComparison: return StickerIcon(systemName: "shield.fill", gradient: [.pink, .indigo])
        case .multiplicationArrays: return StickerIcon(systemName: "bolt.heart.fill", gradient: [.purple, .pink])
        case .fractionComparison:   return StickerIcon(systemName: "hexagon.fill", gradient: [.pink, .purple])
        case .fractionOfWhole:      return StickerIcon(systemName: "chart.pie.fill", gradient: [.purple, .indigo])
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.fill", gradient: [.pink, .purple])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.purple, .pink])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.pink, .indigo])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.indigo, .pink])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.purple, .pink])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.pink, .purple])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.swap", gradient: [.indigo, .purple])
        case .g2EqualGroups:        return StickerIcon(systemName: "square.grid.2x2.fill", gradient: [.purple, .indigo])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.pink, .indigo])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.purple, .pink])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.indigo, .purple])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.pink, .purple])
        case .g3FractionCompare:    return StickerIcon(systemName: "lessthan.circle.fill", gradient: [.purple, .indigo])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.dashed", gradient: [.pink, .indigo])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.indigo, .pink])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.purple, .indigo])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.pink, .purple])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.indigo, .pink])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.circle.fill", gradient: [.purple, .pink])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.pink, .purple])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "plusminus.circle.fill", gradient: [.indigo, .purple])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.purple, .indigo])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.pink, .indigo])
        }
    }

    // MARK: - Stars & Space (cosmic)

    private static func starsSpace(_ unit: UnitType) -> StickerIcon {
        switch unit {
        case .kCountObjects:        return StickerIcon(systemName: "star.fill", gradient: [.yellow, .orange])
        case .kComposeDecompose:    return StickerIcon(systemName: "moon.fill", gradient: [.blue, .indigo])
        case .kAddWithin5:          return StickerIcon(systemName: "sun.max.fill", gradient: [.yellow, .red])
        case .kAddWithin10:         return StickerIcon(systemName: "sparkles", gradient: [.white, .cyan])
        case .g1AddWithin20:        return StickerIcon(systemName: "globe.americas.fill", gradient: [.blue, .cyan])
        case .g1FactFamilies:       return StickerIcon(systemName: "atom", gradient: [.indigo, .blue])
        case .g2AddWithin100:       return StickerIcon(systemName: "hurricane", gradient: [.purple, .blue])
        case .g2SubWithin100:       return StickerIcon(systemName: "bolt.fill", gradient: [.yellow, .orange])
        case .subtractionStories:   return StickerIcon(systemName: "moon.stars.fill", gradient: [.indigo, .purple])
        case .teenPlaceValue:       return StickerIcon(systemName: "scope", gradient: [.cyan, .blue])
        case .twoDigitComparison:   return StickerIcon(systemName: "shield.lefthalf.filled", gradient: [.blue, .indigo])
        case .threeDigitComparison: return StickerIcon(systemName: "staroflife.fill", gradient: [.orange, .yellow])
        case .multiplicationArrays: return StickerIcon(systemName: "circle.grid.3x3.fill", gradient: [.blue, .purple])
        case .fractionComparison:   return StickerIcon(systemName: "circle.grid.cross.fill", gradient: [.indigo, .cyan])
        case .fractionOfWhole:      return StickerIcon(systemName: "chart.pie.fill", gradient: [.blue, .indigo])
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.fill", gradient: [.yellow, .indigo])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.cyan, .blue])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.blue, .indigo])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.indigo, .blue])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.cyan, .indigo])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.blue, .purple])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.swap", gradient: [.indigo, .cyan])
        case .g2EqualGroups:        return StickerIcon(systemName: "square.grid.2x2.fill", gradient: [.purple, .indigo])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.yellow, .blue])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.cyan, .indigo])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.blue, .indigo])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.indigo, .blue])
        case .g3FractionCompare:    return StickerIcon(systemName: "lessthan.circle.fill", gradient: [.purple, .blue])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.dashed", gradient: [.cyan, .blue])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.indigo, .cyan])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.blue, .indigo])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.indigo, .purple])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.blue, .cyan])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.circle.fill", gradient: [.indigo, .blue])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.yellow, .indigo])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "plusminus.circle.fill", gradient: [.blue, .indigo])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.indigo, .cyan])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.cyan, .indigo])
        }
    }

    // MARK: - Superhero City (heroes & powers)

    private static func superhero(_ unit: UnitType) -> StickerIcon {
        switch unit {
        case .kCountObjects:        return StickerIcon(systemName: "bolt.shield.fill", gradient: [.red, .orange])
        case .kComposeDecompose:    return StickerIcon(systemName: "shield.fill", gradient: [.orange, .red])
        case .kAddWithin5:          return StickerIcon(systemName: "star.circle.fill", gradient: [.yellow, .orange])
        case .kAddWithin10:         return StickerIcon(systemName: "bolt.fill", gradient: [.red, .yellow])
        case .g1AddWithin20:        return StickerIcon(systemName: "flame.fill", gradient: [.orange, .red])
        case .g1FactFamilies:       return StickerIcon(systemName: "figure.run", gradient: [.red, .orange])
        case .g2AddWithin100:       return StickerIcon(systemName: "bolt.heart.fill", gradient: [.yellow, .red])
        case .g2SubWithin100:       return StickerIcon(systemName: "shield.checkered", gradient: [.red, .indigo])
        case .subtractionStories:   return StickerIcon(systemName: "eye.fill", gradient: [.orange, .yellow])
        case .teenPlaceValue:       return StickerIcon(systemName: "star.fill", gradient: [.yellow, .orange])
        case .twoDigitComparison:   return StickerIcon(systemName: "scope", gradient: [.red, .orange])
        case .threeDigitComparison: return StickerIcon(systemName: "target", gradient: [.orange, .red])
        case .multiplicationArrays: return StickerIcon(systemName: "square.grid.3x3.fill", gradient: [.red, .yellow])
        case .fractionComparison:   return StickerIcon(systemName: "shield.lefthalf.filled", gradient: [.indigo, .red])
        case .fractionOfWhole:      return StickerIcon(systemName: "chart.pie.fill", gradient: [.red, .orange])
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.fill", gradient: [.yellow, .red])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.orange, .yellow])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.red, .yellow])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.orange, .red])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.yellow, .orange])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.red, .indigo])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.swap", gradient: [.orange, .red])
        case .g2EqualGroups:        return StickerIcon(systemName: "square.grid.2x2.fill", gradient: [.yellow, .red])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.red, .orange])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.orange, .yellow])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.red, .indigo])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.orange, .red])
        case .g3FractionCompare:    return StickerIcon(systemName: "lessthan.circle.fill", gradient: [.yellow, .orange])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.dashed", gradient: [.red, .orange])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.indigo, .red])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.orange, .indigo])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.red, .yellow])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.orange, .red])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.circle.fill", gradient: [.yellow, .red])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.red, .orange])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "plusminus.circle.fill", gradient: [.indigo, .red])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.orange, .indigo])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.red, .yellow])
        }
    }

    // MARK: - Turbo Cars (racing & machines)

    private static func turboCars(_ unit: UnitType) -> StickerIcon {
        switch unit {
        case .kCountObjects:        return StickerIcon(systemName: "car.fill", gradient: [.blue, .orange])
        case .kComposeDecompose:    return StickerIcon(systemName: "wrench.and.screwdriver.fill", gradient: [.orange, .blue])
        case .kAddWithin5:          return StickerIcon(systemName: "flag.checkered", gradient: [.blue, .cyan])
        case .kAddWithin10:         return StickerIcon(systemName: "flame.fill", gradient: [.orange, .red])
        case .g1AddWithin20:        return StickerIcon(systemName: "gauge.with.dots.needle.67percent", gradient: [.blue, .orange])
        case .g1FactFamilies:       return StickerIcon(systemName: "gear", gradient: [.cyan, .blue])
        case .g2AddWithin100:       return StickerIcon(systemName: "bolt.fill", gradient: [.orange, .yellow])
        case .g2SubWithin100:       return StickerIcon(systemName: "fuelpump.fill", gradient: [.blue, .cyan])
        case .subtractionStories:   return StickerIcon(systemName: "road.lanes", gradient: [.orange, .blue])
        case .teenPlaceValue:       return StickerIcon(systemName: "speedometer", gradient: [.blue, .orange])
        case .twoDigitComparison:   return StickerIcon(systemName: "arrow.up.right.circle.fill", gradient: [.orange, .red])
        case .threeDigitComparison: return StickerIcon(systemName: "medal.fill", gradient: [.yellow, .orange])
        case .multiplicationArrays: return StickerIcon(systemName: "square.grid.3x3.fill", gradient: [.blue, .cyan])
        case .fractionComparison:   return StickerIcon(systemName: "circle.grid.cross.fill", gradient: [.orange, .blue])
        case .fractionOfWhole:      return StickerIcon(systemName: "chart.pie.fill", gradient: [.blue, .orange])
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.fill", gradient: [.yellow, .blue])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.blue, .cyan])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.orange, .blue])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.cyan, .blue])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.orange, .cyan])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.blue, .orange])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.swap", gradient: [.orange, .blue])
        case .g2EqualGroups:        return StickerIcon(systemName: "square.grid.2x2.fill", gradient: [.cyan, .orange])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.blue, .orange])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.orange, .cyan])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.blue, .orange])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.orange, .blue])
        case .g3FractionCompare:    return StickerIcon(systemName: "lessthan.circle.fill", gradient: [.cyan, .orange])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.dashed", gradient: [.blue, .cyan])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.orange, .blue])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.blue, .cyan])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.orange, .blue])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.blue, .orange])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.circle.fill", gradient: [.cyan, .blue])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.orange, .blue])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "plusminus.circle.fill", gradient: [.blue, .orange])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.cyan, .blue])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.orange, .cyan])
        }
    }
}

struct StickerCollection: Equatable {
    let stickers: [Sticker]

    static func build(from records: [CDStickerRecord]) -> StickerCollection {
        let earnedByUnit = Dictionary(
            uniqueKeysWithValues: records.map { ($0.unitRaw, $0.dateEarned) }
        )
        let stickers = UnitType.learningPath.map { unit in
            Sticker(unitType: unit, dateEarned: earnedByUnit[unit.rawValue])
        }
        return StickerCollection(stickers: stickers)
    }

    var earnedCount: Int { stickers.filter(\.isUnlocked).count }
    var totalCount: Int { stickers.count }
}
