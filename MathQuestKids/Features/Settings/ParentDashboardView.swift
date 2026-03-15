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

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    statsRow
                    if !report.weakSpots.isEmpty {
                        weakSpotsSection
                    }
                    domainSection
                    if !report.recentActivity.isEmpty {
                        recentSessionsSection
                    }
                    standardsFooter
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress Report")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            // Avatar circle with initial
            ZStack {
                Circle()
                    .fill(appState.selectedTheme.primary.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text(String(report.childName.prefix(1)).uppercased())
                    .font(.title2.bold())
                    .foregroundStyle(appState.selectedTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(report.childName)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Grade placement: \(report.gradePlacement)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 14) {
                    Label {
                        Text("\(report.streakDays) day streak")
                    } icon: {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                    if let last = report.lastActiveDate {
                        Label {
                            Text("Active \(last.formatted(date: .abbreviated, time: .omitted))")
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(appState.selectedTheme.primary)
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(
                value: "\(totalSkillsMastered)/\(totalSkills)",
                label: "Skills",
                icon: "checkmark.circle.fill",
                iconColor: .green
            )
            statTile(
                value: overallAccuracy > 0 ? "\(Int(overallAccuracy * 100))%" : "—",
                label: "Accuracy",
                icon: "target",
                iconColor: appState.selectedTheme.primary
            )
            statTile(
                value: "\(totalSessions)",
                label: "Sessions",
                icon: "play.circle.fill",
                iconColor: .blue
            )
            statTile(
                value: "\(report.streakDays)",
                label: "Day Streak",
                icon: "flame.fill",
                iconColor: .orange
            )
        }
    }

    private func statTile(value: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Weak Spots Section

    private var weakSpotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Needs Attention",
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange
            )
            ForEach(report.weakSpots) { domain in
                DomainCoverageCard(report: domain)
            }
        }
    }

    // MARK: - Domain Coverage Section

    private var domainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Skills by Domain",
                icon: "square.stack.3d.up.fill",
                iconColor: appState.selectedTheme.primary
            )
            ForEach(report.domainReports) { domain in
                DomainCoverageCard(report: domain)
            }
        }
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Recent Sessions",
                icon: "clock.fill",
                iconColor: .blue
            )
            VStack(spacing: 0) {
                ForEach(Array(report.recentActivity.enumerated()), id: \.element.id) { index, activity in
                    sessionRow(activity: activity)
                    if index < report.recentActivity.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
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
                    .stroke(Color.gray.opacity(0.15), lineWidth: 3)
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
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(accuracyColor(accuracy))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.unitTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(activity.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Text("\(activity.correctItems)/\(activity.totalItems)")
                .font(.footnote.bold().monospacedDigit())
                .foregroundStyle(accuracyColor(accuracy))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(accuracyColor(accuracy).opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(iconColor)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.bottom, 2)
    }

    // MARK: - Standards Footer

    private var standardsFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green.opacity(0.6))
            Text("Curriculum aligned to Common Core State Standards (CCSS)")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .font(.caption)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.5 { return .orange }
        return AppTheme.error
    }
}
