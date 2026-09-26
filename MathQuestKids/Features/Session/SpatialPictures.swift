import SwiftUI

/// Pictures for the spatial question formats, drawn from each item's payload: the figure
/// above the choices, and a picture on each answer choice. Without them, choices such as
/// "A" or "B" referred to pictures that were never shown.
enum SpatialPictures {
    /// The question's figure, or nil when the format has none of its own.
    static func figure(for item: PracticeItem, theme: VisualTheme) -> AnyView? {
        let payload = item.payload
        switch item.format {
        case .rotateToMatch:
            guard let shape = payload.shape else { return nil }
            return AnyView(RotationCue(shape: shape, color: SpatialPalette.color(payload.color), degrees: payload.rotationDegrees ?? 0))
        case .symmetryMirror:
            guard let object = payload.object else { return nil }
            return AnyView(MirrorPicture(object: object, vertical: payload.axis != "horizontal", candidate: nil, size: 120))
        case .positionWords:
            guard let objects = payload.objects, let grid = payload.gridSize else { return nil }
            let placements = objects.compactMap { object in
                object.name.map { ObjectPlacement(name: $0, point: SpatialGridPoint(x: object.x, y: object.y)) }
            }
            return AnyView(ObjectGrid(grid: grid, placements: placements, highlight: payload.anchor, theme: theme))
        case .gridPath:
            guard let grid = payload.gridSize, let start = payload.start, let startPoint = payload.startPosition else { return nil }
            return AnyView(ObjectGrid(grid: grid, placements: gridPathPlacements(item: item, start: start, startPoint: startPoint, grid: grid), highlight: start, theme: theme))
        case .buildShape:
            guard let target = payload.targetShape else { return nil }
            return AnyView(TargetOutline(shape: target, theme: theme))
        case .netPreview:
            return AnyView(SolidPicture(name: payload.targetSolid ?? "cube", size: 96))
        default:
            return nil
        }
    }

    /// A picture for one answer choice, or nil when the choice is plain text.
    static func choice(_ option: String, for item: PracticeItem) -> AnyView? {
        let payload = item.payload
        switch item.format {
        case .rotateToMatch:
            guard let spec = payload.options?.first(where: { $0.label == option }) else { return nil }
            return AnyView(SpatialShapePicture(
                shape: spec.shape ?? payload.shape ?? "triangle",
                color: SpatialPalette.color(payload.color),
                rotation: spec.rotation ?? 0,
                mirrored: spec.mirrored ?? false,
                size: 64
            ))
        case .symmetryMirror:
            guard let object = payload.object, let options = payload.options,
                  let spec = options.first(where: { $0.label == option }) else { return nil }
            let candidate: MirrorPicture.Candidate
            if spec.mirrorsCorrectly == true {
                candidate = .correct
            } else {
                // Each wrong choice shows a different mistake.
                let mistakes: [MirrorPicture.Candidate] = [.unflipped, .turned, .otherObject]
                let wrongIndex = options.filter { $0.mirrorsCorrectly != true }.firstIndex(where: { $0.label == option }) ?? 0
                candidate = mistakes[wrongIndex % mistakes.count]
            }
            return AnyView(MirrorPicture(object: object, vertical: payload.axis != "horizontal", candidate: candidate, size: 64))
        case .netPreview:
            guard let spec = payload.options?.first(where: { $0.label == option }) else { return nil }
            return AnyView(NetPicture(cells: NetLayouts.cells(pattern: spec.pattern ?? "", folds: spec.foldsToCube ?? false), size: 64))
        case .positionWords, .gridPath:
            return AnyView(Text(SpatialPalette.emoji(option)).font(.system(size: 34)))
        case .buildShape:
            return AnyView(PiecesPicture(pieces: ShapePieces.parse(option)))
        case .solidAttributes:
            return AnyView(SolidPicture(name: option, size: 48))
        default:
            return nil
        }
    }

