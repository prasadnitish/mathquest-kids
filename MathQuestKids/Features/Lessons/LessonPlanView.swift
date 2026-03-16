import SwiftUI

struct LessonPlanView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedGrade: GradeBand = .kindergarten
    @State private var expandedStandards: Set<String> = []

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    gradeSelector

                    if appState.adaptivePath.hasRecommendations {
                        adaptiveCard
                    }

                    if let plan = appState.curriculumCatalog.gradePlan(for: selectedGrade) {
                        overviewSection(plan)
                        lessonList(plan)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            selectedGrade = appState.adaptivePath.placedGrade
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { appState.closeLessonPlans() }) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Back")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(appState.selectedTheme.primary)
            }
            .accessibilityLabel("Go back to home")

            VStack(alignment: .leading, spacing: 4) {
                Text("Lesson Roadmap")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Standards-aligned curriculum · K through 5")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Grade Selector

    private var gradeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(GradeBand.allCases) { grade in
                    let isSelected = selectedGrade == grade
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGrade = grade
                        }
                    } label: {
                        Text(grade.shortLabel)
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                            .background(
                                isSelected
                                    ? AnyShapeStyle(appState.selectedTheme.primary)
                                    : AnyShapeStyle(AppTheme.card),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected ? Color.clear : AppTheme.textSecondary.opacity(0.15),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Adaptive Placement

    private var adaptiveCard: some View {
        HStack(spacing: 14) {
            // Confidence ring
            ZStack {
                Circle()
                    .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: appState.adaptivePath.confidence)
                    .stroke(appState.selectedTheme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(appState.adaptivePath.confidence * 100))%")
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(appState.selectedTheme.primary)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("Adaptive Placement")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Placed at **\(appState.adaptivePath.placedGrade.title)** based on diagnostic results")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(appState.selectedTheme.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(appState.selectedTheme.primary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Overview

    private func overviewSection(_ plan: GradePlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(plan.overview)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(plan.bigIdeas, id: \.self) { idea in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(appState.selectedTheme.primary.opacity(0.7))
                        .padding(.top, 2)
                    Text(idea)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }

    // MARK: - Lesson List

    private func lessonList(_ plan: GradePlan) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(plan.lessons.enumerated()), id: \.element.id) { index, lesson in
                lessonRow(lesson, number: index + 1, isLast: index == plan.lessons.count - 1)
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }

    private func lessonRow(_ lesson: LessonPlanItem, number: Int, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                // Left: domain color bar + number
                VStack(spacing: 6) {
                    Text("\(number)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(lesson.domain.accentColor.opacity(0.85), in: Circle())
                }
                .frame(width: 26)
                .padding(.top, 2)

                // Middle: content
                VStack(alignment: .leading, spacing: 6) {
                    // Title row
                    HStack(alignment: .firstTextBaseline) {
                        Text(lesson.title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Text("\(lesson.estimatedMinutes) min")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.textSecondary.opacity(0.08), in: Capsule())
                    }

                    // Domain tag
                    Text(lesson.domain.shortTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(lesson.domain.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(lesson.domain.accentColor.opacity(0.10), in: Capsule())

                    // Objective
                    Text(lesson.objective)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Pedagogy pills
                    FlowLayout(spacing: 6) {
                        ForEach(lesson.strategies) { strategy in
                            Text(strategy.title)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundStyle(AppTheme.textSecondary)
                                .background(AppTheme.textSecondary.opacity(0.06), in: Capsule())
                        }
                    }

                    // Expandable standards
                    if !lesson.standards.isEmpty {
                        let isExpanded = expandedStandards.contains(lesson.id)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isExpanded {
                                    expandedStandards.remove(lesson.id)
                                } else {
                                    expandedStandards.insert(lesson.id)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Standards")
                                    .font(.caption2.weight(.medium))
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            }
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)

                        if isExpanded {
                            Text(lesson.standards.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // Play button
                    if lesson.isPlayableInApp, let linked = lesson.linkedUnit {
                        let unlocked = appState.isUnitUnlocked(linked)
                        Button {
                            appState.startSession(for: linked)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: unlocked ? "play.fill" : "lock.fill")
                                    .font(.caption2)
                                Text(unlocked ? "Play" : "Locked")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundStyle(unlocked ? .white : AppTheme.textSecondary)
                            .background(
                                unlocked
                                    ? AnyShapeStyle(appState.selectedTheme.primary)
                                    : AnyShapeStyle(AppTheme.textSecondary.opacity(0.10)),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!unlocked)
                        .accessibilityLabel(unlocked ? "Play \(lesson.title)" : "\(lesson.title) is locked")
                        .padding(.top, 2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Divider between rows
            if !isLast {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}

// MARK: - Flow Layout for wrapping pills

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
