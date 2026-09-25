# UX matrix

Automated layout checks across iPhone and iPad simulators, in portrait and landscape,
so layout problems show up without owning every device.

`MathQuestKidsUITests/LayoutMatrixUITests.swift` walks:

- the core flow: profile setup, home, quest map, sticker book, parent gate, parent settings,
  a quest, its celebrations, and the summary
- the first-launch quest check (placement quiz)
- one quest for each of the 33 question formats

At every stop it rotates the device, takes a screenshot, and records findings:

| Finding | Meaning |
|---|---|
| Unreachable | A control can't be brought on screen, even by scrolling. Required controls (such as Submit) also fail the test. |
| Overlap | Two on-screen elements partly cover each other. |
| Clipped | Something is cut off at a screen edge. Expected for sideways-scrolling carousels. |
| Below the fold | A primary control (for example Submit) needs scrolling to reach. |
| Small target | A tap area is under Apple's 44×44 pt minimum. |

Only an unreachable required control, a screen that never appears, or a crash fails the run.
Everything else is for review, because carousels and decorative layers make those checks noisy.

## Devices

`pick_simulators.py` creates dedicated `UX …` simulators on the newest iOS runtime:
iPhone SE (3rd generation), iPhone 17, iPhone 17 Pro Max, iPad mini, iPad (A16), and
iPad Pro 13-inch. Each falls back to a similar model if the runtime lacks it.

## Running it

In CI, `.github/workflows/app-checks.yml` runs on pushes and pull requests that touch the
app, weekly, and on demand (Actions → App checks → Run workflow). Each device runs in
parallel. Results appear in three places:

- the run's summary page: a findings table per device and a list of screens to look at
- the `ux-matrix-report` artifact: `index.html` with every screenshot side by side
- the `ux-matrix-report` branch: the same report, replaced on each run of `main`, `claude/*`
  branches, the weekly schedule, and manual runs

Locally, with Xcode 26:

```bash
scripts/ux-matrix/run.sh                          # all six devices (about an hour)
scripts/ux-matrix/run.sh iphone-small ipad-large  # just these
open build/ux-matrix/report/index.html
```