    /// Where each object sits on a grid-path question. The payload only places the start and
    /// the answer, so the other choices go where common mistakes would land: up and down
    /// swapped, left and right swapped, the two moves swapped, or one move forgotten.
    private static func gridPathPlacements(item: PracticeItem, start: String, startPoint: SpatialGridPoint, grid: SpatialGridSize) -> [ObjectPlacement] {
        var placements = [ObjectPlacement(name: start, point: startPoint)]
        func isFree(_ point: SpatialGridPoint) -> Bool {
            point.x >= 0 && point.y >= 0 && point.x < grid.columns && point.y < grid.rows
                && !placements.contains { $0.point == point }
        }

        let answer = item.payload.targetObject ?? item.answer
        if let target = item.payload.targetPosition, isFree(target) {
            placements.append(ObjectPlacement(name: answer, point: target))
        }

        let s = startPoint
        let d = item.payload.delta ?? SpatialGridPoint(x: 0, y: 0)
        var spots = [
            SpatialGridPoint(x: s.x + d.x, y: s.y - d.y),
            SpatialGridPoint(x: s.x - d.x, y: s.y + d.y),
            SpatialGridPoint(x: s.x + d.y, y: s.y + d.x),
            SpatialGridPoint(x: s.x - d.x, y: s.y - d.y),
            SpatialGridPoint(x: s.x + d.x, y: s.y),
            SpatialGridPoint(x: s.x, y: s.y + d.y),
        ]
        for y in 0..<grid.rows {
            for x in 0..<grid.columns {
                spots.append(SpatialGridPoint(x: x, y: y))
            }
        }
        for name in item.options where name != answer && name != start {
            if let spot = spots.first(where: isFree) {
                placements.append(ObjectPlacement(name: name, point: spot))
            }
        }
        return placements
    }
}

// MARK: - Palette

enum SpatialPalette {
    static func color(_ name: String?) -> Color {
        switch name {
        case "red": return Color(red: 0.90, green: 0.26, blue: 0.27)
        case "blue": return Color(red: 0.22, green: 0.47, blue: 0.93)
        case "green": return Color(red: 0.20, green: 0.66, blue: 0.36)
        case "yellow": return Color(red: 0.96, green: 0.75, blue: 0.10)
        case "purple": return Color(red: 0.55, green: 0.33, blue: 0.85)
        case "orange": return Color(red: 0.97, green: 0.52, blue: 0.14)
        case "pink": return Color(red: 0.93, green: 0.40, blue: 0.66)
        case "teal": return Color(red: 0.10, green: 0.62, blue: 0.64)
        default: return Color(red: 0.22, green: 0.47, blue: 0.93)
        }
    }

    static func emoji(_ name: String) -> String {
        switch name {
        case "rocket", "rocket badge": return "🚀"
        case "key": return "🔑"
        case "shell": return "🐚"
        case "gem": return "💎"
        case "flag": return "🚩"
        case "heart": return "❤️"
        case "moon": return "🌙"
        case "flower": return "🌸"
        case "book": return "📘"
        case "coin": return "🪙"
        case "kite": return "🪁"
        case "star": return "⭐️"
        case "butterfly": return "🦋"
        case "leaf": return "🍃"
        default: return "🔷"
        }
    }
}

// MARK: - Flat shapes

/// Flat shapes drawn in a unit square. Shapes that look the same after some turns or a flip
/// (rectangles, diamonds) get an off-center dot in their picture so every choice differs.
struct SpatialShape: Shape {
    let kind: String

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        func polygon(_ points: [(CGFloat, CGFloat)]) -> Path {
            var path = Path()
            path.addLines(points.map { point($0.0, $0.1) })
            path.closeSubpath()
            return path
        }

