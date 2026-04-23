import SwiftUI

struct SkillTrailView: View {
    @EnvironmentObject private var appState: AppState
    let trail: SkillTrail

    private var trailGroups: [(title: String, subtitle: String, nodes: [TrailNode])] {
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
            ("Trail 1", "Count & Play", trail.nodes.filter { kUnits.contains($0.unit) }),
            ("Trail 2", "Add & Solve", trail.nodes.filter { g1Units.contains($0.unit) }),
            ("Trail 3", "Build Big Numbers", trail.nodes.filter { g2Units.contains($0.unit) }),
            ("Trail 4", "Groups & Fractions", trail.nodes.filter { g3Units.contains($0.unit) }),
            ("Trail 5", "Bigger Challenges", trail.nodes.filter { g4Units.contains($0.unit) }),
            ("Trail 6", "Patterns & Power", trail.nodes.filter { g5Units.contains($0.unit) }),
        ].filter { !$0.nodes.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(headerTitle)
                        .kidText(.h2)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(headerSubtitle)
                        .kidText(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ThemeCompanionArtworkView(
                    companion: appState.activeCompanion,
                    theme: appState.selectedTheme,
                    size: 42,
                    highlighted: true
                )
            }
            .padding(.bottom, 12)

            ForEach(trailGroups, id: \.title) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(group.title)
                            .kidText(.caption)
                            .foregroundStyle(appState.selectedTheme.primary)
                        Image(systemName: groupIconName)
                            .kidText(.caption)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appState.selectedTheme.primary.opacity(0.10),
                                in: Capsule())
                    .padding(.bottom, 4)

