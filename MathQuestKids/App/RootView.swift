import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackgroundView(theme: appState.selectedTheme)

                Group {
                    switch appState.route {
                    case .profileSetup:
                        ProfileSetupView()
                    case .diagnostic:
                        DiagnosticView()
                    case .home:
                        HomeView()
                    case .lessonPlans:
                        LessonPlanView()
                    case .session:
                        SessionView()
                    case .summary:
                        SessionSummaryView()
                    case .stickerBook:
                        StickerBookView()
                    }
                }

                if showsSettingsButton {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                appState.showParentGate()
                                showingSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape.fill")
                                    .labelStyle(.iconOnly)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(13)
                                    .background(.black.opacity(0.24), in: Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                            }
                            .accessibilityLabel("Settings")
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
        }
        .tint(appState.selectedTheme.primary)
    }

    private var showsSettingsButton: Bool {
        appState.route != .profileSetup
    }
}
