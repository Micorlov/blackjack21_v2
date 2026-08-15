#!/usr/bin/env python3
"""Regenerates every spoken clip under `assets/sfx/` in one voice.

The table's call-outs are synthesized speech, not recordings, so the whole set
can be re-cut in a different voice by running this. Clips are produced on the
build machine and shipped as assets — the phone never runs a TTS engine, so
Android and iOS play byte-identical audio.

    python3 tool/gen_voice.py                          # Kokoro, am_michael
    python3 tool/gen_voice.py --voice af_heart
    python3 tool/gen_voice.py --engine say --voice Karen --out /tmp/preview

Two engines:

  kokoro (default) — local neural TTS (Apache-2.0), what the app ships. Its
    model is ~325MB, so it lives outside the repo under $KOKORO_HOME
    (default ~/.cache/blackjack21-voice), holding `kokoro-env/` (a venv with
    kokoro-onnx and soundfile), `kokoro-v1.0.onnx` and `voices-v1.0.bin`.
    It also needs Homebrew espeak-ng (`brew install espeak-ng`): the espeak
    that ships inside `espeakng-loader` has its data path compiled in as a
    build-machine path that does not exist here, so `_kokoro_synthesize`
    redirects the loader at Homebrew's copy before importing Kokoro.

  say — macOS built-in voices. Kept for quick auditions; every voice it offers
    is from the old compact set and none sound human enough to ship.

`say` silently substitutes a fallback voice for a name it does not have rather
than failing, so `--engine say` fingerprints that fallback and refuses to run
if the requested voice matches it. A whole set was nearly cut in the wrong
voice that way.

Each clip is trimmed to its own edges, peak-normalised so no line is louder
than the rest, and faded out — `test/sfx_assets_test.dart` fails any clip still
sounding in its final 10ms, which is how a truncated `npc_stand.wav` shipped
once. See README.md's Assets section for the format contract.
"""

from __future__ import annotations

import argparse
import array
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SFX_DIR = REPO_ROOT / "assets" / "sfx"

KOKORO_HOME = Path(
    os.environ.get("KOKORO_HOME", Path.home() / ".cache" / "blackjack21-voice")
)
ESPEAK_LIB = "/opt/homebrew/lib/libespeak-ng.dylib"
ESPEAK_DATA = "/opt/homebrew/share/espeak-ng-data"

# Spoken lines announcing the hero's settled hand and each NPC seat's turn.
# Keys are paths under assets/sfx/; values are what the voice says.
VOICE_LINES: dict[str, str] = {
    "player_win.wav": "Player wins",
    "player_lose.wav": "Player lost",
    "big_win.wav": "Big win",
    "player_pot.wav": "Player wins the sweep pot",
    "npc_stand.wav": "Stand",
    "npc_bust.wav": "Bust",
}

