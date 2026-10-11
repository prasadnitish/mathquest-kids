import SwiftUI

// Drawing helpers for the spatial question formats.
//
// Every picture here is drawn from the question's own payload data, so what a child
// sees is exactly what scripts/verify_question_bank.py checked. Nothing here reads
// `answer`, `answerChoice`, `foldsToCube`, `mirrorsCorrectly` or `correctPieces`.

// MARK: - Colors

enum SpatialPalette {
    static func color(named name: String?, fallback: Color) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "teal": return .teal
        case "red": return .red
        default: return fallback
        }
    }
}

// MARK: - Object map (positionWords, gridPath)

enum SpatialObjectGlyph {
    static func symbol(for name: String) -> String {
        switch name.lowercased() {
        case "rocket": return "🚀"
        case "key": return "🔑"
        case "shell": return "🐚"
        case "gem": return "💎"
        case "flag": return "🚩"
        case "heart": return "❤️"
        case "star": return "⭐️"
        case "moon": return "🌙"
        case "kite": return "🪁"
        case "book": return "📖"
        case "flower": return "🌸"
        case "coin": return "🪙"
        default: return "🔷"
        }
    }
}

/// A grid map that draws every named object in its cell, with one object ringed.
struct SpatialObjectGridView: View {
    let objects: [SpatialSceneObject]
    let gridSize: SpatialGridSize
    let highlightedName: String?
    let ringLabel: String
    let theme: VisualTheme

