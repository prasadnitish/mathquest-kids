import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var appState: AppState
    @State private var name = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: appState.selectedTheme.heroSymbol)
                    .font(.system(size: 64, weight: .black)) // SF Symbol decorative icon
                    .foregroundStyle(appState.selectedTheme.primary)

                Text("Sprout Math")
                    .kidText(.display)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Create a profile, run a quick diagnostic, and unlock a premium adaptive K-5 math path.")
                    .kidText(.h2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .foregroundStyle(.secondary)

                TextField("Child name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .kidText(.h2)
                    .accessibilityLabel("Child name")

                Button("Start Adventure") {
                    appState.createProfile(name: name)
                }
                .buttonStyle(CTAButtonStyle(theme: appState.selectedTheme))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Start Adventure")
            }
            .padding(28)
            .frame(maxWidth: 620)
            .background {
                ZStack {
                    Image(appState.selectedTheme.backgroundAssetName)
                        .resizable()
                        .scaledToFill()
                    Color.white.opacity(0.82)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)

            Spacer()
        }
        .padding()
    }
}
