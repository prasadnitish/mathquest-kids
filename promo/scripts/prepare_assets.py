#!/usr/bin/env python3
"""Copies the app's own art, fonts and voice clips into public/app for the videos, resized
for 1080p so renders stay quick. Run after the app's assets change."""

import glob
import os
import shutil

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
ASSETS = os.path.join(REPO, "MathQuestKids", "Assets.xcassets")
OUT = os.path.join(HERE, "..", "public", "app")

CHARACTERS = [
    "CandyBenny", "CandySprinkle", "CandyTaffy", "ReefCoral", "ReefFinn", "ReefPearl",
    "UnicornClover", "UnicornDizzy", "UnicornSparkle", "SpaceCosmo", "SpaceLuna", "SpaceZip",
    "HeroCaptainCalc", "HeroDashDigit", "HeroNovaShield", "TurboAxleAce", "TurboRevRacer", "TurboTurboTread",
]
BACKGROUNDS = [
    "CandylandBackgroundV2", "AxolotlBackground", "RainbowUnicornBackground",
    "StarsSpaceBackgroundV2", "SuperheroBackground", "TurboCarsBackground",
]
FONTS = ["Nunito-Black.ttf", "Nunito-ExtraBold.ttf", "Nunito-Bold.ttf", "DMSans-Bold.ttf", "DMSans-Medium.ttf"]
VOICE = {
    "voice-kept-trying.mp3": "feedback/praise-01.mp3",       # "You kept trying and solved it!"
    "voice-great-strategy.mp3": "feedback/praise-00.mp3",    # "Great strategy!"
    "voice-nice-thinking.mp3": "feedback/praise-02.mp3",     # "Nice math thinking!"
    "voice-great-finish.mp3": "feedback/session-end-00.mp3", # "Great finish!"
}


def image(name):
    return glob.glob(os.path.join(ASSETS, f"{name}.imageset", "*.png"))[0]


def save(src, dest, max_side):
    im = Image.open(src)
    im.thumbnail((max_side, max_side), Image.LANCZOS)
    im.save(dest, optimize=True)


def main():
    for sub in ("characters", "backgrounds", "fonts", "voice"):
        os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    for name in CHARACTERS:
        save(image(name), os.path.join(OUT, "characters", f"{name}.png"), 640)
    for name in BACKGROUNDS:
        save(image(name), os.path.join(OUT, "backgrounds", f"{name}.png"), 1600)
    save(os.path.join(ASSETS, "AppIcon.appiconset", "icon-1024.png"), os.path.join(OUT, "icon.png"), 1024)
    for font in FONTS:
        shutil.copy(os.path.join(REPO, "MathQuestKids", "Resources", "Fonts", font), os.path.join(OUT, "fonts", font))
    for dest, src in VOICE.items():
        shutil.copy(os.path.join(REPO, "MathQuestKids", "Audio", src), os.path.join(OUT, "voice", dest))
    print(f"Wrote app assets to {os.path.relpath(OUT, REPO)}")


if __name__ == "__main__":
    main()
