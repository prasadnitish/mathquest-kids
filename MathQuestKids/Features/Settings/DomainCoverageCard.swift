import SwiftUI

struct DomainCoverageCard: View {
    let report: DomainReport
    @State private var expanded = false

    private var progressColor: Color {
        report.isWeakSpot ? .orange : .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Domain icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(progressColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: domainIcon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(progressColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.domain.title)
                            .parentText(.data)
                            .foregroundStyle(.white)
                        Text("\(report.skillsCovered) of \(report.skillsTotal) skills")
                            .parentText(.caption)
                            .foregroundStyle(DesignTokens.parentMuted)
                    }

                    Spacer()

                    if report.isWeakSpot {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.parentMuted)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(DesignTokens.parentMuted.opacity(0.2))
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
                        .frame(
                            width: max(
                                geo.size.width * report.coverageFraction,
                                report.coverageFraction > 0 ? 8 : 0
                            ),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            // Weak spot label
            if report.isWeakSpot {
                Text("Needs more practice")
                    .parentText(.caption)
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
                                .parentText(.data)
                                .foregroundStyle(.white)

                            Spacer()

                            Text(statusLabel(skill.masteryStatus))
                                .parentText(.caption)
                                .foregroundStyle(statusColor(skill.masteryStatus))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(statusColor(skill.masteryStatus).opacity(0.15), in: Capsule())
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)

                        if index < report.perSkillStatus.count - 1 {
                            Divider()
                                .background(DesignTokens.parentMuted.opacity(0.3))
                                .padding(.leading, 34)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            DesignTokens.parentCard,
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(
                    report.isWeakSpot ? Color.orange.opacity(0.45) : Color.clear,
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
        case .practicing: return DesignTokens.parentMuted
        case .learning: return DesignTokens.parentMuted.opacity(0.6)
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
