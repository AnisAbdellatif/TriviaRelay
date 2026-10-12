#!/usr/bin/env python3
"""
Writes the app's game sounds (app/assets/sounds/*.wav), synthesized here from plain tones
so that every one is ours: no sample, recording or other app's audio goes into them.

    python3 scripts/make_sounds.py

Standard library only, and deterministic: running it again writes the same bytes, so the
files in the repository can be checked against this script. 22.05 kHz, 16-bit mono,
short enough that each is a few kilobytes.

    start     the game begins: a rising four-note run
    question  a question opens: two bright notes
    submit    your answer is locked in: a quick upward blip
    correct   you got it right: a rising major third, with a sparkle
    wrong     you got it wrong: a soft falling pair, low
    tick      one of the last five seconds: a short woodblock-like tick

And one for each reaction another player can send (reaction_<type>.wav, the types in
protocol/fixtures/constants.json's `reaction_sounds`), each a small cartoon of its name
made from tones and seeded noise:

    goose         a double horn honk
    cow           a low, slow moo
    donkey        a hee-haw, twice
    goat          a wavering bleat
    rooster       a rising crow
    sheep         a trembling baa
    soccer_cheer  a crowd's roar swelling and falling
    aww           a soft falling "aww"
    clap          a patter of claps
    ooh           a soft rising "ooh"
    laugh         a quick falling "ha-ha-ha-ha"
    accordion     a wheezing major chord
    rim_shot      two drum hits and a cymbal
    trombone      the sad falling "wah wah wah waaah"
    trumpet       a short rising fanfare
    tuba          a low oom-pah
"""

import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "sounds"


def note(name):
    """Frequency of a note like "C5" or "F#4" (A4 = 440 Hz)."""
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    semis = names[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        semis += 1
        rest = rest[1:]
    elif rest.startswith("b"):
        semis -= 1
        rest = rest[1:]
    octave = int(rest)
    return 440.0 * 2 ** ((semis + 12 * (octave - 4)) / 12)


def envelope(i, n, attack=0.004, release=None):
    """A soft attack and an exponential fall, so nothing clicks at either end."""
    t = i / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    length = n / RATE
    release = release if release is not None else length
    decay = math.exp(-4.0 * t / release)
    tail = min(1.0, (n - i) / (0.004 * RATE))
    return a * decay * tail


def tone(freq, seconds, volume=0.45, harmonics=(1.0, 0.25, 0.08), release=None, sweep_to=None):
    """A tone with a few harmonics; `sweep_to` glides the pitch to another frequency."""
    n = int(seconds * RATE)
    out = []
    phase = 0.0
    for i in range(n):
        f = freq if sweep_to is None else freq + (sweep_to - freq) * (i / n)
        phase += 2 * math.pi * f / RATE
        s = sum(h * math.sin(phase * (k + 1)) for k, h in enumerate(harmonics))
        s /= sum(harmonics)
        out.append(volume * s * envelope(i, n, release=release))
    return out


class Noise:
    """Seeded white noise (a linear congruential generator), so every run is the same."""

    def __init__(self, seed):
        self.state = seed

    def next(self):
        self.state = (1103515245 * self.state + 12345) % 2**31
        return self.state / 2**30 - 1.0


def noise(seconds, seed, volume=0.4, smooth=0.0, attack=0.002, release=None):
    """Noise through a one-pole low-pass (`smooth` 0: bright, towards 1: dull)."""
    n = int(seconds * RATE)
    source = Noise(seed)
    out = []
    last = 0.0
    for i in range(n):
        last = smooth * last + (1 - smooth) * source.next()
        out.append(volume * last * envelope(i, n, attack=attack, release=release))
    return out


def shaped(freq_at, seconds, volume=0.45, harmonics=(1.0, 0.25, 0.08), attack=0.01,
           release=None, wobble=0.0, wobble_hz=0.0, hold=False):
    """A tone whose pitch follows `freq_at(t)` (t from 0 to 1), with an optional
    tremolo (`wobble`, 0 to 1, at `wobble_hz`). `hold` keeps it level until a short fade
    rather than decaying."""
    n = int(seconds * RATE)
    out = []
    phase = 0.0
    for i in range(n):
        f = freq_at(i / n)
        phase += 2 * math.pi * f / RATE
        s = sum(h * math.sin(phase * (k + 1)) for k, h in enumerate(harmonics))
        s /= sum(harmonics)
        trem = 1.0 - wobble * (0.5 + 0.5 * math.sin(2 * math.pi * wobble_hz * i / RATE))
        if hold:
            t = i / RATE
            a = min(1.0, t / attack) if attack > 0 else 1.0
            fade = min(1.0, (n - i) / (0.06 * RATE))
            env = a * fade
        else:
            env = envelope(i, n, attack=attack, release=release)
        out.append(volume * s * trem * env)
    return out


def glide(start, end):
    return lambda t: start + (end - start) * t


def reed(n=9):
    """Odd harmonics falling off slowly: a horn's, a reed's buzz."""
    return tuple(1.0 / (k + 1) if k % 2 == 0 else 0.35 / (k + 1) for k in range(n))


def seq(*parts):
    """Tracks one after another, each `(track, gap_after_seconds)`."""
    out = []
    for track, gap in parts:
        out += track + silence(gap)
    return out


def silence(seconds):
    return [0.0] * int(seconds * RATE)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def delayed(track, seconds):
    return silence(seconds) + track


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    # Nothing louder than 0.6 of full scale, whatever the mix added up to.
    scale = min(1.0, 0.6 / peak)
    frames = b"".join(
        struct.pack("<h", int(round(max(-1.0, min(1.0, s * scale)) * 32767))) for s in samples
    )
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f"{path.relative_to(OUT.parent.parent.parent)}  {len(samples) / RATE:.2f}s")


