# Sprout Math promo videos

Three short videos edited in [Remotion](https://www.remotion.dev) from real footage of the app:

| Video | Size | Length | For |
|---|---|---|---|
| `Overview` | 1920×1080 | 46 s | Website hero, LinkedIn: themes, a quest, the parent dashboard, curriculum |
| `OnPaper` | 1080×1080 | 32 s | LinkedIn feed: column-by-column arithmetic and its coaching |
| `Parents` | 1080×1080 | 36 s | LinkedIn feed: the parent zone, dashboard, Common Core mapping, privacy |

Everything on screen comes from the app: the footage is the app running in the iOS
simulator, and the mascots, backgrounds, fonts, icon and voice clips are copied from
`MathQuestKids/`. The music and sound effects are synthesized by `audio/make_audio.py`, so
they're original and free to use anywhere. The numbers quoted (3,000+ questions, 49 lesson
plans, 65 Common Core standards) are counts of the app's content files.

## How the footage is made

The **Promo capture** workflow (`.github/workflows/promo-capture.yml`) runs
`scripts/promo/capture.sh`, which records an iPhone and an iPad simulator while
`MathQuestKidsUITests/PromoCaptureUITests.swift` plays through each scene. The app starts
with `-ui-test -promo-demo`: an in-memory sample second grader, Maya, with ten days of
quests (see `MathQuestKids/App/DemoProgress.swift`). Each scene's test logs its steps and
taps with timestamps; the edit uses them to cut on the right moment and to draw a finger
ripple where each tap landed. The footage is published to the `promo-footage` branch.

The workflow runs on pushes that touch those files, or from the Actions tab.

## Rendering

```bash
cd promo
npm install
python3 scripts/prepare_assets.py   # the app's art, fonts and voice clips -> public/app
python3 audio/make_audio.py         # music and sound effects -> public/audio
scripts/fetch_footage.sh            # footage -> public/footage, timings -> src/footage.json
npm run render                      # -> out/*.mp4 and a poster frame for each
npm run studio                      # or preview and tweak them in the browser
```

Rendering needs Chrome's headless shell; set `REMOTION_BROWSER` to its path if Remotion
can't download one.

## Changing things

- Copy, captions and the call to action live in `src/videos/*.tsx`.
- Sections start on the music's bar lines (120 BPM, 60 frames a bar at 30 fps); keep
  new cuts on multiples of `BAR` so they land on the beat.
- An Instagram Reels/Stories cut (1080×1920) can reuse the same components with the
  iPhone footage: add a composition in `src/Root.tsx`.
