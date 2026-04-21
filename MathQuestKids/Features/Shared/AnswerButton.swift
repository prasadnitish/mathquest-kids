import SwiftUI

enum AnswerButtonState: Equatable {
    case `default`
    case selected
    case correct
    case wrong
    case idk     // "I don't know yet"
}

enum AnswerButtonModel {
    /// 1-based number label from 0-based index.
    static func numberLabel(forIndex index: Int) -> String {
        String(index + 1)
    }

    /// State-aware label (returns "?" for .idk, otherwise the numeric label).
    static func numberLabel(forState state: AnswerButtonState) -> String {
        state == .idk ? "?" : ""   // index-based callers fill in the number
    }
}

struct AnswerButton: View {
    let index: Int
    let title: String
    let state: AnswerButtonState
    let theme: VisualTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sp4) {
                numberPill
                Text(title)
                    .kidText(.answer)
                    .foregroundStyle(foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailingGlyph
            }
            .padding(.horizontal, DesignTokens.Spacing.sp4)
            .frame(minHeight: 60)
            .background(background, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderStyle, lineWidth: borderWidth)
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Styling per state

    private var numberPill: some View {
        Text(displayNumber)
            .kidText(.caption)
            .foregroundStyle(numberForeground)
            .frame(width: 32, height: 32)
            .background(numberBackground, in: Circle())
    }

    private var displayNumber: String {
        state == .idk ? "?" : AnswerButtonModel.numberLabel(forIndex: index)
    }

    private var numberBackground: Color {
        switch state {
        case .default:  return theme.primary
        case .selected: return Color.white.opacity(0.3)
        case .correct:  return DesignTokens.correct
        case .wrong:    return DesignTokens.incorrect
        case .idk:      return Color.white.opacity(0.3)
        }
    }

    private var numberForeground: Color {
        switch state {
        case .default, .correct, .wrong: return .white
        case .selected, .idk:            return .white
        }
    }

    private var background: Color {
        switch state {
        case .default:  return .white
        case .selected: return theme.primary
        case .correct:  return DesignTokens.correctBg
        case .wrong:    return DesignTokens.incorrectBg
        case .idk:      return Color.white.opacity(0.15)
        }
    }

    private var foreground: Color {
        switch state {
        case .default:  return AppTheme.textPrimary
        case .selected: return .white
        case .correct:  return DesignTokens.correctText
        case .wrong:    return DesignTokens.incorrectText
        case .idk:      return .white
        }
    }

    private var borderStyle: Color {
        switch state {
        case .default:  return .clear
        case .selected: return theme.primary
        case .correct:  return DesignTokens.correct
        case .wrong:    return DesignTokens.incorrect
        case .idk:      return Color.white.opacity(0.5)
        }
    }

    private var borderWidth: CGFloat { state == .default ? 0 : 3 }

    @ViewBuilder
    private var trailingGlyph: some View {
        switch state {
        case .correct: Text("✓").kidText(.answer)
        case .wrong:   Text("✗").kidText(.answer)
        default:       EmptyView()
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .correct: return "Correct. Option \(displayNumber): \(title)"
        case .wrong:   return "Try again. Option \(displayNumber): \(title)"
        case .idk:     return "I don't know yet"
        default:       return "Option \(displayNumber): \(title)"
        }
    }
}
