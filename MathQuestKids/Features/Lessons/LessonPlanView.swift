import SwiftUI

struct LessonPlanView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedGrade: GradeBand = .kindergarten

    private var featuredLessonID: String? {
        appState.adaptivePath.recommendedLessons.first?.id
    }

    var body: some View {
        ZStack {
            ThemedBackgroundView(theme: appState.selectedTheme, mode: .gradientOnly)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp6) {
                    header

                    MascotBlock(
                        companion: appState.activeCompanion,
                        context: .lessonStart,
                        theme: appState.selectedTheme
                    )
                    .padding(.horizontal, DesignTokens.Spacing.sp4)

                    chapterSelector

                    if let plan = appState.curriculumCatalog.gradePlan(for: selectedGrade) {
                        if let featured = featuredLesson(in: plan) {
                            featuredQuestCard(featured)
                        }

                        lessonStack(plan)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            selectedGrade = appState.adaptivePath.placedGrade
        }
    }

    private var header: some View {
        AppCard(theme: appState.selectedTheme) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                Button(action: { appState.closeLessonPlans() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .kidText(.body)
                        Text("Back")
                            .kidText(.body)
                    }
                    .foregroundStyle(appState.selectedTheme.primary)
                }
                .accessibilityLabel("Go back to home")

                Text("Quest Map")
                    .kidText(.display)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Pick a path, tap play, and keep moving toward your next sticker.")
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var chapterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GradeBand.allCases) { grade in
                    let isSelected = selectedGrade == grade
                    Button {
                        withAnimation(Motion.stateChange) {
                            selectedGrade = grade
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Trail \(grade.order + 1)")
                                .kidText(.body)
                            Text(chapterTheme(for: grade))
                                .kidText(.caption)
                                .foregroundStyle(isSelected ? Color.white.opacity(0.82) : AppTheme.textSecondary)
                        }
                        .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            isSelected
                                ? AnyShapeStyle(appState.selectedTheme.primary)
                                : AnyShapeStyle(Color.white.opacity(0.72)),
                            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func featuredQuestCard(_ lesson: LessonPlanItem) -> some View {
        AppCard(theme: appState.selectedTheme) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
                Text("Picked for You")
                    .kidText(.caption)
                    .foregroundStyle(appState.selectedTheme.primary)

                Text(lesson.title)
                    .kidText(.h1)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(lesson.activityPrompt)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let linkedUnit = lesson.linkedUnit {
                    Text("Sticker waiting in \(linkedUnit.title)")
                        .kidText(.caption)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(appState.selectedTheme.accent.opacity(0.14), in: Capsule())
                }
            }
        }
    }

    private func lessonStack(_ plan: GradePlan) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(plan.lessons.enumerated()), id: \.element.id) { index, lesson in
                LessonQuestCard(
                    lesson: lesson,
                    number: index + 1,
                    isFeatured: lesson.id == featuredLessonID,
                    isUnlocked: lesson.linkedUnit.map(appState.isUnitUnlocked) ?? false,
                    theme: appState.selectedTheme,
                    onPlay: {
                        if let linked = lesson.linkedUnit {
                            appState.startSession(for: linked)
                        }
                    }
                )
            }
        }
    }

    private func featuredLesson(in plan: GradePlan) -> LessonPlanItem? {
        if let featuredLessonID {
            return plan.lessons.first(where: { $0.id == featuredLessonID })
        }
        return plan.lessons.first(where: { $0.isPlayableInApp })
    }

    private func chapterTheme(for grade: GradeBand) -> String {
        switch grade {
        case .kindergarten: return "Count & Play"
        case .grade1: return "Add & Solve"
        case .grade2: return "Build Big Numbers"
        case .grade3: return "Groups & Fractions"
        case .grade4: return "Bigger Challenges"
        case .grade5: return "Patterns & Power"
        }
    }
}

private struct LessonQuestCard: View {
    let lesson: LessonPlanItem
    let number: Int
    let isFeatured: Bool
    let isUnlocked: Bool
    let theme: VisualTheme
    let onPlay: () -> Void

    private var statusTitle: String {
        if isFeatured && isUnlocked {
            return "Best next quest"
        }
        if lesson.isPlayableInApp && isUnlocked {
            return "Ready to play"
        }
        if lesson.isPlayableInApp {
            return "Coming up soon"
        }
        return "More adventures soon"
    }

    private var buttonTitle: String {
        if lesson.isPlayableInApp && isUnlocked {
            return "Play"
        }
        if lesson.isPlayableInApp {
            return "Locked"
        }
        return "Soon"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp4) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(isFeatured ? 1.0 : 0.78))
                    Text("\(number)")
                        .kidText(.caption)
                        .foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 8) {
                    Text(statusTitle)
                        .kidText(.caption)
                        .foregroundStyle(theme.primary)

                    Text(lesson.title)
                        .kidText(.h2)
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(lesson.activityPrompt)
                        .kidText(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Text("\(lesson.estimatedMinutes) min")
                    .kidText(.caption)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.74), in: Capsule())

                if let linkedUnit = lesson.linkedUnit, lesson.isPlayableInApp {
                    Text(linkedUnit.title)
                        .kidText(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Button(buttonTitle, action: onPlay)
                    .buttonStyle(PlayButtonStyle(theme: theme))
                    .disabled(!(lesson.isPlayableInApp && isUnlocked))
                    .accessibilityLabel(buttonAccessibilityLabel)
            }
        }
        .padding(DesignTokens.Spacing.sp6)
        .background(
            isFeatured
                ? theme.cardSurface
                : Color.white.opacity(0.82),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(isFeatured ? theme.primary.opacity(0.45) : Color.white.opacity(0.7), lineWidth: isFeatured ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 6)
    }

    private var buttonAccessibilityLabel: String {
        if lesson.isPlayableInApp && isUnlocked {
            return "Play \(lesson.title)"
        }
        if lesson.isPlayableInApp {
            return "\(lesson.title) is locked for now"
        }
        return "\(lesson.title) is coming soon"
    }
}