        switch kind {
        case "rectangle":
            return polygon([(0.05, 0.25), (0.95, 0.25), (0.95, 0.75), (0.05, 0.75)])
        case "square":
            return polygon([(0.12, 0.12), (0.88, 0.12), (0.88, 0.88), (0.12, 0.88)])
        case "diamond":
            return polygon([(0.5, 0.04), (0.9, 0.5), (0.5, 0.96), (0.1, 0.5)])
        case "pentagon":
            return polygon([(0.5, 0.05), (0.95, 0.4), (0.95, 0.95), (0.05, 0.95), (0.05, 0.4)])
        case "hexagon":
            return polygon([(0.27, 0.08), (0.73, 0.08), (0.96, 0.5), (0.73, 0.92), (0.27, 0.92), (0.04, 0.5)])
        case "trapezoid":
            return polygon([(0.1, 0.25), (0.6, 0.25), (0.92, 0.8), (0.1, 0.8)])
        case "arrow":
            return polygon([(0.05, 0.4), (0.58, 0.4), (0.58, 0.18), (0.95, 0.5), (0.58, 0.82), (0.58, 0.6), (0.05, 0.6)])
        case "L shape":
            return polygon([(0.12, 0.05), (0.42, 0.05), (0.42, 0.65), (0.88, 0.65), (0.88, 0.95), (0.12, 0.95)])
        case "T shape":
            return polygon([(0.05, 0.05), (0.95, 0.05), (0.95, 0.35), (0.65, 0.35), (0.65, 0.95), (0.35, 0.95), (0.35, 0.35), (0.05, 0.35)])
        case "circle":
            return Path(ellipseIn: rect.insetBy(dx: rect.width * 0.1, dy: rect.height * 0.1))
        case "equilateral triangle":
            return polygon([(0.5, 0.08), (0.95, 0.9), (0.05, 0.9)])
        default:
            // "triangle": a right triangle with unequal legs, so turns and flips all differ.
            return polygon([(0.1, 0.9), (0.9, 0.9), (0.1, 0.15)])
        }
    }

    /// A point inside the shape and off its lines of symmetry, as fractions of its box.
    static func markerPoint(for kind: String) -> CGPoint {
        switch kind {
        case "rectangle": return CGPoint(x: 0.2, y: 0.4)
        case "diamond": return CGPoint(x: 0.35, y: 0.42)
        case "pentagon": return CGPoint(x: 0.28, y: 0.72)
        case "trapezoid": return CGPoint(x: 0.25, y: 0.45)
        case "arrow": return CGPoint(x: 0.68, y: 0.38)
        case "L shape": return CGPoint(x: 0.27, y: 0.3)
        case "T shape": return CGPoint(x: 0.18, y: 0.2)
        default: return CGPoint(x: 0.3, y: 0.7)
        }
    }
}

/// A colored shape, optionally flipped, then turned clockwise.
struct SpatialShapePicture: View {
    let shape: String
    let color: Color
    let rotation: Int
    let mirrored: Bool
    let size: CGFloat

    var body: some View {
        let inner: CGFloat = size * 0.78
        let marker = SpatialShape.markerPoint(for: shape)
        let dot: CGFloat = inner * 0.14
        let dotOffset = CGSize(width: inner * marker.x - dot / 2, height: inner * marker.y - dot / 2)
        let flip: CGFloat = mirrored ? -1 : 1
        SpatialShape(kind: shape)
            .fill(color)
            .overlay(SpatialShape(kind: shape).stroke(Color.black.opacity(0.18), lineWidth: 1.5))
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.white)
                    .frame(width: dot, height: dot)
                    .offset(dotOffset)
            }
            .frame(width: inner, height: inner)
            .scaleEffect(x: flip, y: 1)
            .rotationEffect(.degrees(Double(rotation)))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The starting shape, a turn arrow with the angle, and a spot for the answer.
private struct RotationCue: View {
    let shape: String
    let color: Color
    let degrees: Int

    var body: some View {
        HStack(spacing: 14) {
            SpatialShapePicture(shape: shape, color: color, rotation: 0, mirrored: false, size: 96)
            VStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                Text("\(degrees)°")
                    .kidText(.h2)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.textSecondary.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                .frame(width: 96, height: 96)
                .overlay(Text("?").kidText(.h1).foregroundStyle(AppTheme.textSecondary))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A \(shape) that turns \(degrees) degrees clockwise")
    }
}

// MARK: - Mirror pictures

/// Half of an object beside a dashed mirror line. As a choice, the other half is filled in:
/// the true reflection, or one of three mistakes (not flipped, turned, or a different object).
struct MirrorPicture: View {
    enum Candidate {
        case correct, unflipped, turned, otherObject
    }

    let object: String
    let vertical: Bool
    let candidate: Candidate?
    let size: CGFloat

    var body: some View {
        ZStack {
            givenHalf
                .opacity(candidate == nil ? 1 : 0.35)
            if let candidate {
                candidateHalf(candidate)
            } else {
                missingHalf
            }
            mirrorLine
        }
        .frame(width: size, height: size)
        .clipped()
        .accessibilityHidden(true)
    }

    private var givenHalf: some View {
        art(object).mask(alignment: givenSide) { halfMask }
    }

