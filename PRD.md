# Lean PRD — Sprout Math

## 1. Summary

* **Product / Feature Name:** Sprout Math
* **Owner:** Nitish Prasad
* **Date:** March 10, 2026
* **Status:** Shipped (V1)

**One-line summary:** Sprout Math is an offline-first iOS math app that helps K-5 learners build foundational math skills through short adaptive sessions, deterministic hints, and a parent-trusted privacy model — without ads, accounts, or cloud dependencies.

---

## 2. Problem

**Problem statement:** Parents of young children (ages 5-11) struggle to find math practice apps that are trustworthy, calm, and effective. The current market is dominated by apps that either require accounts and internet access to function, bombard kids with ads and upsells, collect behavioral data without clear disclosure, or overwhelm parents with complex dashboards and subscription tiers. Kids lose focus when sessions are too long or too noisy, and parents lose trust when they cannot understand what the app is doing with their child's data.

**Why now:**
- Apple's Kids Category requirements and App Tracking Transparency have raised the bar for privacy in children's apps — apps that are genuinely offline and data-minimal now have a regulatory and trust advantage.
- Post-pandemic screen time fatigue means parents are more selective about educational apps. "Calm tech" that respects attention is a growing preference.
- Competitors like Khan Kids and Moose Math have shifted toward engagement-maximizing features (streaks, social, notifications) — creating a gap for a deliberately restrained product.

**Evidence:**
- App Store reviews for top K-5 math apps consistently surface complaints about: mandatory logins, broken offline behavior, aggressive in-app purchases in kids-facing UI, and confusing parent dashboards.
- 2,400+ question templates and 40 lessons have been authored and validated across the full K-5 US math curriculum (CCSS-aligned), confirming the content is deep enough to sustain repeat use.
- A working build has completed 5 phases of development with unit, integration, and UI test coverage — confirming technical feasibility.

---

## 3. Goal

**Primary goal:** Ship Sprout Math to the iOS App Store as a free, offline-first math practice app that parents can hand to a K-5 learner without hesitation — no setup friction, no login, no privacy concerns.

**Business impact:**
- Establishes a portfolio-grade shipped product demonstrating product craft, privacy-first design, and full-stack iOS delivery (SwiftUI, Core Data, adaptive learning systems).
- Creates a foundation for a freemium model in V2 (cloud sync, multi-child profiles, expanded content) if organic adoption reaches 50-100+ users.
- Differentiates in a crowded edtech market by competing on trust and restraint rather than feature volume.

**Non-goals:**
- V1 will not include cloud sync, user accounts, or any network-dependent features.
- V1 will not include multi-child profiles (single profile per device).
- V1 will not support Android — iOS (iPhone + iPad) only.
- V1 will not include teacher-facing tools, classroom management, or school licensing.
- V1 will not use AI-generated hints or any language model in the learning loop — all tutoring is deterministic and rule-based. An AI tutor companion is planned for V2.
- V1 will not include monetization (no subscriptions, no in-app purchases, no ads).

---

## 4. Users

**Primary user:** K-5 learners (ages 5-11) practicing math independently or with light parent supervision, primarily on a shared family iPad or parent's iPhone.

**Secondary user:** Parents of K-5 learners who want visibility into their child's progress, control over app settings, and confidence that the app is safe and ad-free.

**Key user need:**
- *Child:* A short, playful math session that starts fast, feels fair, and ends with a reward — without needing help from an adult to navigate.
- *Parent:* Confidence that the app is safe (no data collection, no ads, no surprise purchases) and useful (visible progress, appropriate difficulty, calm interaction model).

---

## 5. Use Cases

1. **As a parent**, I want to hand my child an iPad with a math app that works immediately without creating an account, so that my child can start practicing without my help.

2. **As a K-5 learner**, I want the app to figure out what math level I'm at, so that the questions feel just right — not too easy, not too hard.

3. **As a K-5 learner**, I want to earn stickers and see my progress on a skill trail after each session, so that I feel motivated to come back.

4. **As a parent**, I want to see what my child has been working on and where they are struggling, so that I can support them without needing a separate dashboard app.

5. **As a parent**, I want settings and controls behind a gate my child cannot bypass, so that I stay in control of themes, narration, and difficulty without my child changing things.

---

## 6. Proposed Solution

**Overview:** A native SwiftUI app for iPhone and iPad that bundles a full K-5 math curriculum as local content, uses an 18-question adaptive diagnostic to place learners at the right grade level, then delivers 5-10 minute practice sessions with deterministic hints, spaced review, and sticker-based rewards. All data stays on device. Parent access is gated behind a math challenge the child is unlikely to solve.

**User flow:**

