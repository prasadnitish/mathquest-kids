#!/usr/bin/env python3
"""Indexes public/footage into src/footage.json: each scene's video file, size, length,
marks (seconds into the video) and taps (x, y as screen fractions, seconds)."""

import glob
import json
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
PROMO = os.path.abspath(os.path.join(HERE, ".."))
FOOTAGE = os.path.join(PROMO, "public", "footage")
FFPROBE = os.path.join(PROMO, "node_modules", "@remotion", "compositor-linux-x64-gnu", "ffprobe")


def probe(path):
    out = subprocess.run(
        [FFPROBE, "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height:format=duration",
         "-of", "json", path],
        check=True, capture_output=True, text=True,
    ).stdout
    info = json.loads(out)
    stream = info["streams"][0]
    return stream["width"], stream["height"], float(info["format"]["duration"])


def main():
    index = {}
    for video in sorted(glob.glob(os.path.join(FOOTAGE, "*", "*.mp4"))):
        device = os.path.basename(os.path.dirname(video))
        scene = os.path.splitext(os.path.basename(video))[0]
        width, height, duration = probe(video)
        marks, taps = {}, []
        log = os.path.splitext(video)[0] + ".log"
        if os.path.exists(log):
            for line in open(log):
                parts = line.split()
                if parts[:1] == ["MARK"] and len(parts) == 3:
                    marks.setdefault(parts[1], float(parts[2]))
                elif parts[:1] == ["TAP"] and len(parts) == 4:
                    taps.append([float(parts[1]), float(parts[2]), float(parts[3])])
        index.setdefault(device, {})[scene] = {
            "file": os.path.relpath(video, os.path.join(PROMO, "public")),
            "duration": round(duration, 3),
            "width": width,
            "height": height,
            "marks": marks,
            "taps": taps,
        }
        print(f"{device}/{scene}: {width}x{height} {duration:.1f}s, {len(marks)} marks, {len(taps)} taps")
    with open(os.path.join(PROMO, "src", "footage.json"), "w") as f:
        json.dump(index, f, indent=1)


if __name__ == "__main__":
    main()
