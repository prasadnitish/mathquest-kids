import SwiftUI

struct LegalSection: Identifiable {
    let title: String
    let paragraphs: [String]

    var id: String { title }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .kidText(.h2)
                            .foregroundStyle(AppTheme.textPrimary)

                        ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(.body)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
                    )
                }
            }
            .padding(24)
        }
        .background(
            ThemedBackgroundView(theme: VisualTheme.loadPersisted(), mode: .gradientOnly)
                .ignoresSafeArea()
        )
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(document.title)
                .kidText(.display)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Effective date: \(document.effectiveDate)  |  Last updated: \(document.lastUpdated)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Text(document.summary)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.textSecondary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct LegalDocument {
    let title: String
    let effectiveDate: String
    let lastUpdated: String
    let summary: String
    let sections: [LegalSection]
}

extension LegalDocument {
    static let termsOfUse = LegalDocument(
        title: "Terms of Use",
        effectiveDate: "March 10, 2026",
        lastUpdated: "March 10, 2026",
        summary: "Sprout Math is a free, offline educational app for math practice. It supports learning at home, but it does not replace classroom instruction, teacher evaluation, or formal assessment.",
        sections: [
            LegalSection(
                title: "1. Acceptance of Terms",
                paragraphs: [
                    "By downloading, installing, or using Sprout Math, you agree to these Terms of Use. If you do not agree, do not use the app.",
                    "When the app is used by a child, a parent or guardian is responsible for reviewing and accepting these terms on the child’s behalf."
                ]
            ),
            LegalSection(
                title: "2. Description of the App",
                paragraphs: [
                    "Sprout Math is a free educational app for iPhone and iPad that helps children practice foundational K-5 math skills.",
                    "The app includes adaptive placement, practice sessions, deterministic hints, narration, and rewards. Its learning content is bundled locally in the app."
                ]
            ),
            LegalSection(
                title: "3. Intended Use",
                paragraphs: [
                    "Sprout Math is intended for personal, non-commercial educational practice by families.",
                    "It is not a substitute for classroom instruction, professional tutoring, or formal academic assessment.",
                    "The app is designed for children ages 5 and older. Use by children under 5 is not intended."
                ]
            ),
            LegalSection(
                title: "4. Educational Content Disclaimer",
                paragraphs: [
                    "Sprout Math is designed around Common Core-aligned K-5 practice, but standards coverage may vary by state, district, and classroom sequence.",
                    "Adaptive placement is an estimate to guide practice. It should not be treated as a diagnostic tool, a placement exam, or a determination about learning disabilities.",
                    "Hints and worked examples are rule-based product features, not live instruction from a licensed educator."
                ]
            ),
            LegalSection(
                title: "5. Accounts, Fees, and Access",
                paragraphs: [
                    "Sprout Math version 1 has no account system, no subscriptions, no in-app purchases, no ads, and no paywalled content.",
                    "Parent-facing settings and reports can be protected with a 4-digit parent PIN stored on the device."
                ]
            ),
            LegalSection(
                title: "6. Intellectual Property",
                paragraphs: [
                    "The app’s code, curriculum content, visual design, character art, audio, and branding are owned by the developer and protected by applicable intellectual property laws.",
                    "You may not copy, modify, distribute, or create derivative works from the app or its content without written permission."
                ]
            ),
            LegalSection(
                title: "7. Warranty and Liability",
                paragraphs: [
                    "Sprout Math is provided on an \"as is\" and \"as available\" basis, without warranties of any kind.",
                    "To the maximum extent permitted by law, the developer is not liable for indirect, incidental, special, consequential, or punitive damages arising from use of the app.",
                    "Because the app is provided free of charge, aggregate liability is limited to $0.00 USD where permitted by law."
                ]
            ),
            LegalSection(
                title: "8. Changes",
                paragraphs: [
                    "The app and these terms may be updated, changed, or discontinued at any time. Continued use of the app after an update means you accept the revised terms."
                ]
            ),
            LegalSection(
                title: "9. Governing Law and Contact",
                paragraphs: [
                    "These terms are governed by the laws of the State of Washington, United States, without regard to conflict-of-law rules.",
                    "Questions about these terms can be sent to support@sproutmath.app.",
                    "Sprout Math is built by Nitish Prasad."
                ]
            )
        ]
    )

