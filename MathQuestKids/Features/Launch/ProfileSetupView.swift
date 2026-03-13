import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var name = ""

    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: appState.selectedTheme.heroSymbol)
                    .font(.system(size: AppTheme.scaled(64, compact: isCompact), weight: .black))
                    .foregroundStyle(appState.selectedTheme.primary)

                Text("Sprout Math")
                    .font(.system(size: AppTheme.scaled(46, compact: isCompact), weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Create a profile, run a quick diagnostic, and unlock a premium adaptive K-5 math path.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .foregroundStyle(.secondary)

                TextField("Child name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .accessibilityLabel("Child name")

                Button("Start Adventure") {
                    appState.createProfile(name: name)
                }
                .buttonStyle(PrimaryButtonStyle())
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
