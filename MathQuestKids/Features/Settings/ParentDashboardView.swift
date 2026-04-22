import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var report: ProgressReport {
        appState.progressReport
    }

    // MARK: - Computed helpers

    private var totalSkillsMastered: Int {
        report.domainReports.reduce(0) { $0 + $1.skillsCovered }
    }

    private var totalSkills: Int {
        report.domainReports.reduce(0) { $0 + $1.skillsTotal }
    }

    private var overallAccuracy: Double {
        let reports = report.domainReports.filter { $0.skillsCovered > 0 }
        guard !reports.isEmpty else { return 0 }
        return reports.reduce(0.0) { $0 + $1.averageAccuracy } / Double(reports.count)
    }

    private var totalSessions: Int {
        appState.dashboard.completedSessions
    }

    private var skillsText: String {
        "\(totalSkillsMastered)/\(totalSkills)"
    }

    private var accuracyText: String {
        overallAccuracy > 0 ? "\(Int(overallAccuracy * 100))%" : "—"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DesignTokens.parentSlate.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sp6) {
                    headerBar
                    statGrid
                    if !report.weakSpots.isEmpty {
                        weakSpotsSection
                    }
                    domainSection
                    if !report.recentActivity.isEmpty {
                        recentSessionsSection
                    }
                    standardsFooter
                }
                .padding(DesignTokens.Spacing.sp6)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: DesignTokens.Spacing.sp3) {
                Text("PARENT VIEW")
                    .parentText(.section)
                    .textCase(.uppercase)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        DesignTokens.parentCard,
                        in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    )
                    .foregroundStyle(DesignTokens.parentMuted)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Exit")
                        .parentText(.data)
                        .foregroundStyle(DesignTokens.parentMuted)
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    headerPill(systemName: "person.fill", text: report.childName)
                    headerPill(systemName: "map.fill", text: report.gradePlacement)
                    headerPill(systemName: "lock.fill", text: "Local-only data")
                }

                VStack(alignment: .leading, spacing: 8) {
                    headerPill(systemName: "person.fill", text: report.childName)
                    headerPill(systemName: "map.fill", text: report.gradePlacement)
                    headerPill(systemName: "lock.fill", text: "Local-only data")
                }
            }
        }
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ParentStat(value: skillsText, label: "Skills")
            ParentStat(value: accuracyText, label: "Accuracy")
            ParentStat(value: "\(totalSessions)", label: "Sessions")
            ParentStat(
                value: "\(report.streakDays)",
                label: "Day Streak",
                prefix: "🔥",
                tint: DesignTokens.streakWarning
            )
        }
    }

    // MARK: - Weak Spots Section

    private var weakSpotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            parentSectionHeader(title: "NEEDS ATTENTION", icon: "exclamationmark.triangle.fill", iconColor: .orange)
            ForEach(report.weakSpots) { domain in
                DomainCoverageCard(report: domain)
            }
        }
    }

    // MARK: - Domain Coverage Section

    private var domainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            parentSectionHeader(title: "SKILLS BY DOMAIN", icon: "square.stack.3d.up.fill", iconColor: DesignTokens.parentMuted)
            ForEach(report.domainReports) { domain in
                DomainCoverageCard(report: domain)
            }
        }
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            parentSectionHeader(title: "RECENT SESSIONS", icon: "clock.fill", iconColor: DesignTokens.parentMuted)
            VStack(spacing: 0) {
                ForEach(Array(report.recentActivity.enumerated()), id: \.element.id) { index, activity in
                    sessionRow(activity: activity)
                    if index < report.recentActivity.count - 1 {
                        Divider()
                            .background(DesignTokens.parentCard)
                            .padding(.leading, 44)
                    }
                }
            }
            .background(
                DesignTokens.parentCard,
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
            )
        }
    }

    private func sessionRow(activity: WeeklyActivity) -> some View {
        let accuracy = activity.totalItems > 0
            ? Double(activity.correctItems) / Double(activity.totalItems)
            : 0

        return HStack(spacing: 12) {
            // Accuracy ring
            ZStack {
                Circle()
                    .stroke(DesignTokens.parentMuted.opacity(0.25), lineWidth: 3)
                    .frame(width: 32, height: 32)
                Circle()
                    .trim(from: 0, to: accuracy)
                    .stroke(
                        accuracyColor(accuracy),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                Text("\(activity.correctItems)")
                    .font(.custom("DMSans-Bold", size: 10))
                    .foregroundStyle(accuracyColor(accuracy))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.unitTitle)
                    .parentText(.data)
                    .foregroundStyle(.white)
                Text(activity.date.formatted(date: .abbreviated, time: .omitted))
                    .parentText(.caption)
                    .foregroundStyle(DesignTokens.parentMuted)
            }

            Spacer()

            Text("\(activity.correctItems)/\(activity.totalItems)")
                .parentText(.data)
                .foregroundStyle(accuracyColor(accuracy))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(accuracyColor(accuracy).opacity(0.15), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Section Header

    private func parentSectionHeader(title: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(title)
                .parentText(.section)
                .foregroundStyle(DesignTokens.parentMuted)
        }
        .padding(.bottom, 2)
    }

    // MARK: - Standards Footer

    private var standardsFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(DesignTokens.parentMuted.opacity(0.7))
            Text("Curriculum aligned to Common Core State Standards (CCSS)")
                .parentText(.caption)
                .foregroundStyle(DesignTokens.parentMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.5 { return .orange }
        return DesignTokens.incorrect
    }

    private func headerPill(systemName: String, text: String) -> some View {
        Label(text, systemImage: systemName)
            .parentText(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                DesignTokens.parentCard,
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
            )
    }
}

// MARK: - ParentStat Tile

private struct ParentStat: View {
    let value: String
    let label: String
    var prefix: String = ""
    var tint: Color = .white

    var body: some View {
        VStack(spacing: 2) {
            if prefix.isEmpty {
                Text(value)
                    .parentText(.title)
                    .foregroundStyle(tint)
            } else {
                Text("\(prefix) \(value)")
                    .parentText(.title)
                    .foregroundStyle(tint)
            }
            Text(label)
                .parentText(.caption)
                .foregroundStyle(DesignTokens.parentMuted)
        }
        .padding(DesignTokens.Spacing.sp3)
        .frame(maxWidth: .infinity)
        .background(
            DesignTokens.parentCard,
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(prefix.isEmpty ? value : "\(prefix) \(value)")")
    }
}
