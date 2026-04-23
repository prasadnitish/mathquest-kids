import SwiftUI

struct ParentPINUnlockCard: View {
    @Binding var parentAnswer: String

    let gateMessage: String
    let cooldownSeconds: Int?
    let isLocked: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter Parent PIN")
                .font(.title2.bold())

            Text("Use the 4-digit PIN to open parent settings, reports, and privacy controls.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("4-digit PIN", text: $parentAnswer)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: parentAnswer) { _, newValue in
                    parentAnswer = ParentPINPolicy.sanitize(newValue)
                }
                .accessibilityLabel("Parent PIN")

            Button("Unlock Settings", action: onSubmit)
                .buttonStyle(SecondaryButtonStyle())
                .disabled(isLocked || parentAnswer.count != ParentPINPolicy.requiredLength)

            if let cooldownSeconds {
                Text("Too many attempts. Try again in about \(cooldownSeconds) seconds.")
                    .foregroundStyle(DesignTokens.incorrect)
                    .multilineTextAlignment(.center)
            }

            if !gateMessage.isEmpty {
                Text(gateMessage)
                    .foregroundStyle(DesignTokens.incorrect)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
    }
}

struct ParentPINSetupCard: View {
    @Binding var setupPIN: String
    @Binding var confirmSetupPIN: String

    let gateMessage: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Create Parent PIN")
                .font(.title2.bold())

            Text("Choose a 4-digit PIN to protect parent settings, reports, and local data controls.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("New 4-digit PIN", text: $setupPIN)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .textContentType(.newPassword)
                .onChange(of: setupPIN) { _, newValue in
                    setupPIN = ParentPINPolicy.sanitize(newValue)
                }
                .accessibilityLabel("New parent PIN")

            SecureField("Confirm 4-digit PIN", text: $confirmSetupPIN)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .textContentType(.newPassword)
                .onChange(of: confirmSetupPIN) { _, newValue in
                    confirmSetupPIN = ParentPINPolicy.sanitize(newValue)
                }
                .accessibilityLabel("Confirm parent PIN")

            Button("Save Parent PIN", action: onSave)
                .buttonStyle(SecondaryButtonStyle())
                .disabled(
                    setupPIN.count != ParentPINPolicy.requiredLength ||
                    confirmSetupPIN.count != ParentPINPolicy.requiredLength
                )

            if !gateMessage.isEmpty {
                Text(gateMessage)
                    .foregroundStyle(DesignTokens.incorrect)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
    }
}

struct ParentSettingsHeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parent Settings")
                .kidText(.display)

            Text("Review progress, tune the app experience, and manage local data from one place.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .kidText(.h2)

            Text(subtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            content
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct MetricPillView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct SettingsLinkRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    init(title: String, subtitle: String, symbol: String, tint: Color = AppTheme.textPrimary) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct ParentPINEditorSheet: View {
    let mode: ParentPINEditorMode
    let onSave: (String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Use a 4-digit PIN that only the parent or guardian knows.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SecureField("New 4-digit PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                        .textContentType(.newPassword)
                        .onChange(of: newPIN) { _, newValue in
                            newPIN = ParentPINPolicy.sanitize(newValue)
                        }

                    SecureField("Confirm 4-digit PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                        .textContentType(.newPassword)
                        .onChange(of: confirmPIN) { _, newValue in
                            confirmPIN = ParentPINPolicy.sanitize(newValue)
                        }

                    if !message.isEmpty {
                        Text(message)
                            .foregroundStyle(DesignTokens.incorrect)
                    }
                }
            }
            .navigationTitle(mode == .change ? "Change Parent PIN" : "Create Parent PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .disabled(
                            newPIN.count != ParentPINPolicy.requiredLength ||
                            confirmPIN.count != ParentPINPolicy.requiredLength
                        )
                }
            }
        }
    }

    private func save() {
        message = ""

        guard ParentPINPolicy.isValid(newPIN), ParentPINPolicy.isValid(confirmPIN) else {
            message = "Use exactly 4 digits for the parent PIN."
            return
        }

        guard newPIN == confirmPIN else {
            message = "The PIN entries do not match."
            return
        }

        do {
            try onSave(newPIN)
            dismiss()
        } catch {
            message = "Couldn't update the parent PIN right now."
        }
    }
}

struct ThemeCard: View {
    let theme: VisualTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Image(theme.backgroundAssetName)
                        .resizable()
                        .scaledToFill()
                    LinearGradient(
                        colors: [Color.black.opacity(0.05), Color.black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Image(systemName: theme.heroSymbol)
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white.opacity(0.98))
                }
                .frame(width: 170, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(theme.name)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(8)
            .background(
                isSelected ? theme.primary.opacity(0.18) : AppTheme.card,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(theme.name) theme")
    }
}

struct CompanionCard: View {
    let companion: ThemeCompanion
    let isSelected: Bool
    let theme: VisualTheme
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    ThemeCompanionArtworkView(
                        companion: companion,
                        theme: theme,
                        size: 56,
                        highlighted: isSelected
                    )
                    .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(companion.name)
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(companion.title)
                            .kidText(.body)
                            .foregroundStyle(AppTheme.textPrimary.opacity(0.78))
                    }

                    Spacer(minLength: 8)
                }

                Text(companion.tagline)
                    .kidText(.body)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.84))
                    .lineLimit(3)

                if isSelected {
                    Label("Selected", systemImage: "checkmark.seal.fill")
                        .kidText(.caption)
                        .foregroundStyle(theme.primary)
                }
            }
            .padding(14)
            .frame(width: min(280, UIScreen.main.bounds.width - 80), alignment: .leading)
            .background {
                Group {
                    if isSelected {
                        ZStack {
                            Image(theme.backgroundAssetName)
                                .resizable()
                                .scaledToFill()
                            AppTheme.card.opacity(0.92)
                        }
                    } else {
                        AppTheme.card
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? theme.primary : Color.black.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: .black.opacity(isSelected ? 0.14 : 0.07),
                radius: isSelected ? 10 : 5,
                x: 0,
                y: isSelected ? 6 : 3
            )
        }
        .buttonStyle(.plain)
    }
}
