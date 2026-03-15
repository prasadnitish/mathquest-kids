#!/usr/bin/env python3
"""Generate ElevenLabs audio for the 104 content-pack items missing from audio_index.json."""

import json
import os
import shutil
import time
import urllib.request
import urllib.error

# ── Config ──────────────────────────────────────────────────────────────────
ELEVENLABS_API_KEY = os.environ.get("ELEVENLABS_API_KEY", "")
VOICE_ID = "tapn1QwocNXk3viVSowa"  # Sparkles for Kids
MODEL_ID = "eleven_turbo_v2_5"
VOICE_SETTINGS = {
    "stability": 0.65,
    "similarity_boost": 0.80,
    "style": 0.35,
    "use_speaker_boost": True,
}

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO_DIR = os.path.join(BASE_DIR, "MathQuestKids", "Audio", "questions")
INDEX_PATH = os.path.join(BASE_DIR, "MathQuestKids", "Audio", "audio_index.json")
CONTENT_PATH = os.path.join(BASE_DIR, "MathQuestKids", "Content", "content-pack-v1.json")

RATE_LIMIT_DELAY = 0.15  # seconds between API calls


def load_missing_items():
    """Find content-pack template IDs not in audio_index.json."""
    with open(INDEX_PATH) as f:
        audio_index = json.load(f)
    with open(CONTENT_PATH) as f:
        content = json.load(f)

    audio_ids = set(audio_index.keys())
    missing = []
    for t in content["itemTemplates"]:
        if t["id"] not in audio_ids:
            spoken = t.get("spokenForm") or t["prompt"]
            missing.append({"id": t["id"], "text": spoken})

    return missing, audio_index


def generate_audio(text: str, output_path: str) -> bool:
    """Call ElevenLabs TTS API and save the MP3."""
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"
    payload = json.dumps({
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": VOICE_SETTINGS,
    }).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "xi-api-key": ELEVENLABS_API_KEY,
            "Accept": "audio/mpeg",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            data = resp.read()
            if len(data) < 100:
                print(f"  WARNING: Response too small ({len(data)} bytes)")
                return False
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "wb") as f:
                f.write(data)
            return True
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"  HTTP {e.code}: {body[:200]}")
        return False
    except Exception as e:
        print(f"  Error: {e}")
        return False


def main():
    missing, audio_index = load_missing_items()
    print(f"Found {len(missing)} items missing audio")

    if not missing:
        print("Nothing to generate!")
        return

    # Group by spoken text to avoid duplicate API calls
    text_to_ids: dict[str, list[str]] = {}
    for item in missing:
        text_to_ids.setdefault(item["text"], []).append(item["id"])

    unique_texts = len(text_to_ids)
    print(f"Unique spoken texts: {unique_texts} (saving {len(missing) - unique_texts} duplicate API calls)")

    generated = 0
    skipped = 0
    failed = 0

    for text, ids in text_to_ids.items():
        primary_id = ids[0]
        rel_path = f"questions/{primary_id}.mp3"
        abs_path = os.path.join(AUDIO_DIR, f"{primary_id}.mp3")

        # Skip if file already exists on disk
        if os.path.exists(abs_path) and os.path.getsize(abs_path) > 100:
            print(f"  SKIP (exists): {primary_id}")
            skipped += 1
        else:
            print(f"  [{generated + failed + 1}/{unique_texts}] Generating: {primary_id} — \"{text[:60]}...\"" if len(text) > 60 else f"  [{generated + failed + 1}/{unique_texts}] Generating: {primary_id} — \"{text}\"")
            if generate_audio(text, abs_path):
                generated += 1
                print(f"    OK ({os.path.getsize(abs_path):,} bytes)")
            else:
                failed += 1
                print(f"    FAILED")
                continue
            time.sleep(RATE_LIMIT_DELAY)

        # Add primary to index
        audio_index[primary_id] = rel_path

        # Handle duplicates — copy file and add index entries
        for dup_id in ids[1:]:
            dup_rel = f"questions/{dup_id}.mp3"
            dup_abs = os.path.join(AUDIO_DIR, f"{dup_id}.mp3")
            if not os.path.exists(dup_abs):
                shutil.copy2(abs_path, dup_abs)
                print(f"    COPY: {primary_id} → {dup_id}")
            audio_index[dup_id] = dup_rel

    # Save updated index
    with open(INDEX_PATH, "w") as f:
        json.dump(audio_index, f, indent=2)
        f.write("\n")

    print(f"\nDone! Generated: {generated}, Skipped: {skipped}, Failed: {failed}, Duplicates: {len(missing) - unique_texts}")
    print(f"Audio index now has {len(audio_index)} entries")


if __name__ == "__main__":
    main()
