# Audio Feedback and Spatial Exercise Roadmap

Date: 2026-04-26

## Current State

MathQuest Kids already has strong question narration coverage:

- `content-pack-v1.json` has 38 units, 40 lessons, and 2,472 practice templates.
- Every practice template currently has a matching entry in `Audio/audio_index.json`.
- `Audio/audio_index.json` has 3,182 entries:
  - 3,092 question clips
  - 35 companion clips
  - 27 diagnostic clips
  - 17 feedback clips
  - 10 lead-in clips
  - 1 system clip

The weak point is not missing item audio. The weak point is the feedback model:

- `NarrationService.speakFeedback` still depends on exact text matching.
- The feedback pool is small compared with the number of learning states a child can be in.
- Current spoken feedback is mostly tied to broad buckets: correct, incorrect, hint, sticker, session end, diagnostic.
- `SessionView.questFeedback` generates richer domain-specific feedback text, but most of those strings do not have matching pre-recorded audio, so they fall back to device TTS.

There is also prompt repetition in generic visual formats:

- 35 `countAndMatch` items say "How many dots? Tap the number."
- 30 `measureLength` items say "How many units long is this object?"
- 30 `angleMeasure` items say "What is the measure of this angle in degrees?"
- Shape items repeat attribute prompts for the same shape families.

## Product Direction

Do not try to future-proof by recording every possible generated question forever. That gets expensive, brittle, and still misses new content.

Instead, future-proof the app with a layered audio system:

1. Record a large set of studio-quality feedback and coaching clips.
2. Record domain-specific strategy lines for the most common mistake states.
3. Record prompt variants for repetitive visual formats.
4. Record small vocabulary and phrase banks for future dynamic templates.
5. Keep full-question recordings for early-grade and high-frequency templates where narration matters most.

This makes the app feel much less repetitive even if the underlying question set remains the same.

## Recommended Recording Batches

### Batch 1: Must Record Before Subscription Expires

Target: 450-650 clips

This gives the highest product impact per generated clip.

| Category | Target Count | Why |
| --- | ---: | --- |
| Correct feedback by state | 80 | Avoids hearing the same 5 success lines repeatedly. |
| Retry feedback by attempt number | 80 | Makes mistakes feel coached, not generic. |
| Hint intros and transitions | 45 | Gives hints a warmer companion feel. |
| Domain-specific coaching | 160 | Covers the formats the app already uses. |
| Session pacing | 35 | Start, middle, last question, comeback, finished. |
| Reward and sticker lines | 60 | Rewards become more emotional and less mechanical. |
| Spatial and geometry vocabulary | 70 | Prepares for new shape/spatial exercises. |
| Safety and settings/system lines | 20 | Handles voice preview, offline fallback, muted audio. |

### Batch 2: Strong Future-Proof Pack

Target: 1,200-1,600 clips

Adds broad variety without exploding asset size.

| Category | Target Count | Why |
| --- | ---: | --- |
| Batch 1 clips | 450-650 | Foundation. |
| K-1 full prompt variants | 250 | Early readers benefit most from complete narration. |
| Generic visual prompt variants | 180 | Fixes repeated dots, rulers, clocks, graphs, angles. |
| Spatial exercise prompts | 220 | Enables new shape hunt, rotate, symmetry, grid tasks. |
| Worked-step micro explanations | 220 | Lets correction overlays speak naturally. |
| Companion personality variants | 120 | Different themes/companions can feel distinct. |

### Batch 3: Maximum Archive Pack

Target: 2,500-3,500 clips

Use this only if the generation window is cheap and fast enough. It would include full prompt variants for every existing high-use unit, all Batch 2 clips, and multiple tones for common feedback lines.

## Feedback Audio Taxonomy

The important implementation change is to stop selecting audio by exact text. Feedback should be event-driven:

```json
{
  "id": "fb-correct-after-hint-012",
  "text": "That hint helped you spot the important part. Nice fix.",
  "category": "feedback.correct",
  "tone": "warm",
  "state": "correctAfterHint",
  "domains": ["any"],
  "minGrade": "K",
  "maxGrade": "5",
  "cooldown": 12,
  "weight": 1.0,
  "file": "feedback/correct/fb-correct-after-hint-012.mp3"
}
```

The selector should use:

- `event`: correct, incorrect, hint, correction, reward, sessionStart, sessionEnd.
- `attemptState`: firstTry, secondTry, afterHint, comeback, repeatedMiss, idk.
- `format`: countAndMatch, shapeClassification, measureLength, areaTiling, etc.
- `unit`: kShapeAttributes, g1MeasureLength, g3AreaConcept, etc.
- `tone`: calm, playful, energetic, storyteller.
- `recentAudioIDs`: prevent repeats with a no-repeat window.

