#!/usr/bin/env python3
"""Synthesizes the promo videos' music and sound effects, so every sound is original and
free to use anywhere.

The music is a sunny ukulele-and-marimba loop at 120 BPM (I-V-vi-IV in C): a Karplus-Strong
ukulele strumming an island pattern, a plucked bass, a marimba tune, glockenspiel sparkles
and light drums. Each track is cut to a whole number of bars and ends on a ringing chord.

Usage:
  python3 make_audio.py            # writes every track and effect into ../public/audio
"""

import os
import wave

import numpy as np

SR = 44_100
BPM = 120
BEAT = 60 / BPM
BAR = 4 * BEAT
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "public", "audio")
RNG = np.random.default_rng(7)


def midi(note):
    return 440.0 * 2 ** ((note - 69) / 12)


# Re-entrant ukulele voicings (G4 C4 E4 A4 strings), as MIDI notes.
UKE = {
    "C": [67, 60, 64, 72],
    "G": [67, 62, 67, 71],
    "Am": [69, 60, 64, 69],
    "F": [69, 60, 65, 69],
}
BASS_ROOT = {"C": 36, "G": 43, "Am": 45, "F": 41}
PROGRESSION = ["C", "G", "Am", "F"]

# Melody: (beat within the 4-bar phrase, MIDI note, length in beats). Two answering phrases.
PHRASE_A = [
    (0, 79, .5), (.5, 76, .5), (1, 79, .5), (1.5, 81, .5), (2, 79, 1), (3, 76, 1),
    (4, 74, .5), (4.5, 74, .5), (5, 71, .5), (5.5, 74, .5), (6, 79, 1.5),
    (8, 72, .5), (8.5, 76, .5), (9, 81, .5), (9.5, 79, .5), (10, 76, 1), (11, 72, 1),
    (12, 77, .5), (12.5, 76, .5), (13, 74, .5), (13.5, 72, .5), (14, 69, 1), (15, 72, 1),
]
PHRASE_B = [
    (0, 84, .5), (.5, 81, .5), (1, 79, .5), (1.5, 76, .5), (2, 79, 1), (3, 81, .5), (3.5, 79, .5),
    (4, 74, .5), (4.5, 79, .5), (5, 83, .5), (5.5, 81, .5), (6, 79, 1.5),
    (8, 76, .5), (8.5, 79, .5), (9, 81, 1), (10, 84, .5), (10.5, 81, .5), (11, 79, 1),
    (12, 77, .5), (12.5, 79, .5), (13, 81, .5), (13.5, 79, .5), (14, 76, .5), (14.5, 74, .5), (15, 72, 1),
]


def envelope(n, attack=0.004, decay=0.3):
    t = np.arange(n) / SR
    env = np.exp(-t / decay)
    a = max(1, int(attack * SR))
    env[:a] *= np.linspace(0, 1, a)
    return env


_pluck_cache = {}


def pluck(freq, seconds, brightness=0.5, decay=0.996):
    """Karplus-Strong plucked string, computed a delay-line length at a time."""
    key = (round(freq, 2), seconds, brightness, decay)
    if key in _pluck_cache:
        return _pluck_cache[key]
    n = int(seconds * SR)
    period = max(2, int(round(SR / freq)))
    noise = RNG.uniform(-1, 1, period)
    # A softer pick: low-pass the initial burst.
    for _ in range(int(3 * (1 - brightness)) + 1):
        noise = 0.5 * (noise + np.roll(noise, 1))
    out = np.zeros(n + period + 1)
    out[:period] = noise
    i = period
    while i < n:
        end = min(i + period, n)
        prev = out[i - period:end - period]
        prev_next = out[i - period + 1:end - period + 1]
        out[i:end] = decay * 0.5 * (prev + prev_next)
        i = end
    sig = out[:n] - np.mean(out[:n])
    sig *= envelope(n, attack=0.001, decay=seconds * 0.9)
    _pluck_cache[key] = sig
    return sig


def marimba(freq, seconds):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    tone = np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.45)
    tone += 0.35 * np.sin(2 * np.pi * freq * 3.93 * t) * np.exp(-t / 0.06)
    tone += 0.12 * np.sin(2 * np.pi * freq * 9.2 * t) * np.exp(-t / 0.02)
    a = int(0.002 * SR)
    tone[:a] *= np.linspace(0, 1, a)
    return tone