# Number words stitched into the spoken pot figure by SoundPlayer.playWords.
# Must stay in step with spoken_amount.dart, which decides the word order —
# a word it can emit without a clip here is silent at runtime, not an error.
_ONES = [
    "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    "seventeen", "eighteen", "nineteen",
]
_TENS = ["twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

NUMBER_WORDS: dict[str, str] = {
    **{f"num/{w}.wav": w for w in _ONES + _TENS},
    "num/hundred.wav": "hundred",
    "num/thousand.wav": "thousand",
    "num/dollars.wav": "dollars",
    "num/sweep_pot.wav": "Sweep pot",
    "num/you_have.wav": "You have",
}

CLIPS: dict[str, str] = {**VOICE_LINES, **NUMBER_WORDS}

SAMPLE_RATE = 44100
TARGET_PEAK_DBFS = -6.5
FADE_OUT_MS = 15
# Lead-in kept ahead of the first audible sample, so a word does not start on
# its own attack transient.
LEAD_IN_MS = 5
# Trim thresholds as a share of the clip's own peak. The tail is cut looser than
# the head so a word keeps its natural decay rather than ending abruptly.
HEAD_THRESHOLD = 0.02
TAIL_THRESHOLD = 0.005

FULL_SCALE = 32767

# Run inside the Kokoro venv. Every clip is synthesized in one process because
# loading the model costs far more than a single line does.
_KOKORO_SCRIPT = r"""
import json, sys
from pathlib import Path

home, lib, data, voice, speed, jobs_path, out_dir = sys.argv[1:8]

# espeakng-loader ships an espeak whose data path is compiled in as the path it
# had on its build machine, so point both it and phonemizer at Homebrew's copy
# before anything imports them.
import espeakng_loader
espeakng_loader.get_data_path = lambda: data
espeakng_loader.get_library_path = lambda: lib
from phonemizer.backend.espeak.wrapper import EspeakWrapper
EspeakWrapper.set_library(lib)
EspeakWrapper.set_data_path(data)

from kokoro_onnx import Kokoro
import soundfile as sf

kokoro = Kokoro(str(Path(home) / "kokoro-v1.0.onnx"), str(Path(home) / "voices-v1.0.bin"))
if voice not in kokoro.get_voices():
    raise SystemExit(f"unknown Kokoro voice {voice!r}")

for key, text in json.loads(Path(jobs_path).read_text()).items():
    samples, rate = kokoro.create(text, voice=voice, speed=float(speed), lang="en-us")
    sf.write(str(Path(out_dir) / f"{key}.wav"), samples, rate)
"""


def _clip_key(name: str) -> str:
    """A flat filename for a clip path, so num/one.wav can share a temp dir."""
    return name.replace("/", "__").removesuffix(".wav")


def kokoro_synthesize(voice: str, speed: float, out_dir: Path, clips: dict[str, str]) -> None:
    """Writes one raw WAV per clip in `clips` into `out_dir`, at Kokoro's own rate."""
    python = KOKORO_HOME / "kokoro-env" / "bin" / "python"
    if not python.exists():
        raise SystemExit(
            f"No Kokoro venv at {python}. See this file's docstring for setup."
        )
    if not Path(ESPEAK_DATA).is_dir():
        raise SystemExit(f"No espeak-ng data at {ESPEAK_DATA}. brew install espeak-ng")

    jobs = {_clip_key(name): text for name, text in clips.items()}
    jobs_file = out_dir / "jobs.json"
    jobs_file.write_text(json.dumps(jobs))

    subprocess.run(
        [
            str(python), "-c", _KOKORO_SCRIPT,
            str(KOKORO_HOME), ESPEAK_LIB, ESPEAK_DATA,
            voice, str(speed), str(jobs_file), str(out_dir),
        ],
        check=True,
    )


def say_to_wav(text: str, voice: str, rate: int | None, dest: Path) -> None:
    """Synthesizes `text` straight to a mono 16-bit 44.1kHz WAV."""
    cmd = [
        "say", "-v", voice,
        "--data-format=LEI16@44100", "--channels=1",
        "-o", str(dest),
    ]
    if rate is not None:
        cmd += ["-r", str(rate)]
    cmd.append(text)
    subprocess.run(cmd, check=True, capture_output=True)


def to_asset_format(src: Path, dest: Path) -> None:
    """Resamples to the mono 16-bit 44.1kHz every clip in assets/sfx/ uses."""
    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error", "-i", str(src),
            "-ar", str(SAMPLE_RATE), "-ac", "1", "-sample_fmt", "s16", str(dest),
        ],
        check=True,
    )


def read_samples(path: Path) -> array.array:
    with wave.open(str(path), "rb") as wav:
        if wav.getnchannels() != 1 or wav.getsampwidth() != 2:
            raise SystemExit(f"{path} is not mono 16-bit")
        if wav.getframerate() != SAMPLE_RATE:
            raise SystemExit(f"{path} is {wav.getframerate()}Hz, expected {SAMPLE_RATE}")
        samples = array.array("h")
        samples.frombytes(wav.readframes(wav.getnframes()))
    if sys.byteorder == "big":
        samples.byteswap()
    return samples