This one change will make even 300 new clips feel much larger.

## Recording Script Examples

### Correct: First Try

- "Yes, first try. You saw it quickly."
- "That clicked right away. Nice thinking."
- "You matched the answer on the first try."
- "Clean solve. You knew what to look for."
- "That was careful and quick."
- "You found the important clue."
- "Nice work. Your strategy was ready."
- "That answer fits perfectly."
- "You solved it without needing a hint."
- "Great start. Keep that focus."

### Correct: After Retry

- "Nice fix. You changed your thinking and got it."
- "That is how learning works. Try, adjust, solve."
- "You checked it again and found the answer."
- "Good comeback. You stayed with the problem."
- "You used the mistake to find the right path."
- "That second look helped."
- "You corrected the tricky part."
- "You kept going and solved it."
- "Strong persistence. That answer is right."
- "You made a smart adjustment."

### Correct: After Hint

- "That hint helped you spot the clue."
- "Nice use of the hint. You did the thinking."
- "You followed the strategy and got it."
- "Good job turning the hint into an answer."
- "The helper gave you a start, and you finished it."
- "That is a strong way to use support."
- "You checked the visual and chose well."
- "Nice. The hint pointed the way, and you solved it."
- "You used the step carefully."
- "Great learning moment."

### Retry: First Miss

- "Not quite yet. Take another look."
- "Close thinking. Check one part again."
- "Good try. There is one clue to revisit."
- "Almost. Slow down and test it."
- "You are near it. Try one more time."
- "That answer does not fit yet."
- "Pause and compare before you tap."
- "Look back at the picture."
- "Check the numbers one more time."
- "Try a different strategy."

### Retry: Repeated Miss

- "Let's use a hint before the next try."
- "This one is being tricky. We can break it into steps."
- "Pause with me. What do we know first?"
- "Let's find the first clue together."
- "You do not have to guess. Use the visual helper."
- "Let's slow this one down."
- "Try naming the parts before choosing."
- "A smaller step will help here."
- "Let's check the picture and the answer choices."
- "We can solve this one piece at a time."

### Correction Overlay

- "The answer is {answer}. Let's see why."
- "Watch the first step, then you will get the next one."
- "Here is the part that mattered."
- "This answer works because the picture shows it."
- "Let's solve it together once."
- "The trick was to compare the biggest place first."
- "The trick was to count each object only once."
- "The trick was to find the equal parts."
- "The trick was to count rows and columns."
- "The trick was to trace the sides and corners."

### Hint Intros

- "Here is a small clue."
- "Let's make the problem easier to see."
- "Try this helper."
- "Look at it this way."
- "I will show one step."
- "Let's use the picture."
- "Here comes a strategy clue."
- "This hint can help you check."
- "Try the visual first."
- "Let's find the important part."

### Session Pacing

- "First question. Let's warm up."
- "You are moving through the quest."
- "Halfway there. Keep your thinking steady."
- "Last question. Finish strong."
- "You got through a tricky stretch."
- "Nice focus this round."
- "You solved a lot of math today."
- "That session is complete."
- "You earned progress for showing up."
- "Let's do one more careful solve."

### Rewards

- "New sticker earned."
- "That sticker is for your persistence."
- "Your sticker book just grew."
- "A new reward is ready."
- "You unlocked something fun."
- "That was earned by real thinking."
- "You completed the step and earned a prize."
- "The collection has a new piece."
- "You made progress and got a reward."
- "Nice work. Your reward is ready."

## Domain-Specific Feedback Lines To Record

### Counting

- "Touch each dot once, then say the last number."
- "The last number you count tells the total."
- "Try moving left to right so you do not count twice."
- "You matched the group to the number."
- "Good counting. Each object got one number."

### Addition and Subtraction

- "Put the groups together to find the total."
- "Count on from the bigger number."
- "Take away the removed group, then count what is left."
- "The missing part plus the known part makes the whole."
- "You checked the whole and the parts."

### Place Value

- "Compare tens first, then ones."
- "Build the tens before the ones."
- "The hundreds place is the biggest clue."
- "Expanded form can show the number clearly."
- "You matched the blocks to the number."

### Fractions

- "Equal parts matter first."
- "The denominator tells how many equal pieces."
- "The numerator tells how many pieces are shaded."
- "When denominators match, compare the numerators."
- "When numerators match, fewer pieces means bigger pieces."

### Measurement, Data, and Geometry

- "Start measuring at zero."
- "Count the spaces, not just the marks."
- "Read the bar from the label up to the top."
- "Rows times columns gives the area."
- "A right angle is 90 degrees."

### Shapes and Spatial Reasoning

