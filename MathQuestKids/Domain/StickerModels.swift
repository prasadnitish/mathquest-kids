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

    static func icon(for unit: UnitType, theme: VisualTheme) -> StickerIcon {
        switch theme {
        case .candyland:    return candyland(unit)
        case .axolotl:      return axolotl(unit)
        case .rainbowUnicorn: return rainbowUnicorn(unit)
        case .starsSpace:   return starsSpace(unit)
        }
    }

    // MARK: - Candyland (sweets & treats)

    private static func candyland(_ unit: UnitType) -> StickerIcon {
        switch unit {
        case .kCountObjects:        return StickerIcon(systemName: "birthday.cake.fill", gradient: [.pink, .orange])
        case .kComposeDecompose:    return StickerIcon(systemName: "cube.fill", gradient: [.red, .pink])
        case .kAddWithin5:          return StickerIcon(systemName: "heart.circle.fill", gradient: [.pink, .purple])
        case .kAddWithin10:         return StickerIcon(systemName: "star.circle.fill", gradient: [.orange, .red])
        case .g1AddWithin20:        return StickerIcon(systemName: "diamond.circle.fill", gradient: [.red, .orange])
        case .g1FactFamilies:       return StickerIcon(systemName: "gift.fill", gradient: [.purple, .pink])
        case .g2AddWithin100:       return StickerIcon(systemName: "crown.fill", gradient: [.yellow, .orange])
        case .g2SubWithin100:       return StickerIcon(systemName: "wand.and.stars", gradient: [.pink, .yellow])
        case .subtractionStories:   return StickerIcon(systemName: "cherry.fill", gradient: [.red, .pink])
        case .teenPlaceValue:       return StickerIcon(systemName: "lollipop.fill", gradient: [.orange, .pink])
        case .twoDigitComparison:   return StickerIcon(systemName: "tag.circle.fill", gradient: [.purple, .red])
        case .threeDigitComparison: return StickerIcon(systemName: "rosette", gradient: [.yellow, .pink])
        case .multiplicationArrays: return StickerIcon(systemName: "seal.fill", gradient: [.orange, .purple])
        case .fractionComparison:   return StickerIcon(systemName: "circle.grid.2x2.fill", gradient: [.pink, .red])
        case .fractionOfWhole:      return StickerIcon(systemName: "chart.pie.fill", gradient: [.red, .yellow])
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.circle.fill", gradient: [.yellow, .orange])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.pink, .red])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.orange, .yellow])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.circle.fill", gradient: [.red, .orange])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.purple, .pink])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.orange, .red])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.2.circlepath", gradient: [.pink, .purple])
        case .g2EqualGroups:        return StickerIcon(systemName: "circle.grid.2x1.fill", gradient: [.red, .yellow])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.yellow, .pink])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.orange, .pink])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.purple, .orange])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.pink, .orange])
        case .g3FractionCompare:    return StickerIcon(systemName: "equal.circle.fill", gradient: [.red, .purple])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.grid.3x3.fill", gradient: [.orange, .red])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.pink, .yellow])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.red, .pink])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.purple, .red])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.orange, .purple])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.pink, .red])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.yellow, .orange])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "chart.pie.fill", gradient: [.purple, .pink])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.red, .orange])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.orange, .purple])
        }
    }

    // MARK: - Axolotl Lagoon (aquatic & nature)

    private static func axolotl(_ unit: UnitType) -> StickerIcon {
        switch unit {
        case .kCountObjects:        return StickerIcon(systemName: "fish.fill", gradient: [.teal, .cyan])
        case .kComposeDecompose:    return StickerIcon(systemName: "tortoise.fill", gradient: [.green, .teal])
        case .kAddWithin5:          return StickerIcon(systemName: "leaf.circle.fill", gradient: [.green, .mint])
        case .kAddWithin10:         return StickerIcon(systemName: "drop.circle.fill", gradient: [.cyan, .blue])
        case .g1AddWithin20:        return StickerIcon(systemName: "fossil.shell.fill", gradient: [.teal, .green])
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
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.circle.fill", gradient: [.cyan, .teal])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.teal, .green])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.green, .cyan])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.circle.fill", gradient: [.cyan, .teal])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.teal, .mint])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.green, .teal])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.2.circlepath", gradient: [.mint, .green])
        case .g2EqualGroups:        return StickerIcon(systemName: "circle.grid.2x1.fill", gradient: [.teal, .cyan])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.cyan, .mint])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.green, .teal])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.teal, .blue])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.mint, .teal])
        case .g3FractionCompare:    return StickerIcon(systemName: "equal.circle.fill", gradient: [.green, .mint])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.grid.3x3.fill", gradient: [.teal, .green])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.cyan, .teal])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.blue, .teal])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.teal, .blue])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.green, .teal])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.mint, .cyan])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.teal, .green])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "chart.pie.fill", gradient: [.cyan, .teal])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.teal, .mint])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.green, .cyan])
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
        case .subtractionStories:   return StickerIcon(systemName: "butterfly.fill", gradient: [.pink, .purple])
        case .teenPlaceValue:       return StickerIcon(systemName: "cloud.rainbow.half.fill", gradient: [.purple, .pink])
        case .twoDigitComparison:   return StickerIcon(systemName: "diamond.fill", gradient: [.indigo, .purple])
        case .threeDigitComparison: return StickerIcon(systemName: "shield.fill", gradient: [.pink, .indigo])
        case .multiplicationArrays: return StickerIcon(systemName: "bolt.heart.fill", gradient: [.purple, .pink])
        case .fractionComparison:   return StickerIcon(systemName: "circle.hexagongrid.fill", gradient: [.pink, .purple])
        case .fractionOfWhole:      return StickerIcon(systemName: "chart.pie.fill", gradient: [.purple, .indigo])
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.circle.fill", gradient: [.pink, .purple])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.purple, .pink])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.pink, .indigo])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.circle.fill", gradient: [.indigo, .purple])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.pink, .purple])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.purple, .indigo])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.2.circlepath", gradient: [.pink, .purple])
        case .g2EqualGroups:        return StickerIcon(systemName: "circle.grid.2x1.fill", gradient: [.purple, .pink])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.indigo, .pink])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.pink, .purple])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.purple, .indigo])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.pink, .purple])
        case .g3FractionCompare:    return StickerIcon(systemName: "equal.circle.fill", gradient: [.indigo, .pink])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.grid.3x3.fill", gradient: [.purple, .pink])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.pink, .indigo])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.purple, .pink])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.indigo, .purple])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.pink, .indigo])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.purple, .pink])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.pink, .purple])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "chart.pie.fill", gradient: [.indigo, .purple])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.purple, .pink])
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
        case .g1AddWithin20:        return StickerIcon(systemName: "globe.central.south.asia.fill", gradient: [.blue, .cyan])
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
        case .volumeAndDecimals:    return StickerIcon(systemName: "trophy.circle.fill", gradient: [.yellow, .indigo])
        case .kCompareGroups:       return StickerIcon(systemName: "scalemass.fill", gradient: [.blue, .cyan])
        case .kShapeAttributes:     return StickerIcon(systemName: "triangle.fill", gradient: [.cyan, .blue])
        case .g1AddSub100:          return StickerIcon(systemName: "plus.circle.fill", gradient: [.indigo, .cyan])
        case .g1MeasureLength:      return StickerIcon(systemName: "ruler.fill", gradient: [.blue, .indigo])
        case .g2PlaceValue1000:     return StickerIcon(systemName: "number.circle.fill", gradient: [.cyan, .blue])
        case .g2AddSubRegroup:      return StickerIcon(systemName: "arrow.triangle.2.circlepath", gradient: [.indigo, .blue])
        case .g2EqualGroups:        return StickerIcon(systemName: "circle.grid.2x1.fill", gradient: [.blue, .cyan])
        case .g2TimeMoney:          return StickerIcon(systemName: "clock.fill", gradient: [.yellow, .blue])
        case .g2DataIntro:          return StickerIcon(systemName: "chart.bar.fill", gradient: [.cyan, .indigo])
        case .g3DivMeaning:         return StickerIcon(systemName: "divide.circle.fill", gradient: [.blue, .purple])
        case .g3FractionUnit:       return StickerIcon(systemName: "circle.lefthalf.filled", gradient: [.indigo, .blue])
        case .g3FractionCompare:    return StickerIcon(systemName: "equal.circle.fill", gradient: [.cyan, .indigo])
        case .g3AreaConcept:        return StickerIcon(systemName: "square.grid.3x3.fill", gradient: [.blue, .indigo])
        case .g3MultiStep:          return StickerIcon(systemName: "list.number", gradient: [.indigo, .cyan])
        case .g4PlaceValueMillion:  return StickerIcon(systemName: "textformat.123", gradient: [.purple, .blue])
        case .g4MultMultiDigit:     return StickerIcon(systemName: "multiply.circle.fill", gradient: [.blue, .purple])
        case .g4DivPartialQuotients: return StickerIcon(systemName: "divide.square.fill", gradient: [.indigo, .blue])
        case .g4FractionAddSub:     return StickerIcon(systemName: "plus.forwardslash.minus", gradient: [.cyan, .blue])
        case .g4AngleMeasure:       return StickerIcon(systemName: "angle", gradient: [.orange, .blue])
        case .g5FractionAddSubUnlike: return StickerIcon(systemName: "chart.pie.fill", gradient: [.blue, .indigo])
        case .g5LinePlotsFractions: return StickerIcon(systemName: "chart.xyaxis.line", gradient: [.indigo, .cyan])
        case .g5PreRatios:          return StickerIcon(systemName: "arrow.left.arrow.right", gradient: [.cyan, .purple])
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
