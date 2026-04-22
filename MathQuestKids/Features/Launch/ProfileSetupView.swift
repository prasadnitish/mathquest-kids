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

                Text("Choose a name, take a quick quest check, and start a math adventure made just for this device.")
                    .kidText(.h2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .foregroundStyle(.secondary)

                // WS7.4: Mascot welcome — use first companion of the current theme as fallback
                // (user hasn't completed profile yet, so no companion is selected)
                let setupCompanion = CharacterPackLibrary.companions(for: appState.selectedTheme).first
                    ?? CharacterPackLibrary.defaultCompanion(for: appState.selectedTheme)
                MascotBlock(
                    companion: setupCompanion,
                    context: .homeGreeting,
                    theme: appState.selectedTheme
                )
                .padding(.horizontal, DesignTokens.Spacing.sp4)
                .padding(.bottom, DesignTokens.Spacing.sp4)

                TextField("Child name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .kidText(.h2)
                    .submitLabel(.done)
                    .onSubmit {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        appState.createProfile(name: trimmed)
                    }
                    .accessibilityLabel("Child name")

                VStack(alignment: .leading, spacing: 8) {
                    Text("The child’s first name stays only on this device and is never sent to a server or third party.")
                        .parentText(.data)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Parent Settings use a 4-digit PIN that you create on this device.")
                        .parentText(.data)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    NavigationLink {
                        LegalDocumentView(document: .privacyPolicy)
                    } label: {
                        Text("Review the Privacy Policy")
                            .parentText(.data)
                            .foregroundStyle(appState.selectedTheme.primary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
