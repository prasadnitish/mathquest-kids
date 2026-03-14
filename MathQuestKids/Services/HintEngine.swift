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
        case .kCompareGroups:
            return "Count each group one by one. Point to each dot as you count."
        case .kShapeAttributes:
            return "Look at the shape. Count the sides and corners."
        case .g1AddSub100:
            return "Break the numbers into tens and ones. Add or subtract each part."
        case .g1MeasureLength:
            return "Line up the object with the ruler. Count the unit marks."
        case .g2PlaceValue1000:
            return "Think about how many hundreds, tens, and ones make the number."
        case .g2AddSubRegroup:
            return "When the ones add up to more than 9, regroup 10 ones as 1 ten."
        case .g2EqualGroups:
            return "Put the same number of items in each group."
        case .g2TimeMoney:
            if context.payload.hours != nil {
                return "The short hand shows the hour. The long hand shows the minutes."
            }
            return "Count quarters first (25 each), then dimes (10), nickels (5), and pennies (1)."
        case .g2DataIntro:
            return "Look at the height of each bar. The taller the bar, the more items."
        case .g3DivMeaning:
            return "Think about sharing equally. How many in each group?"
        case .g3FractionUnit:
            return "A unit fraction has 1 on top. The bottom number tells how many equal parts."
        case .g3FractionCompare:
            return "When denominators match, compare the numerators. More parts shaded means bigger."
        case .g3AreaConcept:
            return "Count the rows and columns of unit squares. Multiply to find the area."
        case .g3MultiStep:
            return "Solve the first step. Use that answer in the second step."
        case .g4PlaceValueMillion:
            return "Compare from left to right: millions, then hundred-thousands, and so on."
        case .g4MultMultiDigit:
            return "Break the bigger number into parts. Multiply each part, then add."
        case .g4DivPartialQuotients:
            return "Ask: how many groups of the divisor fit? Subtract and repeat."
        case .g4FractionAddSub:
            return "When denominators match, add or subtract the numerators. Keep the denominator."
        case .g4AngleMeasure:
            return "A right angle is 90\u{00B0}. Is this angle smaller, equal, or bigger?"
        case .g5FractionAddSubUnlike:
            return "Find a common denominator first. Then add or subtract the numerators."
        case .g5LinePlotsFractions:
            return "Read each X on the line plot. Count the Xs above each fraction value."
        case .g5PreRatios:
            return "Look at how the numbers change. Find the pattern and continue it."
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
        case .kCompareGroups:
            return "Count each group. Write both numbers. Which is bigger?"
        case .kShapeAttributes:
            return "Trace each side with your finger. Count the corners where sides meet."
        case .g1AddSub100:
            return "Use a number line. Jump by tens first, then by ones."
        case .g1MeasureLength:
            return "Start at zero on the ruler. Count each space, not each mark."
        case .g2PlaceValue1000:
            return "Write the number in expanded form: hundreds + tens + ones."
        case .g2AddSubRegroup:
            return "Add the ones column first. If you get 10 or more, carry one ten to the tens column."
        case .g2EqualGroups:
            return "Deal items one at a time into each group, like dealing cards."
        case .g2TimeMoney:
            if context.payload.hours != nil {
                return "Find the hour first (short hand), then count by 5s for the minute hand."
            }
            return "Sort coins by value. Add the biggest coins first, then the smallest."
        case .g2DataIntro:
            return "Find the category on the bottom, then read up to the top of the bar."
        case .g3DivMeaning:
            return "Use repeated subtraction. Keep subtracting the group size until you reach zero."
        case .g3FractionUnit:
            return "The denominator tells the total parts. The numerator tells how many are shaded."
        case .g3FractionCompare:
            return "Draw fraction strips. Make them the same length. Compare the shaded parts."
        case .g3AreaConcept:
            return "Multiply the number of rows by the number of columns."
        case .g3MultiStep:
            return "Read the problem twice. Circle what you need to find. Solve one step at a time."
        case .g4PlaceValueMillion:
            return "Line up the digits. Compare the leftmost place value first."
        case .g4MultMultiDigit:
            return "Use partial products: multiply ones, then tens, then add the results."
        case .g4DivPartialQuotients:
            return "Subtract easy multiples of the divisor. Add up how many times you subtracted."
        case .g4FractionAddSub:
            return "Keep the denominator the same. Only add or subtract the numerators."
        case .g4AngleMeasure:
            return "Compare to a right angle (90\u{00B0}). Acute is less, obtuse is more."
        case .g5FractionAddSubUnlike:
            return "Find the least common denominator. Convert both fractions, then add or subtract."
        case .g5LinePlotsFractions:
            return "Each X represents one data point. Count all Xs to find the total."
        case .g5PreRatios:
            return "Make a table. Multiply both sides of the ratio by the same number."
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
            let partValue = Double(whole) / Double(bottom)
            let result = partValue * Double(top)
            let partStr = partValue.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(partValue))" : String(format: "%.1f", partValue)
            let resultStr = result.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(result))" : String(format: "%.1f", result)
            return "One part is \(whole) / \(bottom) = \(partStr). Then \(top) parts is \(resultStr)."
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
        case .kCompareGroups:
            let l = context.payload.left ?? 0
            let r = context.payload.right ?? 0
            let relation = l > r ? "more" : (l < r ? "fewer" : "the same")
            return "Group A has \(l) and Group B has \(r). Group A has \(relation)."
        case .kShapeAttributes:
            let sides = context.payload.sides ?? 0
            let corners = context.payload.corners ?? 0
            return "This shape has \(sides) sides and \(corners) corners. That makes it a \(context.payload.shapeName ?? "shape")."
        case .g1AddSub100:
            let a = context.payload.left ?? context.payload.minuend ?? 0
            let b = context.payload.right ?? context.payload.subtrahend ?? 0
            return "Break it apart: \(a) and \(b). Add or subtract to get \(a + b)."
        case .g1MeasureLength:
            let length = context.payload.target ?? 0
            return "The object stretches from 0 to \(length). So it is \(length) units long."
        case .g2PlaceValue1000:
            let target = context.payload.target ?? 0
            return "\(target) = \(target / 100) hundreds + \((target % 100) / 10) tens + \(target % 10) ones."
        case .g2AddSubRegroup:
            let a = context.payload.left ?? context.payload.minuend ?? 0
            let b = context.payload.right ?? context.payload.subtrahend ?? 0
            return "Add: \(a) + \(b). Ones: \(a % 10) + \(b % 10) = \((a % 10) + (b % 10)). Regroup if needed. Total: \(a + b)."
        case .g2EqualGroups:
            let total = context.payload.dividend ?? (context.payload.multiplicand ?? 0) * (context.payload.multiplier ?? 1)
            let groups = max(context.payload.divisor ?? context.payload.multiplier ?? 1, 1)
            return "\(total) items shared into \(groups) groups gives \(total / groups) in each group."
        case .g2TimeMoney:
            if let h = context.payload.hours, let m = context.payload.minutes {
                return "The short hand points to \(h) and the long hand points to \(m / 5 * 5 == m ? "\(m / 5) (which is \(m) minutes)" : "\(m) minutes"). The time is \(h):\(String(format: "%02d", m))."
            }
            let cents = context.payload.cents ?? 0
            return "Count the coins: \(cents / 25) quarters (\(cents / 25 * 25)\u{00A2}), then add the rest to get \(cents)\u{00A2}."
        case .g2DataIntro:
            return "Read the bar heights. The tallest bar has the most. Compare the numbers to find the answer."
        case .g3DivMeaning:
            let total = context.payload.dividend ?? 0
            let groups = max(context.payload.divisor ?? 1, 1)
            return "\(total) \u{00F7} \(groups) = \(total / groups). Each group gets \(total / groups) items."
        case .g3FractionUnit:
            let d = max(context.payload.denominatorA ?? 1, 1)
            return "The whole is split into \(d) equal parts. One part is 1/\(d)."
        case .g3FractionCompare:
            let aTop = context.payload.numeratorA ?? 0
            let aBot = max(context.payload.denominatorA ?? 1, 1)
            let bTop = context.payload.numeratorB ?? 0
            let bBot = max(context.payload.denominatorB ?? 1, 1)
            let sign = (Double(aTop) / Double(aBot)) == (Double(bTop) / Double(bBot)) ? "=" : ((Double(aTop) / Double(aBot)) > (Double(bTop) / Double(bBot)) ? ">" : "<")
            return "Compare \(aTop)/\(aBot) and \(bTop)/\(bBot). Since \(aTop)/\(aBot) \(sign) \(bTop)/\(bBot)."
        case .g3AreaConcept:
            let rows = context.payload.length ?? context.payload.multiplicand ?? 1
            let cols = context.payload.width ?? context.payload.multiplier ?? 1
            return "\(rows) rows \u{00D7} \(cols) columns = \(rows * cols) unit squares."
        case .g3MultiStep:
            return "Step 1: solve the first operation. Step 2: use that result in the second operation."
        case .g4PlaceValueMillion:
            let l = context.payload.left ?? 0
            let r = context.payload.right ?? 0
            let sign = l == r ? "=" : (l > r ? ">" : "<")
            return "Compare place by place from left to right. \(l) \(sign) \(r)."
        case .g4MultMultiDigit:
            let a = context.payload.multiplicand ?? 1
            let b = context.payload.multiplier ?? 1
            return "\(a) \u{00D7} \(b): partial products are \(a) \u{00D7} \(b % 10) = \(a * (b % 10)) and \(a) \u{00D7} \(b / 10 * 10) = \(a * (b / 10 * 10)). Total: \(a * b)."
        case .g4DivPartialQuotients:
            let total = context.payload.dividend ?? 0
            let divisor = max(context.payload.divisor ?? 1, 1)
            return "\(total) \u{00F7} \(divisor): subtract \(divisor) repeatedly. You can subtract \(total / divisor) groups. Answer: \(total / divisor)."
        case .g4FractionAddSub:
            let nA = context.payload.numeratorA ?? 0
            let nB = context.payload.numeratorB ?? 0
            let d = max(context.payload.denominatorA ?? 1, 1)
            return "\(nA)/\(d) + \(nB)/\(d) = \(nA + nB)/\(d). Add the numerators, keep the denominator."
        case .g4AngleMeasure:
            let deg = context.payload.degrees ?? 90
            return "This angle measures \(deg)\u{00B0}. A right angle is 90\u{00B0}, so this is \(deg < 90 ? "acute" : deg == 90 ? "right" : "obtuse")."
        case .g5FractionAddSubUnlike:
            let dA = max(context.payload.denominatorA ?? 1, 1)
            let dB = max(context.payload.denominatorB ?? 1, 1)
            let lcd = dA * dB / gcd(dA, dB)
            return "Find the common denominator: LCD of \(dA) and \(dB) is \(lcd). Convert both fractions, then add or subtract."
        case .g5LinePlotsFractions:
            return "Count the Xs above each value. Use the totals to answer the question."
        case .g5PreRatios:
            let l = context.payload.ratioLeft ?? context.payload.left ?? 2
            let r = context.payload.ratioRight ?? context.payload.right ?? 3
            return "The ratio is \(l):\(r). Multiply both by the same number: \(l)\u{00D7}4 = \(l * 4), \(r)\u{00D7}4 = \(r * 4)."
        }
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }

    private func fractionValue(top: Int?, bottom: Int?) -> Double {
        let denominator = max(bottom ?? 1, 1)
        return Double(top ?? 0) / Double(denominator)
    }

    private func formatDecimal(_ value: Double) -> String {
        String(format: "%.3f", value)
    }
}
