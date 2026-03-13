# Sprout Math (iPad, Offline-First)

Native SwiftUI iPad app for early math practice with deterministic tutoring, local-only persistence, and bundled content packs.

## Scope Implemented
- iPad-only target (`TARGETED_DEVICE_FAMILY = 2`)
- iPadOS 17+
- 3 units: subtraction stories, teen place value, two-digit comparison
- Deterministic tiered hints + text-to-speech narration
- Theme system with illustrated bitmap background packs (`Candyland`, `Axolotl Lagoon`, `Rainbow Unicorn`, `Stars and Space`)
- Parent-configurable narration style (`Calm`, `Playful`, `Energetic`)
- Automatic read-aloud when each new question appears (toggle in settings)
- Expanded offline question bank (535 templates) across subtraction, tens/ones, and comparison
- Session composer now prefers recently unseen templates for the focus unit to reduce repeats
- Core Data local persistence for profiles, attempts, mastery, review, sessions
- Session composition with mixed review and spaced schedule support
- Unit unlock progression (subtraction -> teen place value -> two-digit comparison)
- Home dashboard metrics (streak, completed sessions, lifetime accuracy)
- Retry-on-miss behavior (first miss retries same item; second miss advances)
- Portrait-only orientation lock for focused iPad classroom UX
- Reduced-motion-friendly reward reveal in session summary
- Parent-gated settings + privacy copy
- Unit, integration, and UI test scaffolding

## Project Layout
- `MathQuestKids/` app source
- `MathQuestKidsTests/` unit + integration tests (Swift Testing)
- `MathQuestKidsUITests/` UI automation (XCTest)

## Build/Test
Open:
- `mathquest-kids/MathQuestKids.xcodeproj`

Run tests in Xcode for:
- `MathQuestKidsTests`
- `MathQuestKidsUITests`
Or run both via script:
- `mathquest-kids/scripts/run-local-qa.sh`

> Note: local CLI validation with `xcodebuild` requires a full Xcode install and active developer directory pointed at Xcode.
