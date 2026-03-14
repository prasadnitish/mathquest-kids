#!/usr/bin/env python3
"""
Generate MP3 audio files for all MathQuest Kids narration using ElevenLabs API.
Saves files to MathQuestKids/Audio/ organized by category.

Usage:
    python3 scripts/generate_audio.py

Resumes from where it left off if interrupted (skips existing files).
"""

import json
import os
import time
import hashlib
import requests
import sys

# ── Configuration ────────────────────────────────────────────────────────────

API_KEY = "***REMOVED***"
VOICE_ID = "tapn1QwocNXk3viVSowa"  # Sparkles for Kids
MODEL_ID = "eleven_turbo_v2_5"     # Fast, good quality, cheaper
OUTPUT_DIR = "MathQuestKids/Audio"
CONTENT_PACK = "MathQuestKids/Content/content-pack-v1.json"

# ElevenLabs rate limit: ~10 req/s for paid plans, be conservative
REQUESTS_PER_SECOND = 8
REQUEST_DELAY = 1.0 / REQUESTS_PER_SECOND

VOICE_SETTINGS = {
    "stability": 0.65,          # Slightly varied for natural feel
    "similarity_boost": 0.80,   # Stay close to voice character
    "style": 0.35,              # Some expressiveness for kids
    "use_speaker_boost": True
}


# ── Helpers ──────────────────────────────────────────────────────────────────

def text_to_id(text):
    """Create a stable, filesystem-safe ID from text content."""
    return hashlib.md5(text.encode('utf-8')).hexdigest()[:12]


def generate_audio(text, output_path, retries=3):
    """Call ElevenLabs TTS API and save MP3 to disk."""
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"
    headers = {
        "xi-api-key": API_KEY,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg"
    }
    payload = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": VOICE_SETTINGS
    }

    for attempt in range(retries):
        try:
            resp = requests.post(url, json=payload, headers=headers, timeout=30)

            if resp.status_code == 200:
                os.makedirs(os.path.dirname(output_path), exist_ok=True)
                with open(output_path, 'wb') as f:
                    f.write(resp.content)
                return True

            elif resp.status_code == 429:
                # Rate limited — wait and retry
                wait = 2 ** (attempt + 1)
                print(f"  Rate limited. Waiting {wait}s...")
                time.sleep(wait)
                continue

            else:
                print(f"  ERROR {resp.status_code}: {resp.text[:200]}")
                if attempt < retries - 1:
                    time.sleep(1)
                    continue
                return False

        except requests.exceptions.RequestException as e:
            print(f"  Network error: {e}")
            if attempt < retries - 1:
                time.sleep(2)
                continue
            return False

    return False


# ── Build full manifest ──────────────────────────────────────────────────────

