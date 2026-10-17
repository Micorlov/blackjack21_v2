#!/usr/bin/env python3
"""Cut the landscape Play/YouTube trailer: the icon dealer explains the game.

The dealer from the app icon (`play-assets/src/icon-master.png`) presents the
game in her own voice. She opens and closes the trailer full frame; in between
she stands on the left and talks in speech bubbles while a real gameplay
recording (an `adb shell screenrecord` capture, never a mockup) plays in a
phone on the right.

Landscape, because Play shows the trailer in a 16:9 hero banner above the
listing: a portrait video there is a thin strip with black bars either side.
The bubbles carry every spoken line as text too, since Play autoplays that
banner muted.

Her voice is Kokoro `af_heart`, synthesized through `gen_voice.py`, so it needs
the same local Kokoro install that file documents. The sound bed is the game's
own table effects from `Unity/Assets/Resources/Sfx`.

Frames are composed with Pillow and piped straight into ffmpeg, so every layer
(presenter, phone, bubbles) keeps its own motion across scene cuts.

Run: python3 tool/make_trailer.py <recording.mp4> <out.mp4>
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

import gen_voice

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / 'Unity' / 'Assets' / 'Resources' / 'Fonts'
SFX = ROOT / 'Unity' / 'Assets' / 'Resources' / 'Sfx'
DEALER = ROOT / 'play-assets' / 'src' / 'icon-master.png'

W, H, FPS = 1920, 1080, 30
VOICE = 'af_heart'
GOLD = (232, 182, 76)
INK = (27, 20, 16)
PAPER = (255, 248, 236)
WHITE = (255, 255, 255)

# Phone: the 1080x2340 recording scaled into a bezel on the right.
SCREEN_H = 1000
SCREEN_W = round(SCREEN_H * 1080 / 2340)
BEZEL = 12
PHONE_X = W - 110 - (SCREEN_W + 2 * BEZEL)
PHONE_Y = (H - (SCREEN_H + 2 * BEZEL)) // 2

# Presenter: the part of the icon master shown on the left during gameplay
# (source pixels). She fades out to the right over PANEL_FADE (panel x).
PANEL_CROP = (50, 40, 905, 1140)
PANEL_FADE = (600, 840)
PANEL_DRIFT = 0.05               # slow push-in over the whole gameplay run

# Speech bubbles: top-left corner, width, and where the tail points (frame px).
GAME_BUBBLE = ((830, 190), 470, (770, 300))
PORTRAIT_BUBBLE = ((1400, 110), 440, (1330, 270))

# Portrait shots: the icon master filling the frame, with a slow push-in.
PORTRAIT_TOP = 110               # source y the 16:9 crop starts at
PORTRAIT_ZOOM = 0.06

VOICE_GAIN, SFX_GAIN = 1.0, 0.35
LOUDNESS = -16                   # integrated LUFS of the final mix
POP = 0.18                       # seconds a bubble takes to pop in
FADE = 0.4                       # fade from / to black at either end


@dataclass
class Scene:
    """One beat. `src` is where it starts in the recording (None = a full-frame
    portrait shot); `voice_at` is when she starts talking, from scene start;
    `sfx` lists (recording time, Sfx clip name) for the table's own sounds."""
    key: str
    dur: float
    line: str
    src: float | None = None
    voice_at: float = 0.35
    sfx: list = field(default_factory=list)
    title: str | None = None


