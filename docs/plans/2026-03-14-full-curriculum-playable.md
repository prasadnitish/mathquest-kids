# Full K-5 Curriculum: All Lessons Playable

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make all 41 lessons in the K-5 roadmap playable with unique interaction views, 30+ templates per unit (no duplicate questions), and ElevenLabs narration audio.

**Architecture:** Add 22 new UnitType cases, 10 new ItemFormat types with dedicated SwiftUI interaction views, procedurally generate ~1,500 new question templates via Python, then run the existing `generate_audio.py` pipeline to produce ElevenLabs MP3s for every question.

**Tech Stack:** Swift/SwiftUI (iOS), Python 3 (template + audio generation), ElevenLabs TTS API

---

## Current State

- 16 UnitType cases, 15 ItemFormat types, 1,471 templates
- K-2 units have only 5 templates each → causes duplicate questions
- 22 of 41 lessons have linkedUnit values that don't match any UnitType
- Audio pipeline exists at `scripts/generate_audio.py` (ElevenLabs, voice "Sparkles for Kids")

## New Interaction Views Needed

| View | Formats | Math Concept |
|------|---------|-------------|
| GroupComparisonInteraction | groupComparison | Two dot groups + more/fewer/same |
| ShapeClassificationInteraction | shapeClassification | Shapes with attribute labels |
| MeasureLengthInteraction | measureLength | Ruler with unit marks |
| DivisionGroupsInteraction | divisionGroups | Items split into equal groups |
| AreaTilingInteraction | areaTiling | Unit square grid counting |
| TimeMoneyInteraction | timeMoney | Clock face + coin images |
| DataPlotInteraction | dataPlot | Bar chart reading |
| AngleMeasureInteraction | angleMeasure | Angle visual with degree options |
| FractionAddSubInteraction | fractionAddSub | Fraction strips for add/subtract |
| RatioTableInteraction | ratioTable | Pattern/ratio table completion |

Formats that reuse existing views (no new view needed):
- `multiStepStory` → AdditionStoryInteraction (word problem + numeric options)
- `longMultiplication` → AdditionStoryInteraction (numeric options)
- `longDivision` → AdditionStoryInteraction (numeric options)
- `placeValueExpanded` → TeenPlaceValueInteraction extended (hundreds/thousands buckets)
- `largeComparison` → ComparisonInteraction (same < > = pattern, bigger numbers)

---

## Task 1: Add New UnitType Cases

**Files:**
- Modify: `MathQuestKids/Domain/Models.swift`

**Step 1: Add 22 new cases to UnitType enum**

Add after existing cases:

```swift
// Kindergarten
case kCompareGroups
case kShapeAttributes
// Grade 1
case g1AddSub100
case g1MeasureLength
// Grade 2
case g2PlaceValue1000
case g2AddSubRegroup
case g2EqualGroups
case g2TimeMoney
case g2DataIntro
// Grade 3
case g3DivMeaning
case g3FractionUnit
case g3FractionCompare
case g3AreaConcept
case g3MultiStep
// Grade 4
case g4PlaceValueMillion
case g4MultMultiDigit
case g4DivPartialQuotients
case g4FractionAddSub
case g4AngleMeasure
// Grade 5
case g5FractionAddSubUnlike
case g5LinePlotsFractions
case g5PreRatios
```

**Step 2: Add `title` for each new case**

```swift
case .kCompareGroups:       return "Compare Groups"
case .kShapeAttributes:     return "Shape Attributes"
case .g1AddSub100:          return "Add & Subtract to 100"
case .g1MeasureLength:      return "Measure Length"
case .g2PlaceValue1000:     return "Place Value to 1,000"
case .g2AddSubRegroup:      return "Regroup to Add & Subtract"
case .g2EqualGroups:        return "Equal Groups"
case .g2TimeMoney:          return "Time & Money"
case .g2DataIntro:          return "Picture Graphs"
case .g3DivMeaning:         return "Meaning of Division"
case .g3FractionUnit:       return "Unit Fractions"
case .g3FractionCompare:    return "Compare Fractions"
case .g3AreaConcept:        return "Area as Tiling"
case .g3MultiStep:          return "Two-Step Problems"
case .g4PlaceValueMillion:  return "Place Value to Millions"
case .g4MultMultiDigit:     return "Multi-Digit Multiply"
case .g4DivPartialQuotients: return "Long Division"
case .g4FractionAddSub:     return "Add & Subtract Fractions"
case .g4AngleMeasure:       return "Angles & Degrees"
case .g5FractionAddSubUnlike: return "Unlike Denominators"
case .g5LinePlotsFractions: return "Line Plots"
case .g5PreRatios:          return "Ratios & Patterns"
```

**Step 3: Add `subtitle` for each new case**