    @ViewBuilder
    private func candidateHalf(_ candidate: Candidate) -> some View {
        switch candidate {
        case .correct:
            reflected(art(object))
        case .otherObject:
            reflected(art(Self.otherObject(than: object)))
        case .unflipped:
            art(object)
                .mask(alignment: givenSide) { halfMask }
                .offset(unflippedShift)
        case .turned:
            art(object)
                .rotationEffect(.degrees(90))
                .mask(alignment: otherSide) { halfMask }
        }
    }

    /// The given half flipped across the mirror line.
    private func reflected(_ view: some View) -> some View {
        let flipX: CGFloat = vertical ? -1 : 1
        let flipY: CGFloat = vertical ? 1 : -1
        return view
            .mask(alignment: givenSide) { halfMask }
            .scaleEffect(x: flipX, y: flipY)
    }

    /// The side the given half is on: left of a vertical mirror line, above a horizontal one.
    private var givenSide: Alignment { vertical ? .leading : .top }
    private var otherSide: Alignment { vertical ? .trailing : .bottom }

    /// Moves the given half, unflipped, onto the other side of the mirror line.
    private var unflippedShift: CGSize {
        vertical ? CGSize(width: size / 2, height: 0) : CGSize(width: 0, height: size / 2)
    }

    private var halfMask: some View {
        let half: CGFloat = size / 2
        let width: CGFloat = vertical ? half : size
        let height: CGFloat = vertical ? size : half
        return Rectangle().frame(width: width, height: height)
    }

    private var missingHalf: some View {
        // Typed locals: the same math inline was too slow for the type checker.
        let half: CGFloat = size / 2
        let width: CGFloat = (vertical ? half : size) - 8
        let height: CGFloat = (vertical ? size : half) - 8
        let shift: CGSize = vertical ? CGSize(width: size / 4, height: 0) : CGSize(width: 0, height: size / 4)
        return RoundedRectangle(cornerRadius: 8)
            .stroke(AppTheme.textSecondary.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            .frame(width: width, height: height)
            .overlay(Text("?").kidText(.h2).foregroundStyle(AppTheme.textSecondary))
            .offset(shift)
    }

    private var mirrorLine: some View {
        Path { path in
            if vertical {
                path.move(to: CGPoint(x: size / 2, y: 0))
                path.addLine(to: CGPoint(x: size / 2, y: size))
            } else {
                path.move(to: CGPoint(x: 0, y: size / 2))
                path.addLine(to: CGPoint(x: size, y: size / 2))
            }
        }
        .stroke(Color.purple.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
    }

    @ViewBuilder
    private func art(_ name: String) -> some View {
        Group {
            if name == "square pattern" {
                SquarePattern()
                    .frame(width: size * 0.8, height: size * 0.8)
            } else {
                Text(SpatialPalette.emoji(name))
                    .font(.system(size: size * 0.78))
            }
        }
        .frame(width: size, height: size)
    }

    private static func otherObject(than name: String) -> String {
        let objects = ["heart", "butterfly", "star", "leaf", "rocket badge", "square pattern"]
        let index = objects.firstIndex(of: name) ?? 0
        return objects[(index + 2) % objects.count]
    }
}

/// A 4×4 tile pattern that isn't symmetric, for the "square pattern" mirror questions.
private struct SquarePattern: View {
    private let filled: Set<Int> = [0, 1, 4, 6, 9, 10, 15]

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { column in
                        Rectangle()
                            .fill(filled.contains(row * 4 + column) ? Color.orange : Color.teal.opacity(0.25))
                    }
                }
            }
        }
    }
}

// MARK: - Nets

enum NetLayouts {
    /// Squares of a net as (column, row) cells. Drawn from whether the choice folds into a
    /// cube, not only its name: a choice that doesn't fold gets a broken version of its
    /// pattern (every six-square net with a 2×2 block, a strip, or five squares can't fold).
    static func cells(pattern: String, folds: Bool) -> [(Int, Int)] {
        let cross = [(1, 0), (0, 1), (1, 1), (2, 1), (3, 1), (1, 2)]
        switch (pattern, folds) {
        case ("T net", true):
            return [(0, 0), (1, 0), (2, 0), (1, 1), (1, 2), (1, 3)]
        case ("zigzag net", true):
            return [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2), (3, 2)]
        case ("cross net", false):
            return [(0, 1), (1, 1), (2, 1), (3, 1), (1, 0), (2, 0)]
        case ("T net", false):
            return [(0, 0), (1, 0), (2, 0), (3, 0), (1, 1), (2, 1)]
        case ("zigzag net", false):
            return [(0, 0), (1, 0), (1, 1), (2, 1), (1, 2), (2, 2)]
        case ("missing-face net", _):
            return [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)]
        case ("strip net", _):
            return [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0)]
        case ("overlap net", _):
            return [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]
        default:
            return folds ? cross : [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]
        }
    }
}