    var body: some View {
        let columns = max(gridSize.columns, 1)
        let rows = max(gridSize.rows, 1)

        GeometryReader { proxy in
            let cellWidth = proxy.size.width / CGFloat(columns)
            let cellHeight = proxy.size.height / CGFloat(rows)
            let cellSize = min(cellWidth, cellHeight)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.primary.opacity(0.07))
                gridLines(columns: columns, rows: rows)

                ForEach(Array(objects.enumerated()), id: \.offset) { _, object in
                    objectCell(object, cellSize: cellSize)
                        .frame(width: cellWidth, height: cellHeight)
                        .position(
                            x: (CGFloat(object.x) + 0.5) * cellWidth,
                            y: (CGFloat(object.y) + 0.5) * cellHeight
                        )
                }
            }
        }
        .aspectRatio(CGFloat(columns) / CGFloat(rows), contentMode: .fit)
        .frame(maxHeight: 250)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private func objectCell(_ object: SpatialSceneObject, cellSize: CGFloat) -> some View {
        let name = object.name ?? ""
        let isHighlighted = name == highlightedName
        VStack(spacing: 0) {
            Text(SpatialObjectGlyph.symbol(for: name))
                .font(.system(size: cellSize * 0.46))
            Text(name)
                .font(.system(size: max(cellSize * 0.17, 9), weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(2)
        .background {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.accent.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(theme.accent, lineWidth: 2.5)
                    )
            }
        }
    }

    private func gridLines(columns: Int, rows: Int) -> some View {
        GeometryReader { proxy in
            Path { path in
                if columns > 1 {
                    for column in 1..<columns {
                        let x = proxy.size.width * CGFloat(column) / CGFloat(columns)
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    }
                }
                if rows > 1 {
                    for row in 1..<rows {
                        let y = proxy.size.height * CGFloat(row) / CGFloat(rows)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                }
            }
            .stroke(AppTheme.textSecondary.opacity(0.14), lineWidth: 1)
        }
    }

    private var accessibilitySummary: String {
        let names = objects.compactMap { $0.name }.joined(separator: ", ")
        return "Map with \(names). The \(highlightedName ?? "marked object") is the \(ringLabel)."
    }
}

// MARK: - Rotating shapes (rotateToMatch)

/// Outline polygons in unit coordinates. Triangle and trapezoid are right-angled so that a
/// mirrored copy is genuinely different from every rotation of the original.
struct SpatialPuzzleShape: Shape {
    let kind: String

    func path(in rect: CGRect) -> Path {
        let points = Self.unitPoints(for: kind)
        guard let first = points.first else {
            return Path(roundedRect: rect.insetBy(dx: rect.width * 0.1, dy: rect.height * 0.1), cornerRadius: 8)
        }
        var path = Path()
        path.move(to: map(first, in: rect))
        for point in points.dropFirst() {
            path.addLine(to: map(point, in: rect))
        }
        path.closeSubpath()
        return path
    }

    private func map(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height)
    }

    static func unitPoints(for kind: String) -> [CGPoint] {
        switch kind {
        case "triangle":
            return [CGPoint(x: 0.12, y: 0.88), CGPoint(x: 0.12, y: 0.12), CGPoint(x: 0.88, y: 0.88)]
        case "rectangle":
            return [CGPoint(x: 0.06, y: 0.3), CGPoint(x: 0.94, y: 0.3), CGPoint(x: 0.94, y: 0.7), CGPoint(x: 0.06, y: 0.7)]
        case "diamond":
            return [CGPoint(x: 0.5, y: 0.04), CGPoint(x: 0.8, y: 0.5), CGPoint(x: 0.5, y: 0.96), CGPoint(x: 0.2, y: 0.5)]
        case "pentagon":
            return (0..<5).map { (index: Int) -> CGPoint in
                let angle = -Double.pi / 2 + Double(index) * 2 * Double.pi / 5
                return CGPoint(x: 0.5 + 0.45 * cos(angle), y: 0.5 + 0.45 * sin(angle))
            }
        case "trapezoid":
            return [CGPoint(x: 0.1, y: 0.78), CGPoint(x: 0.1, y: 0.3), CGPoint(x: 0.55, y: 0.3), CGPoint(x: 0.92, y: 0.78)]
        case "arrow":
            return [
                CGPoint(x: 0.5, y: 0.05), CGPoint(x: 0.92, y: 0.5), CGPoint(x: 0.66, y: 0.5), CGPoint(x: 0.66, y: 0.95),
                CGPoint(x: 0.34, y: 0.95), CGPoint(x: 0.34, y: 0.5), CGPoint(x: 0.08, y: 0.5)
            ]
        case "L shape":
            return [
                CGPoint(x: 0.2, y: 0.1), CGPoint(x: 0.46, y: 0.1), CGPoint(x: 0.46, y: 0.64),
                CGPoint(x: 0.86, y: 0.64), CGPoint(x: 0.86, y: 0.9), CGPoint(x: 0.2, y: 0.9)
            ]
        case "T shape":
            return [
                CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.9, y: 0.1), CGPoint(x: 0.9, y: 0.36), CGPoint(x: 0.62, y: 0.36),
                CGPoint(x: 0.62, y: 0.9), CGPoint(x: 0.38, y: 0.9), CGPoint(x: 0.38, y: 0.36), CGPoint(x: 0.1, y: 0.36)
            ]
        default:
            return []
        }
    }
}

/// A shape turned clockwise by `rotation` degrees, optionally mirrored left-to-right first.
struct SpatialRotatedShapeView: View {
    let shapeName: String
    let rotation: Int
    let mirrored: Bool
    let color: Color

    var body: some View {
        SpatialPuzzleShape(kind: shapeName)
            .fill(color)
            .overlay(SpatialPuzzleShape(kind: shapeName).stroke(Color.black.opacity(0.25), lineWidth: 1))
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            .rotationEffect(.degrees(Double(rotation)))
    }
}

// MARK: - Cell pictures (netPreview, symmetryMirror)

/// Draws rows of '#' / '.' as filled squares. Used for cube nets and for mirror pictures.
struct SpatialCellPictureView: View {
    let rows: [String]
    var axis: String? = nil
    /// Number of columns (vertical mirror line) or rows (horizontal mirror line) before the line.
    var splitIndex: Int? = nil
    var outlineEmptySecondPart = false
    let firstColor: Color
    var secondColor: Color? = nil
    var borderColor: Color = Color.white.opacity(0.7)

