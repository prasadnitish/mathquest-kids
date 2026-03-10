import Foundation

enum FeatureFlags {
    static let networkDisabled = true
    static let minimumSessionItems = 5
    static let defaultSessionItems = 7
    static let maximumSessionItems = 10

    static func adaptiveSessionItems(for unit: UnitType, placedGrade: GradeBand?) -> Int {
        let target: Int

        switch unit {
        case .subtractionStories, .teenPlaceValue:
            switch placedGrade ?? .kindergarten {
            case .kindergarten:
                target = 5
            case .grade1:
                target = 6
            default:
                target = 6
            }
        case .twoDigitComparison:
            switch placedGrade ?? .grade1 {
            case .kindergarten, .grade1:
                target = 6
            case .grade2:
                target = 7
            default:
                target = 7
            }
        case .threeDigitComparison:
            switch placedGrade ?? .grade2 {
            case .kindergarten, .grade1:
                target = 6
            case .grade2:
                target = 7
            default:
                target = 8
            }
        case .multiplicationArrays, .fractionComparison:
            switch placedGrade ?? .grade3 {
            case .kindergarten, .grade1:
                target = 6
            case .grade2:
                target = 7
            case .grade3:
                target = 8
            default:
                target = 9
            }
        case .fractionOfWhole, .volumeAndDecimals:
            switch placedGrade ?? .grade4 {
            case .kindergarten, .grade1:
                target = 6
            case .grade2:
                target = 7
            case .grade3, .grade4:
                target = 8
            case .grade5:
                target = 9
            }
        case .kCountObjects, .kComposeDecompose, .kAddWithin5, .kAddWithin10:
            switch placedGrade ?? .kindergarten {
            case .kindergarten:
                target = 5
            default:
                target = 6
            }
        case .g1AddWithin20, .g1FactFamilies:
            switch placedGrade ?? .grade1 {
            case .kindergarten, .grade1:
                target = 6
            default:
                target = 7
            }
        case .g2AddWithin100, .g2SubWithin100:
            switch placedGrade ?? .grade2 {
            case .kindergarten, .grade1:
                target = 6
            case .grade2:
                target = 7
            default:
                target = 8
            }
        }

        return min(max(target, minimumSessionItems), maximumSessionItems)
    }
}
