# Voice Enhancement Plan: character voices with ElevenLabs V4

Date: 2026-10-11. Scope: ElevenLabs only (no other voice services).

**Confidence labels used below**

| Label | Meaning |
|---|---|
| **[REPO]** | Measured or counted from this repository. Reproducible. |
| **[READ]** | Read directly from an official ElevenLabs file on GitHub (`elevenlabs/skills`, `elevenlabs-python`). |
| **[SEARCH]** | Taken from a search summary of an official ElevenLabs page. `elevenlabs.io` is blocked from this build environment, so the page itself was not read. Confirm on the live page. |
| **[3RD-PARTY]** | Taken from a non-ElevenLabs article. Treat as a lead only. |

The task listed "ElevenLabs V4 documentation or feature list" as an input but did not supply it, so the V4 facts come from research, labeled as above.

---

## 1. Bottom line

1. **Use `eleven_v4` for the character voices, and keep the current voice and model for the existing question narration.** Re-recording 3,000+ question clips is not needed to get character personality, and mixing models inside one narrator would make the app sound inconsistent.
2. **Subscription: start on Creator, step up to Pro for one billing month only if the verified V4 credit rate makes the bulk run exceed Creator's allowance.** Creator is the lowest tier that appears to cover 18+ saved voices, the commercial licence and Voice Design. This is a decision rule, not a firm tier, because the V4 credit rate could not be verified (section 6).
3. **Before spending anything, get written confirmation from ElevenLabs that a children's app is permitted.** Their Prohibited Use Policy reportedly forbids experiences directed at people under 18 unless approved in writing **[SEARCH]**. The app already ships ElevenLabs audio, so this applies today as well as to the new work.
4. **Record about 3,300 character clips (about 106,000 characters), not 7,000.** That covers each of the 18 companions' own lines plus their feedback variants. Section 5 sizes three tiers.
5. **Do not reuse the current generator scripts as they are.** They send `style` and `use_speaker_boost`; V4 reportedly accepts only `stability` and `similarity_boost` **[READ]**.
6. **Pricing is moving right now.** ElevenLabs' own V4 banner says "3x credits included on Creator+ until October 12" **[SEARCH]**, which is tomorrow. Check the live pricing page before choosing.

---

## 2. What exists today [REPO]

| Fact | Value | How measured |
|---|---|---|
| Voice | One shared voice, "Sparkles for Kids" (`tapn1QwocNXk3viVSowa`) | `scripts/generate_audio.py:22` |
| Model | `eleven_turbo_v2_5` (not the original model) | `scripts/generate_audio.py:23`, `generate_missing_audio.py:14` |
| Voice settings sent | stability 0.65, similarity_boost 0.80, style 0.35 | same files |
| Files | 4,367 MP3, 243 minutes, 235 MB | `ffprobe` over every file |
| Format | MP3, 44,100 Hz, mono, 128-133 kbps (equals the API default `mp3_44100_128`) | `ffprobe`, all 4,367 files |
| Loudness | Median -18.3 LUFS; 10th to 90th percentile -20.9 to -15.5; range -26.5 to -14.0 (63-clip sample); true peak median -2.3 dBFS | `ffmpeg ebur128` |
| Characters | 18 named companions: 6 themes x 3, tones split 6 energetic / 6 encouraging / 6 calm | `CharacterPacks.swift` |
| How companion audio is chosen | By **tone**, never by character: a hard-coded text-to-file table such as `"Boom! Nailed it!" -> companion-correct_energetic-00` | `NarrationService.swift` (`companionMappings`) |
| Text already written for a character-voiced pool | 364 clips, 12,701 characters (feedback correct/retry/hint/session/reward/correction + themed companion lines) | `Audio/future/audio_recording_set_2026_04_26.json` |

The "required audio format" was not specified, so this plan keeps the format the app already plays: **MP3, 44.1 kHz, mono, `output_format=mp3_44100_128`.**

---

## 3. What ElevenLabs V4 offers

