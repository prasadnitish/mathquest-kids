#!/usr/bin/env python3
"""
Generate MP3s from an audio recording set manifest.

This is separate from generate_audio.py because the future recording set is an
expanded backlog, not the current production content-pack audio index.

Usage:
  ELEVENLABS_API_KEY=... python3 scripts/generate_audio_from_recording_set.py
  ELEVENLABS_API_KEY=... python3 scripts/generate_audio_from_recording_set.py --priority must_have
  ELEVENLABS_API_KEY=... python3 scripts/generate_audio_from_recording_set.py --dry-run --limit 20
"""

from __future__ import annotations

import argparse
import json
import os
import socket
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DEFAULT_MANIFEST = SCRIPT_DIR / "audio_recording_set_2026_04_26.json"
OUTPUT_ROOT = PROJECT_ROOT / "MathQuestKids" / "Audio"
INDEX_PATH = OUTPUT_ROOT / "future" / "audio_recording_set_2026_04_26_index.json"
ENV_PATH = PROJECT_ROOT / ".env"

DEFAULT_VOICE_ID = "tapn1QwocNXk3viVSowa"  # Sparkles for Kids
DEFAULT_MODEL_ID = "eleven_turbo_v2_5"
REQUEST_DELAY_SECONDS = 0.15


def load_dotenv(path: Path = ENV_PATH) -> None:
    """Load simple KEY=value pairs from .env without adding a dependency."""
    if not path.exists():
        return
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate MP3s from a MathQuest Kids recording manifest.")
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help="Path to audio recording JSON manifest.")
    parser.add_argument("--priority", action="append", choices=["must_have", "strong_pack"], help="Generate only one or more priorities. Can be repeated.")
    parser.add_argument("--category", action="append", help="Generate only one or more categories. Can be repeated.")
    parser.add_argument("--limit", type=int, help="Generate at most N clips after filters.")
    parser.add_argument("--force", action="store_true", help="Regenerate even if the output MP3 already exists.")
    parser.add_argument("--dry-run", action="store_true", help="Print what would be generated without calling ElevenLabs.")
    parser.add_argument("--voice-id", default=os.environ.get("ELEVENLABS_VOICE_ID", DEFAULT_VOICE_ID))
    parser.add_argument("--model-id", default=os.environ.get("ELEVENLABS_MODEL_ID", DEFAULT_MODEL_ID))
    return parser.parse_args()


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open() as f:
        data = json.load(f)
    if "clips" not in data or not isinstance(data["clips"], list):
        raise ValueError(f"Manifest does not have a clips array: {path}")
    return data


def filtered_clips(manifest: dict[str, Any], args: argparse.Namespace) -> list[dict[str, Any]]:
    clips = manifest["clips"]
    if args.priority:
        allowed = set(args.priority)
        clips = [clip for clip in clips if clip.get("priority") in allowed]
    if args.category:
        allowed = set(args.category)
        clips = [clip for clip in clips if clip.get("category") in allowed]
    if args.limit is not None:
        clips = clips[: max(0, args.limit)]
    return clips


def output_path_for(clip: dict[str, Any]) -> Path:
    rel = clip["file"]
    if rel.startswith("Audio/"):
        rel = rel.removeprefix("Audio/")
    return OUTPUT_ROOT / rel


def elevenlabs_payload(text: str, model_id: str, clip: dict[str, Any]) -> bytes:
    settings = clip.get("voiceSettings") or {}
    payload = {
        "text": text,
        "model_id": model_id,
        "voice_settings": {
            "stability": settings.get("stability", 0.65),
            "similarity_boost": settings.get("similarityBoost", 0.80),
            "style": settings.get("style", 0.35),
            "use_speaker_boost": settings.get("speakerBoost", True),
        },
    }
    return json.dumps(payload).encode("utf-8")


def generate_clip(api_key: str, voice_id: str, model_id: str, clip: dict[str, Any], output_path: Path) -> bool:
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    request = urllib.request.Request(
        url,
        data=elevenlabs_payload(clip["text"], model_id, clip),
        headers={
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
            "xi-api-key": api_key,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=45) as response:
            data = response.read()
        if len(data) < 100:
            print(f"  WARNING: response too small for {clip['id']} ({len(data)} bytes)")
            return False
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(data)
        return True
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        if exc.code in {401, 403}:
            raise SystemExit(
                f"ElevenLabs rejected the API key or account access for {clip['id']} "
                f"(HTTP {exc.code}): {body[:240]}"
            ) from exc
        print(f"  HTTP {exc.code} for {clip['id']}: {body[:240]}")
        return False
    except Exception as exc:
        print(f"  ERROR for {clip['id']}: {exc}")
        return False


def save_index(index: dict[str, str]) -> None:
    INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)
    INDEX_PATH.write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n")


def verify_network() -> None:
    try:
        socket.getaddrinfo("api.elevenlabs.io", 443)
    except OSError as exc:
        raise SystemExit(
            "Cannot resolve api.elevenlabs.io from this environment. "
            "Run this script from a terminal with internet access."
        ) from exc


def main() -> None:
    load_dotenv()
    args = parse_args()
    manifest = load_manifest(Path(args.manifest))
    clips = filtered_clips(manifest, args)

    total_chars = sum(len(clip["text"]) for clip in clips)
    print("Future audio recording generation")
    print(f"  Manifest: {args.manifest}")
    print(f"  Clips after filters: {len(clips)}")
    print(f"  Characters after filters: {total_chars:,}")
    print(f"  Voice: {args.voice_id}")
    print(f"  Model: {args.model_id}")
    print(f"  Output root: {OUTPUT_ROOT}")

    if args.dry_run:
        for clip in clips[:20]:
            print(f"  DRY {clip['priority']} {clip['category']} {clip['id']}: {clip['text']}")
        if len(clips) > 20:
            print(f"  ... {len(clips) - 20} more")
        return

    api_key = os.environ.get("ELEVENLABS_API_KEY", "")
    if not api_key:
        raise SystemExit("ELEVENLABS_API_KEY is required unless --dry-run is used.")
    verify_network()

    index: dict[str, str] = {}
    if INDEX_PATH.exists():
        index = json.loads(INDEX_PATH.read_text())

    generated = 0
    skipped = 0
    failed = 0
    for offset, clip in enumerate(clips, 1):
        output_path = output_path_for(clip)
        rel_path = output_path.relative_to(OUTPUT_ROOT).as_posix()
        if output_path.exists() and output_path.stat().st_size > 100 and not args.force:
            skipped += 1
            index[clip["id"]] = rel_path
            print(f"[{offset}/{len(clips)}] SKIP {clip['id']} -> {rel_path}")
            continue

        print(f"[{offset}/{len(clips)}] GEN {clip['id']} -> {rel_path}")
        if generate_clip(api_key, args.voice_id, args.model_id, clip, output_path):
            generated += 1
            index[clip["id"]] = rel_path
            print(f"  OK {output_path.stat().st_size:,} bytes")
        else:
            failed += 1
        time.sleep(REQUEST_DELAY_SECONDS)

    save_index(index)
    print("\nDone")
    print(f"  Generated: {generated}")
    print(f"  Skipped: {skipped}")
    print(f"  Failed: {failed}")
    print(f"  Index: {INDEX_PATH.relative_to(PROJECT_ROOT)} ({len(index)} entries)")


if __name__ == "__main__":
    main()
