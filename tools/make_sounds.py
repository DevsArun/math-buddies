#!/usr/bin/env python3
"""Synthesizes all Math Buddies audio (zero downloads, fully offline-safe).
Outputs 16-bit mono WAVs into android_overrides/app/src/main/res/raw/.
Android resource names must be [a-z0-9_]. Run: python3 tools/make_sounds.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "android_overrides", "app", "src", "main", "res", "raw")


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.85 / peak if peak > 0.85 else 1.0
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767))
            for s in samples
        )
        w.writeframes(frames)
    print("wrote", name, f"{len(samples) / RATE:.2f}s")


def pluck(freq, dur, bright=0.5, vol=0.5):
    """Music-box / marimba like note."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-3.2 * t / max(dur, 0.01))
        s = (math.sin(2 * math.pi * freq * t)
             + bright * 0.6 * math.sin(2 * math.pi * freq * 2 * t)
             + bright * 0.25 * math.sin(2 * math.pi * freq * 3 * t))
        out.append(vol * env * s)
    return out


def sweep(f0, f1, dur, vol=0.5, vib=0.0):
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = f0 + (f1 - f0) * (t / dur)
        if vib:
            f += vib * math.sin(2 * math.pi * 18 * t)
        phase += 2 * math.pi * f / RATE
        env = math.exp(-4.0 * t / dur)
        out.append(vol * env * math.sin(phase))
    return out


def mix(*parts):
    total = max(len(p[0]) + p[1] for p in parts) if parts else 0
    out = [0.0] * total
    for samples, offset in parts:
        for i, s in enumerate(samples):
            out[offset + i] += s
    return out


def sec(x):
    return int(RATE * x)


def main():
    random.seed(11)

    # pop: quick pitch drop bubble
    write_wav("pop", sweep(720, 260, 0.14, vol=0.55))
    # click: tiny tick
    write_wav("click", pluck(1250, 0.06, bright=0.3, vol=0.4))
    # sparkle: rising triplet
    write_wav("sparkle", mix(
        (pluck(1568, 0.18, 0.7, 0.4), 0),
        (pluck(2093, 0.20, 0.7, 0.4), sec(0.07)),
        (pluck(2637, 0.28, 0.7, 0.4), sec(0.14)),
    ))
    # correct: happy C-E-G arpeggio
    write_wav("correct", mix(
        (pluck(523, 0.30, 0.6, 0.5), 0),
        (pluck(659, 0.30, 0.6, 0.5), sec(0.09)),
        (pluck(784, 0.45, 0.6, 0.5), sec(0.18)),
    ))
    # wrong: gentle low boing (never scary)
    write_wav("wrong", sweep(230, 170, 0.32, vol=0.30, vib=14))
    # star: bright ping
    write_wav("star", mix(
        (pluck(1319, 0.25, 0.8, 0.45), 0),
        (pluck(1976, 0.35, 0.8, 0.30), sec(0.06)),
    ))
    # win: little fanfare C E G C6 + final chord
    write_wav("win", mix(
        (pluck(523, 0.22, 0.6, 0.5), 0),
        (pluck(659, 0.22, 0.6, 0.5), sec(0.15)),
        (pluck(784, 0.22, 0.6, 0.5), sec(0.30)),
        (pluck(1047, 0.55, 0.6, 0.55), sec(0.45)),
        (pluck(784, 0.7, 0.5, 0.30), sec(0.45)),
        (pluck(1319, 0.7, 0.5, 0.25), sec(0.45)),
    ))
    # jump: rising sweep
    write_wav("jump", sweep(320, 760, 0.16, vol=0.4))
    # place: soft thock (drop a shape/sticker)
    write_wav("place", pluck(480, 0.10, bright=0.25, vol=0.5))
    # whoosh: filtered noise sweep
    n = sec(0.35)
    noise = []
    last = 0.0
    for i in range(n):
        t = i / RATE
        env = math.sin(math.pi * t / 0.35)
        last = 0.85 * last + 0.15 * random.uniform(-1, 1)
        noise.append(0.5 * env * last)
    write_wav("whoosh", noise)

    # music_loop: gentle original music-box loop (~16s, seamless-ish)
    # melody: airy lullaby in C major
    melody = [
        (523, 0.5), (659, 0.5), (784, 0.5), (659, 0.5),
        (698, 0.5), (659, 0.5), (587, 0.5), (523, 0.5),
        (587, 0.5), (659, 0.5), (523, 0.75), (392, 0.25), (392, 0.5),
        (523, 0.5), (587, 0.5), (659, 1.0),
        (698, 0.5), (784, 0.5), (880, 0.5), (784, 0.5),
        (698, 0.5), (659, 0.5), (698, 0.5), (784, 0.5),
        (659, 0.5), (587, 0.5), (523, 0.75), (587, 0.25), (659, 0.5),
        (523, 1.0), (523, 0.5),
    ]
    bass = [131, 175, 196, 131]  # C F G C
    parts = []
    t = 0.0
    beat = 0.5
    bar = 0
    for freq, beats in melody:
        parts.append((pluck(freq, max(0.9, beats * beat + 0.4), 0.55, 0.30), sec(t)))
        if abs((t / (beat * 4)) - round(t / (beat * 4))) < 1e-6:
            b = bass[(bar // 1) % len(bass)]
            parts.append((pluck(b, 2.2, 0.2, 0.14), sec(t)))
            bar += 1
        t += beats * beat
    total = sec(t) + sec(1.5)
    music = [0.0] * total
    for samples, off in parts:
        for i, s in enumerate(samples):
            if off + i < total:
                music[off + i] += s
    # fade tail into start for smoother loop
    fade = sec(0.4)
    for i in range(fade):
        music[total - fade + i] *= (1 - i / fade)
        music[i] += music[total - fade + i] * 0.0  # keep head clean
    write_wav("music_loop", music)


if __name__ == "__main__":
    main()