1. **Profile setup** — Child enters a display name. No account, no email, no login.
2. **Adaptive diagnostic** — 18 multiple-choice questions spanning K-5 domains (number sense, operations, place value, fractions, geometry, measurement). Takes approximately 5 minutes. App places child at appropriate grade band with a confidence score.
3. **Home screen** — Child sees a greeting with their name, a metrics bar (streak days, sessions completed, lifetime accuracy), a recommended mission card based on adaptive placement, a companion character spotlight, a skill trail showing their progress across 38 units, and a sticker book card.
4. **Practice session** — Child selects a unit (or taps the recommended mission). Session presents 5-9 adaptive items based on unit and grade. Each item shows a prompt, 4-choice answers, and buttons for hints and read-aloud narration. First incorrect answer triggers a retry; second incorrect advances. Hints escalate through 3 tiers: concrete visual support, strategy prompt, worked example step.
5. **Session summary** — Shows correct/total count, a reward title, and a sticker reveal if this was the child's first completed session for that unit.
6. **Parent dashboard** — Behind a parent gate (random addition problem, e.g. "7 + 4 = ?"). Shows grade placement, domain coverage, weak spots, recent session history, and a diagnostics export option.

**Key decisions / principles:**

* **Offline-first is a product choice, not a technical limitation.** No network calls exist in V1. This keeps the app fast, private, and dependable in low-connectivity environments (cars, waiting rooms, planes).
* **Deterministic hints over AI-generated responses.** Hints are rule-based and tiered so tutoring behavior is explainable and age-appropriate. No language model is in the learning loop.
* **Short sessions over endless play.** Sessions cap at 5-10 minutes with a clean stopping point. Parents need predictable handoff. Kids need closure.
* **Portrait lock across iPhone and iPad.** Reduces cognitive overhead, keeps touch targets and narration consistent across devices, and avoids layout bugs from rotation.
* **Content as data, not code.** The 2,400+ question templates and 40 lesson plans are bundled JSON. New content can ship via app updates without code changes.
* **Professional narration over synthetic voice.** 2,500+ question, feedback, and diagnostic audio clips are pre-generated using ElevenLabs with a child-friendly voice, with system TTS as a graceful fallback.
* **Parent trust is a core feature.** Parent gate, local-only storage, explicit privacy copy, progress dashboard, and diagnostics export are treated as first-class product features — not afterthoughts tacked onto settings.

---

## 7. Requirements

### Must Have

* Adaptive placement diagnostic (18 questions, K-5, grade-level result with confidence score)
* 38 playable skill units across K-5 with 2,400+ question templates
* Session composer with adaptive item count (5-9 items), spaced review interleaving (25% review / 75% focus), and retry-on-miss behavior
* Deterministic 3-tier hint engine (concrete → strategy → worked example)
* Text-to-speech narration with 4 voice styles (Calm, Playful, Energetic, Storyteller) and auto-read toggle
* Core Data persistence for profiles, attempts, mastery state, review schedule, session logs, and sticker records — all local, no cloud
* Skill trail visualization showing 38 units grouped by grade with locked / available / in-progress / completed / mastered states
* Professional narration with 2,500+ pre-generated ElevenLabs audio clips across 4 voice styles (Calm, Playful, Energetic, Storyteller), plus system TTS fallback
* Correction flow: after 2 incorrect attempts, the app shows the correct answer with a worked explanation before advancing
* 43-sticker reward system with 6 themed visual packs (Candyland, Axolotl Lagoon, Rainbow Unicorn, Stars and Space, Superhero City, Turbo Cars)
* 12 companion characters (3 per active theme) with distinct taglines and coaching approaches
* Parent gate (random addition challenge) before settings access
* Parent dashboard with grade placement, domain coverage, weak spot flagging, recent activity (last 50 sessions), and curriculum alignment note
* Local diagnostics export for parents and testers
* Universal iOS (iPhone + iPad), portrait-only, iOS 17+
* Accessibility: 44x44pt minimum touch targets, VoiceOver labels, reduced-motion reward animations
* No ads, no analytics, no third-party SDKs, no network calls

### Nice to Have

* Sound effects for interactions (correct, incorrect, hint, tap, reward) with parent toggle
* Themed background wallpapers with floating particle animations (reduced-motion aware)
* Adaptive lesson planner recommending support lessons (prior grade), stretch lessons (next grade), and pedagogy highlights
* 40-lesson K-5 lesson plan viewer with CCSS standards mapping, pedagogical strategy tags, and activity prompts

### Out of Scope (V1)

* Cloud sync / multi-device progress
* Multi-child profiles per device
* Android or web version
* Teacher/classroom dashboard
* In-app purchases or subscription
* AI-generated hints or any language model integration (planned for V2 as AI tutor companion)
* Social features, leaderboards, or multiplayer
* Push notifications
* Localization beyond US English / CCSS standards

---

## 8. Acceptance Criteria