def build_manifest():
    """Build complete list of all text needing audio generation."""
    manifest = []

    # 1. Question spokenForms from content pack
    with open(CONTENT_PACK) as f:
        data = json.load(f)

    seen_texts = set()
    for item in data['itemTemplates']:
        text = item.get('spokenForm', item['prompt'])
        if text not in seen_texts:
            seen_texts.add(text)
            manifest.append({
                'id': item['id'],
                'category': 'questions',
                'text': text,
                'filename': f"{item['id']}.mp3"
            })
        else:
            # Duplicate text — still need a mapping but skip generation
            # We'll create a symlink or copy later
            pass

    # 2. Companion feedback phrases
    companion_phrases = {
        'correct_encouraging': [
            'Awesome job!', 'You got it!', 'Way to go!', 'Super!', 'You did it!',
        ],
        'correct_energetic': [
            'Boom! Nailed it!', 'Yes! Crushed it!', 'Woo-hoo!', 'Incredible!', 'Amazing!',
        ],
        'correct_calm': [
            'Well done.', 'Nicely solved.', 'That is correct.', 'Good work.', 'Right answer.',
        ],
        'incorrect_encouraging': [
            'Almost there!', 'Try again!', 'You can do it!', 'Keep going!', 'Nice try!',
        ],
        'incorrect_energetic': [
            'Oops! Try once more!', 'So close! Give it another shot!', 'Not quite! You got this!',
        ],
        'incorrect_calm': [
            'Not quite. Try again.', 'Close. Think it through.', 'Let us try once more.',
        ],
        'hint_intros': [
            'Here is a hint.', 'Let me help.', 'Try thinking about it this way.',
            'Want a clue?', 'How about a little help?',
        ],
        'sticker_earned': [
            'You earned a sticker!', 'New sticker unlocked!',
            'Check out your new sticker!', 'A sticker just for you!',
        ],
    }

    for sub_cat, phrases in companion_phrases.items():
        for i, text in enumerate(phrases):
            manifest.append({
                'id': f'companion-{sub_cat}-{i:02d}',
                'category': 'companion',
                'text': text,
                'filename': f'companion-{sub_cat}-{i:02d}.mp3'
            })

    # 3. Lead-in phrases
    lead_ins = [
        ('calm', 'Let us think together. '),
        ('playful-1', 'Math mission. '),
        ('playful-2', 'Puzzle time. '),
        ('playful-3', 'Your turn. '),
        ('energetic-1', 'Challenge time. '),
        ('energetic-2', 'Here comes the next one. '),
        ('energetic-3', 'Let us solve this. '),
        ('storyteller-1', 'In this quest, '),
        ('storyteller-2', 'Our story begins: '),
        ('storyteller-3', 'Listen closely, '),
    ]
    for lid, text in lead_ins:
        manifest.append({
            'id': f'leadin-{lid}',
            'category': 'leadins',
            'text': text.strip(),
            'filename': f'leadin-{lid}.mp3'
        })

    # 4. Praise / retry phrases
    praise = [
        'Great strategy!', 'You kept trying and solved it!', 'Nice math thinking!',
        'Strong effort, nice job!', 'That was careful math work!',
        'You noticed the important part. Nice job!',
    ]
    retry = [
        'Nice try. Let us look again.', 'You are learning. Try one more time.',
        'Good effort. Use the hint if you want.', 'Keep going. You can do this step.',
        'You are close. Check one part and try again.',
        'Good thinking. Adjust one step and test it again.',
    ]
    for i, text in enumerate(praise):
        manifest.append({
            'id': f'praise-{i:02d}',
            'category': 'feedback',
            'text': text,
            'filename': f'praise-{i:02d}.mp3'
        })
    for i, text in enumerate(retry):
        manifest.append({
            'id': f'retry-{i:02d}',
            'category': 'feedback',
            'text': text,
            'filename': f'retry-{i:02d}.mp3'
        })

    # 5. Session completion
    for i, text in enumerate(['Great finish!', 'Nice persistence. You did it!']):
        manifest.append({
            'id': f'session-end-{i:02d}',
            'category': 'feedback',
            'text': text,
            'filename': f'session-end-{i:02d}.mp3'
        })

    # 6. Preview voice
    manifest.append({
        'id': 'preview-voice',
        'category': 'system',
        'text': 'Hi explorer. I can read your math problems in this voice.',
        'filename': 'preview-voice.mp3'
    })

    # 7. Diagnostic feedback
    diag_fb = [
        'Thanks for showing your thinking. I will use that to choose the next challenge.',
        'Thanks for telling me. I will use that to find a better starting point.',
        'Nice number sense. I am noting how confidently that was solved.',
        'Strong thinking. I am using that strategy signal for the next question.',
        'Nice place-value thinking. That helps tune the next level.',
        'Good reasoning. I am checking how stories and equations connect.',
        'Nice noticing. That helps me place the next shape or measurement task.',
        'Careful measurement thinking. I am using that to shape the next task.',
        'Nice fraction reasoning. That gives me a clearer picture of the right level.',
    ]
    for i, text in enumerate(diag_fb):
        manifest.append({
            'id': f'diag-feedback-{i:02d}',
            'category': 'diagnostic',
            'text': text,
            'filename': f'diag-feedback-{i:02d}.mp3'
        })

    # 8. Hint encouragement lines
    hint_lines = [
        'Nice effort. Let us use a visual helper.',
        'Good thinking. Try this strategy hint.',
        'You are learning. Let us do one step together.',
    ]
    for i, text in enumerate(hint_lines):
        manifest.append({
            'id': f'hint-encourage-{i:02d}',
            'category': 'feedback',
            'text': text,
            'filename': f'hint-encourage-{i:02d}.mp3'
        })

    # 9. Diagnostic questions
    diag_questions = [
        ('diag-k-01', 'Which number is 1 more than 7?'),
        ('diag-k-02', 'Sam has 5 apples and gets 2 more. How many now?'),
        ('diag-k-03', 'Pick the shape with 4 equal sides.'),
        ('diag-g1-01', 'What is 14 as tens and ones?'),
        ('diag-g1-02', 'What is 12 minus 5?'),
        ('diag-g1-03', 'Which equation matches this story: 9 birds, 3 fly away?'),
        ('diag-g2-01', 'Which number is greater?'),
        ('diag-g2-02', 'What is 46 plus 27?'),
        ('diag-g2-03', 'A ribbon is 35 centimeters. It is cut into 20 centimeters and how many more?'),
        ('diag-g3-01', 'Which is the same as 3 times 7?'),
        ('diag-g3-02', 'Which fraction is larger?'),
        ('diag-g3-03', 'What is the perimeter of a 5 by 3 rectangle?'),
        ('diag-g4-01', 'What is 304 times 10?'),
        ('diag-g4-02', 'Which decimal is greatest?'),
        ('diag-g4-03', 'What is one half plus one fourth?'),
        ('diag-g5-01', 'What is three fifths of 20?'),
        ('diag-g5-02', 'A recipe uses 1.5 cups sugar per batch. For 4 batches?'),
        ('diag-g5-03', 'What is the volume of a prism that is 4 by 3 by 2?'),
    ]
    for did, text in diag_questions:
        manifest.append({
            'id': did,
            'category': 'diagnostic',
            'text': text,
            'filename': f'{did}.mp3'
        })

    return manifest


# ── Duplicate mapping (multiple item IDs → same audio) ───────────────────────