# Timings read off the recording (see README, Regenerating the store assets).
SCENES = [
    Scene('intro', 3.8, "Hi, I'm your dealer. Welcome to Blackjack 21!",
          title='Big Cards Offline'),
    Scene('bet', 4.6, 'Pick your chips, and place your bet.', src=53.6,
          sfx=[(55.8, 'chip'), (56.8, 'chip'), (57.7, 'deal')]),
    Scene('table', 4.2, 'You play at a five-seat table, against four players, and me.',
          src=7.0),
    Scene('rule', 3.9, 'Get closer to twenty-one than I do, without going over.',
          src=14.5),
    Scene('hit', 3.6, 'Hit for another card, or stand.', src=19.0,
          sfx=[(20.6, 'deal')]),
    Scene('beat', 4.2, 'Beat me, and you win your bet.', src=84.6, voice_at=1.4,
          sfx=[(86.6, 'deal')]),
    Scene('sweep', 6.0, 'Beat the whole table, and you sweep the pot!', src=88.8,
          voice_at=0.7, sfx=[(89.2, 'pot_celebration')]),
    Scene('end', 5.4, 'Big cards, no wifi needed, and free chips every day. '
          'Pull up a seat!', title='Free on Google Play'),
]


def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


def run(*args):
    subprocess.run([str(a) for a in args], check=True, capture_output=True)


def duration(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
                          '-of', 'csv=p=0', str(path)], capture_output=True, text=True,
                         check=True).stdout
    return float(out)


def wrap(draw, text, fnt, max_w):
    lines, cur = [], ''
    for word in text.split():
        trial = f'{cur} {word}'.strip()
        if cur and draw.textlength(trial, font=fnt) > max_w:
            lines.append(cur)
            cur = word
        else:
            cur = trial
    return lines + [cur]


