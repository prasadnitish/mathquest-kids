# Sprout Math

A native SwiftUI math app for iPhone and iPad that helps K-5 learners (ages 5-11) build foundational math skills through short adaptive sessions, deterministic tutoring, and a privacy-first design — no ads, no accounts, no cloud dependencies.

## Product

- **Full K-5 curriculum** — 38 skill units spanning counting, operations, place value, fractions, geometry, measurement, data, and pre-algebra, aligned to Common Core State Standards
- **2,400+ question templates** — enough variety across 40 lessons to sustain long-term use without repetition fatigue
- **Adaptive placement** — an 18-question diagnostic places each learner at the right grade band automatically
- **3-tier deterministic hints** — concrete visual → strategy prompt → worked solution, all hand-authored (no AI in the learning loop)
- **Professional narration** — 2,500+ pre-generated ElevenLabs audio clips with four voice styles (Calm, Playful, Energetic, Storyteller), plus system TTS fallback
- **Correction flow** — after two incorrect attempts, the app shows the correct answer with a worked explanation before advancing
- **Spaced review** — skills resurface at 1, 3, 7, 14, and 30 day intervals based on evidence-based spacing
- **6 themed worlds** — Candyland, Axolotl Lagoon, Rainbow Unicorn, Stars & Space, Superhero City, and Turbo Cars, each with 3 companion characters and a unique sticker collection
- **43 collectible stickers** — earned through unit completion across all themed packs
- **Parent dashboard** — gated behind a math challenge; shows grade placement, domain coverage, weak spots, and recent session history
- **Offline-first** — zero network calls, all data stored locally via Core Data
- **Privacy by design** — no analytics, no third-party SDKs, no data collection, COPPA-compliant

## Roadmap

| Phase | Focus |
|-------|-------|
| V1 (current) | Full K-5 curriculum, adaptive placement, deterministic tutoring, narration, rewards |
| V2 | AI tutor companion with conversational math support |

## Architecture

- **Platform:** Universal iOS (iPhone + iPad), iPadOS/iOS 17+, portrait-only
- **Framework:** SwiftUI with Core Data persistence
- **Content model:** JSON-based content packs (`content-pack-v1.json`) with lesson plans, question templates, hints, and rewards
- **Audio:** Pre-generated ElevenLabs MP3s indexed via `audio_index.json`, with AVSpeechSynthesizer fallback
- **Session engine:** Adaptive item selection with spaced review interleaving (25% review / 75% focus)
- **Mastery system:** Per-skill mastery progression with promotion/regression thresholds

## Project Layout

```
MathQuestKids/
├── App/            App shell, state management, theming, feature flags
├── Content/        Content packs, lesson plans, content loader
├── Data/           Core Data stack, mastery engine, progress repository, session composer
├── Domain/         Business models, session runtime, curriculum models, sticker system
├── Features/       SwiftUI views organized by feature area
├── Services/       Hint engine, narration, diagnostics, sound effects, curriculum service
├── Audio/          2,500+ pre-generated ElevenLabs MP3 narration files
└── Assets.xcassets Character art, theme imagery, app icon
```

## Build and Test

Open `MathQuestKids.xcodeproj` in Xcode 26 or later.

```bash
# Run all tests
scripts/run-local-qa.sh

# Run unit + integration tests only
xcodebuild test -scheme MathQuestKids -destination 'platform=iOS Simulator,name=iPad Air'
```

## Links

- **Product website:** [sproutmath.app](https://www.sproutmath.app)
- **Privacy policy:** [sproutmath.app/privacy](https://www.sproutmath.app/privacy.html)
- **Portfolio case study:** [nitishprasad.com/project-sproutmath](https://www.nitishprasad.com/project-sproutmath.html)