    var body: some View {
        let columns = max(rows.map { $0.count }.max() ?? 1, 1)
        let rowCount = max(rows.count, 1)

        GeometryReader { proxy in
            let size = min(proxy.size.width / CGFloat(columns), proxy.size.height / CGFloat(rowCount))
            let width = size * CGFloat(columns)
            let height = size * CGFloat(rowCount)

            ZStack(alignment: .topLeading) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, character in
                        cell(character, row: rowIndex, column: columnIndex)
                            .frame(width: size, height: size)
                            .offset(x: CGFloat(columnIndex) * size, y: CGFloat(rowIndex) * size)
                    }
                }
                mirrorLine(size: size, width: width, height: height)
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private func isFirstPart(row: Int, column: Int) -> Bool {
        guard let axis = axis, let split = splitIndex else { return true }
        return axis == "vertical" ? column < split : row < split
    }

    @ViewBuilder
    private func cell(_ character: Character, row: Int, column: Int) -> some View {
        let first = isFirstPart(row: row, column: column)
        if character == "#" {
            Rectangle()
                .fill(first ? firstColor : (secondColor ?? firstColor))
                .overlay(Rectangle().stroke(borderColor, lineWidth: 0.75))
        } else if outlineEmptySecondPart && !first {
            Rectangle()
                .stroke((secondColor ?? firstColor).opacity(0.28), style: StrokeStyle(lineWidth: 0.75, dash: [2, 2]))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func mirrorLine(size: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        if let axis = axis, let split = splitIndex {
            Path { path in
                if axis == "vertical" {
                    let x = CGFloat(split) * size
                    path.move(to: CGPoint(x: x, y: -4))
                    path.addLine(to: CGPoint(x: x, y: height + 4))
                } else {
                    let y = CGFloat(split) * size
                    path.move(to: CGPoint(x: -4, y: y))
                    path.addLine(to: CGPoint(x: width + 4, y: y))
                }
            }
            .stroke(Color.red.opacity(0.75), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
        }
    }
}

/// The visible half joined to a candidate other half across the mirror line.
struct SpatialMirrorPictureView: View {
    let half: [String]
    /// nil draws the empty (to be completed) side.
    let other: [String]?
    let axis: String
    let theme: VisualTheme

    var body: some View {
        let combined = Self.combine(half: half, other: other, axis: axis)
        SpatialCellPictureView(
            rows: combined.rows,
            axis: axis,
            splitIndex: combined.split,
            outlineEmptySecondPart: other == nil,
            firstColor: theme.primary,
            secondColor: theme.accent
        )
    }

    static func combine(half: [String], other: [String]?, axis: String) -> (rows: [String], split: Int) {
        if axis == "vertical" {
            let width = half.map { $0.count }.max() ?? 0
            let blank = String(repeating: ".", count: width)
            let rows = half.enumerated().map { index, row -> String in
                let right = (other != nil && index < other!.count) ? other![index] : blank
                return row + right
            }
            return (rows, width)
        }
        let width = half.map { $0.count }.max() ?? 0
        let blankRows = half.map { _ in String(repeating: ".", count: width) }
        return (half + (other ?? blankRows), half.count)
    }
}

// MARK: - Visual answer option

/// A lettered, tappable card that shows a picture instead of text.
struct SpatialVisualOptionButton<Content: View>: View {
    let label: String
    let isSelected: Bool
    let theme: VisualTheme
    let accessibilityDescription: String
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(label)
                    .kidText(.caption)
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
                    .background(theme.primary, in: Circle())

                content()
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(isSelected ? theme.primary.opacity(0.14) : Color.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.primary : theme.primary.opacity(0.18), lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Option \(label): \(accessibilityDescription)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