- "Trace the sides with your finger."
- "Corners are where two sides meet."
- "Rotate it in your mind before choosing."
- "A matching shape can be turned and still match."
- "A line of symmetry makes two mirror halves."
- "Inside, outside, above, below, and between are position clues."
- "A cube has flat square faces."
- "A cylinder can roll and has two circle faces."
- "A cone has one point and one circle face."
- "A sphere is round all the way around."

## Existing Prompt Repetition Fixes

These can be fixed through prompt variants without changing the underlying math.

### Count And Match

Current repeated prompt: "How many dots? Tap the number."

New variants:

- "Count the dots. Which number matches?"
- "How many dots do you see?"
- "Touch each dot as you count. What is the total?"
- "Find the number that matches the dots."
- "Count every dot one time."
- "Which answer shows the dot total?"
- "Say the numbers as you count the dots."
- "Look carefully. How many dots are there?"
- "Count the group and tap the total."
- "What number belongs with this group?"

### Measure Length

Current repeated prompt: "How many units long is this object?"

New variants:

- "Start at zero. How long is the object?"
- "Count the unit spaces. What is the length?"
- "How many ruler units does it cover?"
- "Measure from the start to the end."
- "What number does the object reach?"
- "Count the spaces along the ruler."
- "Find the length in units."
- "Which length matches the object?"
- "Use the ruler to measure the object."
- "How many equal units long is it?"

### Angle Measure

Current repeated prompt: "What is the measure of this angle in degrees?"

New variants:

- "How wide is this angle?"
- "Choose the angle measure."
- "Is it smaller or bigger than 90 degrees?"
- "What degree measure matches the opening?"
- "Read the angle and choose the degrees."
- "How many degrees does this angle show?"
- "Find the measure of the angle."
- "Compare it to a right angle, then choose."
- "What number belongs on the angle?"
- "Which degree answer fits?"

### Shape Classification

Current repeated pattern: "This shape has {sides} sides and {corners} corners. What is it?"

New variants:

- "Trace the sides. Which shape is this?"
- "Count the corners. What shape do you see?"
- "This shape has {sides} sides. What is its name?"
- "Which shape matches these attributes?"
- "Look at the sides and corners. Name the shape."
- "Find the shape with {sides} sides."
- "Which answer names this shape?"
- "What shape has these sides and corners?"
- "Use the attributes to choose the shape."
- "Look closely. What is this shape called?"

## New Exercise Types

### Spatial Exercises For Shapes

These would make geometry more engaging than the current side/corner classifier.

| Exercise | Grade Band | Interaction | Audio Needs |
| --- | --- | --- | --- |
| Shape Hunt | K-1 | Tap every triangle, circle, square, etc. in a scene. | Shape names, "tap all", "you found another one", missed-object coaching. |
| Position Words | K-1 | Choose the object above, below, beside, between, inside, outside. | Position vocabulary and short prompts. |
| Rotate To Match | K-2 | Pick the same shape after rotation. | "Turn it in your mind", match/mismatch coaching. |
| Complete The Picture | K-2 | Select the missing shape in a pattern or scene. | Pattern and shape-placement prompts. |
| Build A Shape | 1-3 | Drag smaller shapes to compose a larger shape. | Compose/decompose coaching. |
| Symmetry Mirror | 1-4 | Choose or draw the missing half across a mirror line. | Symmetry vocabulary and correction lines. |
| Grid Paths | 1-4 | Move on a grid using up/down/left/right directions. | Direction and step-count prompts. |
| Tangram Lite | 2-5 | Fit pieces into an outline, with rotation. | Rotation, flip, corner, side, and fit coaching. |
| 3D Solid Match | 2-5 | Match cube/cone/cylinder/sphere to attributes or real objects. | Face, edge, vertex, roll, stack vocabulary. |
| Nets Preview | 4-5 | Pick which flat pattern folds into a cube. | Fold, face, opposite, adjacent vocabulary. |

### Other Engagement Exercises

| Exercise | Why It Helps | Audio Needs |
| --- | --- | --- |
| Error Detective | Builds reasoning by asking "what went wrong?" | "Find the mistake", misconception-specific explanations. |
| Strategy Choice | Child chooses how they solved it: counted on, made ten, used array. | Strategy names and praise for metacognition. |
| Drag Manipulatives | Ten frames, base-ten blocks, number lines, fraction strips. | Manipulative-specific hints and confirmations. |
| Story Builder | Match a story to an equation, then solve. | Story stems and equation language. |
| Estimate First | Ask "about how many?" before exact answer. | Estimation coaching and low-pressure validation. |
| Compare Before Calculate | Pick bigger/smaller before computing. | Place-value and magnitude language. |
| Explain The Visual | Tap the visual clue that proves the answer. | "What shows you know?" prompts. |