def glock(freq, seconds=1.2):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    tone = np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.6)
    tone += 0.4 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t / 0.15)
    tone += 0.2 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t / 0.05)
    return tone


def bass(freq, seconds):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    tone = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(4 * np.pi * freq * t) + 0.12 * np.sin(6 * np.pi * freq * t)
    return tone * envelope(n, attack=0.006, decay=0.35)


def kick():
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    pitch = 50 + 110 * np.exp(-t / 0.03)
    phase = 2 * np.pi * np.cumsum(pitch) / SR
    return np.sin(phase) * np.exp(-t / 0.08)


def clap():
    n = int(0.25 * SR)
    sig = np.zeros(n)
    for offset in (0, 0.011, 0.022):
        start = int(offset * SR)
        burst = RNG.normal(0, 1, n - start) * np.exp(-np.arange(n - start) / SR / (0.012 if offset < 0.02 else 0.07))
        sig[start:] += burst
    return bandpass(sig, 900, 2600) * 0.9


def shaker():
    n = int(0.05 * SR)
    sig = RNG.normal(0, 1, n) * envelope(n, attack=0.006, decay=0.015)
    return highpass(sig, 6000)


def fft_filter(sig, low=None, high=None):
    spec = np.fft.rfft(sig)
    freqs = np.fft.rfftfreq(len(sig), 1 / SR)
    mask = np.ones_like(freqs)
    if low is not None:
        mask *= 1 / (1 + (low / np.maximum(freqs, 1)) ** 4)
    if high is not None:
        mask *= 1 / (1 + (freqs / high) ** 4)
    return np.fft.irfft(spec * mask, len(sig))


def bandpass(sig, low, high):
    return fft_filter(sig, low=low, high=high)


def highpass(sig, low):
    return fft_filter(sig, low=low)


class Mix:
    def __init__(self, seconds):
        self.left = np.zeros(int((seconds + 3) * SR))
        self.right = np.zeros_like(self.left)
        self.seconds = seconds

    def add(self, sig, at, gain=1.0, pan=0.0):
        start = int(at * SR)
        if start >= len(self.left):
            return
        end = min(len(self.left), start + len(sig))
        chunk = sig[: end - start] * gain
        self.left[start:end] += chunk * np.sqrt((1 - pan) / 2)
        self.right[start:end] += chunk * np.sqrt((1 + pan) / 2)

    def render(self, fade_out=1.2):
        n = int(self.seconds * SR)
        stereo = np.stack([self.left[:n], self.right[:n]], axis=1)
        fade = int(fade_out * SR)
        stereo[-fade:] *= np.linspace(1, 0, fade)[:, None] ** 1.5
        # Gentle bus compression, then normalize.
        stereo = np.tanh(stereo * 1.4) / np.tanh(1.4)
        peak = np.max(np.abs(stereo))
        return stereo / peak * 0.89 if peak > 0 else stereo


def strum(mix, chord, at, down=True, gain=1.0, ring=1.2):
    strings = UKE[chord] if down else list(reversed(UKE[chord]))
    for i, note in enumerate(strings):
        mix.add(pluck(midi(note), ring, brightness=0.55 if down else 0.35), at + i * 0.012, gain * (1.0 if down else 0.7), pan=-0.25)


def sparkle(mix, at, gain=0.22):
    for i, note in enumerate([84, 88, 91, 96]):
        mix.add(glock(midi(note)), at + i * 0.07, gain, pan=0.4 - 0.25 * i)


