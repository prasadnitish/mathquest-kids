#!/usr/bin/env python3
"""Record ElevenLabs narration for the content-pack questions that need it.

A question needs a clip when it has none yet, or when it has been reworded since its clip was
recorded. Each audio_index.json entry keeps the words its clip says ("text"), and the app only
plays a clip whose words match the question on screen, so a reworded question is read by the
system voice until it's re-recorded here.

    ELEVENLABS_API_KEY=... python3 scripts/generate_missing_audio.py
    python3 scripts/generate_missing_audio.py --list    # only refresh the waiting list

Either way, scripts/questions_awaiting_audio.json lists the questions still without a clip.
"""

import json
import os
import shutil
import sys
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
AWAITING_PATH = os.path.join(BASE_DIR, "scripts", "questions_awaiting_audio.json")

RATE_LIMIT_DELAY = 0.15  # seconds between API calls


def spoken_text(template):
    return " ".join((template.get("spokenForm") or template["prompt"]).split())


def recorded_text(entry):
    """The words an index entry's clip says, if the entry records them."""
    if isinstance(entry, dict) and entry.get("text"):
        return " ".join(entry["text"].split())
    return None


def load_missing_items():
    """Content-pack questions with no clip, or a clip recorded from different words."""
    with open(INDEX_PATH) as f:
        audio_index = json.load(f)
    with open(CONTENT_PATH) as f:
        content = json.load(f)

    missing = []
    for t in content["itemTemplates"]:
        if t.get("audioID"):
            continue  # voiced from the recording set in Audio/future, not this index
        if recorded_text(audio_index.get(t["id"])) != spoken_text(t):
            missing.append({"id": t["id"], "text": spoken_text(t)})

    return missing, audio_index


def save_index(audio_index):
    with open(INDEX_PATH, "w") as f:
        json.dump(audio_index, f, indent=2, ensure_ascii=False)
        f.write("\n")


def save_awaiting(items):
    with open(AWAITING_PATH, "w") as f:
        json.dump(sorted(items, key=lambda item: item["id"]), f, indent=2, ensure_ascii=False)
        f.write("\n")


def clip_path(audio_index, item_id):
    """Where an item's clip goes: its existing file (keeping that name's case), or a new one."""
    entry = audio_index.get(item_id)
    if isinstance(entry, dict):
        return entry["file"]
    if isinstance(entry, str):
        return entry
    return f"questions/{item_id}.mp3"


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
    print(f"Found {len(missing)} items needing audio")

    if "--list" in sys.argv or not missing:
        save_awaiting(missing)
        print(f"Waiting list: {os.path.relpath(AWAITING_PATH, BASE_DIR)}")
        return

    if not ELEVENLABS_API_KEY:
        save_awaiting(missing)
        print("Set ELEVENLABS_API_KEY to record them.")
        sys.exit(1)

    # Group by spoken text to avoid duplicate API calls
    text_to_ids: dict[str, list[str]] = {}
    for item in missing:
        text_to_ids.setdefault(item["text"], []).append(item["id"])

    unique_texts = len(text_to_ids)
    print(f"Unique spoken texts: {unique_texts} (saving {len(missing) - unique_texts} duplicate API calls)")

    generated = 0
    failed = 0
    done: set[str] = set()

    for text, ids in text_to_ids.items():
        primary_id = ids[0]
        rel_path = clip_path(audio_index, primary_id)
        abs_path = os.path.join(os.path.dirname(AUDIO_DIR), rel_path)

        # Always record afresh: a file already there says older words.
        print(f"  [{generated + failed + 1}/{unique_texts}] Generating: {primary_id} — \"{text}\"")
        if not generate_audio(text, abs_path):
            failed += 1
            print(f"    FAILED")
            continue
        generated += 1
        print(f"    OK ({os.path.getsize(abs_path):,} bytes)")

        audio_index[primary_id] = {"file": rel_path, "text": text}
        done.add(primary_id)

        # Duplicates share the recording
        for dup_id in ids[1:]:
            dup_rel = clip_path(audio_index, dup_id)
            dup_abs = os.path.join(os.path.dirname(AUDIO_DIR), dup_rel)
            if os.path.abspath(dup_abs) != os.path.abspath(abs_path):
                shutil.copy2(abs_path, dup_abs)
                print(f"    COPY: {primary_id} → {dup_id}")
            audio_index[dup_id] = {"file": dup_rel, "text": text}
            done.add(dup_id)

        # Save as we go, so an interrupted run picks up where it stopped.
        save_index(audio_index)
        save_awaiting([item for item in missing if item["id"] not in done])
        time.sleep(RATE_LIMIT_DELAY)

    print(f"\nDone! Generated: {generated}, Failed: {failed}, Duplicates: {len(done) - generated}")
    print(f"Audio index now has {len(audio_index)} entries; {len(missing) - len(done)} still waiting")


if __name__ == "__main__":
    main()
