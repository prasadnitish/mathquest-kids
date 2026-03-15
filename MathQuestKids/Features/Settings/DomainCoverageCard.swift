import SwiftUI

struct DomainCoverageCard: View {
    let report: DomainReport
    @State private var expanded = false
    @EnvironmentObject private var appState: AppState

    private var progressColor: Color {
        report.isWeakSpot ? .orange : appState.selectedTheme.primary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Domain icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(progressColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: domainIcon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(progressColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.domain.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(report.skillsCovered) of \(report.skillsTotal) skills")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    if report.isWeakSpot {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: report.isWeakSpot
                                    ? [.orange, .orange.opacity(0.7)]
                                    : [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * report.coverageFraction, report.coverageFraction > 0 ? 8 : 0), height: 8)
                }
            }
            .frame(height: 8)

            // Weak spot label
            if report.isWeakSpot {
                Text("Needs more practice")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            // Expanded skill list
            if expanded {
                VStack(spacing: 0) {
                    ForEach(Array(report.perSkillStatus.enumerated()), id: \.element.id) { index, skill in
                        HStack(spacing: 10) {
                            Image(systemName: statusSymbol(skill.masteryStatus))
                                .font(.caption)
                                .foregroundStyle(statusColor(skill.masteryStatus))
                                .frame(width: 20)

                            Text(skill.title)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textPrimary)

                            Spacer()

                            Text(statusLabel(skill.masteryStatus))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(statusColor(skill.masteryStatus))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(statusColor(skill.masteryStatus).opacity(0.1), in: Capsule())
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)

                        if index < report.perSkillStatus.count - 1 {
                            Divider()
                                .padding(.leading, 34)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    report.isWeakSpot ? Color.orange.opacity(0.35) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Domain Icon

    private var domainIcon: String {
        switch report.domain {
        case .countingCardinality: return "number.circle.fill"
        case .operationsAlgebraicThinking: return "plus.forwardslash.minus"
        case .numberOperationsBaseTen: return "textformat.123"
        case .fractions: return "chart.pie.fill"
        case .measurementData: return "ruler.fill"
        case .geometry: return "triangle.fill"
        case .ratiosExpressions: return "function"
        }
    }

    // MARK: - Status Helpers

    private func statusSymbol(_ status: MasteryStatus) -> String {
        switch status {
        case .mastered: return "checkmark.circle.fill"
        case .practicing: return "circle.dashed"
        case .learning: return "circle"
        case .reviewDue: return "arrow.clockwise.circle.fill"
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

    private func statusLabel(_ status: MasteryStatus) -> String {
        switch status {
        case .mastered: return "Mastered"
        case .practicing: return "Practicing"
        case .learning: return "Not started"
        case .reviewDue: return "Review due"
        }
    }
}
