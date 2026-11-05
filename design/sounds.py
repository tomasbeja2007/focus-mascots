#!/usr/bin/env python3
"""Synthesises the bundled sounds (original, CC0) into Shared/Sounds.

    python3 design/sounds.py
"""
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Shared", "Sounds")


def bell(freq, dur, start, total, amp=0.5, decay=3.2):
    t = np.arange(int(total * SR)) / SR
    env = np.where(t >= start, np.exp(-(t - start) * decay), 0.0)
    attack = np.clip((t - start) / 0.006, 0, 1)
    tt = np.clip(t - start, 0, None)
    tone = (
        np.sin(2 * np.pi * freq * tt)
        + 0.42 * np.sin(2 * np.pi * freq * 2.0 * tt) * np.exp(-tt * 2.5)
        + 0.18 * np.sin(2 * np.pi * freq * 3.01 * tt) * np.exp(-tt * 4.0)
        + 0.08 * np.sin(2 * np.pi * freq * 4.2 * tt) * np.exp(-tt * 6.0)
    )
    return amp * env * attack * tone


def write(name, samples):
    samples = samples / max(1e-9, np.max(np.abs(samples))) * 0.85
    pcm = (samples * 32767).astype("<i2")
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# Session complete: three rising notes (C6, E6, G6) - warm, short.
total = 2.2
s = bell(1046.5, 1.6, 0.00, total, 0.55) + bell(1318.5, 1.6, 0.14, total, 0.5) + bell(1568.0, 1.8, 0.28, total, 0.6, decay=2.4)
write("chime.wav", s)

# Break over / nudge: two soft notes (G5, C6).
total = 1.6
s = bell(784.0, 1.2, 0.0, total, 0.5, decay=3.6) + bell(1046.5, 1.4, 0.16, total, 0.55, decay=3.0)
write("nudge.wav", s)
print("sounds written to", OUT)
