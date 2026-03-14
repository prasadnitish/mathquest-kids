import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                adaptiveMission
                companionSpotlight
                SkillTrailView(trail: appState.skillTrail)
                    .environmentObject(appState)
                rewardCard
            }
            .padding(.horizontal, 24)
            .padding(.top, 84)
            .padding(.bottom, 32)
        }
        .overlay(alignment: .top) {
            if let message = appState.statusMessage {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(greeting), \(appState.profile?.displayName ?? "Explorer")")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            Text("Offline-first math adventures with adaptive K-5 learning paths.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    summaryPill(title: "Streak", value: "\(appState.dashboard.streakDays)")
                    summaryPill(title: "Sessions", value: "\(appState.dashboard.completedSessions)")
                    summaryPill(title: "Accuracy", value: "\(Int(appState.dashboard.averageAccuracy * 100))%")
                }
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        summaryPill(title: "Streak", value: "\(appState.dashboard.streakDays)")
                        summaryPill(title: "Sessions", value: "\(appState.dashboard.completedSessions)")
                    }
                    summaryPill(title: "Accuracy", value: "\(Int(appState.dashboard.averageAccuracy * 100))%")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.97), appState.selectedTheme.accent.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(appState.selectedTheme.primary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
    }

    private var adaptiveMission: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Adaptive Mission")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    if appState.adaptivePath.confidence > 0 {
                        Text("Level: \(appState.adaptivePath.placedGrade.title)  ·  Confidence: \(Int(appState.adaptivePath.confidence * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    } else {
                        Text("Take the placement quiz to personalize your path.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Spacer()

                if appState.dashboard.completedSessions > 0 {
                    Text("\(Int(appState.dashboard.averageAccuracy * 100))%")
                        .font(.title2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(appState.selectedTheme.accent.opacity(0.28), in: Capsule())
                }
            }

            if appState.adaptivePath.recommendedLessons.isEmpty {
                Text("Run the diagnostic to unlock a personalized K-5 roadmap.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                let top = appState.adaptivePath.recommendedLessons.prefix(3).map(\.title).joined(separator: "  •  ")
                Text(top)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            // Support & stretch lesson pills
            if !appState.adaptivePath.supportLessons.isEmpty || !appState.adaptivePath.stretchLessons.isEmpty {
                HStack(spacing: 6) {
                    if !appState.adaptivePath.supportLessons.isEmpty {
                        let supportTitle = appState.adaptivePath.supportLessons.first?.title ?? ""
                        Label(supportTitle, systemImage: "arrow.down.circle")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.12), in: Capsule())
                            .lineLimit(1)
                    }
                    if !appState.adaptivePath.stretchLessons.isEmpty {
                        let stretchTitle = appState.adaptivePath.stretchLessons.first?.title ?? ""
                        Label(stretchTitle, systemImage: "arrow.up.circle")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.12), in: Capsule())
                            .lineLimit(1)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appState.adaptivePath.pedagogyHighlights) { strategy in
                        Text(strategy.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(appState.selectedTheme.primary.opacity(0.10), in: Capsule())
                            .overlay(Capsule().stroke(appState.selectedTheme.primary.opacity(0.18), lineWidth: 1))
                    }
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    Button(appState.isRecommendationPersonalized ? "Start Recommended Quest" : "Start Next Quest") {
                        appState.startRecommendedSession()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("View K-5 Lesson Plan") {
                        appState.openLessonPlans()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                VStack(spacing: 8) {
                    Button(appState.isRecommendationPersonalized ? "Start Recommended Quest" : "Start Next Quest") {
                        appState.startRecommendedSession()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("View K-5 Lesson Plan") {
                        appState.openLessonPlans()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(appState.selectedTheme.primary.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    private var unitGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(UnitType.learningPath) { unit in
                UnitCardView(unit: unit) {
                    appState.startSession(for: unit)
                }
                .environmentObject(appState)
            }
        }
    }

    private var companionSpotlight: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Character Pack")
                .font(.title2.bold())

            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(appState.selectedTheme.primary.opacity(0.22))
                    Circle()
                        .stroke(appState.selectedTheme.primary.opacity(0.45), lineWidth: 1.5)
                    if !appState.activeCompanion.imageName.isEmpty {
                        Image(appState.activeCompanion.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: appState.activeCompanion.symbol)
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .frame(width: 88, height: 88)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.activeCompanion.name)
                        .font(.title3.bold())
                    Text(appState.activeCompanion.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\"\(appState.activeCompanion.tagline)\"")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(appState.availableCompanions) { companion in
                        Button {
                            appState.setCompanion(companion.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(appState.selectedTheme.primary.opacity(0.20))
                                        if !companion.imageName.isEmpty {
                                            Image(companion.imageName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 36, height: 36)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: companion.symbol)
                                                .font(.title2.bold())
                                                .foregroundStyle(AppTheme.textPrimary)
                                        }
                                    }
                                    .frame(width: 42, height: 42)

                                    Spacer(minLength: 0)
                                }

                                Text(companion.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                Text(companion.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(12)
                            .frame(width: 170, height: 120, alignment: .leading)
                            .background(
                                appState.selectedCompanionID == companion.id
                                    ? appState.selectedTheme.primary.opacity(0.22)
                                    : Color.white.opacity(0.93),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        appState.selectedCompanionID == companion.id ? appState.selectedTheme.primary : Color.black.opacity(0.08),
                                        lineWidth: appState.selectedCompanionID == companion.id ? 2 : 1
                                    )
                            )
                            .shadow(color: .black.opacity(appState.selectedCompanionID == companion.id ? 0.12 : 0.06), radius: appState.selectedCompanionID == companion.id ? 8 : 4, x: 0, y: appState.selectedCompanionID == companion.id ? 5 : 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(appState.selectedTheme.primary.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
    }

    private var rewardCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Momentum")
                .font(.title2.bold())
            Text("Streak: \(appState.dashboard.streakDays) day\(appState.dashboard.streakDays == 1 ? "" : "s")")
                .font(.body.weight(.semibold))
            Text("Sessions: \(appState.dashboard.completedSessions)  ·  Accuracy: \(Int(appState.dashboard.averageAccuracy * 100))%")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            ProgressView(value: appState.dashboard.rewardProgress)
                .tint(appState.selectedTheme.primary)
            Text("Keep a 5-day streak to unlock a bonus badge.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Button("Open Sticker Book") {
                appState.openStickerBook()
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Open Sticker Book")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(appState.selectedTheme.primary.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(appState.selectedTheme.primary.opacity(0.14), lineWidth: 1)
        )
    }
}

struct UnitCardView: View {
    @EnvironmentObject private var appState: AppState
    let unit: UnitType
    let onStart: () -> Void

    var body: some View {
        let progress = appState.dashboard.unitProgress.first(where: { $0.unit == unit })
        let unlocked = progress?.unlocked ?? (unit == .kCountObjects)
        let sessions = progress?.completedSessions ?? 0

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(unit.title)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer(minLength: 8)
                Text(unit.gradeHint)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(appState.selectedTheme.accent.opacity(0.22), in: Capsule())
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }

            Text(unit.subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Text("Sessions complete: \(sessions)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer(minLength: 8)

            Button(unlocked ? "Start" : "Locked") {
                onStart()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!unlocked)
            .accessibilityLabel("Start \(unit.title)")
        }
        .padding(16)
        .frame(minHeight: 190)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(unlocked ? 0.96 : 0.94))
                LinearGradient(
                    colors: [appState.selectedTheme.primary.opacity(0.12), Color.white.opacity(0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: appState.selectedTheme.heroSymbol)
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(appState.selectedTheme.primary.opacity(0.16))
                    }
                    Spacer()
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(unlocked ? appState.selectedTheme.primary.opacity(0.20) : Color.gray.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)
        .opacity(unlocked ? 1 : 0.88)
    }
}