struct NetPicture: View {
    let cells: [(Int, Int)]
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let columns = (cells.map { $0.0 }.max() ?? 0) + 1
            let rows = (cells.map { $0.1 }.max() ?? 0) + 1
            let cell = min(canvasSize.width / CGFloat(columns), canvasSize.height / CGFloat(rows))
            let originX = (canvasSize.width - cell * CGFloat(columns)) / 2
            let originY = (canvasSize.height - cell * CGFloat(rows)) / 2
            for (column, row) in cells {
                let rect = CGRect(x: originX + CGFloat(column) * cell, y: originY + CGFloat(row) * cell, width: cell, height: cell)
                    .insetBy(dx: 0.5, dy: 0.5)
                context.fill(Path(rect), with: .color(Color(red: 0.99, green: 0.83, blue: 0.45)))
                context.stroke(Path(rect), with: .color(Color(red: 0.55, green: 0.38, blue: 0.10)), lineWidth: 1.5)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Solids

struct SolidPicture: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let light = Color(red: 0.55, green: 0.75, blue: 0.98)
            let mid = Color(red: 0.33, green: 0.56, blue: 0.90)
            let dark = Color(red: 0.20, green: 0.38, blue: 0.72)
            let outline = GraphicsContext.Shading.color(Color.black.opacity(0.35))

            func polygon(_ points: [CGPoint]) -> Path {
                var path = Path()
                path.addLines(points)
                path.closeSubpath()
                return path
            }
            func box(width: CGFloat, height: CGFloat, depth: CGFloat) {
                let left = (s - width - depth) / 2
                let top = (s - height - depth) / 2
                let front = polygon([
                    CGPoint(x: left, y: top + depth), CGPoint(x: left + width, y: top + depth),
                    CGPoint(x: left + width, y: top + depth + height), CGPoint(x: left, y: top + depth + height),
                ])
                let lid = polygon([
                    CGPoint(x: left, y: top + depth), CGPoint(x: left + depth, y: top),
                    CGPoint(x: left + width + depth, y: top), CGPoint(x: left + width, y: top + depth),
                ])
                let side = polygon([
                    CGPoint(x: left + width, y: top + depth), CGPoint(x: left + width + depth, y: top),
                    CGPoint(x: left + width + depth, y: top + height), CGPoint(x: left + width, y: top + depth + height),
                ])
                for (face, color) in [(front, mid), (lid, light), (side, dark)] {
                    context.fill(face, with: .color(color))
                    context.stroke(face, with: outline, lineWidth: 1)
                }
            }

            switch name {
            case "cube":
                box(width: s * 0.58, height: s * 0.58, depth: s * 0.26)
            case "rectangular prism":
                box(width: s * 0.72, height: s * 0.4, depth: s * 0.2)
            case "sphere":
                let rect = CGRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8)
                context.fill(Path(ellipseIn: rect), with: .radialGradient(
                    Gradient(colors: [light, mid, dark]),
                    center: CGPoint(x: s * 0.38, y: s * 0.35), startRadius: 0, endRadius: s * 0.5
                ))
            case "cylinder":
                let body = CGRect(x: s * 0.22, y: s * 0.2, width: s * 0.56, height: s * 0.6)
                let top = CGRect(x: body.minX, y: body.minY - s * 0.1, width: body.width, height: s * 0.2)
                let bottom = CGRect(x: body.minX, y: body.maxY - s * 0.1, width: body.width, height: s * 0.2)
                context.fill(Path(ellipseIn: bottom), with: .color(mid))
                context.fill(Path(body), with: .linearGradient(
                    Gradient(colors: [mid, light, dark]),
                    startPoint: CGPoint(x: body.minX, y: 0), endPoint: CGPoint(x: body.maxX, y: 0)
                ))
                context.fill(Path(ellipseIn: top), with: .color(light))
                context.stroke(Path(ellipseIn: top), with: outline, lineWidth: 1)
            case "cone":
                let base = CGRect(x: s * 0.2, y: s * 0.72, width: s * 0.6, height: s * 0.18)
                context.fill(Path(ellipseIn: base), with: .color(dark))
                let side = polygon([CGPoint(x: s * 0.5, y: s * 0.08), CGPoint(x: base.maxX, y: base.midY), CGPoint(x: base.minX, y: base.midY)])
                context.fill(side, with: .linearGradient(
                    Gradient(colors: [mid, light, dark]),
                    startPoint: CGPoint(x: base.minX, y: 0), endPoint: CGPoint(x: base.maxX, y: 0)
                ))
            case "pyramid":
                let apex = CGPoint(x: s * 0.5, y: s * 0.1)
                let frontLeft = CGPoint(x: s * 0.14, y: s * 0.86)
                let frontRight = CGPoint(x: s * 0.66, y: s * 0.86)
                let backRight = CGPoint(x: s * 0.88, y: s * 0.7)
                for (face, color) in [(polygon([apex, frontLeft, frontRight]), mid), (polygon([apex, frontRight, backRight]), dark)] {
                    context.fill(face, with: .color(color))
                    context.stroke(face, with: outline, lineWidth: 1)
                }
            default:
                break
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Grids with objects

struct ObjectPlacement {
    let name: String
    let point: SpatialGridPoint
}

/// A grid with an emoji object in some cells; the highlighted object (the anchor or the
/// starting point) gets a ring.
private struct ObjectGrid: View {
    let grid: SpatialGridSize
    let placements: [ObjectPlacement]
    let highlight: String?
    let theme: VisualTheme

    var body: some View {
        let columns = max(grid.columns, 1)
        let rows = max(grid.rows, 1)
        VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<columns, id: \.self) { column in
                        cell(column: column, row: row)
                    }
                }
            }
        }
        .padding(6)
        .background(theme.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .aspectRatio(CGFloat(columns) / CGFloat(rows), contentMode: .fit)
        .frame(maxWidth: 380)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(placements.map(\.name).joined(separator: ", "))
    }

    private func cell(column: Int, row: Int) -> some View {
        let placement = placements.first { $0.point.x == column && $0.point.y == row }
        let isHighlighted = placement != nil && placement?.name == highlight
        return RoundedRectangle(cornerRadius: 6)
            .fill(Color.white.opacity(0.85))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.primary.opacity(0.14), lineWidth: 1))
            .overlay {
                if let placement {
                    Text(SpatialPalette.emoji(placement.name))
                        .font(.system(size: 30))
                        .minimumScaleFactor(0.4)
                        .padding(3)
                }
            }
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 6).stroke(theme.accent, lineWidth: 3)
                }
            }
            .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Building shapes