def bubble(text, spec):
    """A speech bubble with its tail pointing at the speaker. Returns the RGBA
    layer and the frame position to paste it at."""
    (bx, by), width, (tx, ty) = spec
    fnt = font('Sora-SemiBold.ttf', 44)
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    lines = wrap(probe, text, fnt, width - 2 * 36)
    height = 2 * 30 + len(lines) * 58
    pad = 60
    ox, oy = pad + (bx - tx), pad          # bubble corner inside the layer
    img = Image.new('RGBA', (ox + width + pad, oy + height + pad), (0, 0, 0, 0))
    shadow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [ox, oy + 10, ox + width, oy + height + 10], 24, fill=(0, 0, 0, 120))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(14)))
    d = ImageDraw.Draw(img)
    mid = oy + min(height // 2, 64)
    tip = (ox - (bx - tx), oy + (ty - by))
    d.polygon([(ox + 2, mid - 22), (ox + 2, mid + 22), tip], fill=PAPER)
    d.rounded_rectangle([ox, oy, ox + width, oy + height], 24, fill=PAPER)
    for i, line in enumerate(lines):
        d.text((ox + 36, oy + 30 + i * 58), line, font=fnt, fill=INK)
    return img, (bx - ox, by - oy)


def faded(img, k):
    if k >= 1:
        return img
    out = img.copy()
    out.putalpha(img.getchannel('A').point(lambda v: int(v * k)))
    return out


def place_bubble(frame, layer, t, start):
    """Pops the bubble in at `start` (scene time) and holds it."""
    if t < start:
        return
    k = min(1.0, (t - start) / POP)
    img, (x, y) = layer
    frame.alpha_composite(faded(img, k), (x, y + int(14 * (1 - k))))


def scrim(top, bottom, alpha):
    """A vertical black gradient from transparent at `top` to `alpha` at `bottom`."""
    g = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    for y in range(top, H):
        a = int(alpha * min(1.0, (y - top) / max(1, bottom - top)))
        d.line([(0, y), (W, y)], fill=(0, 0, 0, a))
    return g


def title_layer(sub):
    """Bottom-left title block for the portrait shots."""
    layer = scrim(560, 1000, 225)
    d = ImageDraw.Draw(layer)
    d.text((96, 730), 'Blackjack 21', font=font('InstrumentSerif-Italic.ttf', 140), fill=WHITE)
    d.text((100, 900), sub, font=font('Sora-SemiBold.ttf', 56), fill=GOLD)
    d.text((100, 980), 'Free  ·  No ads  ·  No real money', font=font('Sora-Regular.ttf', 32),
           fill=(226, 214, 196))
    return layer


def portrait_frame(dealer, t, dur):
    z = 1 + PORTRAIT_ZOOM * t / dur
    cw = dealer.width / z
    ch = cw * H / W
    x0 = (dealer.width - cw) / 2
    box = (x0, PORTRAIT_TOP, x0 + cw, PORTRAIT_TOP + ch)
    return dealer.resize((W, H), Image.BICUBIC, box=box).convert('RGBA')


def game_background(dealer):
    """The casino behind her, blurred and dimmed so the phone reads on top."""
    bg = dealer.resize((W, W), Image.BICUBIC).crop((0, 300, W, 300 + H))
    bg = bg.filter(ImageFilter.GaussianBlur(28)).convert('RGBA')
    bg.alpha_composite(Image.new('RGBA', (W, H), (8, 20, 15, 175)))
    return bg


def presenter_panel(dealer):
    panel = dealer.crop(PANEL_CROP).convert('RGBA')
    panel = panel.resize((round(panel.width * H / panel.height), H), Image.LANCZOS)
    mask = Image.new('L', panel.size, 255)
    d = ImageDraw.Draw(mask)
    a, b = PANEL_FADE
    for x in range(a, panel.width):
        d.line([(x, 0), (x, H)], fill=int(255 * max(0.0, 1 - (x - a) / (b - a))))
    panel.putalpha(mask)
    return panel


def phone_bezel():
    """The phone body with its drop shadow; the screen sits 40+BEZEL px in."""
    w, h = SCREEN_W + 2 * BEZEL, SCREEN_H + 2 * BEZEL
    shadow = Image.new('RGBA', (w + 80, h + 80), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([40, 52, 40 + w, 52 + h], 48, fill=(0, 0, 0, 160))
    img = shadow.filter(ImageFilter.GaussianBlur(18))
    ImageDraw.Draw(img).rounded_rectangle([40, 40, 40 + w, 40 + h], 48, fill=(14, 12, 10, 255),
                                          outline=(92, 74, 46, 255), width=3)
    return img


def screen_mask():
    m = Image.new('L', (SCREEN_W, SCREEN_H), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, SCREEN_W - 1, SCREEN_H - 1], 36, fill=255)
    return m


def gameplay_frames(rec, start, n):
    """Yields `n` frames of the recording from `start`, already phone-sized."""
    proc = subprocess.Popen(
        ['ffmpeg', '-v', 'error', '-ss', str(start), '-i', str(rec), '-frames:v', str(n),
         '-vf', f'fps={FPS},scale={SCREEN_W}:{SCREEN_H}', '-f', 'rawvideo',
         '-pix_fmt', 'rgb24', '-'],
        stdout=subprocess.PIPE)
    size = SCREEN_W * SCREEN_H * 3
    last = None
    for _ in range(n):
        raw = proc.stdout.read(size)
        if len(raw) == size:
            last = Image.frombytes('RGB', (SCREEN_W, SCREEN_H), raw)
        if last is None:
            raise SystemExit(f'recording has no frames at {start}s')
        yield last
    proc.stdout.close()
    proc.wait()


class Composer:
    """Renders every scene's frames onto one continuous timeline."""

    def __init__(self, rec):
        self.rec = rec
        self.dealer = Image.open(DEALER).convert('RGB')
        self.bg = game_background(self.dealer)
        self.panel = presenter_panel(self.dealer)
        self.bezel = phone_bezel()
        self.mask = screen_mask()
        self.game_t = 0.0
        self.game_total = sum(s.dur for s in SCENES if s.src is not None)

    def frames(self, scene):
        n = round(scene.dur * FPS)
        if scene.src is None:
            yield from self._portrait(scene, n)
        else:
            yield from self._gameplay(scene, n)

    def _portrait(self, scene, n):
        layer = bubble(scene.line, PORTRAIT_BUBBLE)
        title = title_layer(scene.title)
        for i in range(n):
            t = i / FPS
            frame = portrait_frame(self.dealer, t, scene.dur)
            frame.alpha_composite(title)
            place_bubble(frame, layer, t, scene.voice_at)
            yield frame

    def _gameplay(self, scene, n):
        layer = bubble(scene.line, GAME_BUBBLE)
        for i, screen in enumerate(gameplay_frames(self.rec, scene.src, n)):
            t = i / FPS
            frame = self.bg.copy()
            self._presenter(frame, self.game_t + t)
            frame.alpha_composite(self.bezel, (PHONE_X - 40, PHONE_Y - 40))
            frame.paste(screen, (PHONE_X + BEZEL, PHONE_Y + BEZEL), self.mask)
            place_bubble(frame, layer, t, scene.voice_at)
            yield frame
        self.game_t += scene.dur

    def _presenter(self, frame, t):
        s = 1 + PANEL_DRIFT * t / self.game_total
        w, h = round(self.panel.width * s), round(H * s)
        panel = self.panel.resize((w, h), Image.BILINEAR)
        frame.alpha_composite(panel, (-(w - self.panel.width) // 2, H - h))


def narration(tmp):
    """Her lines as WAVs, checked to fit inside their scenes."""
    gen_voice.kokoro_synthesize(VOICE, 1.0, tmp, {s.key: s.line for s in SCENES})
    for s in SCENES:
        spoken = duration(tmp / f'{s.key}.wav')
        if s.voice_at + spoken > s.dur:
            raise SystemExit(f'{s.key}: line runs {spoken:.2f}s, longer than its scene')


def soundtrack(tmp, total):
    """Mixes her voice and the table's own sounds at their scene times."""
    cues, t = [], 0.0
    for s in SCENES:
        cues.append((tmp / f'{s.key}.wav', t + s.voice_at, VOICE_GAIN))
        cues += [(SFX / f'{name}.wav', t + at - s.src, SFX_GAIN) for at, name in s.sfx]
        t += s.dur
    args, chains = ['ffmpeg', '-v', 'error', '-y'], []
    for i, (path, at, gain) in enumerate(cues):
        args += ['-i', str(path)]
        ms = int(at * 1000)
        chains.append(f'[{i}:a]aresample=48000,aformat=channel_layouts=stereo,'
                      f'adelay={ms}|{ms},volume={gain}[a{i}]')
    mix = ''.join(f'[a{i}]' for i in range(len(cues)))
    # loudnorm brings the mix to YouTube's playback loudness; it resamples
    # internally, hence the aresample after it.
    chains.append(f'{mix}amix=inputs={len(cues)}:normalize=0,apad,atrim=0:{total},'
                  f'loudnorm=I={LOUDNESS}:TP=-1.5:LRA=11,aresample=48000,'
                  f'afade=t=out:st={total - FADE}:d={FADE}[out]')
    out = tmp / 'mix.wav'
    run(*args, '-filter_complex', ';'.join(chains), '-map', '[out]', out)
    return out


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    rec, out = Path(sys.argv[1]), Path(sys.argv[2])
    tmp = Path(tempfile.mkdtemp())
    narration(tmp)
    total = sum(s.dur for s in SCENES)
    audio = soundtrack(tmp, total)
    enc = subprocess.Popen(
        ['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba',
         '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-', '-i', str(audio),
         '-vf', f'fade=in:st=0:d={FADE},fade=out:st={total - FADE}:d={FADE},format=yuv420p',
         '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-c:a', 'aac', '-b:a', '192k',
         '-movflags', '+faststart', '-shortest', str(out)],
        stdin=subprocess.PIPE)
    composer = Composer(rec)
    for scene in SCENES:
        for frame in composer.frames(scene):
            enc.stdin.write(frame.tobytes())
    enc.stdin.close()
    if enc.wait() != 0:
        raise SystemExit('ffmpeg failed to encode the trailer')
    print('wrote', out)


if __name__ == '__main__':
    main()
