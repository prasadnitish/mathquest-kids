# Sprout Math Release Prep (Phase 5)

## Sproutmath Design System v1.0 — 2026-04-20

Applied the Sproutmath Design System overhaul across all child-facing surfaces. See `docs/plans/2026-04-20-sproutmath-design-system.md` for the full plan.

### Visual changes
- **Typography**: Nunito 800+ replaces SF Pro on every child screen. DM Sans (NEW) is used only in Parent Mode. Typography is centralized via `KidText` / `ParentText` tokens.
- **Themed canvas**: Every child-facing screen now renders on the themed gradient (no plain white/system backgrounds). New `ThemedBackgroundView` gradient-only mode added.
- **Answer buttons**: Numbered 1–4 (never A/B/C/D), with explicit default/selected/correct/wrong/idk states and a new "I don't know yet" defer option.
- **Read Aloud**: Promoted to full-width primary CTA above the answer list. No more buried speaker icon.
- **Buttons**: Six named styles (CTA, Secondary, Play, Ghost, Icon, Disabled) replace the previous Primary/Secondary pair.
- **Mascot presence**: Every child-facing screen now shows a companion with a <=12-word speech bubble via new `MascotBlock` component.
- **Sticker book**: Cap locked-slot visibility at 4 + one "more coming" mystery tile (vs the previous 36+ locked slots).
- **Celebration modal**: Reward splash aligned to Sproutmath modal spec via new `CelebrationModal` component (preserves particle burst + TTS).
- **Motion**: Centralized four named animations (`kidBounceIdle`, `kidPopIn`, `kidWiggle`, `kidFloat`) + duration scale in `Motion.swift`.
- **Parent Mode**: Dark slate visual language (`#1e293b`), DM Sans typography, no theme gradient, no mascot. Data-forward layout distinct from child UI.

### Data shown to kids (per design-system rule)
- KEPT: streak days, sessions count, mastered skill nodes (visual progression)
- REMOVED from child UI: accuracy %, "X of N skills" fractions, grade labels ("Grade 1" → "Chapter 2"), domain names ("Operations & Algebraic Thinking"), "Kindergarten" tags. All preserved in Parent Mode.

### Copy rules
- No "Wrong" / "Incorrect" anywhere in child UI
- No all-caps labels in child UI
- Every mascot phrase <=12 words (enforced by lint tests)
- No curriculum jargon ("CPA", "Spiral Review", "Variation Theory") in child UI

### Deliberate deviations from design system spec
- **Parent gate**: spec says 4-digit PIN; this app keeps its math-challenge gate (better anti-snooping property)
- **Grade labels**: spec says hide; this app renames them to "Chapter N" (preserves grouping signal without academic framing)

### Test infrastructure additions
- 27 new tests across 7 suites guarding the design system — all passing
- `CopyAuditTests` walks the source tree and bans regressions: `.caption2`, `.textCase(.uppercase)`, "Accuracy", "Grade N", "Kindergarten", "Wrong", "Incorrect", curriculum jargon, and mascot phrases >12 words

### Fonts
- Embedded via `MathQuestKids-Info.plist`'s `UIAppFonts`:
  - Nunito: Regular, Medium, SemiBold, Bold, ExtraBold, Black
  - DM Sans: Regular, Medium, SemiBold, Bold
  - All SIL OFL — free for redistribution.

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