/// The shape to build, as a dashed outline.
private struct TargetOutline: View {
    let shape: String
    let theme: VisualTheme

    var body: some View {
        let kind = shape == "larger triangle" ? "equilateral triangle" : shape
        SpatialShape(kind: kind)
            .fill(theme.primary.opacity(0.08))
            .overlay(SpatialShape(kind: kind).stroke(theme.primary.opacity(0.7), style: StrokeStyle(lineWidth: 3, dash: [8, 6])))
            .frame(width: 120, height: 96)
            .accessibilityHidden(true)
    }
}

enum ShapePieces {
    /// "two squares" → ["square", "square"]; "one triangle and one circle" → ["triangle", "circle"].
    static func parse(_ text: String) -> [String] {
        let counts = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6]
        var pieces: [String] = []
        for part in text.components(separatedBy: " and ") {
            let words = part.split(separator: " ").map(String.init)
            guard let last = words.last else { continue }
            let count = words.first.flatMap { counts[$0] } ?? 1
            var noun = last.hasSuffix("s") ? String(last.dropLast()) : last
            if noun == "triangle" && words.contains("equal") && !words.contains("right") {
                noun = "equilateral triangle"
            }
            pieces += Array(repeating: noun, count: count)
        }
        return pieces
    }
}

private struct PiecesPicture: View {
    let pieces: [String]
    private let colors: [Color] = [.orange, .teal, .pink, .purple, .green, .blue]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(pieces.prefix(6).enumerated()), id: \.offset) { index, piece in
                SpatialShape(kind: piece)
                    .fill(colors[index % colors.count].opacity(0.85))
                    .frame(width: 22, height: 22)
            }
        }
        .accessibilityHidden(true)
    }
}
