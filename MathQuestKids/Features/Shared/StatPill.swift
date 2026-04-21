import SwiftUI

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value).kidText(.h1)
            Text(label).kidText(.caption)
                .opacity(0.75)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, DesignTokens.Spacing.sp4)
        .padding(.vertical, DesignTokens.Spacing.sp3)
        .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
        )
    }
}
