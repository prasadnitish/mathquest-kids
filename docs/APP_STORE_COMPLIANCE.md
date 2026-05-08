# App Store Compliance Checklist

Last reviewed: May 7, 2026

This checklist maps Sprout Math release behavior to the Apple review areas most likely to apply to this app. It is a release-readiness aid, not legal advice.

## Apple Sources Reviewed

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App privacy details: https://developer.apple.com/app-store/app-privacy-details/
- Kids apps guidance: https://developer.apple.com/kids/
- Age rating values and definitions: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions

## Current Compliance Position

### Guideline 1.3 and 5.1.4: Kids Category

- The app is designed for children ages 5 through 11.
- The app has no third-party analytics SDKs, no third-party advertising, no social features, no messaging, no user-generated content, and no unrestricted web access.
- External support/contact information is available from parent settings, behind the parent PIN gate.
- Parent settings, reports, privacy details, terms, support contact, reset progress, and delete profile controls are parent-facing.

### Guideline 1.5: Developer Information

- In-app support is available at Parent Settings -> Privacy & Controls -> Support.
- Public support page: https://www.sproutmath.app/support.html
- Support email: support@sproutmath.app

### Guideline 2.1: App Completeness

- The app is offline-first and does not require a demo account or backend service.
- All listed learning units and lesson-plan entries are playable in-app.
- Avoid App Store review notes or app UI that describe unfinished "coming soon" features.
- For review notes, explain how to reach parent settings and the support page.

### Guideline 2.3.6: Age Rating Accuracy

Recommended App Store Connect answers:

- Age Assurance: None. Sprout Math does not verify, estimate, or request age.
- Parental Controls: Present if App Store Connect asks separately, because parent settings and reports are protected by a parent PIN.
- Advertising: None.
- User-Generated Content: None.
- Messaging or Chat: None.
- Unrestricted Web Access: None.
- Contests, Gambling, Loot Boxes, Simulated Gambling: None.

### Guideline 5.1.1: Privacy Policy and Data Practices

- App Privacy label should be "Data Not Collected" because the developer does not collect, transmit, or receive app data.
- The app stores local-only data in the app sandbox: child first name, local identifier, practice history, mastery and review progress, sticker records, app preferences, and parent PIN hash in Keychain.
- The app makes no gameplay, analytics, telemetry, support logging, or cloud-sync network requests.
- The app privacy manifest declares UserDefaults access with reason `CA92.1`, no collected data types, and no tracking.

## Resubmission Notes Template

```text
Sprout Math is a free, offline K-5 math practice app for children.

The app has no accounts, no third-party analytics, no third-party advertising, no in-app purchases, no cloud sync, no social features, no messaging, no user-generated content, and no unrestricted web access.

The developer does not collect, transmit, receive, or store app data on a server. Learning progress, child first name, app preferences, and the parent PIN hash are stored locally on the device only. Parent Settings includes controls to reset learning progress or delete the child profile and local learning data.

To locate parent controls: open the app, create or select a child profile, then tap the gear icon from Home. If a parent PIN is not configured, the app asks the parent or guardian to create one. Parent Settings, progress reports, privacy controls, terms, support contact, reset progress, and delete profile controls are protected by the parent PIN.

Support URL:
https://www.sproutmath.app/support.html

Support email:
support@sproutmath.app

Age rating clarification: Sprout Math does not include age assurance or age verification. If App Store Connect asks separately about parental controls, the app includes parent PIN-protected settings and reports.
```
