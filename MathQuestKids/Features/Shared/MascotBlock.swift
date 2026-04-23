import SwiftUI

struct MascotBlock: View {
    let companion: ThemeCompanion          // existing type from CharacterPacks.swift
    let context: MascotVoice.Context
    let theme: VisualTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false
    @State private var orbit = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sp3) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(companion.name).kidText(.caption).foregroundStyle(.secondary)
                bubble
            }
            Spacer(minLength: 0)
        }
        .onAppear {
            bob = true
            orbit = true
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(reactionAuraColor.opacity(0.18))
                .frame(width: 78, height: 78)
                .blur(radius: 12)

            Circle()
                .stroke(reactionAccent.opacity(0.34), lineWidth: reactionStyle == .celebrate ? 3 : 2)
                .frame(width: reactionStyle == .celebrate ? 68 : 62, height: reactionStyle == .celebrate ? 68 : 62)

            orbitToken

            ThemeCompanionArtworkView(
                companion: companion,
                theme: theme,
                size: 56,
                highlighted: true
            )
        }
        .frame(width: 60, height: 60)
        .scaleEffect(reactionStyle == .celebrate ? (bob ? 1.06 : 0.98) : 1.0)
        .rotationEffect(.degrees(reactionTilt))
        .offset(y: bob ? -4 : 4)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
        .animation(reduceMotion ? nil : Motion.kidBounceIdle, value: bob)
    }

    private var orbitToken: some View {
        Circle()
            .fill(Color.white.opacity(0.92))
            .frame(width: 10, height: 10)
            .overlay {
                Image(systemName: orbitSymbol)
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(reactionAccent)
            }
            .offset(x: orbit ? 19 : -19, y: orbit ? -16 : 16)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                value: orbit
            )
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reactionLabel)
                .kidText(.caption)
                .foregroundStyle(reactionAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(reactionAccent.opacity(0.10), in: Capsule())

            Text(MascotVoice.phrase(for: context, tone: companion.tone))
                .kidText(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DesignTokens.Spacing.sp4)
        .padding(.vertical, DesignTokens.Spacing.sp3)
        .background(
            LinearGradient(
                colors: bubbleColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: SpeechBubbleShape(cornerRadius: DesignTokens.Radius.md)
        )
        .overlay {
            SpeechBubbleShape(cornerRadius: DesignTokens.Radius.md)
                .stroke(reactionAccent.opacity(0.20), lineWidth: 1.5)
        }
        .shadow(color: reactionAuraColor.opacity(0.12), radius: 14, x: 0, y: 4)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 2)
    }

    private var reactionStyle: ReactionStyle {
        switch context {
        case .answerCorrect, .rewardEarned, .chapterUnlocked, .streakMilestone:
            return .celebrate
        case .answerWrong, .answerIdk:
            return .coach
        case .questionHint, .lessonStart:
            return .guide
        case .homeGreeting:
            return .welcome
        }
    }

    private var reactionLabel: String {
        switch context {
        case .homeGreeting:
            return "Adventure time"
        case .lessonStart:
            return "New chapter"
        case .questionHint:
            return "Hint buddy"
        case .answerCorrect:
            return "Cheering"
        case .answerWrong:
            return "Try again"
        case .answerIdk:
            return "Let's solve it"
        case .rewardEarned:
            return "Treasure found"
        case .chapterUnlocked:
            return "New chapter"
        case .streakMilestone:
            return "Streak shine"
        }
    }

    private var orbitSymbol: String {
        switch reactionStyle {
        case .celebrate:
            return "star.fill"
        case .coach:
            return "sparkles"
        case .guide:
            return "lightbulb.fill"
        case .welcome:
            return theme.decorativeSymbols.first ?? "sparkles"
        }
    }

    private var bubbleColors: [Color] {
        switch reactionStyle {
        case .celebrate:
            return [Color.white.opacity(0.98), reactionAccent.opacity(0.16), reactionAuraColor.opacity(0.10)]
        case .coach:
            return [Color.white.opacity(0.98), theme.primary.opacity(0.08), Color.orange.opacity(0.05)]
        case .guide:
            return [Color.white.opacity(0.98), theme.accent.opacity(0.12)]
        case .welcome:
            return [Color.white.opacity(0.98), theme.accent.opacity(0.10)]
        }
    }

    private var reactionAuraColor: Color {
        switch reactionStyle {
        case .celebrate:
            return theme.accent
        case .coach:
            return theme.primary
        case .guide:
            return theme.accent
        case .welcome:
            return theme.primary
        }
    }

    private var reactionAccent: Color {
        switch reactionStyle {
        case .celebrate:
            return theme.accent
        case .coach:
            return theme.primary
        case .guide:
            return theme.primary
        case .welcome:
            return theme.primary
        }
    }

    private var reactionTilt: Double {
        switch reactionStyle {
        case .celebrate:
            return bob ? -2 : 2
        case .coach:
            return -1
        case .guide:
            return 1
        case .welcome:
            return 0
        }
    }
}

private enum ReactionStyle {
    case welcome
    case guide
    case coach
    case celebrate
}

// Rounded rectangle with a tail pointing left toward the avatar.
private struct SpeechBubbleShape: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: cornerRadius)
        let tipY = rect.minY + 16
        var tail = Path()
        tail.move(to: CGPoint(x: rect.minX, y: tipY - 6))
        tail.addLine(to: CGPoint(x: rect.minX - 8, y: tipY))
        tail.addLine(to: CGPoint(x: rect.minX, y: tipY + 6))
        tail.closeSubpath()
        path.addPath(tail)
        return path
    }
}
