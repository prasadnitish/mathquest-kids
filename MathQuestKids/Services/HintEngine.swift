import Foundation

protocol HintEngine {
    func nextHint(for context: AttemptContext) -> HintAction
}

struct DeterministicHintEngine: HintEngine {
    private let hintsBySkill: [String: HintTemplate]

    init(contentPack: ContentPack) {
        var map: [String: HintTemplate] = [:]
        for template in contentPack.hints {
            map[template.skill] = template
        }
        self.hintsBySkill = map
    }

    func nextHint(for context: AttemptContext) -> HintAction {
        let template = hintsBySkill[context.skillID]

        switch context.incorrectAttempts {
        case ..<1:
            return .showConcreteSupport(text: concreteHint(for: context) ?? template?.concrete ?? "Use a visual helper to think it through.")
        case 1:
            return .strategyPrompt(text: strategyHint(for: context) ?? template?.strategy ?? "Try the strategy step by step.")
        default:
            return .workedStep(text: workedHint(for: context) ?? template?.worked ?? "Let's solve one together, then you solve the next.")
        }
    }

    private func concreteHint(for context: AttemptContext) -> String? {
        switch context.unit {
        case .subtractionStories:
            let start = context.payload.minuend ?? 0
            let takeAway = context.payload.subtrahend ?? 0
            return "Start with \(start). Move or cross out \(takeAway). Then count what is still left."
        case .teenPlaceValue:
            let target = context.payload.target ?? ((context.payload.tens ?? 0) * 10 + (context.payload.ones ?? 0))
            let tens = context.payload.tens ?? target / 10
            let ones = context.payload.ones ?? target % 10
            return "\(target) is built with \(tens) tens bars and \(ones) ones cubes. Build the tens first."
        case .twoDigitComparison:
            let left = context.payload.left ?? 0
            let right = context.payload.right ?? 0
            return "Look at \(left) and \(right). Cover the ones for a moment and compare the tens first."
        case .threeDigitComparison:
            let left = context.payload.left ?? 0
            let right = context.payload.right ?? 0
            return "Compare the biggest place value first. Check the hundreds in \(left) and \(right), then move to tens if needed."
        case .multiplicationArrays:
            let rows = context.payload.multiplicand ?? 1
            let columns = context.payload.multiplier ?? 1
            return "Build \(rows) rows with \(columns) in each row. Equal rows help you see the total."
        case .fractionComparison:
            let aTop = context.payload.numeratorA ?? 0
            let aBottom = max(context.payload.denominatorA ?? 1, 1)
            let bTop = context.payload.numeratorB ?? 0
            let bBottom = max(context.payload.denominatorB ?? 1, 1)
            return "Picture \(aTop)/\(aBottom) and \(bTop)/\(bBottom) with fraction strips. Compare the size of the shaded parts."
        case .fractionOfWhole:
            let top = context.payload.numeratorA ?? 1
            let bottom = max(context.payload.denominatorA ?? 1, 1)
            let whole = context.payload.whole ?? 0
            return "Split \(whole) into \(bottom) equal parts. Then take \(top) of those parts."
        case .volumeAndDecimals:
            if context.payload.decimalLeft != nil, context.payload.decimalRight != nil {
                return "Line up the decimal points and compare place by place from left to right."
            }
            let length = context.payload.length ?? 1
            let width = context.payload.width ?? 1
            let height = context.payload.height ?? 1
            return "Build one layer with \(length) by \(width), then stack \(height) equal layers."
        case .kCountObjects:
            return "Count each object one by one and point to each as you count."
        case .kComposeDecompose:
            return "Use a ten frame. Fill some spots and see how many are left empty."
        case .kAddWithin5:
            let start = context.payload.minuend ?? 0
            let takeAway = context.payload.subtrahend ?? 0
            return "Start with \(start). Count on \(takeAway) more."
        case .kAddWithin10:
            let start = context.payload.minuend ?? 0
            let takeAway = context.payload.subtrahend ?? 0
            return "Start with \(start). Count on \(takeAway) more using your fingers."
        case .g1AddWithin20:
            return "Start with the bigger number and count on from there."
        case .g1FactFamilies:
            return "If you know one fact, you can flip the addends to find the related fact."
        case .g2AddWithin100:
            return "Add the ones first, then add the tens."
        case .g2SubWithin100:
            return "Subtract the ones first, then subtract the tens."
        case .kCompareGroups, .kShapeAttributes:
            return "Look carefully at the picture. Count or compare one group at a time."
        case .g1AddSub100, .g1MeasureLength:
            return "Break the problem into smaller steps. Work with tens and ones."
        case .g2PlaceValue1000, .g2AddSubRegroup:
            return "Think about place value. Hundreds, tens, and ones each have their own column."
        case .g2EqualGroups, .g2TimeMoney, .g2DataIntro:
            return "Read the problem again slowly. What is it really asking?"
        case .g3DivMeaning, .g3FractionUnit, .g3FractionCompare:
            return "Think about equal sharing. Draw a picture to help."
        case .g3AreaConcept, .g3MultiStep:
            return "Break this into two smaller problems and solve one at a time."
        case .g4PlaceValueMillion, .g4MultMultiDigit, .g4DivPartialQuotients:
            return "Use place value. Work from the largest place to the smallest."
        case .g4FractionAddSub, .g4AngleMeasure:
            return "Draw a model or picture to help you see the answer."
        case .g5FractionAddSubUnlike, .g5LinePlotsFractions, .g5PreRatios:
            return "Find what the parts have in common first, then solve."
        }
    }