```swift
case .kCompareGroups:       return "Compare which group has more, fewer, or the same"
case .kShapeAttributes:     return "Sort shapes by sides and corners"
case .g1AddSub100:          return "Add and subtract with tens and ones"
case .g1MeasureLength:      return "Measure objects using unit lengths"
case .g2PlaceValue1000:     return "Build numbers with hundreds, tens, ones"
case .g2AddSubRegroup:      return "Regroup when adding or subtracting"
case .g2EqualGroups:        return "Make equal groups to get ready for multiplication"
case .g2TimeMoney:          return "Tell time and count coins"
case .g2DataIntro:          return "Read and compare picture graphs"
case .g3DivMeaning:         return "Share equally and find how many groups"
case .g3FractionUnit:       return "Name fractions as parts of a whole"
case .g3FractionCompare:    return "Compare fractions with same denominator"
case .g3AreaConcept:        return "Count unit squares to find area"
case .g3MultiStep:          return "Solve two-step word problems"
case .g4PlaceValueMillion:  return "Read and compare numbers to 1,000,000"
case .g4MultMultiDigit:     return "Multiply multi-digit numbers step by step"
case .g4DivPartialQuotients: return "Divide using partial quotients"
case .g4FractionAddSub:     return "Add and subtract fractions with like denominators"
case .g4AngleMeasure:       return "Estimate and measure angles in degrees"
case .g5FractionAddSubUnlike: return "Add and subtract fractions with different denominators"
case .g5LinePlotsFractions: return "Read line plots with fraction data"
case .g5PreRatios:          return "Find and extend ratio patterns"
```

**Step 4: Add `gradeHint` for each new case**

```swift
case .kCompareGroups, .kShapeAttributes: return "K"
case .g1AddSub100, .g1MeasureLength: return "1"
case .g2PlaceValue1000, .g2AddSubRegroup, .g2EqualGroups, .g2TimeMoney, .g2DataIntro: return "2"
case .g3DivMeaning, .g3FractionUnit, .g3FractionCompare, .g3AreaConcept, .g3MultiStep: return "3"
case .g4PlaceValueMillion, .g4MultMultiDigit, .g4DivPartialQuotients, .g4FractionAddSub, .g4AngleMeasure: return "4"
case .g5FractionAddSubUnlike, .g5LinePlotsFractions, .g5PreRatios: return "5"
```

**Step 5: Update `learningPath` to include all 38 units in curriculum order**

```swift
static var learningPath: [UnitType] {
    [
        // Kindergarten (8)
        .kCountObjects, .kComposeDecompose, .kAddWithin5, .kAddWithin10,
        .subtractionStories, .kCompareGroups, .kShapeAttributes, .teenPlaceValue,
        // Grade 1 (7)
        .g1AddWithin20, .g1FactFamilies, .twoDigitComparison,
        .g1AddSub100, .g1MeasureLength,
        // Grade 2 (8)
        .g2AddWithin100, .g2SubWithin100, .threeDigitComparison,
        .g2PlaceValue1000, .g2AddSubRegroup, .g2EqualGroups, .g2TimeMoney, .g2DataIntro,
        // Grade 3 (6)
        .multiplicationArrays, .g3DivMeaning, .g3FractionUnit,
        .g3FractionCompare, .g3AreaConcept, .g3MultiStep,
        // Grade 4 (6)
        .fractionComparison, .g4PlaceValueMillion, .g4MultMultiDigit,
        .g4DivPartialQuotients, .g4FractionAddSub, .g4AngleMeasure,
        // Grade 5 (6)
        .fractionOfWhole, .volumeAndDecimals,
        .g5FractionAddSubUnlike, .g5LinePlotsFractions, .g5PreRatios,
    ]
}
```

**Step 6: Update `DashboardSnapshot.empty` default unlock to `.kCountObjects`**

Already correct — verify it uses first item in learningPath.

**Step 7: Build to verify compilation**

```bash
DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer" xcodebuild -project MathQuestKids.xcodeproj -scheme MathQuestKids -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED (after adding placeholder switch cases — see next task)

**Step 8: Commit**

```bash
git add MathQuestKids/Domain/Models.swift
git commit -m "feat: add 22 new UnitType cases for full K-5 curriculum"
```

---

## Task 2: Add New ItemFormat Cases + Extend ItemPayload

**Files:**
- Modify: `MathQuestKids/Domain/Models.swift` (ItemFormat enum)
- Modify: `MathQuestKids/Content/ContentPack.swift` (ItemPayload)

**Step 1: Add 10 new ItemFormat cases**

```swift
enum ItemFormat: String, Codable {
    // ... existing 15 cases ...
    case groupComparison      // two dot groups + more/fewer/same
    case shapeClassification  // shape image + attribute question
    case measureLength        // ruler + unit count
    case divisionGroups       // items split into equal groups
    case areaTiling           // unit square grid
    case timeMoney            // clock face / coin counting
    case dataPlot             // bar chart / picture graph reading
    case angleMeasure         // angle visual + degree options
    case fractionAddSub       // fraction strip addition/subtraction
    case ratioTable           // ratio/pattern table completion
}
```

**Step 2: Extend ItemPayload with new fields**

Add to `ItemPayload` struct:

```swift
// Shape attributes
let sides: Int?
let corners: Int?
let shapeName: String?

