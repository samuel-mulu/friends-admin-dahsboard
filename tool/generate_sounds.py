"""Generates the in-app game sound effects as small WAV assets.

Run from the repo root:  python tool/generate_sounds.py
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")


def write_wav(filename, samples):
    path = os.path.join(OUT_DIR, filename)
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        f.writeframes(frames)
    print(f"wrote {path} ({len(samples) / SAMPLE_RATE:.2f}s)")


def tone(freq, duration, volume=0.5, attack=0.005, decay=None, harmonic=0.0):
    """Sine tone with attack/exponential-decay envelope; optional 2nd harmonic."""
    n = int(SAMPLE_RATE * duration)
    decay = decay if decay is not None else duration
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = min(1.0, t / attack) * math.exp(-3.5 * t / decay)
        s = math.sin(2 * math.pi * freq * t)
        if harmonic:
            s += harmonic * math.sin(2 * math.pi * freq * 2 * t)
        out.append(volume * env * s)
    return out


def mix(*layers):
    n = max(len(layer) for layer in layers)
    out = [0.0] * n
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    peak = max(abs(s) for s in out) or 1.0
    if peak > 0.95:
        out = [s * 0.95 / peak for s in out]
    return out


def delayed(samples, seconds):
    return [0.0] * int(SAMPLE_RATE * seconds) + samples


def silence(seconds):
    return [0.0] * int(SAMPLE_RATE * seconds)


# Ball called: soft wooden pop (~0.25s) — a quick low thump with a bright tick.
ball = mix(
    tone(620, 0.22, volume=0.55, attack=0.002, decay=0.08),
    tone(310, 0.25, volume=0.35, attack=0.002, decay=0.12),
)
write_wav("ball_called.wav", ball + silence(0.05))

# Game start: upbeat 3-note ascending chime (~0.7s) C5-E5-G5.
start = mix(
    tone(523.25, 0.30, volume=0.45, decay=0.25, harmonic=0.3),
    delayed(tone(659.25, 0.30, volume=0.45, decay=0.25, harmonic=0.3), 0.14),
    delayed(tone(783.99, 0.42, volume=0.50, decay=0.38, harmonic=0.3), 0.28),
)
write_wav("game_start.wav", start + silence(0.05))

# Winner window: celebratory bell arpeggio (~1.4s) C6-E6-G6-C7.
winner = mix(
    tone(1046.5, 0.60, volume=0.40, decay=0.55, harmonic=0.25),
    delayed(tone(1318.5, 0.60, volume=0.40, decay=0.55, harmonic=0.25), 0.18),
    delayed(tone(1568.0, 0.60, volume=0.40, decay=0.55, harmonic=0.25), 0.36),
    delayed(tone(2093.0, 0.80, volume=0.45, decay=0.75, harmonic=0.2), 0.54),
)
write_wav("winner_window.wav", winner + silence(0.05))

# Valid bingo: bright two-note success ding (~0.55s) G5 -> C6.
valid = mix(
    tone(783.99, 0.25, volume=0.45, decay=0.20, harmonic=0.3),
    delayed(tone(1046.5, 0.40, volume=0.50, decay=0.35, harmonic=0.3), 0.12),
)
write_wav("bingo_valid.wav", valid + silence(0.05))
