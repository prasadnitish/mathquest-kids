# Sprout Math Release Prep (Phase 5)

## Build and QA
- Run `MathQuestKidsTests` and `MathQuestKidsUITests` on an iPad simulator.
- Manually verify all three units, hint tiers, and summary reward reveal.
- Validate settings parental gate and privacy copy.
- Confirm app works fully offline by disabling network.

## Accessibility
- Verify all primary controls are >=44x44 points.
- Verify VoiceOver announces key controls and labels.
- Verify Reduced Motion: reward reveal remains readable without heavy motion.

## Privacy and Kids Safety
- Local-only storage: Core Data in app sandbox.
- No third-party ads or analytics.
- No cloud sync in V1.
- Parent gate required before settings access.

## TestFlight Checklist
- Increment build number.
- Archive from Xcode Organizer.
- Upload to App Store Connect.
- Add tester notes covering profile setup and session flow.
- Run internal test pass on at least one physical iPad.

## App Store Metadata Draft
- App Name: Sprout Math
- Subtitle: "Offline math adventures for K-5 learners"
- Age: Kids 5 and under
- Privacy summary: Data stays on-device in V1 unless future opt-in sync is added.
- Screenshots: profile setup, home map, one screen per unit, session summary.