def song(bars, drop_bars=(), quiet_intro=2):
    """`bars` bars long, the last one a ringing C chord. Drums and tune rest in `drop_bars`."""
    mix = Mix(bars * BAR)
    island = [(0, True), (1, True), (1.5, False), (2.5, False), (3, True), (3.5, False)]
    for bar in range(bars):
        t0 = bar * BAR
        chord = PROGRESSION[bar % 4]
        final = bar == bars - 1
        if final:
            strum(mix, "C", t0, True, 1.1, ring=BAR)
            mix.add(bass(midi(BASS_ROOT["C"]), BAR), t0, 0.55)
            mix.add(kick(), t0, 0.6)
            mix.add(marimba(midi(84), 1.5), t0, 0.32, pan=0.3)
            sparkle(mix, t0 + BEAT, 0.25)
            continue

        for beat, down in island:
            strum(mix, chord, t0 + beat * BEAT, down, 0.9 if beat in (0, 3) else 0.75)

        full = bar >= quiet_intro and bar not in drop_bars
        for eighth in range(8):
            mix.add(shaker(), t0 + eighth * BEAT / 2, 0.12 if eighth % 2 else 0.08, pan=0.35)
        if not full:
            continue
        root = BASS_ROOT[chord]
        mix.add(bass(midi(root), BEAT * 1.5), t0, 0.5)
        mix.add(bass(midi(root + 7 if chord != "Am" else root + 3), BEAT), t0 + 2 * BEAT, 0.4)
        mix.add(bass(midi(root + 12), BEAT / 2), t0 + 3.5 * BEAT, 0.3)
        for beat in (0, 2):
            mix.add(kick(), t0 + beat * BEAT, 0.55)
        for beat in (1, 3):
            mix.add(clap(), t0 + beat * BEAT, 0.28, pan=-0.1)

        phrase = PHRASE_A if (bar // 4) % 2 == 0 else PHRASE_B
        for beat, note, length in phrase:
            if int(beat // 4) == bar % 4:
                mix.add(marimba(midi(note), max(0.4, length * BEAT + 0.3)), t0 + (beat % 4) * BEAT, 0.3, pan=0.3)

    for bar in [0, quiet_intro, *drop_bars]:
        if bar < bars - 1:
            sparkle(mix, bar * BAR)
    return mix.render()


def write_wav(path, stereo):
    data = (np.clip(stereo, -1, 1) * 32767).astype(np.int16)
    if data.ndim == 1:
        data = np.stack([data, data], axis=1)
    with wave.open(path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data.tobytes())


def effect(sig, peak=0.8):
    sig = sig / (np.max(np.abs(sig)) or 1) * peak
    return np.stack([sig, sig], axis=1)


def effects():
    t = np.arange(int(0.45 * SR)) / SR
    # A rising whoosh for scene changes: noise swept up through a moving band.
    noise = RNG.normal(0, 1, len(t))
    sweep = np.zeros_like(noise)
    for i, (lo, hi) in enumerate(zip(np.geomspace(300, 3000, 9), np.geomspace(900, 9000, 9))):
        seg = slice(i * len(t) // 9, (i + 1) * len(t) // 9)
        sweep[seg] = bandpass(noise, lo, hi)[seg]
    whoosh = sweep * np.sin(np.pi * t / t[-1]) ** 2

    t2 = np.arange(int(0.12 * SR)) / SR
    pop = np.sin(2 * np.pi * (500 + 900 * t2 / t2[-1]) * t2) * np.exp(-t2 / 0.03)

    tap = np.sin(2 * np.pi * 1800 * t2) * np.exp(-t2 / 0.008) + 0.4 * RNG.normal(0, 1, len(t2)) * np.exp(-t2 / 0.004)

    ding = glock(midi(88), 1.2) + 0.7 * np.concatenate([np.zeros(int(0.09 * SR)), glock(midi(95), 1.2)])[: int(1.2 * SR)]

    return {"whoosh": effect(whoosh, 0.6), "pop": effect(pop, 0.7), "tap": effect(tap, 0.5), "ding": effect(ding, 0.8)}


def main():
    os.makedirs(OUT, exist_ok=True)
    # Track lengths match the videos (whole bars of 2 seconds).
    tracks = {
        "music-overview.wav": song(23, drop_bars=(14,)),
        "music-paper.wav": song(16, drop_bars=()),
        "music-parents.wav": song(18, drop_bars=(11,)),
    }
    for name, stereo in tracks.items():
        write_wav(os.path.join(OUT, name), stereo)
        print(f"{name}: {len(stereo) / SR:.1f}s")
    for name, stereo in effects().items():
        write_wav(os.path.join(OUT, f"sfx-{name}.wav"), stereo)
        print(f"sfx-{name}.wav")


if __name__ == "__main__":
    main()
