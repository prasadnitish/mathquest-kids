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
            Text("Quest Trail")
                .kidText(.h2)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.bottom, 6)

            Text("Tap any glowing stop to jump back into your adventure.")
                .kidText(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            ForEach(trailGroups, id: \.title) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(group.title)
                            .kidText(.caption)
                            .foregroundStyle(appState.selectedTheme.primary)
                        Image(systemName: "star.fill")
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
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22)
            .stroke(appState.selectedTheme.primary.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
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