## Spatial Audio Vocabulary Pack

Record these even before all spatial exercises exist. They are reusable.

### Shape Names

- circle
- triangle
- square
- rectangle
- oval
- diamond
- rhombus
- trapezoid
- pentagon
- hexagon
- octagon
- cube
- cone
- cylinder
- sphere
- pyramid
- rectangular prism

### Attributes

- side
- sides
- corner
- corners
- angle
- angles
- face
- faces
- edge
- edges
- vertex
- vertices
- flat
- curved
- round
- point
- points
- equal sides
- parallel sides

### Spatial Words

- above
- below
- left
- right
- beside
- between
- inside
- outside
- next to
- under
- over
- near
- far
- same
- different
- match
- turn
- rotate
- flip
- slide
- mirror
- symmetry
- half
- whole

## Implementation Plan

### Phase 1: Audio System Upgrade

1. Add a metadata-based audio catalog for feedback clips.
2. Add a `FeedbackAudioEvent` type with fields for result, attempt count, hint usage, unit, format, tone, and reward state.
3. Replace exact feedback text matching with event-based selection.
4. Keep a recent-audio ring buffer so the app avoids repeats.
5. Keep TTS fallback for unrecorded lines.

### Phase 2: Prompt Variety

1. Add prompt variant support to generated visual item templates.
2. Regenerate `spokenForm` for repeated prompt groups.
3. Record or map the new prompt variants.
4. Verify all content templates still have audio-index coverage.

### Phase 3: Spatial Content

1. Add new practice formats:
   - `shapeHunt`
   - `positionWords`
   - `rotateToMatch`
   - `symmetryMirror`
   - `gridPath`
   - `solidAttributes`
2. Add payload fields for:
   - target shape
   - distractor shapes
   - rotation degrees
   - mirror axis
   - grid coordinates
   - solid attributes
3. Add SwiftUI interaction views for each format.
4. Add hint engine branches for each format.
5. Add audio prompt and feedback mappings.

### Phase 4: Content Generation

Generate spatial templates in this order:

1. K shape hunt: 80 templates
2. K-1 position words: 80 templates
3. K-2 rotate to match: 80 templates
4. 1-3 build/decompose shape: 60 templates
5. 1-4 symmetry mirror: 60 templates
6. 1-4 grid paths: 80 templates
7. 2-5 3D solid attributes: 80 templates
8. 4-5 cube nets preview: 40 templates

This adds about 560 spatial templates without needing thousands of one-off recordings.

## Recommendation

Use the remaining ElevenLabs window for Batch 1 and Batch 2, not for recording every existing question again.

The best immediate path is:

1. Generate a 600-clip "must have" feedback and coaching pack.
2. Generate a 1,200-clip "future spatial and prompt variety" pack if time allows.
3. Implement event-based audio selection so those clips actually reduce repetition.
4. Add prompt variants for the currently repetitive visual formats.
5. Add spatial exercises after the audio vocabulary pack is ready.

This gives MathQuest Kids a better voice personality now, while also preparing the asset library for richer geometry and spatial reasoning later.

## Generated Artifacts

Created on 2026-04-26:

- `MathQuestKids/Content/spatial-question-bank-v2.json`
  - 560 draft spatial questions.
  - 0 duplicate spoken prompts.
  - Kept out of `content-pack-v1.json` until the Swift runtime supports the new formats.
- `scripts/audio_recording_set_2026_04_26.json`
  - 1,242 unique recording clips.
  - 482 `must_have` clips and 760 `strong_pack` clips.
  - 0 duplicate recording texts.
- `scripts/audio_recording_set_2026_04_26.csv`
  - Spreadsheet-friendly copy of the same recording backlog.
- `scripts/generate_future_question_audio_sets.py`
  - Deterministically regenerates the spatial question bank and recording set.
- `scripts/generate_audio_from_recording_set.py`
  - Generates MP3s from the recording set when `ELEVENLABS_API_KEY` is available.

The recording set breakdown is:

| Category | Clips |
| --- | ---: |
| question.spatial | 560 |
| coaching.domain | 96 |
| feedback.correction | 92 |
| feedback.correct | 82 |
| vocabulary.spatial | 74 |
| companion.theme | 72 |
| prompt.k1 | 64 |
| prompt.variant | 64 |
| feedback.retry | 46 |
| feedback.hint | 32 |
| feedback.reward | 20 |
| feedback.session | 20 |
| system | 20 |

To generate only the urgent subscription-expiring set:

```bash
ELEVENLABS_API_KEY=... python3 scripts/generate_audio_from_recording_set.py --priority must_have
```

To generate the full set:

```bash
ELEVENLABS_API_KEY=... python3 scripts/generate_audio_from_recording_set.py
```