    static let privacyPolicy = LegalDocument(
        title: "Privacy Policy",
        effectiveDate: "March 10, 2026",
        lastUpdated: "April 21, 2026",
        summary: "Sprout Math does not collect, transmit, or store personal information on a server. There are no accounts, analytics SDKs, ads, telemetry systems, or diagnostics exports in the app. Learning data stays on the device, parent settings are protected by a 4-digit PIN, and local data can be deleted from parent settings.",
        sections: [
            LegalSection(
                title: "1. Information We Collect",
                paragraphs: [
                    "Sprout Math does not collect personal information from children or adults.",
                    "The app does not transmit names, email addresses, phone numbers, device identifiers, advertising IDs, IP addresses, location data, or behavioral analytics.",
                    "The app does not access photos, contacts, camera, microphone input, or similar device sensors."
                ]
            ),
            LegalSection(
                title: "2. Data Stored on the Device",
                paragraphs: [
                    "Sprout Math stores learning progress locally in the app’s private sandbox using Apple frameworks.",
                    "Local data can include a child profile with a first name, a local identifier, practice history, mastery and review progress, sticker records, app preferences such as theme, companion, and narration settings, and a parent PIN hash stored securely on the device.",
                    "This data is not synced to a cloud service, backend server, or third party."
                ]
            ),
            LegalSection(
                title: "3. Network Activity",
                paragraphs: [
                    "Sprout Math version 1 is designed to function entirely offline and makes no network requests for gameplay, analytics, telemetry, or support logging."
                ]
            ),
            LegalSection(
                title: "4. Third-Party Services",
                paragraphs: [
                    "Sprout Math does not include third-party analytics SDKs, advertising networks, crash-reporting services, social SDKs, or sign-in systems.",
                    "The app relies only on Apple-provided frameworks such as SwiftUI, Core Data, and AVFoundation."
                ]
            ),
            LegalSection(
                title: "5. Children’s Privacy",
                paragraphs: [
                    "Sprout Math is designed for children ages 5 through 11.",
                    "The app does not collect personal information from children as defined by COPPA because it does not transmit child data to any server or third party.",
                    "Parent-facing settings are protected by a 4-digit parent PIN stored on the device. The app does not include social features, messaging, or user-generated content."
                ]
            ),
            LegalSection(
                title: "6. Diagnostics and Logging",
                paragraphs: [
                    "Sprout Math does not maintain an in-app diagnostics log or support-log export for parents.",
                    "The app does not send crash reports or diagnostics to the developer."
                ]
            ),
            LegalSection(
                title: "7. Data Security",
                paragraphs: [
                    "All local data is stored inside the app’s sandboxed container. Other apps cannot access this data through normal iOS protections.",
                    "The parent PIN is stored using Apple's secure on-device keychain APIs rather than being sent to a server.",
                    "Because Sprout Math does not transmit app data over a network, there is no server-side data store for the developer to secure or breach."
                ]
            ),
            LegalSection(
                title: "8. Future Versions",
                paragraphs: [
                    "If a future version introduces accounts, cloud sync, or any form of data transmission, this policy will be updated before that version ships."
                ]
            ),
            LegalSection(
                title: "9. Your Choices and Contact",
                paragraphs: [
                    "Parent Settings includes controls to reset learning progress or delete the child profile and local data from the device.",
                    "Deleting the app also removes its locally stored data from the device.",
                    "There is no account to close or deactivate.",
                    "Questions about privacy can be sent to support@sproutmath.app.",
                    "Sprout Math is built by Nitish Prasad in Washington, United States."
                ]
            )
        ]
    )
}
