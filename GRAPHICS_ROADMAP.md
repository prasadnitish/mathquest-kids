# Sprout Math Graphics Roadmap

This roadmap pushes the app from a strong SwiftUI product into a more distinctive, premium-feeling children’s experience. The goal is not to add random decoration. The goal is to make each child-facing screen feel like it belongs to a living world.

## Direction

The current app already has solid foundations:

- strong color worlds and semantic themes
- playful typography and spacing
- themed backgrounds
- mascot-led guidance
- reward and sticker systems

The next-level visual jump comes from three things:

1. More dimensional scene-building in code
2. Authored art packs per world
3. Flagship progression and reward spectacle

## Phase 1: Code-Only Visual Lift

Goal: make the app feel richer immediately without waiting on a custom illustration pipeline.

Status: in progress, with the first pass now implemented.

### Focus areas

- Deepen atmosphere on all child screens
- Make cards feel less flat and more theme-aware
- Make mascot moments feel more premium and expressive
- Upgrade reward reveals so they feel bigger and more special

### Implementations in this phase

- Richer scene layering in [`MathQuestKids/App/ThemedBackgroundView.swift`](MathQuestKids/App/ThemedBackgroundView.swift)
  - atmospheric glows
  - themed floating scene props
  - stronger vignette/depth treatment
- Premium card treatment in [`MathQuestKids/Features/Shared/AppCard.swift`](MathQuestKids/Features/Shared/AppCard.swift)
  - gloss, accent glows, decorative theme details, stronger strokes and shadows
- Upgraded mascot presentation in [`MathQuestKids/Features/Shared/MascotBlock.swift`](MathQuestKids/Features/Shared/MascotBlock.swift)
  - aura, orbit detail, improved speech bubble treatment
- Bigger celebration framing in [`MathQuestKids/Features/Shared/CelebrationModal.swift`](MathQuestKids/Features/Shared/CelebrationModal.swift)
  - halo, starburst, richer modal surface, themed background glow
- Better sticker reveal polish in [`MathQuestKids/Features/Rewards/RewardSplashView.swift`](MathQuestKids/Features/Rewards/RewardSplashView.swift)
  - upgraded sticker pedestal and more varied burst particles

### Remaining Phase 1 tasks

- Add per-theme button/chrome variations for primary child CTAs
- Add richer state-specific mascot reactions in session flow
- Add more foreground scene framing on the home and lesson-map surfaces
- Tune child-facing motion so premium effects feel intentional, not noisy

## Phase 2: Authored Art Packs

Goal: replace generic symbol-led decoration with bespoke illustrated world kits.

This is the biggest single step toward a standout look.

### Deliverables per world

- 1 hero background backplate
- 3-5 midground props
- 2-4 foreground props
- 1 themed card/chrome ornament set
- 1 reward particle/flare set
- 1 sticker-frame treatment
- 1 quest-trail landmark pack

### Deliverables per mascot

- idle pose
- cheering pose
- thinking pose
- hint pose
- celebration pose
- gentle concern/retry pose

### World examples

- Candyland: frosting hills, candy arches, gumdrop trees, sprinkles, sugar sparkle bursts
- Stars and Space: orbit rings, planets, nebula haze, constellations, glowing star trails
- Turbo Cars: racetrack curves, checkered banners, tire streaks, pit markers, medal flares
- Ocean / Underwater world: coral frames, bubbles, rays, shells, treasure markers
- Jungle / Safari world: leaves, vines, trail markers, friendly animal props
- Cozy / Storybook world: paper textures, soft hills, book-page framing, stitched stars

### Technical packaging

- High-res transparent PNG or vector-exported layered assets
- Safe crops for iPad portrait and landscape
- No embedded text in art
- Theme assets loaded by world so future additions stay modular

## Phase 3: Flagship Signature Systems

Goal: make progression and rewards feel magical, not just well designed.

### Systems to build

- World-map quest trail
  - curved path, landmarks, animated checkpoints, chapter reveal logic
- Premium reward reveal system
  - rarity treatment, foil/shimmer variants, layered confetti, reveal choreography
- Session scene framing
  - world-specific lesson frames and manipulatives so gameplay looks less like cards-on-backgrounds
- Character-led reactions
  - state-based mascot expression/pose swaps tied to success, hints, retries, and streaks
- World progression spectacle
  - when a child enters a new grade band or chapter cluster, show a short themed transition moment

### Success criteria

- A child can identify the current world from silhouette and color alone
- Rewards feel noticeably more exciting than standard SwiftUI modal feedback
- Progression feels like moving through a place, not tapping through a stack of cards
- The parent area remains clear and functional while child-facing screens carry the authored visual weight

## Recommended Execution Order

1. Finish the remaining Phase 1 code-based polish
2. Commission or generate one full art pack for a single flagship world
3. Apply that art pack to home, session, rewards, and quest map as the reference implementation
4. Expand the system to the remaining worlds once the pipeline is stable
5. Build the Phase 3 world-map and premium reward systems on top of those assets

## Immediate Next Move

The fastest path to a visibly better app is:

1. Finish Phase 1 child CTA and session-state polish
2. Choose one flagship world for full art treatment
3. Build the first real asset pack around that world

If we want the most impact soonest, the best flagship-world candidates are:

- Candyland, because it supports high delight and clear reward spectacle
- Stars and Space, because it supports layered depth, glow, and motion especially well
