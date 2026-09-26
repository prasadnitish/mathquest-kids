#!/usr/bin/env python3
"""Finds how far each scene's step log is off from its video, and writes it as `offset`
(seconds to add to log times) in public/footage/<device>/<scene>.offset.

Footage filmed before capture.sh recorded the recorder's start time lost that offset in the
transcode. Taps change the screen a moment after they're logged, so the offset is the shift
that lines the logged taps up best with the moments the picture changes.
Scenes without taps take the median offset of the other scenes on the same device."""

import glob
import os
import statistics
import subprocess

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROMO = os.path.abspath(os.path.join(HERE, ".."))
FOOTAGE = os.path.join(PROMO, "public", "footage")
try:
    # A full ffmpeg (pip install imageio-ffmpeg); Remotion's own build lacks raw output.
    import imageio_ffmpeg
    FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
except ImportError:
    FFMPEG = "ffmpeg"
RATE = 10  # frames sampled per second
TAP_LATENCY = 0.35  # a logged tap reaches the screen about this much later


def change_series(video):
    """Mean absolute change between consecutive frames, RATE per second."""
    out = subprocess.run(
        [FFMPEG, "-loglevel", "error", "-i", video, "-vf", f"fps={RATE},scale=96:160", "-f", "rawvideo", "-pix_fmt", "gray", "-"],
        check=True, capture_output=True,
    ).stdout
    frames = np.frombuffer(out, dtype=np.uint8).reshape(-1, 160 * 96).astype(np.int16)
    diffs = np.abs(np.diff(frames, axis=0)).mean(axis=1)
    return np.concatenate([[0.0], diffs])


def best_offset(series, taps):
    best, best_score = 0.0, -1.0
    for step in range(-120, 31):
        offset = step / 10
        score = 0.0
        for t in taps:
            i = int(round((t + TAP_LATENCY + offset) * RATE))
            window = series[max(0, i - 1): i + 4]
            score += float(window.max()) if len(window) else 0.0
        if score > best_score:
            best, best_score = offset, score
    return best, best_score


def main():
    for device_dir in sorted(glob.glob(os.path.join(FOOTAGE, "*"))):
        found = {}
        pending = []
        for video in sorted(glob.glob(os.path.join(device_dir, "*.mp4"))):
            log = os.path.splitext(video)[0] + ".log"
            taps = [float(line.split()[3]) for line in open(log) if line.startswith("TAP ")] if os.path.exists(log) else []
            if len(taps) < 3:
                pending.append(video)
                continue
            offset, score = best_offset(change_series(video), taps)
            found[video] = offset
            print(f"{os.path.relpath(video, FOOTAGE)}: offset {offset:+.1f}s from {len(taps)} taps (score {score:.1f})")
        fallback = statistics.median(found.values()) if found else 0.0
        for video in pending:
            found[video] = fallback
            print(f"{os.path.relpath(video, FOOTAGE)}: no taps to match, using {fallback:+.1f}s")
        for video, offset in found.items():
            with open(os.path.splitext(video)[0] + ".offset", "w") as f:
                f.write(f"{offset:.2f}\n")


if __name__ == "__main__":
    main()