* Child can complete profile setup and adaptive diagnostic in under 8 minutes without adult help.
* Adaptive diagnostic places child within one grade band of their actual math level at least 80% of the time (validated via QA matrix with K, G2, G4 test profiles).
* A single practice session loads in under 2 seconds, presents the correct number of items for the unit, and ends with a summary screen — fully offline, with airplane mode on.
* Hints escalate correctly: first tap shows concrete support, second tap shows strategy prompt, third tap shows worked example. No hint repeats the previous tier's text.
* Parent gate blocks access to settings unless the correct addition answer is entered. Three failed attempts regenerate a new challenge.
* Parent dashboard accurately reflects the child's most recent 50 sessions, grade placement, and domain-level accuracy.
* All interactive controls pass a 44x44pt minimum tap target check (verified via UI test assertions).
* App runs in portrait-only orientation on both iPhone and iPad without layout overflow or clipping.
* Sticker is awarded on first session completion per unit and persists across app launches.
* Narration reads the current question prompt aloud when auto-read is enabled or the read-aloud button is tapped.
* Diagnostics export produces a readable local file containing session history and placement data with no PII beyond the child's first name.
* Status messages (e.g. "Placement Complete: Kindergarten") auto-dismiss after 4 seconds.

---

## 9. Success Metrics

**Primary metric:** 50 organic TestFlight installs within 4 weeks of App Store availability (no paid acquisition).

**Secondary metrics:**
* Average session completion rate ≥ 80% (sessions started vs. sessions reaching summary screen)
* App Store rating ≥ 4.5 stars after first 20 reviews
* Median session duration between 4-8 minutes (validating the "short session" design intent)
* At least 3 returning users completing ≥ 5 sessions each within first month (retention signal)

**Guardrails:**
* Crash-free rate must stay above 99% (Xcode Organizer)
* App launch to home screen must stay under 3 seconds on iPhone SE (oldest supported device)
* No increase in App Store privacy nutrition label disclosures beyond "Data Not Collected"
* Diagnostic placement accuracy should not drop below 75% as measured by QA regression tests

---

## 10. Dependencies and Risks

**Dependencies:**
* Apple Developer Program enrollment (active) for TestFlight and App Store submission
* App Store Connect metadata, screenshots, and privacy policy URL must be finalized before review
* PrivacyInfo.xcprivacy manifest required by Apple for all new submissions (not yet created)
* Content accuracy: 2,400+ question templates must be mathematically correct — human spot-check required for each grade band before launch

**Risks:**

| Risk | Likelihood | Impact |
|------|-----------|--------|
| App Store rejection due to Kids Category requirements (missing privacy policy, wrong age rating, metadata issue) | Medium | High — blocks launch |
| Content errors in question templates (wrong answers, ambiguous prompts) found post-launch | Medium | Medium — erodes parent trust |
| Single-profile limitation frustrates multi-child households | High | Low — known V1 tradeoff, does not block core value |
| Low organic discoverability in a crowded K-5 math category | High | Medium — limits adoption without marketing investment |
| Core Data migration issues if V2 schema changes are needed | Low | Medium — requires careful migration planning now |

**Mitigations:**
* Review Apple's Kids Category guidelines and COPPA requirements before first TestFlight submission. Prepare privacy policy hosted at nitishprasad.com.
* Run a content audit pass across all 6 grade bands before launch. Prioritize K-2 content (highest usage band) for deepest review.
* Design Core Data model with future schema migration in mind (lightweight migration paths documented).
* Plan App Store Optimization (ASO) for launch: keyword research for "offline math," "kids math no ads," "K-5 math practice" — differentiate on privacy and offline in description.

---

## 11. Rollout

**Launch plan:**

| Phase | Timeline | Milestone |
|-------|----------|-----------|
| Internal TestFlight | Week 1 | Build uploaded, tester notes, 1 physical device pass |
| Closed beta | Weeks 2-3 | 10-15 trusted testers (parents with K-5 kids), collect qualitative feedback |
| App Store submission | Week 3 | Submit for review with full metadata, screenshots, privacy policy |
| Public launch | Week 4 | Available on App Store, portfolio case study live at nitishprasad.com/project-mathquest |
| Post-launch observation | Weeks 5-8 | Monitor crash reports, App Store reviews, session metrics via diagnostics exports from beta testers |

**Owner(s):**
* Product: Nitish Prasad
* Design: Nitish Prasad
* Engineering: Nitish Prasad

**Resolved decisions:**
* **Age rating: Ages 6-8.** Apple Kids Category will use the 6-8 band. The curriculum spans K-5, but this band best represents the core audience.
* **Monetization: None in V1.** Ship completely free with no IAP. V2 will introduce an AI tutor companion for conversational math support.
* **Privacy policy: Canonical URL at [sproutmath.app/privacy.html](https://www.sproutmath.app/privacy.html).** Terms at [sproutmath.app/terms.html](https://www.sproutmath.app/terms.html). These URLs will be submitted to App Store Connect. Mirror copy also at nitishprasad.com/sproutmath-legal.
* **Unit availability: All 38 units at launch.** All content is authored and wired. Full K-5 curriculum ships from day one.