def build_duplicate_map():
    """Find question IDs that share the same spokenForm text."""
    with open(CONTENT_PACK) as f:
        data = json.load(f)

    text_to_ids = {}
    for item in data['itemTemplates']:
        text = item.get('spokenForm', item['prompt'])
        if text not in text_to_ids:
            text_to_ids[text] = []
        text_to_ids[text].append(item['id'])

    # Return mapping: secondary_id → primary_id (first one gets the file)
    duplicates = {}
    for text, ids in text_to_ids.items():
        if len(ids) > 1:
            primary = ids[0]
            for secondary in ids[1:]:
                duplicates[secondary] = primary

    return duplicates


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    manifest = build_manifest()
    duplicates = build_duplicate_map()

    total_chars = sum(len(m['text']) for m in manifest)
    print(f"Audio Generation Manifest")
    print(f"========================")
    print(f"Total items: {len(manifest)}")
    print(f"Total characters: {total_chars:,}")
    print(f"Voice: Sparkles for Kids ({VOICE_ID})")
    print(f"Model: {MODEL_ID}")
    print(f"Output: {OUTPUT_DIR}/")
    print(f"Duplicate question texts: {len(duplicates)} (will create symlinks)")
    print()

    # Check what's already generated
    already = 0
    to_generate = []
    for item in manifest:
        path = os.path.join(OUTPUT_DIR, item['category'], item['filename'])
        if os.path.exists(path) and os.path.getsize(path) > 100:
            already += 1
        else:
            to_generate.append(item)

    if already > 0:
        print(f"Already generated: {already}")
    print(f"To generate: {len(to_generate)}")

    if not to_generate:
        print("\nAll audio files already exist! Nothing to do.")
        # Still create duplicate symlinks
        create_duplicate_links(duplicates)
        print_summary(manifest)
        return

    remaining_chars = sum(len(m['text']) for m in to_generate)
    print(f"Characters to send: {remaining_chars:,}")
    est_minutes = len(to_generate) * REQUEST_DELAY / 60
    print(f"Estimated time: {est_minutes:.1f} minutes")
    print()

    # Generate!
    success = 0
    failed = 0
    for i, item in enumerate(to_generate):
        path = os.path.join(OUTPUT_DIR, item['category'], item['filename'])
        pct = (i + 1) / len(to_generate) * 100
        print(f"[{i+1}/{len(to_generate)}] ({pct:.0f}%) {item['category']}/{item['filename']}: {item['text'][:60]}...", end=" ", flush=True)

        ok = generate_audio(item['text'], path)
        if ok:
            size = os.path.getsize(path)
            print(f"✓ {size:,} bytes")
            success += 1
        else:
            print("✗ FAILED")
            failed += 1

        time.sleep(REQUEST_DELAY)

    # Create symlinks for duplicates
    create_duplicate_links(duplicates)

    print(f"\n{'='*50}")
    print(f"Generation complete!")
    print(f"  Success: {success + already}")
    print(f"  Failed:  {failed}")
    print(f"  Duplicates linked: {len(duplicates)}")

    if failed > 0:
        print(f"\n  Re-run the script to retry failed items.")

    print_summary(manifest)

    # Save the text→file mapping for the iOS app
    save_audio_index(manifest, duplicates)


def create_duplicate_links(duplicates):
    """For questions with identical text, copy the primary audio file."""
    questions_dir = os.path.join(OUTPUT_DIR, "questions")
    linked = 0
    for secondary_id, primary_id in duplicates.items():
        primary_path = os.path.join(questions_dir, f"{primary_id}.mp3")
        secondary_path = os.path.join(questions_dir, f"{secondary_id}.mp3")
        if os.path.exists(primary_path) and not os.path.exists(secondary_path):
            import shutil
            shutil.copy2(primary_path, secondary_path)
            linked += 1
    if linked:
        print(f"  Copied {linked} duplicate audio files")


def save_audio_index(manifest, duplicates):
    """Save a JSON index mapping item IDs to audio file paths."""
    index = {}
    for item in manifest:
        rel_path = f"{item['category']}/{item['filename']}"
        index[item['id']] = rel_path

    # Add duplicates
    for secondary_id, primary_id in duplicates.items():
        index[secondary_id] = f"questions/{secondary_id}.mp3"

    index_path = os.path.join(OUTPUT_DIR, "audio_index.json")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with open(index_path, 'w') as f:
        json.dump(index, f, indent=2, ensure_ascii=False)
    print(f"\n  Audio index saved: {index_path} ({len(index)} entries)")


def print_summary(manifest):
    """Print category breakdown."""
    from collections import Counter
    cats = Counter(m['category'] for m in manifest)
    print(f"\n  Category breakdown:")
    for cat, count in cats.most_common():
        dir_path = os.path.join(OUTPUT_DIR, cat)
        if os.path.exists(dir_path):
            files = [f for f in os.listdir(dir_path) if f.endswith('.mp3')]
            total_size = sum(os.path.getsize(os.path.join(dir_path, f)) for f in files)
            print(f"    {cat}: {count} items, {len(files)} files, {total_size/1024/1024:.1f} MB")
        else:
            print(f"    {cat}: {count} items (pending)")


if __name__ == '__main__':
    main()