def main():
    run = [note(n) for n in ("C5", "E5", "G5", "C6")]
    write(
        "start",
        mix(*[delayed(tone(f, 0.28, release=0.25), 0.085 * i) for i, f in enumerate(run)]),
    )
    write(
        "question",
        mix(tone(note("G5"), 0.18, release=0.15), delayed(tone(note("D6"), 0.3, release=0.25), 0.1)),
    )
    write(
        "submit",
        tone(note("A5"), 0.09, volume=0.4, harmonics=(1.0, 0.1), release=0.08, sweep_to=note("E6")),
    )
    write(
        "correct",
        mix(
            tone(note("E5"), 0.22, release=0.2),
            delayed(tone(note("G#5"), 0.4, release=0.35), 0.11),
            delayed(tone(note("E6"), 0.35, volume=0.15, harmonics=(1.0,), release=0.2), 0.2),
        ),
    )
    write(
        "wrong",
        mix(
            tone(note("E4"), 0.2, harmonics=(1.0, 0.35, 0.2), release=0.18),
            delayed(tone(note("C4"), 0.36, harmonics=(1.0, 0.35, 0.2), release=0.3), 0.16),
        ),
    )
    write(
        "tick",
        tone(1800.0, 0.035, volume=0.35, harmonics=(1.0, 0.4), release=0.012),
    )
    reactions()


