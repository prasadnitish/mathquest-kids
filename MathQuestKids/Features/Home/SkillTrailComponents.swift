import SwiftUI

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

struct TrailLaneBackground: View {
    let nodeCount: Int
    let theme: VisualTheme
    let chapterIndex: Int
    let isCurrent: Bool

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
                        .fill(theme.accent.opacity(index.isMultiple(of: 2) ? 0.32 : 0.18))
                        .frame(width: isCurrent ? 18 : 16, height: isCurrent ? 18 : 16)
                        .blur(radius: isCurrent ? 10 : 8)
                        .position(point)
                }

                if theme == .starsSpace {
                    ForEach(Array(starPositions(in: proxy.size).enumerated()), id: \.offset) { _, point in
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.34))
                            .position(point)
                    }
                } else if theme == .candyland {
                    ForEach(Array(candyPositions(in: proxy.size).enumerated()), id: \.offset) { _, point in
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

                chapterLandmark(in: proxy.size)
            }
        }
        .frame(height: 84)
        .allowsHitTesting(false)
    }

    private var laneGradient: LinearGradient {
        if theme == .candyland {
            return LinearGradient(
                colors: [
                    theme.primary.opacity(isCurrent ? 0.68 : 0.52),
                    Color.white.opacity(0.92),
                    theme.accent.opacity(isCurrent ? 0.88 : 0.74),
                    theme.primary.opacity(isCurrent ? 0.68 : 0.52)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: [
                theme.primary.opacity(isCurrent ? 0.48 : 0.35),
                theme.accent.opacity(isCurrent ? 0.82 : 0.65),
                theme.primary.opacity(isCurrent ? 0.48 : 0.35)
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

    @ViewBuilder
    private func chapterLandmark(in size: CGSize) -> some View {
        if theme == .starsSpace {
            Image(systemName: chapterIndex.isMultiple(of: 2) ? "sparkles" : "moon.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(theme.accent.opacity(isCurrent ? 0.88 : 0.58))
                .position(x: size.width * 0.94, y: 18)
        } else if theme == .candyland {
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .fill(theme.primary.opacity(0.65))
                        .frame(width: 8, height: 8)
                )
                .position(x: size.width * 0.92, y: 18)
        }
    }
}

struct TrailLandmarkView: View {
    let chapterLabel: String
    let title: String
    let symbol: String
    let theme: VisualTheme
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: panelColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 68, height: 78)

                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .kidText(.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 78)
                .lineLimit(2)
        }
        .overlay(alignment: .top) {
            if isCurrent {
                Text("Now")
                    .kidText(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(theme.primary, in: Capsule())
                    .offset(y: -10)
            }
        }
    }

    private var panelColors: [Color] {
        switch theme {
        case .starsSpace:
            return [theme.primary.opacity(0.92), theme.accent.opacity(0.26)]
        case .candyland:
            return [Color.white.opacity(0.88), theme.accent.opacity(0.48), theme.primary.opacity(0.30)]
        default:
            return [theme.primary.opacity(0.24), theme.accent.opacity(0.16)]
        }
    }

    private var iconColor: Color {
        switch theme {
        case .starsSpace:
            return .white
        case .candyland:
            return theme.primary
        default:
            return AppTheme.textPrimary
        }
    }
}

struct ChapterStatusPill: View {
    let text: String
    let theme: VisualTheme
    let isCurrent: Bool

    var body: some View {
        Text(text)
            .kidText(.caption)
            .foregroundStyle(isCurrent ? theme.primary : AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isCurrent ? theme.accent.opacity(0.18) : Color.white.opacity(0.50),
                in: Capsule()
            )
    }
}
