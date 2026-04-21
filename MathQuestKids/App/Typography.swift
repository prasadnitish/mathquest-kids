import SwiftUI

struct TextSpec {
    let familyName: String
    let weight: Font.Weight
    let size: CGFloat
    let lineHeight: CGFloat   // multiplier; 1.0 = default
    let tracking: CGFloat     // letter spacing
}

// Child-facing typography. Nunito, 800+ for headings/questions/answers.
enum KidText: CaseIterable {
    case display, h1, h2, question, answer, body, caption

    var spec: TextSpec {
        switch self {
        case .display:  return .init(familyName: "Nunito", weight: .black,     size: 36, lineHeight: 1.1,  tracking: -0.5)
        case .h1:       return .init(familyName: "Nunito", weight: .heavy,     size: 28, lineHeight: 1.2,  tracking: 0)
        case .h2:       return .init(familyName: "Nunito", weight: .heavy,     size: 22, lineHeight: 1.25, tracking: 0)
        case .question: return .init(familyName: "Nunito", weight: .heavy,     size: 26, lineHeight: 1.3,  tracking: 0)
        case .answer:   return .init(familyName: "Nunito", weight: .heavy,     size: 22, lineHeight: 1.2,  tracking: 0)
        case .body:     return .init(familyName: "Nunito", weight: .bold,      size: 16, lineHeight: 1.5,  tracking: 0)
        case .caption:  return .init(familyName: "Nunito", weight: .semibold,  size: 13, lineHeight: 1.3,  tracking: 0)
        }
    }
}

// Parent-mode only. DM Sans, lighter weights permitted.
enum ParentText: CaseIterable {
    case title, section, data, caption

    var spec: TextSpec {
        switch self {
        case .title:   return .init(familyName: "DM Sans", weight: .bold,     size: 22, lineHeight: 1.3, tracking: 0)
        case .section: return .init(familyName: "DM Sans", weight: .semibold, size: 13, lineHeight: 1.3, tracking: 0.08)
        case .data:    return .init(familyName: "DM Sans", weight: .medium,   size: 14, lineHeight: 1.4, tracking: 0)
        case .caption: return .init(familyName: "DM Sans", weight: .medium,   size: 12, lineHeight: 1.3, tracking: 0)
        }
    }
}

private extension Font.Weight {
    var uiWeightSuffix: String {
        switch self {
        case .medium:   return "-Medium"
        case .semibold: return "-SemiBold"
        case .bold:     return "-Bold"
        case .heavy:    return "-ExtraBold"
        case .black:    return "-Black"
        default:        return "-Regular"
        }
    }
}

extension View {
    /// Apply a child-UI typography token. Adds font, line spacing, and tracking in one modifier.
    func kidText(_ style: KidText) -> some View {
        let s = style.spec
        let postscript = s.familyName.replacingOccurrences(of: " ", with: "") + s.weight.uiWeightSuffix
        return self
            .font(.custom(postscript, size: s.size))
            .tracking(s.tracking)
            .lineSpacing(s.size * (s.lineHeight - 1))
    }

    /// Apply a parent-mode typography token.
    func parentText(_ style: ParentText) -> some View {
        let s = style.spec
        let postscript = s.familyName.replacingOccurrences(of: " ", with: "") + s.weight.uiWeightSuffix
        return self
            .font(.custom(postscript, size: s.size))
            .tracking(s.tracking)
            .lineSpacing(s.size * (s.lineHeight - 1))
    }
}