def reactions():
    honk = lambda: shaped(glide(370, 330), 0.13, harmonics=reed(), attack=0.006, hold=True)
    write("reaction_goose", seq((honk(), 0.06), (honk(), 0)))

    write(
        "reaction_cow",
        shaped(lambda t: 150 - 40 * t * t, 0.7, harmonics=reed(11), attack=0.09, hold=True,
               wobble=0.15, wobble_hz=5),
    )

    hee = lambda: shaped(glide(640, 720), 0.16, harmonics=reed(7), attack=0.01, hold=True)
    haw = lambda: shaped(glide(300, 230), 0.22, harmonics=reed(9), attack=0.01, hold=True)
    write("reaction_donkey", seq((hee(), 0.02), (haw(), 0.06), (hee(), 0.02), (haw(), 0)))

    write(
        "reaction_goat",
        shaped(glide(430, 400), 0.45, harmonics=(1.0, 0.5, 0.3, 0.2), attack=0.02, hold=True,
               wobble=0.8, wobble_hz=24),
    )

    write(
        "reaction_rooster",
        seq(
            (shaped(glide(520, 560), 0.1, harmonics=reed(7), hold=True), 0.03),
            (shaped(glide(600, 880), 0.18, harmonics=reed(7), hold=True), 0.0),
            (shaped(glide(880, 700), 0.34, harmonics=reed(7), hold=True, wobble=0.2,
                    wobble_hz=9), 0),
        ),
    )

    write(
        "reaction_sheep",
        shaped(glide(320, 290), 0.5, harmonics=(1.0, 0.6, 0.4, 0.25, 0.15), attack=0.03,
               hold=True, wobble=0.6, wobble_hz=9),
    )

    roar = noise(0.9, seed=7, volume=0.5, smooth=0.82, attack=0.25, release=0.9)
    whistle = delayed(shaped(glide(1900, 2300), 0.18, volume=0.12, harmonics=(1.0,),
                             hold=True), 0.35)
    write("reaction_soccer_cheer", mix(roar, whistle))

    write(
        "reaction_aww",
        shaped(lambda t: 560 - 200 * t, 0.6, harmonics=(1.0, 0.5, 0.25, 0.12), attack=0.05,
               hold=True, wobble=0.1, wobble_hz=6),
    )

    claps = []
    for i, at in enumerate((0.0, 0.11, 0.2, 0.33, 0.41, 0.52, 0.6)):
        claps.append(delayed(noise(0.05, seed=11 + i, volume=0.55, smooth=0.35,
                                   release=0.02), at))
    write("reaction_clap", mix(*claps))

    write(
        "reaction_ooh",
        shaped(lambda t: 330 + 190 * t, 0.55, harmonics=(1.0, 0.3, 0.08), attack=0.06,
               hold=True),
    )

    ha = lambda f: shaped(glide(f, f * 0.9), 0.08, harmonics=(1.0, 0.6, 0.35, 0.2),
                          attack=0.005, hold=True)
    write("reaction_laugh", seq(*[(ha(f), 0.05) for f in (520, 480, 450, 420)]))

    chord = [note(n) for n in ("C4", "E4", "G4", "C5")]
    write(
        "reaction_accordion",
        mix(*[shaped(lambda t, f=f: f, 0.7, volume=0.3, harmonics=reed(9), attack=0.05,
                     hold=True, wobble=0.35, wobble_hz=6.5) for f in chord]),
    )

    drum = lambda f: mix(tone(f, 0.12, volume=0.5, harmonics=(1.0, 0.2), release=0.07,
                              sweep_to=f * 0.7),
                         noise(0.06, seed=int(f), volume=0.2, smooth=0.5, release=0.03))
    cymbal = noise(0.6, seed=3, volume=0.35, smooth=0.0, release=0.45)
    write("reaction_rim_shot", mix(drum(190), delayed(drum(150), 0.14), delayed(cymbal, 0.3)))

    wah = lambda n, seconds, vib=0.0: shaped(
        lambda t, f=note(n): f * (1 - 0.03 * t), seconds, harmonics=reed(9), attack=0.03,
        hold=True, wobble=vib, wobble_hz=6)
    write(
        "reaction_trombone",
        seq((wah("A#3", 0.2), 0.04), (wah("A3", 0.2), 0.04), (wah("G#3", 0.2), 0.04),
            (wah("G3", 0.55, vib=0.35), 0)),
    )

    blast = lambda n, seconds: shaped(lambda t, f=note(n): f, seconds, volume=0.4,
                                      harmonics=(1.0, 0.8, 0.6, 0.45, 0.3, 0.2), attack=0.012,
                                      hold=True)
    write(
        "reaction_trumpet",
        seq((blast("G4", 0.1), 0.03), (blast("C5", 0.1), 0.03), (blast("E5", 0.1), 0.03),
            (blast("G5", 0.3), 0)),
    )

    oom = lambda n, seconds: shaped(lambda t, f=note(n): f, seconds, volume=0.55,
                                    harmonics=(1.0, 0.7, 0.4, 0.2), attack=0.02, hold=True)
    write("reaction_tuba", seq((oom("C2", 0.2), 0.08), (oom("G2", 0.16), 0.08),
                               (oom("C2", 0.2), 0)))


if __name__ == "__main__":
    main()
