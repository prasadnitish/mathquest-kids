import SwiftUI

struct LessonPlanView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedGrade: GradeBand = .kindergarten

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if appState.adaptivePath.hasRecommendations {
                    adaptiveCard
                }

                gradeSelector

                if let plan = appState.curriculumCatalog.gradePlan(for: selectedGrade) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(plan.overview)
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)

                        ForEach(plan.bigIdeas, id: \.self) { idea in
                            Label(idea, systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))

                    ForEach(plan.lessons) { lesson in
                        lessonCard(lesson)
                    }
                }
            }
            .padding(.horizontal, sizeClass == .compact ? 16 : 24)
            .padding(.top, sizeClass == .compact ? 64 : 84)
            .padding(.bottom, 32)
        }
        .onAppear {
            selectedGrade = appState.adaptivePath.placedGrade
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { appState.closeLessonPlans() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Back")
                        .font(.body.weight(.semibold))
                }
            }
            .accessibilityLabel("Go back to home")

            VStack(alignment: .leading, spacing: 6) {
                Text("K-5 Lesson Roadmap")
                    .font(.system(size: AppTheme.scaled(34, compact: sizeClass == .compact), weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("US standards aligned with blended pedagogy: Singapore-style CPA/bar models, RSM-style reasoning, plus spiral review and math talks.")
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.86))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
        }
    }

    private var adaptiveCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adaptive Placement")
                .font(.title3.bold())
            Text("Current level: \(appState.adaptivePath.placedGrade.title)  ·  Confidence: \(Int(appState.adaptivePath.confidence * 100))%")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appState.adaptivePath.pedagogyHighlights) { strategy in
                        Text(strategy.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(appState.selectedTheme.primary.opacity(0.16), in: Capsule())
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private var gradeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GradeBand.allCases) { grade in
                    Button {
                        selectedGrade = grade
                    } label: {
                        let isSelected = selectedGrade == grade
                        Text(grade.title)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? appState.selectedTheme.primary.opacity(0.22) : Color.white.opacity(0.88),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? appState.selectedTheme.primary.opacity(0.52) : Color.clear, lineWidth: 1)
                            )
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 4)
        }
    }

    private func lessonCard(_ lesson: LessonPlanItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(lesson.title)
                    .font(.title3.bold())
                Spacer()
                Text("\(lesson.estimatedMinutes)m")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(appState.selectedTheme.accent.opacity(0.22), in: Capsule())
            }

            Text(lesson.domain.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(lesson.objective)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Standards: \(lesson.standards.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Class move: \(lesson.activityPrompt)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lesson.strategies) { strategy in
                        Text(strategy.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9), in: Capsule())
                            .overlay(
                                Capsule().stroke(appState.selectedTheme.primary.opacity(0.25), lineWidth: 1)
                            )
                    }
                }
            }

            if lesson.isPlayableInApp, let linked = lesson.linkedUnit {
                let unlocked = appState.isUnitUnlocked(linked)
                Button(unlocked ? "Play This Skill" : "Locked for Now") {
                    appState.startSession(for: linked)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!unlocked)
                .accessibilityLabel("Play \(lesson.title)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