    private func strategyHint(for context: AttemptContext) -> String? {
        switch context.unit {
        case .subtractionStories:
            let start = context.payload.minuend ?? 0
            let takeAway = context.payload.subtrahend ?? 0
            return "Think \(start) minus \(takeAway). Count back \(takeAway) steps, or count the leftovers after you remove some."
        case .teenPlaceValue:
            let target = context.payload.target ?? ((context.payload.tens ?? 0) * 10 + (context.payload.ones ?? 0))
            return "Ask two questions: how many full groups of ten fit into \(target)? What ones are left after that?"
        case .twoDigitComparison:
            return "Use place value order: compare tens first. Only compare ones if the tens are tied."
        case .threeDigitComparison:
            return "Use hundreds, then tens, then ones. Stop as soon as one place value is bigger."
        case .multiplicationArrays:
            let rows = context.payload.multiplicand ?? 1
            let columns = context.payload.multiplier ?? 1
            return "Skip-count by rows: \(columns), \(columns * 2), \(columns * 3). Keep going until you have \(rows) rows."
        case .fractionComparison:
            let sameDenominator = context.payload.denominatorA == context.payload.denominatorB
            let sameNumerator = context.payload.numeratorA == context.payload.numeratorB
            if sameDenominator {
                return "The denominators match, so compare the numerators. More equal parts shaded means the fraction is larger."
            }
            if sameNumerator {
                return "The numerators match, so compare the denominators. Fewer total parts means each part is bigger."
            }
            return "Look for a benchmark like one half or one whole. Decide which fraction is closer to the bigger benchmark."
        case .fractionOfWhole:
            let top = context.payload.numeratorA ?? 1
            let bottom = max(context.payload.denominatorA ?? 1, 1)
            let whole = context.payload.whole ?? 0
            return "First find one part: \(whole) divided by \(bottom). Then multiply that part by \(top)."
        case .volumeAndDecimals:
            if context.payload.decimalLeft != nil {
                return "Compare whole numbers first. If they match, compare tenths, then hundredths."
            }
            return "Multiply the dimensions in parts: length times width gives one layer, then multiply by the height."
        case .kCountObjects:
            return "Touch each object and say the number out loud. The last number you say is the total."
        case .kComposeDecompose:
            return "Think: what number plus my number makes 10? Use a ten frame to check."
        case .kAddWithin5:
            return "Use your fingers. Hold up the first number, then count up the second number."
        case .kAddWithin10:
            return "Start at the bigger number and count on using your fingers."
        case .g1AddWithin20:
            return "Use a number line. Start at the bigger number and jump forward."
        case .g1FactFamilies:
            return "Look at the three numbers. Any two can add up to the biggest one."
        case .g2AddWithin100:
            return "Break the numbers into tens and ones. Add tens with tens, ones with ones."
        case .g2SubWithin100:
            return "Break the numbers into tens and ones. Subtract ones first, then tens."
        case .kCompareGroups, .kShapeAttributes:
            return "Count each group, then see which has more or fewer."
        case .g1AddSub100, .g1MeasureLength:
            return "Use a number line. Jump by tens, then by ones."
        case .g2PlaceValue1000, .g2AddSubRegroup:
            return "Stack the numbers by place value and work column by column."
        case .g2EqualGroups, .g2TimeMoney, .g2DataIntro:
            return "Underline the key numbers and the question, then solve step by step."
        case .g3DivMeaning, .g3FractionUnit, .g3FractionCompare:
            return "Draw equal groups or fraction strips to see the answer."
        case .g3AreaConcept, .g3MultiStep:
            return "Solve the first part, write it down, then use it for the next part."
        case .g4PlaceValueMillion, .g4MultMultiDigit, .g4DivPartialQuotients:
            return "Break the big number into parts. Solve each part, then combine."
        case .g4FractionAddSub, .g4AngleMeasure:
            return "Check if the parts are the same size first. If not, make them match."
        case .g5FractionAddSubUnlike, .g5LinePlotsFractions, .g5PreRatios:
            return "Find a common denominator or unit first, then solve."
        }
    }

