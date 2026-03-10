import SwiftUI

struct DomainCoverageCard: View {
    let report: DomainReport
    @State private var expanded = false
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: { expanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.domain.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(report.skillsCovered) of \(report.skillsTotal) skills")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.18))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(report.isWeakSpot
                              ? Color.orange
                              : appState.selectedTheme.primary)
                        .frame(width: geo.size.width * report.coverageFraction, height: 8)
                }
            }
            .frame(height: 8)

            if report.isWeakSpot {
                Label("Needs more practice", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(report.perSkillStatus) { skill in
                        HStack {
                            Image(systemName: statusSymbol(skill.masteryStatus))
                                .foregroundStyle(statusColor(skill.masteryStatus))
                                .frame(width: 18)
                            Text(skill.title)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text(skill.masteryStatus.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(report.isWeakSpot ? Color.orange.opacity(0.5) : Color.gray.opacity(0.14), lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: expanded)
    }

    private func statusSymbol(_ status: MasteryStatus) -> String {
        switch status {
        case .mastered: return "checkmark.circle.fill"
        case .practicing: return "circle.dotted"
        case .learning: return "circle"
        case .reviewDue: return "arrow.clockwise.circle"
        }
    }

    private func statusColor(_ status: MasteryStatus) -> Color {
        switch status {
        case .mastered: return .green
        case .practicing: return appState.selectedTheme.primary
        case .learning: return .secondary
        case .reviewDue: return .orange
        }
    }
}