// Time & money
let hours: Int?
let minutes: Int?
let cents: Int?

// Division
let dividend: Int?
let divisor: Int?

// Angles
let degrees: Int?

// Data plots
let barValues: [Int]?
let barLabels: [String]?

// Ratios
let ratioLeft: Int?
let ratioRight: Int?
```

Add these parameters to the `init` with `nil` defaults and assign them.

**Step 3: Build to verify**

**Step 4: Commit**

```bash
git commit -m "feat: add 10 new ItemFormat cases and extend ItemPayload"
```

---

## Task 3: Update SessionComposer for New Formats

**Files:**
- Modify: `MathQuestKids/Data/SessionComposer.swift`

**Step 1: Add new format cases to `makePracticeItem` switch**

```swift
case .groupComparison:
    options = ["More", "Fewer", "Same"]
case .shapeClassification:
    // Options generated from template (shape names)
    let answer = template.answer
    options = makeShapeOptions(answer: answer)
case .measureLength, .areaTiling, .angleMeasure, .timeMoney, .dataPlot, .ratioTable:
    let answer = Int(template.answer) ?? template.payload.target ?? 0
    options = makeNumericOptions(answer: answer)
case .divisionGroups:
    let answer = Int(template.answer) ?? template.payload.target ?? 0
    options = makeNumericOptions(answer: answer)
case .fractionAddSub:
    // Answer is "numerator/denominator" string
    options = makeFractionOptions(answer: template.answer)
```

**Step 2: Add helper methods**

```swift
private func makeShapeOptions(answer: String) -> [String] {
    let shapes = ["Triangle", "Square", "Rectangle", "Circle", "Pentagon", "Hexagon", "Rhombus", "Trapezoid"]
    var opts = [answer]
    for s in shapes.shuffled() where s != answer && opts.count < 4 {
        opts.append(s)
    }
    return deterministic ? opts.sorted() : opts.shuffled()
}