    private func workedHint(for context: AttemptContext) -> String? {
        switch context.unit {
        case .subtractionStories:
            let start = context.payload.minuend ?? 0
            let takeAway = context.payload.subtrahend ?? 0
            let left = max(0, start - takeAway)
            return "Work it through: start at \(start), take away \(takeAway), and \(left) are left. So \(start) - \(takeAway) = \(left)."
        case .teenPlaceValue:
            let target = context.payload.target ?? ((context.payload.tens ?? 0) * 10 + (context.payload.ones ?? 0))
            let tens = context.payload.tens ?? target / 10
            let ones = context.payload.ones ?? target % 10
            return "Break it apart: \(target) = \(tens * 10) + \(ones). That means \(tens) tens and \(ones) ones."
        case .twoDigitComparison:
            let left = context.payload.left ?? 0
            let right = context.payload.right ?? 0
            let sign = left == right ? "=" : (left > right ? ">" : "<")
            return "Check the tens, then the ones. That gives \(left) \(sign) \(right)."
        case .threeDigitComparison:
            let left = context.payload.left ?? 0
            let right = context.payload.right ?? 0
            let sign = left == right ? "=" : (left > right ? ">" : "<")
            return "Compare one place at a time from left to right. That shows \(left) \(sign) \(right)."
        case .multiplicationArrays:
            let rows = context.payload.multiplicand ?? 1
            let columns = context.payload.multiplier ?? 1
            return "An array with \(rows) rows of \(columns) makes \(rows * columns) total squares."
        case .fractionComparison:
            let a = fractionValue(top: context.payload.numeratorA, bottom: context.payload.denominatorA)
            let b = fractionValue(top: context.payload.numeratorB, bottom: context.payload.denominatorB)
            let sign = a == b ? "=" : (a > b ? ">" : "<")
            let aLabel = "\(context.payload.numeratorA ?? 0)/\(max(context.payload.denominatorA ?? 1, 1))"
            let bLabel = "\(context.payload.numeratorB ?? 0)/\(max(context.payload.denominatorB ?? 1, 1))"
            return "When you compare the fraction sizes, you get \(aLabel) \(sign) \(bLabel)."
        case .fractionOfWhole:
            let top = context.payload.numeratorA ?? 1
            let bottom = max(context.payload.denominatorA ?? 1, 1)
            let whole = context.payload.whole ?? 0
            let part = whole / bottom
            return "One part is \(whole) / \(bottom) = \(part). Then \(top) parts is \(part * top)."
        case .volumeAndDecimals:
            if let left = context.payload.decimalLeft, let right = context.payload.decimalRight {
                let sign = left == right ? "=" : (left > right ? ">" : "<")
                return "Line up the decimals and compare each place. That gives \(formatDecimal(left)) \(sign) \(formatDecimal(right))."
            }
            let length = context.payload.length ?? 1
            let width = context.payload.width ?? 1
            let height = context.payload.height ?? 1
            return "Multiply the dimensions: \(length) x \(width) = \(length * width), and \(length * width) x \(height) = \(length * width * height)."
        case .kCountObjects:
            return "Count each object one by one. The last number you say is the answer."
        case .kComposeDecompose:
            let part = context.payload.subtrahend ?? 0
            return "You need \(10 - part) more to make 10. So the missing part is \(10 - part)."
        case .kAddWithin5:
            let a = context.payload.minuend ?? 0
            let b = context.payload.subtrahend ?? 0
            return "Put \(a) and \(b) together. That makes \(a + b)."
        case .kAddWithin10:
            let a = context.payload.minuend ?? 0
            let b = context.payload.subtrahend ?? 0
            return "Count on from \(a): \(a + b). So \(a) + \(b) = \(a + b)."
        case .g1AddWithin20:
            let a = context.payload.minuend ?? 0
            let b = context.payload.subtrahend ?? 0
            return "Start at \(a), count up \(b). You land on \(a + b)."
        case .g1FactFamilies:
            let a = context.payload.minuend ?? 0
            let b = context.payload.subtrahend ?? 0
            return "The fact family has \(a), \(b), and \(a + b). If \(a) + \(b) = \(a + b), then \(a + b) - \(b) = \(a)."
        case .g2AddWithin100:
            let a = context.payload.minuend ?? 0
            let b = context.payload.subtrahend ?? 0
            return "Add the ones: \(a % 10) + \(b % 10). Add the tens: \(a / 10 * 10) + \(b / 10 * 10). Total: \(a + b)."
        case .g2SubWithin100:
            let a = context.payload.minuend ?? 0
            let b = context.payload.subtrahend ?? 0
            return "Subtract the ones first, then the tens. \(a) - \(b) = \(max(0, a - b))."
        case .kCompareGroups, .kShapeAttributes:
            return "Count each group carefully. The group with more objects is the bigger group."
        case .g1AddSub100, .g1MeasureLength:
            return "Break the numbers apart by tens and ones, then put them back together."
        case .g2PlaceValue1000, .g2AddSubRegroup:
            return "Line up the digits by place value. Add or subtract each column starting from the ones."
        case .g2EqualGroups, .g2TimeMoney, .g2DataIntro:
            return "Find the key numbers in the problem, then use the operation that matches."
        case .g3DivMeaning, .g3FractionUnit, .g3FractionCompare:
            return "Divide into equal parts. Count how many are in each group."
        case .g3AreaConcept, .g3MultiStep:
            return "Solve one step at a time. Use your first answer in the second step."
        case .g4PlaceValueMillion, .g4MultMultiDigit, .g4DivPartialQuotients:
            return "Use partial products or partial quotients. Break the big numbers into friendly parts."
        case .g4FractionAddSub, .g4AngleMeasure:
            return "Make the denominators the same, then add or subtract the numerators."
        case .g5FractionAddSubUnlike, .g5LinePlotsFractions, .g5PreRatios:
            return "Find the least common denominator, rewrite both fractions, then solve."
        }
    }

    private func fractionValue(top: Int?, bottom: Int?) -> Double {
        let denominator = max(bottom ?? 1, 1)
        return Double(top ?? 0) / Double(denominator)
    }

    private func formatDecimal(_ value: Double) -> String {
        String(format: "%.3f", value)
    }
}
