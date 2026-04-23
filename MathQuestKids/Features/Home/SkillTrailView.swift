import SwiftUI

struct SkillTrailView: View {
    @EnvironmentObject private var appState: AppState
    let trail: SkillTrail

    private struct TrailChapter: Identifiable {
        let info: TrailChapterInfo
        let nodes: [TrailNode]

        var id: String { info.id }
        var chapterLabel: String { info.chapterLabel }
        var title: String { info.title }
        var subtitle: String { info.subtitle }
        var landmark: String { info.landmark }
    }

    private var trailGroups: [TrailChapter] {
        TrailChapterCatalog.chapters(for: appState.selectedTheme).compactMap { chapter in
            let nodes = trail.nodes.filter { chapter.units.contains($0.unit) }
            guard !nodes.isEmpty else { return nil }
            return TrailChapter(
                info: chapter,
                nodes: nodes
            )
        }
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

            mapStatusBanner
                .padding(.bottom, 16)

            ForEach(Array(trailGroups.enumerated()), id: \.element.id) { index, group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        TrailLandmarkView(
                            chapterLabel: group.chapterLabel,
                            title: group.title,
                            symbol: group.landmark,
                            theme: appState.selectedTheme,
                            isCurrent: currentChapter?.id == group.id
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(group.chapterLabel)
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

                            Text(group.subtitle)
                                .kidText(.body)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            ChapterStatusPill(
                                text: statusText(for: group),
                                theme: appState.selectedTheme,
                                isCurrent: currentChapter?.id == group.id
                            )
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 6)

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
                            TrailLaneBackground(
                                nodeCount: group.nodes.count,
                                theme: appState.selectedTheme,
                                chapterIndex: index,
                                isCurrent: currentChapter?.id == group.id
                            )
                                .padding(.horizontal, 10)
                        }
                    }
                }
                .padding(14)
                .background(chapterBackground(for: group), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(chapterBorder(for: group), lineWidth: currentChapter?.id == group.id ? 1.4 : 1)
                )
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

    private var mapStatusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: headerBadgeSymbol)
                .kidText(.h2)
                .foregroundStyle(appState.selectedTheme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(currentChapter?.title ?? "Adventure ready")
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(mapStatusText)
                    .kidText(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Text("\(completedChapterCount)/\(trailGroups.count) done")
                .kidText(.caption)
                .foregroundStyle(appState.selectedTheme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(appState.selectedTheme.primary.opacity(0.10), in: Capsule())
        }
        .padding(14)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(appState.selectedTheme.primary.opacity(0.12), lineWidth: 1)
        )
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

    private var currentChapter: TrailChapter? {
        trailGroups.first { chapter in
            chapter.nodes.contains(where: { node in
                node.isRecommended || {
                    switch node.nodeState {
                    case .available, .inProgress:
                        return true
                    default:
                        return false
                    }
                }()
            })
        } ?? trailGroups.first
    }

    private var completedChapterCount: Int {
        trailGroups.filter(isChapterComplete).count
    }

    private var mapStatusText: String {
        guard let currentChapter else {
            return "Every chapter path is ready to explore."
        }
        if isChapterComplete(currentChapter) {
            return "You cleared this chapter. A new route is glowing ahead."
        }
        let readyCount = currentChapter.nodes.filter {
            switch $0.nodeState {
            case .available, .inProgress:
                return true
            default:
                return false
            }
        }.count
        return readyCount == 1
            ? "One glowing stop is ready in this chapter."
            : "\(readyCount) glowing stops are ready in this chapter."
    }

    private var headerBadgeSymbol: String {
        switch appState.selectedTheme {
        case .starsSpace:
            return "sparkles.rectangle.stack.fill"
        case .candyland:
            return "birthday.cake.fill"
        default:
            return appState.selectedTheme.heroSymbol
        }
    }

    private func chapterBackground(for chapter: TrailChapter) -> some ShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: chapterBackgroundColors(for: chapter),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func chapterBackgroundColors(for chapter: TrailChapter) -> [Color] {
        let base: [Color]
        switch appState.selectedTheme {
        case .starsSpace:
            base = [
                Color.white.opacity(0.06),
                appState.selectedTheme.primary.opacity(0.16),
                appState.selectedTheme.accent.opacity(0.08)
            ]
        case .candyland:
            base = [
                Color.white.opacity(0.26),
                Color(red: 1.00, green: 0.86, blue: 0.92).opacity(0.34),
                Color(red: 1.00, green: 0.85, blue: 0.66).opacity(0.22)
            ]
        default:
            base = [
                Color.white.opacity(0.52),
                appState.selectedTheme.primary.opacity(0.08),
                appState.selectedTheme.accent.opacity(0.05)
            ]
        }
        if currentChapter?.id == chapter.id {
            return base.map { $0.opacity(1.0) }
        }
        return base.map { $0.opacity(0.82) }
    }

    private func chapterBorder(for chapter: TrailChapter) -> Color {
        if currentChapter?.id == chapter.id {
            return appState.selectedTheme.accent.opacity(0.42)
        }
        return appState.selectedTheme.primary.opacity(0.12)
    }

    private func statusText(for chapter: TrailChapter) -> String {
        if isChapterComplete(chapter) {
            return appState.selectedTheme == .starsSpace ? "Chapter cleared" : "Chapter complete"
        }
        let readyCount = chapter.nodes.filter {
            switch $0.nodeState {
            case .available, .inProgress:
                return true
            default:
                return false
            }
        }.count
        return readyCount == 1 ? "1 stop ready" : "\(readyCount) stops ready"
    }

    private func isChapterComplete(_ chapter: TrailChapter) -> Bool {
        chapter.nodes.allSatisfy {
            switch $0.nodeState {
            case .completed, .mastered:
                return true
            default:
                return false
            }
        }
    }
}