                    Text(group.subtitle)
                        .kidText(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(group.nodes) { node in
                                SkillTrailNodeView(node: node) {
                                    appState.startSession(for: node.unit)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .background {
                            TrailLaneBackground(nodeCount: group.nodes.count, theme: appState.selectedTheme)
                                .padding(.horizontal, 10)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .overlay {
                    if themedTrailUsesArtwork {
                        ZStack {
                            Image(appState.selectedTheme.backgroundAssetName)
                                .resizable()
                                .scaledToFill()
                            LinearGradient(
                                colors: trailCardOverlayColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .opacity(trailArtworkOpacity)
                    }
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(appState.selectedTheme.primary.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
    }

    private var headerTitle: String {
        switch appState.selectedTheme {
        case .starsSpace:
            return "Star Map"
        case .candyland:
            return "Candy Path"
        default:
            return "Quest Trail"
        }
    }

    private var headerSubtitle: String {
        if appState.selectedTheme == .starsSpace {
            return "Follow the glowing route and jump into any mission stop."
        }
        if appState.selectedTheme == .candyland {
            return "Skip along the frosting path and pop into any sweet challenge."
        }
        return "Tap any glowing stop to jump back into your adventure."
    }

    private var groupIconName: String {
        appState.selectedTheme == .candyland ? "heart.fill" : "star.fill"
    }

    private var themedTrailUsesArtwork: Bool {
        appState.selectedTheme == .starsSpace || appState.selectedTheme == .candyland
    }

    private var trailArtworkOpacity: Double {
        appState.selectedTheme == .candyland ? 0.24 : 0.30
    }

    private var trailCardOverlayColors: [Color] {
        if appState.selectedTheme == .candyland {
            return [
                Color.white.opacity(0.10),
                Color(red: 0.62, green: 0.20, blue: 0.41).opacity(0.16),
                Color(red: 0.38, green: 0.10, blue: 0.20).opacity(0.22)
            ]
        }
        return [Color.black.opacity(0.18), Color.black.opacity(0.32)]
    }
}

struct SkillTrailNodeView: View {
    @EnvironmentObject private var appState: AppState
    let node: TrailNode
    let onTap: () -> Void

    private var nodeColor: Color {
        switch node.nodeState {
        case .locked:           return Color.gray.opacity(0.35)
        case .available:        return appState.selectedTheme.primary.opacity(0.88)
        case .inProgress:       return appState.selectedTheme.primary
        case .completed:        return AppTheme.accent
        case .mastered:         return Color.yellow
        }
    }

    private var nodeSymbol: String {
        switch node.nodeState {
        case .locked:           return "lock.fill"
        case .available:        return "play.fill"
        case .inProgress:       return "pencil"
        case .completed:        return "checkmark"
        case .mastered:         return "star.fill"
        }
    }

    private var nodeIconColor: Color {
        switch node.nodeState {
        case .locked:
            return .white
        case .available, .inProgress:
            return appState.selectedTheme.onPrimaryText
        case .completed:
            return AppTheme.textPrimary
        case .mastered:
            return AppTheme.textPrimary
        }
    }

    var body: some View {
        Button(action: {
            guard node.nodeState != .locked else { return }
            onTap()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(nodeColor)
                        .frame(width: 64, height: 64)

                    if node.isRecommended && node.nodeState != .locked {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                    }

                    Image(systemName: nodeSymbol)
                        .kidText(.h2)
                        .foregroundStyle(nodeIconColor)

                    if case .inProgress(let pct) = node.nodeState {
                        Circle()
                            .trim(from: 0, to: pct)
                            .stroke(nodeIconColor.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 58, height: 58)
                            .rotationEffect(.degrees(-90))
                    }

                    if node.stickerEarned {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "star.circle.fill")
                                    .kidText(.caption)
                                    .foregroundStyle(.yellow)
                                    .background(Circle().fill(.white).padding(-2))
                            }
                            Spacer()
                        }
                        .frame(width: 64, height: 64)
                    }
                }

                Text(node.unit.title)
                    .kidText(.caption)
                    .foregroundStyle(node.nodeState == .locked ? .secondary : AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: 72)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
        .opacity(node.nodeState == .locked ? 0.5 : 1.0)
        .accessibilityLabel("\(node.unit.title): \(accessibilityStateLabel)")
    }

    private var accessibilityStateLabel: String {
        switch node.nodeState {
        case .locked: return "Locked"
        case .available: return "Available, tap to start"
        case .inProgress(let p): return "In progress, \(Int(p * 100)) percent"
        case .completed: return "Completed"
        case .mastered: return "Mastered"
        }
    }
}

private struct TrailLaneBackground: View {
    let nodeCount: Int
    let theme: VisualTheme

    var body: some View {
        GeometryReader { proxy in
            let points = lanePoints(in: proxy.size)

            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for index in 1..<points.count {
                            let previous = points[index - 1]
                            let current = points[index]
                            let midX = (previous.x + current.x) / 2
                            path.addCurve(
                                to: current,
                                control1: CGPoint(x: midX, y: previous.y),
                                control2: CGPoint(x: midX, y: current.y)
                            )
                        }
                    }
                    .stroke(laneGradient, style: laneStrokeStyle)
                }

                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(theme.accent.opacity(index.isMultiple(of: 2) ? 0.28 : 0.18))
                        .frame(width: 16, height: 16)
                        .blur(radius: 8)
                        .position(point)
                }

                if theme == .starsSpace {
                    ForEach(starPositions(in: proxy.size), id: \.self) { point in
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.34))
                            .position(point)
                    }
                } else if theme == .candyland {
                    ForEach(candyPositions(in: proxy.size), id: \.self) { point in
                        Circle()
                            .fill(Color.white.opacity(0.34))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .fill(theme.accent.opacity(0.72))
                                    .frame(width: 4, height: 4)
                            )
                            .position(point)
                    }
                }
            }
        }
        .frame(height: 84)
        .allowsHitTesting(false)
    }

    private var laneGradient: LinearGradient {
        if theme == .candyland {
            return LinearGradient(
                colors: [
                    theme.primary.opacity(0.52),
                    Color.white.opacity(0.92),
                    theme.accent.opacity(0.74),
                    theme.primary.opacity(0.52)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: [
                theme.primary.opacity(0.35),
                theme.accent.opacity(0.65),
                theme.primary.opacity(0.35)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var laneStrokeStyle: StrokeStyle {
        if theme == .candyland {
            return StrokeStyle(lineWidth: 5, lineCap: .round, dash: [6, 10])
        }
        return StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 10])
    }

    private func lanePoints(in size: CGSize) -> [CGPoint] {
        guard nodeCount > 0 else { return [] }
        let usableWidth = max(size.width - 36, 1)
        let step = nodeCount == 1 ? 0 : usableWidth / CGFloat(nodeCount - 1)

        return (0..<nodeCount).map { index in
            let wave = sin(CGFloat(index) * 0.8) * 10
            return CGPoint(
                x: 18 + CGFloat(index) * step,
                y: 42 + wave
            )
        }
    }

    private func starPositions(in size: CGSize) -> [CGPoint] {
        [
            CGPoint(x: size.width * 0.12, y: 16),
            CGPoint(x: size.width * 0.48, y: 72),
            CGPoint(x: size.width * 0.82, y: 18)
        ]
    }

    private func candyPositions(in size: CGSize) -> [CGPoint] {
        [
            CGPoint(x: size.width * 0.16, y: 20),
            CGPoint(x: size.width * 0.38, y: 66),
            CGPoint(x: size.width * 0.63, y: 18),
            CGPoint(x: size.width * 0.86, y: 62)
        ]
    }
}
