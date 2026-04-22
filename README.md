# Sprout Math

Sprout Math is a native SwiftUI learning app for K-5 math practice. The app combines structured curriculum content, local persistence, narration assets, and a dedicated testing and release-prep workflow.

## What This Project Demonstrates

- full native app design for education, not just a feature demo
- thoughtful boundary-setting around offline-first and privacy-first product choices
- curriculum, progress, and content systems living inside one codebase
- supporting scripts and QA artifacts for a real release process

## Current Scope

- iOS/iPadOS app in `MathQuestKids/`
- curriculum and lesson content in `MathQuestKids/Content`
- persistence and mastery logic in `MathQuestKids/Data`
- feature views in `MathQuestKids/Features`
- narration and content-generation scripts in `scripts/`
- unit and UI tests in `MathQuestKidsTests/` and `MathQuestKidsUITests/`

## Build and Test

Open [MathQuestKids.xcodeproj](/Users/nitish/VS Code Projects/tpm-portfolio/mathquest-kids/MathQuestKids.xcodeproj) in Xcode.

Helpful commands:

```bash
xcodebuild build -project MathQuestKids.xcodeproj -scheme MathQuestKids -destination 'generic/platform=iOS Simulator'
```

The repository includes `MathQuestKidsTests/` and `MathQuestKidsUITests/`. Running those targets from Xcode is currently the most reliable validation path.

## Supporting Docs

- `IMPLEMENTATION_STATUS.md`
- `QA_MATRIX.md`
- `RELEASE_PREP.md`
- `PRD.md`

## Current State

This repo is beyond an early prototype. It contains a substantial app structure, content pipeline scripts, art, audio assets, and release-readiness documentation. The README stays intentionally conservative and avoids fragile count-based claims.