def write_samples(samples: array.array, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = array.array("h", samples)
    if sys.byteorder == "big":
        out.byteswap()
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(out.tobytes())


def trim(samples: array.array) -> array.array:
    """Cuts the silence the engine leaves around the word, keeping its decay."""
    peak = max((abs(s) for s in samples), default=0)
    if peak == 0:
        raise SystemExit("clip is silent")

    head_floor = peak * HEAD_THRESHOLD
    tail_floor = peak * TAIL_THRESHOLD

    first = next(i for i, s in enumerate(samples) if abs(s) >= head_floor)
    last = next(
        i for i in range(len(samples) - 1, -1, -1) if abs(samples[i]) >= tail_floor
    )

    lead_in = SAMPLE_RATE * LEAD_IN_MS // 1000
    start = max(0, first - lead_in)
    return samples[start : last + 1]


def normalize(samples: array.array) -> array.array:
    """Scales the clip so its loudest sample sits at TARGET_PEAK_DBFS."""
    peak = max(abs(s) for s in samples)
    target = FULL_SCALE * (10 ** (TARGET_PEAK_DBFS / 20))
    gain = target / peak
    return array.array(
        "h", (max(-FULL_SCALE, min(FULL_SCALE, int(round(s * gain)))) for s in samples)
    )


def fade_out(samples: array.array) -> array.array:
    """Ramps the last FADE_OUT_MS to silence so no clip ends on a click."""
    frames = min(SAMPLE_RATE * FADE_OUT_MS // 1000, len(samples))
    faded = array.array("h", samples)
    start = len(faded) - frames
    for i in range(frames):
        faded[start + i] = int(round(faded[start + i] * (1 - (i + 1) / frames)))
    return faded


def tail_ratio(samples: array.array, window_ms: int = 10) -> float:
    """The share of its own peak a clip still plays at in its final moments —
    the same measure `test/sfx_assets_test.dart` fails a clip on."""
    peak = max(abs(s) for s in samples)
    frames = SAMPLE_RATE * window_ms // 1000
    tail = samples[max(0, len(samples) - frames) :]
    return max(abs(s) for s in tail) / peak


# "Samantha            en_US    # Hello!" and "Reed (English (US)) en_US    # …"
# both have to parse, so the locale is the anchor rather than the whitespace.
_VOICE_LINE = re.compile(r"^(?P<name>.+?)\s+(?P<locale>[a-z]{2}(?:_[A-Z]{2})?)\s+#")


def installed_say_voices() -> list[str]:
    """English voice names `say` lists on this machine."""
    listing = subprocess.run(
        ["say", "-v", "?"], check=True, capture_output=True, text=True
    ).stdout
    names = []
    for line in listing.splitlines():
        found = _VOICE_LINE.match(line)
        if found and found["locale"].startswith("en"):
            names.append(found["name"].strip())
    return names


def _say_fingerprint(voice: str) -> str:
    """Hash of one line spoken by `voice`, for spotting a silent substitution."""
    with tempfile.NamedTemporaryFile(suffix=".wav") as probe:
        say_to_wav("Player wins", voice, None, Path(probe.name))
        return hashlib.md5(Path(probe.name).read_bytes()).hexdigest()


def check_say_voice(voice: str) -> None:
    """Rejects a voice `say` would quietly swap for its fallback.

    `say -v Alex` on a machine without Alex returns success and audio — in the
    fallback voice. Nothing downstream can tell, so the whole set gets cut in
    the wrong voice. Comparing against a deliberately absent name catches it.
    """
    if voice not in installed_say_voices():
        raise SystemExit(
            f"Voice {voice!r} is not installed. Run with --list to see what is."
        )
    if _say_fingerprint(voice) == _say_fingerprint("ZzzNoSuchVoice"):
        raise SystemExit(
            f"`say` produced its fallback voice for {voice!r} rather than the "
            "voice itself — it is listed but not usable. Pick another."
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--engine", choices=("kokoro", "say"), default="kokoro",
        help="synthesizer to use (default: %(default)s)",
    )
    parser.add_argument(
        "--voice", default="am_michael",
        help="Kokoro voice id, or a macOS voice name for --engine say "
             "(default: %(default)s)",
    )
    parser.add_argument(
        "--speed", type=float, default=1.0, help="Kokoro speaking rate"
    )
    parser.add_argument("--rate", type=int, default=None, help="`say` words per minute")
    parser.add_argument(
        "--out", type=Path, default=SFX_DIR,
        help="where to write the clips (default: assets/sfx/)",
    )
    parser.add_argument(
        "--list", action="store_true", help="list this machine's `say` voices and exit"
    )
    parser.add_argument(
        "--only", action="append",
        help="regenerate just this clip path (e.g. num/you_have.wav) instead of the "
             "whole set; repeatable",
    )
    args = parser.parse_args()

    if args.list:
        print("\n".join(installed_say_voices()))
        return 0

    if args.engine == "say":
        check_say_voice(args.voice)

    clips = {name: CLIPS[name] for name in args.only} if args.only else CLIPS

    print(f"Engine: {args.engine}    Voice: {args.voice}\n")
    tmp = Path(tempfile.mkdtemp(prefix="gen_voice_"))
    try:
        if args.engine == "kokoro":
            kokoro_synthesize(args.voice, args.speed, tmp, clips)

        for name, text in clips.items():
            raw = tmp / f"{_clip_key(name)}.wav"
            if args.engine == "say":
                say_to_wav(text, args.voice, args.rate, raw)

            converted = tmp / f"{_clip_key(name)}_44k.wav"
            to_asset_format(raw, converted)

            samples = fade_out(normalize(trim(read_samples(converted))))
            write_samples(samples, args.out / name)
            print(
                f"  {name:<24} {len(samples) / SAMPLE_RATE:5.3f}s  "
                f"tail {tail_ratio(samples) * 100:4.1f}%  “{text}”"
            )
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    pot_ms = round(len(read_samples(args.out / "player_pot.wav")) / SAMPLE_RATE * 1000)
    print(
        f"\nplayer_pot.wav is {pot_ms}ms. `_kPotVoiceLength` in "
        "lib/state/game_notifier.dart schedules the drum flourish off this "
        "length — update it if it has moved."
    )
    print(f"{len(CLIPS)} clips written to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