private func makeFractionOptions(answer: String) -> [String] {
    // Parse "n/d" format
    let parts = answer.split(separator: "/").compactMap { Int($0) }
    guard parts.count == 2 else { return [answer] }
    let n = parts[0], d = parts[1]
    var opts = ["\(n)/\(d)"]
    let offsets = [-2, -1, 1, 2]
    for off in offsets {
        let candidate = max(0, n + off)
        if candidate != n { opts.append("\(candidate)/\(d)") }
    }
    let unique = Array(Set(opts))
    let selected = deterministic ? Array(unique.sorted().prefix(4)) : Array(unique.shuffled().prefix(4))
    var result = selected
    if !result.contains("\(n)/\(d)") {
        result[result.count - 1] = "\(n)/\(d)"
    }
    return deterministic ? result.sorted() : result.shuffled()
}
```

**Step 3: Build and commit**

---

## Task 4: Create 10 New Interaction Views

**Files:**
- Create: `MathQuestKids/Features/Session/Interactions/GroupComparisonInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/ShapeClassificationInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/MeasureLengthInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/DivisionGroupsInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/AreaTilingInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/TimeMoneyInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/DataPlotInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/AngleMeasureInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/FractionAddSubInteraction.swift`
- Create: `MathQuestKids/Features/Session/Interactions/RatioTableInteraction.swift`
- Modify: `MathQuestKids/Features/Session/SessionView.swift` (manipulativeArea switch)

Each view follows the same pattern: `let item: PracticeItem`, `@Binding var selection: String`, visual + `ChoiceButton` options.

### 4a: GroupComparisonInteraction

Two groups of colored dots side by side. Child taps "More", "Fewer", or "Same".

```swift
struct GroupComparisonInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                dotGroup(count: item.payload.left ?? 0, label: "Group A", color: AppTheme.accent)
                dotGroup(count: item.payload.right ?? 0, label: "Group B", color: AppTheme.primary)
            }
            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private func dotGroup(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.caption.bold()).foregroundStyle(AppTheme.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(24)), count: 5), spacing: 6) {
                ForEach(0..<max(count, 0), id: \.self) { _ in
                    Circle().fill(color.opacity(0.8)).frame(width: 20, height: 20)
                }
            }
            .frame(minHeight: 40)
        }
        .padding(10)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
    }
}
```

### 4b: ShapeClassificationInteraction

Shows an SF Symbol shape and asks to identify it or count sides/corners.

```swift
struct ShapeClassificationInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var shapeSymbol: String {
        switch item.payload.shapeName ?? "" {
        case "Triangle": return "triangle.fill"
        case "Square": return "square.fill"
        case "Rectangle": return "rectangle.fill"
        case "Circle": return "circle.fill"
        case "Pentagon": return "pentagon.fill"
        case "Hexagon": return "hexagon.fill"
        case "Diamond", "Rhombus": return "diamond.fill"
        default: return "questionmark.square.fill"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: shapeSymbol)
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.primary.opacity(0.7))
                .frame(height: 120)

            if let sides = item.payload.sides {
                Text("This shape has \(sides) sides")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
```

### 4c: MeasureLengthInteraction

A horizontal ruler with unit tick marks. Object shown above it.

```swift
struct MeasureLengthInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var objectLength: Int { item.payload.target ?? 5 }

    var body: some View {
        VStack(spacing: 16) {
            // Object bar
            RoundedRectangle(cornerRadius: 6)
                .fill(AppTheme.accent.opacity(0.6))
                .frame(width: CGFloat(objectLength) * 32, height: 24)

            // Ruler
            HStack(spacing: 0) {
                ForEach(0...12, id: \.self) { tick in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(AppTheme.textPrimary.opacity(tick <= objectLength ? 0.8 : 0.3))
                            .frame(width: 1, height: tick % 5 == 0 ? 18 : 10)
                        if tick % 1 == 0 {
                            Text("\(tick)")
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .frame(width: 32)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
```

### 4d: DivisionGroupsInteraction

Items arranged into equal groups with circles around each group.

```swift
struct DivisionGroupsInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var total: Int { item.payload.dividend ?? (item.payload.multiplicand ?? 1) * (item.payload.multiplier ?? 1) }
    private var groups: Int { item.payload.divisor ?? item.payload.multiplier ?? 1 }
    private var perGroup: Int { max(1, total / max(groups, 1)) }

    var body: some View {
        VStack(spacing: 16) {
            Text("\(total) items ÷ \(groups) groups")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(groups, 4)), spacing: 12) {
                ForEach(0..<min(groups, 8), id: \.self) { g in
                    VStack(spacing: 4) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 16))], spacing: 4) {
                            ForEach(0..<min(perGroup, 12), id: \.self) { _ in
                                Circle().fill(AppTheme.accent.opacity(0.8)).frame(width: 14, height: 14)
                            }
                        }
                        Text("Group \(g + 1)").font(.caption2.bold()).foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(8)
                    .background(AppTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.primary.opacity(0.2), lineWidth: 1))
                }
            }

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
```

### 4e: AreaTilingInteraction

Grid of unit squares. Child counts total area.

```swift
struct AreaTilingInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var rows: Int { item.payload.length ?? item.payload.multiplicand ?? 3 }
    private var cols: Int { item.payload.width ?? item.payload.multiplier ?? 4 }

    var body: some View {
        VStack(spacing: 16) {
            Text("Count the unit squares")
                .font(.headline)

            VStack(spacing: 2) {
                ForEach(0..<min(rows, 10), id: \.self) { _ in
                    HStack(spacing: 2) {
                        ForEach(0..<min(cols, 10), id: \.self) { _ in
                            Rectangle()
                                .fill(AppTheme.accent.opacity(0.5))
                                .frame(width: 28, height: 28)
                                .overlay(Rectangle().stroke(AppTheme.primary.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))

            Text("\(rows) rows × \(cols) columns = ?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
```

### 4f: TimeMoneyInteraction

Clock face for time questions, coin images for money questions.

```swift
struct TimeMoneyInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var isTimeQuestion: Bool { item.payload.hours != nil }

    var body: some View {
        VStack(spacing: 16) {
            if isTimeQuestion {
                ClockFaceView(hours: item.payload.hours ?? 0, minutes: item.payload.minutes ?? 0)
                    .frame(width: 160, height: 160)
            } else {
                CoinDisplayView(cents: item.payload.cents ?? 0)
            }

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ClockFaceView: View {
    let hours: Int
    let minutes: Int

    var body: some View {
        ZStack {
            Circle().stroke(AppTheme.textPrimary, lineWidth: 3)
            // Hour marks
            ForEach(1...12, id: \.self) { h in
                Text("\(h)")
                    .font(.caption.bold())
                    .position(hourPosition(h, in: 150))
            }
            // Hour hand
            Rectangle()
                .fill(AppTheme.textPrimary)
                .frame(width: 4, height: 40)
                .offset(y: -20)
                .rotationEffect(.degrees(Double(hours % 12) * 30 + Double(minutes) * 0.5))
            // Minute hand
            Rectangle()
                .fill(AppTheme.primary)
                .frame(width: 2.5, height: 55)
                .offset(y: -27.5)
                .rotationEffect(.degrees(Double(minutes) * 6))
            Circle().fill(AppTheme.textPrimary).frame(width: 8, height: 8)
        }
    }

    private func hourPosition(_ hour: Int, in size: CGFloat) -> CGPoint {
        let angle = Double(hour) * .pi / 6 - .pi / 2
        let r = size / 2 - 20
        return CGPoint(x: size/2 + r * cos(angle), y: size/2 + r * sin(angle))
    }
}

struct CoinDisplayView: View {
    let cents: Int
    private var coins: [(String, Int)] {
        var remaining = cents
        var result: [(String, Int)] = []
        for (name, value) in [("Quarter", 25), ("Dime", 10), ("Nickel", 5), ("Penny", 1)] {
            let count = remaining / value
            if count > 0 { result.append((name, count)); remaining -= count * value }
        }
        return result
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(coins, id: \.0) { name, count in
                VStack(spacing: 4) {
                    ZStack {
                        Circle().fill(name == "Penny" ? Color.orange.opacity(0.6) : Color.gray.opacity(0.4))
                            .frame(width: name == "Quarter" ? 40 : name == "Dime" ? 28 : 34,
                                   height: name == "Quarter" ? 40 : name == "Dime" ? 28 : 34)
                        Text(name.prefix(1)).font(.caption.bold())
                    }
                    Text("×\(count)").font(.caption2.bold()).foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}
```

### 4g: DataPlotInteraction

Simple bar chart with labeled bars. Question asks to read a value or compare.

```swift
struct DataPlotInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var values: [Int] { item.payload.barValues ?? [3, 5, 2, 4] }
    private var labels: [String] { item.payload.barLabels ?? ["A", "B", "C", "D"] }
    private var maxVal: Int { max(values.max() ?? 1, 1) }

    var body: some View {
        VStack(spacing: 16) {
            // Bar chart
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<min(values.count, labels.count), id: \.self) { i in
                    VStack(spacing: 4) {
                        Text("\(values[i])").font(.caption.bold())
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.primary.opacity(0.6 + 0.1 * Double(i)))
                            .frame(width: 36, height: CGFloat(values[i]) / CGFloat(maxVal) * 100)
                        Text(labels[i]).font(.caption2.bold()).foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .frame(height: 140)
            .padding()
            .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
```

### 4h: AngleMeasureInteraction

Two lines forming an angle with an arc showing the measurement.

```swift
struct AngleMeasureInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var degrees: Double { Double(item.payload.degrees ?? 90) }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Base line
                Path { p in
                    p.move(to: CGPoint(x: 30, y: 130))
                    p.addLine(to: CGPoint(x: 200, y: 130))
                }
                .stroke(AppTheme.textPrimary, lineWidth: 3)

                // Angled line
                Path { p in
                    let radians = degrees * .pi / 180
                    p.move(to: CGPoint(x: 30, y: 130))
                    p.addLine(to: CGPoint(x: 30 + 170 * cos(radians), y: 130 - 170 * sin(radians)))
                }
                .stroke(AppTheme.primary, lineWidth: 3)

                // Arc
                Path { p in
                    p.addArc(center: CGPoint(x: 30, y: 130), radius: 40,
                             startAngle: .degrees(0), endAngle: .degrees(-degrees), clockwise: true)
                }
                .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))

                Text("?°")
                    .font(.headline.bold())
                    .position(x: 30 + 55 * cos(degrees/2 * .pi/180), y: 130 - 55 * sin(degrees/2 * .pi/180))
            }
            .frame(width: 230, height: 160)

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
```

### 4i: FractionAddSubInteraction

Two fraction strips showing addition or subtraction.

```swift
struct FractionAddSubInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var numA: Int { item.payload.numeratorA ?? 1 }
    private var denA: Int { max(item.payload.denominatorA ?? 1, 1) }
    private var numB: Int { item.payload.numeratorB ?? 1 }
    private var denB: Int { max(item.payload.denominatorB ?? 1, 1) }
    private var isSubtraction: Bool { item.prompt.contains("-") || item.prompt.contains("subtract") }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                fractionStrip(numerator: numA, denominator: denA, label: "A", color: AppTheme.accent)
                Text(isSubtraction ? "−" : "+")
                    .font(.title.bold())
                fractionStrip(numerator: numB, denominator: denB, label: "B", color: AppTheme.primary)
            }

            Text("= ?")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private func fractionStrip(numerator: Int, denominator: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            FractionBadge(numerator: numerator, denominator: denominator)
            HStack(spacing: 1) {
                ForEach(0..<denominator, id: \.self) { i in
                    Rectangle()
                        .fill(i < numerator ? color.opacity(0.7) : Color.gray.opacity(0.15))
                        .frame(height: 20)
                        .overlay(Rectangle().stroke(color.opacity(0.3), lineWidth: 0.5))
                }
            }
            .frame(width: 100)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
```

### 4j: RatioTableInteraction

A simple ratio/pattern table with a missing value.

```swift
struct RatioTableInteraction: View {
    let item: PracticeItem
    @Binding var selection: String

    private var ratioL: Int { item.payload.ratioLeft ?? item.payload.left ?? 2 }
    private var ratioR: Int { item.payload.ratioRight ?? item.payload.right ?? 3 }

    var body: some View {
        VStack(spacing: 16) {
            // Ratio pattern table
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    cell("×", header: true)
                    cell("1", header: true)
                    cell("2", header: true)
                    cell("3", header: true)
                    cell("4", header: true)
                }
                HStack(spacing: 0) {
                    cell("A", header: true)
                    cell("\(ratioL)")
                    cell("\(ratioL * 2)")
                    cell("\(ratioL * 3)")
                    cell("?")
                }
                HStack(spacing: 0) {
                    cell("B", header: true)
                    cell("\(ratioR)")
                    cell("\(ratioR * 2)")
                    cell("\(ratioR * 3)")
                    cell("\(ratioR * 4)")
                }
            }
            .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.primary.opacity(0.2), lineWidth: 1))

            HStack(spacing: 8) {
                ForEach(item.options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private func cell(_ text: String, header: Bool = false) -> some View {
        Text(text)
            .font(header ? .caption.bold() : .body.bold())
            .frame(width: 54, height: 36)
            .background(header ? AppTheme.primary.opacity(0.1) : (text == "?" ? AppTheme.accent.opacity(0.2) : Color.clear))
            .overlay(Rectangle().stroke(AppTheme.primary.opacity(0.12), lineWidth: 0.5))
    }
}
```

### 4k: Wire all new views into SessionView.manipulativeArea

Add to the switch statement in `SessionView.swift`:

```swift
case .groupComparison:
    GroupComparisonInteraction(item: item, selection: $selectedChoice)
case .shapeClassification:
    ShapeClassificationInteraction(item: item, selection: $selectedChoice)
case .measureLength:
    MeasureLengthInteraction(item: item, selection: $selectedChoice)
case .divisionGroups:
    DivisionGroupsInteraction(item: item, selection: $selectedChoice)
case .areaTiling:
    AreaTilingInteraction(item: item, selection: $selectedChoice)
case .timeMoney:
    TimeMoneyInteraction(item: item, selection: $selectedChoice)
case .dataPlot:
    DataPlotInteraction(item: item, selection: $selectedChoice)
case .angleMeasure:
    AngleMeasureInteraction(item: item, selection: $selectedChoice)
case .fractionAddSub:
    FractionAddSubInteraction(item: item, selection: $selectedChoice)
case .ratioTable:
    RatioTableInteraction(item: item, selection: $selectedChoice)
```

Also add feedback text for new formats in `questFeedback`:

```swift
case .groupComparison:
    return isCorrect ? "Great comparing! You noticed which group has more." : "Good try. Count each group carefully."
case .shapeClassification:
    return isCorrect ? "Nice shape thinking! You noticed the right attributes." : "Look at the sides and corners again."
case .measureLength:
    return isCorrect ? "Good measuring! You counted the units carefully." : "Try counting the marks from the start."
case .divisionGroups:
    return isCorrect ? "Nice sharing! You split them into equal groups." : "Try dividing the total evenly."
case .areaTiling:
    return isCorrect ? "Great area thinking! You counted the squares." : "Count the rows and columns carefully."
case .timeMoney:
    return isCorrect ? "Nice time and money skills!" : "Look at the clock hands or coins again."
case .dataPlot:
    return isCorrect ? "Good data reading! You found the right value." : "Check the chart labels and heights."
case .angleMeasure:
    return isCorrect ? "Nice angle measurement!" : "Look at how wide the angle opens."
case .fractionAddSub:
    return isCorrect ? "Great fraction work! You combined the parts correctly." : "Try adding the numerators over the same denominator."
case .ratioTable:
    return isCorrect ? "Nice pattern thinking! You extended the ratio." : "Look at how the numbers grow in each row."
```

**Step: Build and commit**

```bash
git commit -m "feat: add 10 new interaction views for full K-5 curriculum"
```

---

## Task 5: Generate Question Templates (Python Script)

**Files:**
- Create: `scripts/generate_templates.py`
- Modify: `MathQuestKids/Content/content-pack-v1.json` (output)

This script generates 30-50 question templates per new unit, adding them to the existing content pack. Total: ~800 new templates.

**Template generation approach per unit:**

| Unit | Format | Generation Logic | Count |
|------|--------|-----------------|-------|
| kCompareGroups | groupComparison | left ∈ [1-10], right ∈ [1-10], answer = More/Fewer/Same | 40 |
| kShapeAttributes | shapeClassification | 6 shapes × 5 questions each | 30 |
| g1AddSub100 | addTwoDigit | a ∈ [10-50], b ∈ [10-49], answer = a+b | 40 |
| g1MeasureLength | measureLength | length ∈ [2-12] | 30 |
| g2PlaceValue1000 | teenPlaceValue | hundreds/tens/ones for 100-999 | 40 |
| g2AddSubRegroup | addTwoDigit/subTwoDigit | a+b requiring regrouping | 40 |
| g2EqualGroups | multiplicationArray | groups × per_group ≤ 25 | 30 |
| g2TimeMoney | timeMoney | hours × 12, minutes in [0,15,30,45]; cents combos | 40 |
| g2DataIntro | dataPlot | 3-4 bars with values 1-10 | 30 |
| g3DivMeaning | divisionGroups | dividend ∈ [6-36], divisor ∈ [2-6] | 40 |
| g3FractionUnit | fractionOfWhole | unit fractions: 1/2, 1/3, 1/4, 1/5, 1/6, 1/8 | 30 |
| g3FractionCompare | fractionComparison | same denominator fractions | 30 |
| g3AreaConcept | areaTiling | rows ∈ [2-8], cols ∈ [2-8] | 40 |
| g3MultiStep | additionStory | two-step: a+b then result-c | 30 |
| g4PlaceValueMillion | threeDigitComparison | 4-6 digit number comparison | 40 |
| g4MultMultiDigit | addTwoDigit | a ∈ [10-99], b ∈ [2-9], answer = a×b | 40 |
| g4DivPartialQuotients | addTwoDigit | dividend ∈ [20-144], divisor ∈ [2-12] | 40 |
| g4FractionAddSub | fractionAddSub | same denominator, num_a + num_b ≤ den | 40 |
| g4AngleMeasure | angleMeasure | degrees ∈ [30,45,60,90,120,135,150] | 30 |
| g5FractionAddSubUnlike | fractionAddSub | unlike denominators (2,3,4,5,6,8) | 40 |
| g5LinePlotsFractions | dataPlot | fraction-labeled data points | 30 |
| g5PreRatios | ratioTable | ratioLeft ∈ [1-6], ratioRight ∈ [1-6] | 30 |

The script:
1. Reads existing `content-pack-v1.json`
2. Generates templates with proper IDs, skills, formats, payloads, prompts, and spokenForms
3. Adds new UnitDefinition entries
4. Writes updated JSON back

**Step: Run the script**

```bash
python3 scripts/generate_templates.py
```

**Step: Verify template counts**

```bash
python3 -c "
import json
with open('MathQuestKids/Content/content-pack-v1.json') as f:
    data = json.load(f)
from collections import Counter
counts = Counter(t['unit'] for t in data['itemTemplates'])
for unit, count in sorted(counts.items()):
    print(f'{unit}: {count} templates')
print(f'Total: {len(data[\"itemTemplates\"])}')
"
```

Expected: Every unit has ≥ 30 templates.

**Step: Commit**

```bash
git commit -m "feat: generate 800+ question templates for 22 new units"
```

---

## Task 6: Update Lesson Plans JSON

**Files:**
- Modify: `MathQuestKids/Content/lesson-plans-k5.json`

Set `isPlayableInApp: true` and correct `linkedUnit` for all 41 lessons:

```python
# scripts/fix_lesson_plans.py
import json

with open('MathQuestKids/Content/lesson-plans-k5.json') as f:
    data = json.load(f)

for grade in data['grades']:
    for lesson in grade['lessons']:
        lesson['isPlayableInApp'] = True

with open('MathQuestKids/Content/lesson-plans-k5.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
```

The linkedUnit values already match the new UnitType case names since we used the same raw values.

**Step: Commit**

---

## Task 7: Add Hints for New Skills

**Files:**
- Modify: `MathQuestKids/Content/content-pack-v1.json` (hints array)
- Modify: `MathQuestKids/Services/DeterministicHintEngine.swift` (if needed)

Add HintTemplate entries for each new skill. Example pattern:

```json
{
  "skill": "compare_groups",
  "concrete": "Count each group one by one. Touch each dot as you count.",
  "strategy": "Compare: count Group A, then count Group B. Which number is bigger?",
  "worked": "Group A has 5. Group B has 3. 5 is more than 3, so Group A has more."
}
```

Generate hint templates for all ~22 new skills in the template generation script.

**Step: Commit**

---

## Task 8: Update SkillTrailView Grade Groups

**Files:**
- Modify: `MathQuestKids/Features/Home/SkillTrailView.swift`

Update the `gradeGroups` computed property to include all 38 units:

```swift
private var gradeGroups: [(grade: String, nodes: [TrailNode])] {
    let kUnits: Set<UnitType> = [.kCountObjects, .kComposeDecompose, .kAddWithin5, .kAddWithin10,
                                  .subtractionStories, .kCompareGroups, .kShapeAttributes, .teenPlaceValue]
    let g1Units: Set<UnitType> = [.g1AddWithin20, .g1FactFamilies, .twoDigitComparison,
                                   .g1AddSub100, .g1MeasureLength]
    let g2Units: Set<UnitType> = [.g2AddWithin100, .g2SubWithin100, .threeDigitComparison,
                                   .g2PlaceValue1000, .g2AddSubRegroup, .g2EqualGroups,
                                   .g2TimeMoney, .g2DataIntro]
    let g3Units: Set<UnitType> = [.multiplicationArrays, .g3DivMeaning, .g3FractionUnit,
                                   .g3FractionCompare, .g3AreaConcept, .g3MultiStep]
    let g4Units: Set<UnitType> = [.fractionComparison, .g4PlaceValueMillion, .g4MultMultiDigit,
                                   .g4DivPartialQuotients, .g4FractionAddSub, .g4AngleMeasure]
    let g5Units: Set<UnitType> = [.fractionOfWhole, .volumeAndDecimals,
                                   .g5FractionAddSubUnlike, .g5LinePlotsFractions, .g5PreRatios]

    return [
        ("Kindergarten", trail.nodes.filter { kUnits.contains($0.unit) }),
        ("Grade 1", trail.nodes.filter { g1Units.contains($0.unit) }),
        ("Grade 2", trail.nodes.filter { g2Units.contains($0.unit) }),
        ("Grade 3", trail.nodes.filter { g3Units.contains($0.unit) }),
        ("Grade 4", trail.nodes.filter { g4Units.contains($0.unit) }),
        ("Grade 5", trail.nodes.filter { g5Units.contains($0.unit) }),
    ].filter { !$0.1.isEmpty }
}
```

**Step: Commit**

---

## Task 9: Update AppState Placement Unlock Indices

**Files:**
- Modify: `MathQuestKids/App/AppState.swift`

Update `placementUnlockIndex` to match the new 38-unit learning path:

```swift
private func placementUnlockIndex(for grade: GradeBand?) -> Int {
    guard let grade else { return 0 }
    switch grade {
    case .kindergarten: return 3   // unlock through kAddWithin10
    case .grade1: return 7         // through g1MeasureLength
    case .grade2: return 15        // through g2DataIntro
    case .grade3: return 21        // through g3MultiStep
    case .grade4: return 27        // through g4AngleMeasure
    case .grade5: return UnitType.learningPath.count - 1
    }
}
```

**Step: Commit**

---

## Task 10: Generate ElevenLabs Audio

**Files:**
- Modify: `scripts/generate_audio.py` (already reads from content-pack-v1.json)
- Output: `MathQuestKids/Audio/questions/*.mp3`
- Output: `MathQuestKids/Audio/audio_index.json`

The existing script already reads all spokenForms from `content-pack-v1.json` and generates audio. After Task 5 adds new templates with spokenForms, just re-run:

```bash
cd /Users/nitish/VS\ Code\ Projects/tpm-portfolio/mathquest-kids
python3 scripts/generate_audio.py
```

This will:
1. Skip all existing audio files
2. Generate MP3s for new question templates
3. Update `audio_index.json` with new entries

**Estimated:** ~800 new audio files, ~15 minutes at 8 req/s

**Step: Verify**

```bash
python3 -c "
import json
with open('MathQuestKids/Audio/audio_index.json') as f:
    idx = json.load(f)
print(f'Audio index entries: {len(idx)}')
"
```

Expected: ~2,300+ entries (1,471 existing + ~800 new)

**Step: Commit**

```bash
git add MathQuestKids/Audio/ scripts/
git commit -m "feat: generate ElevenLabs audio for all new question templates"
```

---

## Task 11: Build, Test, Verify

**Step 1: Full build**

```bash
DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer" xcodebuild -project MathQuestKids.xcodeproj -scheme MathQuestKids -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```

**Step 2: Verify all units have templates**

```bash
python3 -c "
import json
with open('MathQuestKids/Content/content-pack-v1.json') as f:
    data = json.load(f)
from collections import Counter
counts = Counter(t['unit'] for t in data['itemTemplates'])
for unit, count in sorted(counts.items()):
    flag = '✓' if count >= 30 else '✗ NEEDS MORE'
    print(f'  {flag} {unit}: {count}')
"
```

**Step 3: Verify all lessons are playable**

```bash
python3 -c "
import json
with open('MathQuestKids/Content/lesson-plans-k5.json') as f:
    data = json.load(f)
for g in data['grades']:
    for l in g['lessons']:
        playable = l.get('isPlayableInApp', False)
        linked = l.get('linkedUnit', 'NONE')
        flag = '✓' if playable else '✗'
        print(f'  {flag} {l[\"id\"]}: linkedUnit={linked}')
"
```

**Step 4: Push to GitHub and Gitea**

```bash
git push origin main
git push gitea main
```

---

## Summary

| What | Count |
|------|-------|
| New UnitType cases | 22 (total: 38) |
| New ItemFormat types | 10 (total: 25) |
| New interaction views | 10 |
| New question templates | ~800 (total: ~2,300) |
| New audio files | ~800 |
| Files created | ~12 |
| Files modified | ~8 |