| Capability | Detail | Source |
|---|---|---|
| Model ids | `eleven_v4` (highest quality) and `eleven_v4_turbo` (about 100 ms, real-time) | **[READ]** `elevenlabs/skills` `text-to-speech/SKILL.md` |
| Status | Released 2026-09-28; stated as available on every plan | **[SEARCH]** ElevenLabs docs changelog, help centre |
| Emotion control | Inline audio tags in square brackets, e.g. `[excited]`, `[whispers]`, `[laughs]`, `[sighs]`. Tags are natural language, not a fixed list; punctuation (ellipses, capitals) also shapes delivery | **[READ]** `references/voice-settings.md`; **[SEARCH]** ElevenLabs blog |
| Voice settings | Only `stability` and `similarity_boost`. No `style`, no `speed`, no SSML | **[READ]** `references/voice-settings.md` |
| Character-voice starting point | "Character Voices / Drama" preset: stability 0.3, similarity_boost 0.8, with text such as `[excited] We did it! [laughs]` | **[READ]** same file |
| Guidance on stability | Lower is more emotional but can sound erratic; higher is steadier | **[READ]** same file |
| Tag advice | One emotion per phrase; swap the tag rather than rewriting the text; do not ask a calm voice to shout; tags are "not perfect yet" | **[SEARCH]** ElevenLabs best-practices and help-centre pages |
| Request stitching | `previous_text` / `next_text` supported | **[READ]** SKILL.md |
| Streaming | Not available on the `stream-input` WebSocket; plain REST works (what the app's pre-generation uses) | **[READ]** SKILL.md |
| Characters per request | 10,000 for V4 (clips here are under 200) | **[SEARCH]** |
| Output formats | `mp3_22050_32`, `mp3_24000_48`, `mp3_44100_32/64/96/128/192`, Opus, PCM, WAV, u-law/a-law; default `mp3_44100_128`; `mp3_44100_192` marked Creator+ | **[READ]** `elevenlabs-python` output-format type, SKILL.md |
| Voice creation | Voice Design (text description of 20-1,000 characters returns previews, then save), Instant Voice Cloning, Professional Voice Cloning (Creator+, 1 slot) | **[SEARCH]** ElevenLabs API reference and docs |
| Saved-voice slots | Free 3, Starter 10, Creator 30, Pro 160, Scale 660 (article is old; may be stale) | **[SEARCH]** help centre |
| Determinism | `seed` exists; "determinism is not guaranteed" | **[SEARCH]** API reference |

**Not confirmed:** whether `seed`, `use_speaker_boost` or the Creative/Natural/Robust stability presets apply to V4; V4's concurrency limit; whether a Voice Design voice made on an older design model sounds right on V4.

---

## 4. Risks that gate the work

| # | Risk | Evidence | Action |
|---|---|---|---|
| 1 | **Children's-app policy.** The Prohibited Use Policy reportedly bars apps or experiences directed at under-18s unless ElevenLabs has approved them in writing, and requires parental consent where the law demands it | **[SEARCH]** agent summary. My own search could not find the clause text, so it is unverified | Read `elevenlabs.io/use-policy` and the ElevenAPI terms; email ElevenLabs asking specifically about pre-generated audio in a COPPA-relevant app for ages 5-11. Do not buy the bulk plan until answered |
| 2 | **Child-like voices.** Child-like voices cannot be published to the Voice Library, and the policy prohibits likenesses of real minors | **[SEARCH]** help-centre article | Design animal, robot and hero voices that are clearly not child-sounding. Never upload a recording of a child |
| 3 | **Pricing and promotion.** V4 launch pricing ends 2026-10-12; list pricing afterwards is unclear | ElevenLabs banner **[SEARCH]**; one article says V4 list is $0.08 per 1K characters versus $0.022 promotional **[3RD-PARTY]** | Open `elevenlabs.io/pricing` and `/pricing/api` the day you buy. Re-run the section 6 arithmetic with the real numbers |
| 4 | **Existing scripts break on V4 settings.** `style` and `use_speaker_boost` are sent today | **[REPO]** + **[READ]** | Write a V4 generator that sends only `stability` and `similarity_boost`; test one clip first |
| 5 | **Commercial rights.** Content from paid plans can be used commercially; the free plan cannot | **[SEARCH]** | Generate only on a paid plan |
| 6 | **Tag reliability.** Tags sometimes misfire or are read as sound effects | **[SEARCH]** | Audition every tag per voice; keep a per-line retry budget (the cost model assumes 2x) |

---

## 5. Scope: what to record

Counts are exact and come from the Swift source and the existing recording set.

| Tier | Contents per character | Clips (x18 characters) | Characters of text |
|---|---|---:|---:|
| **1. Character core** | The 9 MascotVoice lines plus the CompanionPhrases pool for the character's own tone (25-26 distinct lines) | 462 | 11,352 |
| **2. Character feedback** (recommended) | Tier 1, plus the correct (82), retry (46) and hint (32) variants from the recording set | 3,342 | 106,320 |
| **3. Everything in the pool** | Tier 1, plus all 364 pool clips per character | 7,014 | 239,970 |

Tier 3 is not recommended: the app picks one variant at random per event, so 364 variants per character add cost and bundle size for little audible gain.

Add to every tier a one-off **audition budget** of 12,960 characters (18 voices x 6 emotion test lines x about 40 characters x 3 takes).

**Separate, small job: patch the narrator.** The verification report flags 172 question clips whose narration is missing or has to change: 35 clips with no audio file, 56 that keep a fraction such as "4/7" as digits, 50 with "1 sixths" / "halfs" grammar, 20 gridPath lines that never say the moves, 7 that ask "which is bigger" about equal numbers, and 4 impossible "how many more" prompts. They are 152 core-bank clips (4,849 characters) and 20 spatial clips (1,316 characters), 6,165 characters in all. Regenerate them with the **current voice and `eleven_turbo_v2_5`**, so the narrator stays consistent. This is independent of the character work. Fix the question text first (see the verification report), then regenerate. Any spatial prompts rewritten to fix the on-screen problems in the report will need new clips too; that count is not included here.

### Character roster and voice brief

Species come from the art file names in `characters/`; the three turbo-car characters have no art in that folder, so confirm theirs.

| Theme | Character | Role / title | Tone | Voice brief (starting point for Voice Design) |
|---|---|---|---|---|
| Candyland | Benny (bear) | Candy Sky Pilot | energetic | Big, bouncy, warm bear; lots of rise and fall; never shouty |
| Candyland | Sprinkle (fox) | Sweet Strategy Coach | encouraging | Bright, kind, quick; smiling delivery |
| Candyland | Taffy (bunny) | Challenge Ranger | calm | Light, patient, soft-spoken |
| Reef | Coral (axolotl) | Lagoon Explorer | calm | Slow, gentle, slightly dreamy |
| Reef | Finn (seahorse) | Pattern Hunter | energetic | Quick, curious, playful |
| Reef | Pearl (jellyfish) | Reasoning Guide | encouraging | Soft, thoughtful, reassuring |
| Unicorn | Sparkle (unicorn) | Rainbow Pathfinder | encouraging | Warm, sunny, gently theatrical |
| Unicorn | Clover (pegasus) | Fraction Fairy | calm | Airy, soothing, precise |
| Unicorn | Dizzy (cloud pup) | Number Whisperer | energetic | Giddy, wiggly, fast but clear |
| Space | Cosmo (robot) | Galaxy Navigator | energetic | Friendly synthetic character voice, clear consonants |
| Space | Luna (space cat) | Array Engineer | calm | Low, smooth, unhurried |
| Space | Zip (alien) | Mission Analyst | encouraging | Quirky, upbeat, a little squeaky but not child-like |
| Superhero | Captain Calc | Number Champion | energetic | Confident hero, heroic but friendly |
| Superhero | Nova Shield | Strategy Defender | calm | Steady, protective, measured |
| Superhero | Dash Digit | Speed Solver | encouraging | Fast, upbeat, supportive |
| Turbo cars | Rev | Racing Engineer | energetic | Revving enthusiasm, crisp |
| Turbo cars | Axle | Pit Crew Chief | calm | Grounded, steady, practical |
| Turbo cars | Tread | Track Analyst | encouraging | Even, proud, coach-like |

### Emotion palette per tone (starting values to audition, not documented defaults)

| Tone | Stability | Similarity | Tags to try (one per phrase) | Used for |
|---|---:|---:|---|---|
| energetic | 0.30 (the documented character preset) | 0.80 | `[excited]`, `[laughs]`, `[cheering]` | correct, reward, sticker, lesson start |
| encouraging | 0.45 | 0.80 | `[warmly]`, `[proud]`, `[gently]` | retry, hint intro, session end |
| calm | 0.70 | 0.80 | `[calm]`, `[softly]`, `[reassuring]` | hints, corrections, "I don't know yet" |

Only stability 0.3 / similarity 0.8 and the tags `[excited]`, `[laughs]`, `[whispers]`, `[sighs]` appear in the official files that were read; every other value and tag is a hypothesis to test in the audition step.

---

## 6. Subscription choice and cost

### Inputs

| Input | Value |
|---|---|
| Text volume | Tier 1: 11,352; Tier 2: 106,320; Tier 3: 239,970 characters |
| Retry factor | 2x on production text (assumption; tags misfire) |
| Audition budget | 12,960 characters, not doubled |
| **Total characters to generate** | Tier 1: **35,664**; Tier 2: **225,600**; Tier 3: **492,900** |

### Two cost models (neither verified on the live page)

| Model | Rate | Tier 1 | Tier 2 | Tier 3 |
|---|---|---:|---:|---:|
| **A. Plan credits**, 1 credit per character **[SEARCH]** | Creator $22/mo for 121,000 credits; Pro $99/mo for 600,000; Scale $299/mo for 1,800,000 **[SEARCH]** | Fits Creator | **Exceeds Creator, fits Pro (38%)** | Fits Pro (82%) |
| **B. API list price** (V4 about $0.08 per 1K characters; $0.022 promotional) **[3RD-PARTY]** | per 1K characters | $2.85 list / $0.78 promo | $18.05 / $4.96 | $39.43 / $10.84 |

Third-party pages disagree with each other on both credits and V4 rates, so treat the dollar figures as an order of magnitude.

### Recommendation

| Step | Plan | List price | Why |
|---|---|---:|---|
| Month 1, weeks 1-2 | **Creator** | $22 | 30 saved voices **[SEARCH]** covers 18 characters; commercial rights; Voice Design; enough credits for the audition and Tier 1 under Model A |
| Month 1, week 3 (only if needed) | **Pro**, for one billing month | $99 | Needed only if live V4 credit cost makes Tier 2 exceed Creator's allowance. Downgrade afterwards; the finished MP3s are yours to keep on a paid plan **[SEARCH]** |
| After | Free, or Creator | $0-22 | No ongoing generation load once the files are in the app |

Expected total: **about $22 to $121 in plan fees** (list prices, monthly billing, unverified), plus roughly $5-40 if API-priced overage applies. Starter is not recommended: its 10-voice slot limit **[SEARCH]** is below the 18 needed.

---

## 7. Steps and timeline

The timeline is a planning estimate, not a measurement. Human listening time dominates; the generation itself is minutes (about 3,300 short clips at a concurrency of 5-10 requests).

| Phase | Work | Output | Elapsed |
|---|---|---|---|
| 0. Gates | Written answer from ElevenLabs on child-directed use (risk 1); read the live pricing page and confirm the credit rate for `eleven_v4`; subscribe to Creator | Go / no-go; confirmed rate | 2-5 days (waiting on ElevenLabs) |
| 1. Voice design | For each of the 18 characters, write a Voice Design description from the section 5 brief (20-1,000 characters), generate previews, save the winner. Record voice ids in `scripts/character_voices.json` | 18 voice ids; one narrator unchanged | 3-4 days |
| 2. Audition | Per voice: 6 test lines covering praise, retry, hint, celebration, calm, and one `[laughs]`/`[sighs]` line. Adjust stability and tags; lock per-character settings. A parent or teacher listens for tone and clarity at child listening level | Locked settings table | 3-4 days |
| 3. Line manifest | Add emotion tags to the Tier 1 and Tier 2 lines in a manifest that records `characterId`, `voiceId`, `text`, `taggedText`, `stability`, `similarity_boost` | `character_audio_manifest.json` | 2 days |
| 4. Generate | New V4 script: `model_id=eleven_v4`, `output_format=mp3_44100_128`, only `stability` and `similarity_boost`; one clip first, then Tier 1, then Tier 2; 429 back-off; store the SHA-256 of the exact text sent | MP3s plus generation record | 1-2 days |
| 5. Normalise and QA | Run the acceptance checks in section 9; loudness-match to the existing set | Passing clip set | 2 days |
| 6. App integration | Section 8 | Characters speak in their own voices | 3-5 days of Swift work |
| 7. Narrator patch | Fix the question text found by the verifier, then regenerate the 172 flagged clips in the current voice | Verified audio | 1 day |

Total elapsed: **about 3-4 weeks**, dominated by phases 0, 2 and 6.

---

## 8. Changes needed in the app and scripts [REPO]

1. `NarrationService.companionMappings` is a hard-coded text-to-file table keyed by tone. Add a `characterId` dimension (for example `companion/<characterId>/<event>-NN.mp3`) and fall back to the existing tone clip when a character clip is missing, so nothing goes silent during the roll-out.
2. `audio_index.json` has no character field. Extend its schema or add a second index loaded the same way `audio_recording_set_2026_04_26_index.json` already is.
3. New generator script (do not edit the old ones): reads `character_voices.json` and the manifest, sends V4 settings only, writes the text hash.
4. **Bundle size.** Existing audio is 235 MB. Tier 2 adds about 3,300 clips; at the current mean of about 54 KB per clip that is roughly 180 MB. Options: keep 128 kbps (matches the rest), or generate character clips at `mp3_44100_96` or `mp3_44100_64` (both listed in the API **[READ]**) and compare quality in the audition, or ship them as on-demand resources.
5. Tier 1 alone adds about 25 MB.

---

## 9. Acceptance checks (all deterministic)

| Check | Pass condition |
|---|---|
| Container and codec | `ffprobe`: codec `mp3`, 44,100 Hz, 1 channel, 120-135 kbps |
| Duration | Greater than 0.3 s and less than 12 s |
| Text provenance | Manifest SHA-256 equals the SHA-256 of the current line text (closes the 966 "unproven" warnings for these clips) |
| Coverage | One clip per (character, line) in the manifest, no extras |
| Loudness | Integrated loudness within 1.5 LU of the target (the existing set's median is -18.3 LUFS; choose one target and normalise everything new to it); true peak at or below -1.0 dBFS |
| Question bank | `python3 -I scripts/verify_question_bank.py` reports 0 ERROR |
| Listening | A named listener signs off each voice's six audition lines before bulk generation |

---

## 10. Open questions to answer on the live ElevenLabs pages

1. Does ElevenLabs approve a children's app (ages 5-11) using pre-generated audio, and what is the written process? (risk 1)
2. What is the credit cost per character for `eleven_v4` on subscription plans, and is API usage billed in credits or dollars? What changes after 2026-10-12?
3. Does `eleven_v4` ignore or reject `style` and `use_speaker_boost`? Does `seed` work?
4. What is the V4 concurrency limit on Creator and Pro?
5. May a Voice Design voice be used commercially in a distributed app with embedded audio, with no attribution on paid plans?
6. Do saved Voice Design voices count against the slot limit?

## Sources

- Read directly: [`elevenlabs/skills` text-to-speech SKILL.md](https://raw.githubusercontent.com/elevenlabs/skills/main/text-to-speech/SKILL.md), [voice-settings.md](https://raw.githubusercontent.com/elevenlabs/skills/main/text-to-speech/references/voice-settings.md), [output-format type in `elevenlabs-python`](https://raw.githubusercontent.com/elevenlabs/elevenlabs-python/main/src/elevenlabs/text_to_speech/types/text_to_speech_convert_request_output_format.py).
- Search summaries of ElevenLabs pages (not opened): [Eleven v4 audio tags](https://elevenlabs.io/blog/elevenlabs-audio-tags-list), [emotional text to speech with Eleven v4](https://elevenlabs.io/blog/emotional-text-to-speech-with-eleven-v4), [terms of use](https://elevenlabs.io/terms-of-use), [use policy](https://elevenlabs.io/use-policy), [models overview](https://elevenlabs.io/docs/overview/models), [pricing](https://elevenlabs.io/pricing).
- Third-party (lead only): [Eleven v4 pricing explainer](https://www.eesel.ai/blog/eleven-v4-pricing).
