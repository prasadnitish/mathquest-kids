#!/usr/bin/env python3
"""Finds how far each scene's step log is off from its video, and writes it as `offset`
(seconds to add to log times) in public/footage/<device>/<scene>.offset.

A tap changes the screen right where it lands (the key or box it hit) a moment after it's
logged, so the offset is the shift at which the picture changes in a small patch around
each logged tap. Matching the patch, not the whole frame, keeps big transitions (a new
question sliding in) from pulling the match off. Scenes without taps take the median offset
of the other scenes on the same device.

Usage: calibrate_footage.py [--report]   (--report prints offsets without writing them)"""

import glob
import os
import statistics
import subprocess
import sys

import numpy as np

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
TAP_LATENCY = 0.7  # a logged tap shows on screen about this much later
W, H = 120, 120  # sampled frame size; taps are fractions of the screen, so shape doesn't matter


def frames(video):
    out = subprocess.run(
        [FFMPEG, "-loglevel", "error", "-i", video, "-vf", f"fps={RATE},scale={W}:{H}", "-f", "rawvideo", "-pix_fmt", "gray", "-"],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(out, dtype=np.uint8).reshape(-1, H, W).astype(np.int16)


def patch_changes(video_frames, x, y, radius=7):
    """How much a patch around (x, y) changes from each frame to the next."""
    cx, cy = int(x * W), int(y * H)
    patch = video_frames[:, max(0, cy - radius): cy + radius, max(0, cx - radius): cx + radius]
    if patch.size == 0:
        return np.zeros(len(video_frames))
    return np.concatenate([[0.0], np.abs(np.diff(patch, axis=0)).mean(axis=(1, 2))])


def best_offset(video_frames, taps, low=-40.0, high=10.0):
    series = [(patch_changes(video_frames, x, y), t) for x, y, t in taps if 0 <= x <= 1 and 0 <= y <= 1]
    if not series:
        return None
    best, best_score = 0.0, -1.0
    for step in range(int(low * 10), int(high * 10) + 1):
        offset = step / 10
        score = 0.0
        for changes, t in series:
            i = int(round((t + TAP_LATENCY + offset) * RATE))
            window = changes[max(0, i - 3): i + 4]
            score += float(window.max()) if len(window) else 0.0
        if score > best_score:
            best, best_score = offset, score
    return best, best_score / len(series)


def main():
    write = "--report" not in sys.argv
    for device_dir in sorted(glob.glob(os.path.join(FOOTAGE, "*"))):
        found, pending = {}, []
        for video in sorted(glob.glob(os.path.join(device_dir, "*.mp4"))):
            log = os.path.splitext(video)[0] + ".log"
            taps = []
            if os.path.exists(log):
                taps = [tuple(map(float, line.split()[1:4])) for line in open(log) if line.startswith("TAP ")]
            result = best_offset(frames(video), taps) if len(taps) >= 3 else None
            if result is None:
                pending.append(video)
                continue
            found[video] = result[0]
            print(f"{os.path.relpath(video, FOOTAGE)}: offset {result[0]:+.1f}s from {len(taps)} taps (match {result[1]:.1f})")
        fallback = statistics.median(found.values()) if found else 0.0
        for video in pending:
            found[video] = fallback
            print(f"{os.path.relpath(video, FOOTAGE)}: no taps to match, using {fallback:+.1f}s")
        if write:
            for video, offset in found.items():
                with open(os.path.splitext(video)[0] + ".offset", "w") as f:
                    f.write(f"{offset:.2f}\n")


if __name__ == "__main__":
    main()
