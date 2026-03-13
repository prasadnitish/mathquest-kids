# Sprout Math QA Matrix (V1)

## Functional
- Profile creation persists after app restart.
- Home shows all 3 unit cards.
- Unit unlocking enforces order: subtraction -> teen place value -> two-digit comparison.
- Session starts for each unit and completes to summary.
- Summary shows correct count and reward title.
- Parent gate blocks settings until correct answer.

## Learning Logic
- Mastery promotion at >=85% over recent 20 attempts across >=2 sessions.
- Mastered skill can regress to `reviewDue` after drop/lapse patterns.
- Review schedule supports 1/3/7/14/30-day cadence.
- Session includes mixed review items when due.
- Session includes fallback interleaving review items even if no due schedule exists.
- Incorrect answers retry once before item advances.

## Accessibility
- All primary controls are at least 44x44 points.
- Buttons and key fields have accessibility labels.
- Contrast is readable in default light mode.
- Reduced-motion mode avoids strong reward motion while preserving feedback.
- UI regression test captures snapshots for key screens (home/session/summary path).

## Offline/Privacy
- App runs without network calls during gameplay.
- No cloud sync dependency.
- Data stored locally in Core Data.
