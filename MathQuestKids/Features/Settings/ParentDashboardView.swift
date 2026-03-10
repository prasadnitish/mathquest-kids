import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var report: ProgressReport {
        appState.progressReport
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(report.childName)
                            .font(.title.bold())
                        Text("Grade placement: \(report.gradePlacement)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        HStack(spacing: 16) {
                            Label("\(report.streakDays) day streak", systemImage: "flame.fill")
                            if let last = report.lastActiveDate {
                                Label("Last active \(last.formatted(date: .abbreviated, time: .omitted))",
                                      systemImage: "calendar")
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))

                    // Weak spots
                    if !report.weakSpots.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Needs more practice", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.orange)
                            ForEach(report.weakSpots) { domain in
                                DomainCoverageCard(report: domain)
                            }
                        }
                    }

                    // Domain coverage
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills by Domain")
                            .font(.headline)
                        ForEach(report.domainReports) { domain in
                            DomainCoverageCard(report: domain)
                        }
                    }

                    // Recent activity
                    if !report.recentActivity.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Sessions")
                                .font(.headline)
                            ForEach(report.recentActivity) { activity in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activity.unitTitle)
                                            .font(.subheadline.bold())
                                        Text(activity.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(activity.correctItems)/\(activity.totalItems) correct")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green.opacity(0.15), in: Capsule())
                                }
                                .padding(10)
                                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    // Standards note
                    Text("Curriculum aligned to Washington State K–2 Math Learning Standards (CCSS-based)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(20)
            }
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
}
