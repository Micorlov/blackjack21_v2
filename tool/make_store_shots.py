#!/usr/bin/env python3
"""Compose Play Store screenshots from raw device captures.

Each store shot is a caption band over the capture, on the same felt-green
gradient as the feature graphic. The caption exists because the store shows
these as small thumbnails, where the app's own text is unreadable — the band
is the only part a browsing player actually reads.

Raw captures come from `adb exec-out screencap` (see README, Play assets).
Run: python3 tool/make_store_shots.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / 'play-assets' / 'raw'
OUT = ROOT / 'play-assets'

# Play rejects a screenshot whose long side is more than twice its short side,
# and a raw 1344x2992 capture is 1:2.23 — so the canvas is exactly 2:1 and the
# capture is scaled to sit inside it under the caption band.
W, H = 1344, 2688
BAND = 380           # caption band height
GAP = 26
GOLD = (232, 182, 76)
WHITE = (255, 255, 255)

# (raw file, caption line 1, caption line 2 — line 2 is drawn in gold)
SHOTS = [
    ('04-your-turn.png', 'Big cards you can', 'actually read'),
    ('07-sweep-win.png', 'Beat the table.', 'Sweep the pot.'),
    ('02-playing.png', 'Every seat, every hand,', 'in front of you'),
    ('01-table-bet.png', 'Learn blackjack 21', 'in three hands'),
    ('03-actions.png', 'Double, split, surrender.', 'Blackjack pays 3:2'),
    ('10-friends.png', 'Invite friends with', 'one WhatsApp link'),
    ('09-daily.png', 'Free chips every day,', 'and a 7-day streak'),
    ('14-howtoplay.png', 'Full rules, always', 'one tap away'),
]

def font(size, bold=True):
    for path in (
        '/System/Library/Fonts/Helvetica.ttc',
        '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
        '/Library/Fonts/Arial.ttf',
    ):
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size, index=1 if bold and path.endswith('.ttc') else 0)
            except OSError:
                continue
    return ImageFont.load_default(size)

def felt(w, h):
    """The same dark-to-green radial ground the feature graphic uses."""
    bg = Image.new('RGB', (w, h), (7, 39, 29))
    d = ImageDraw.Draw(bg)
    cx, cy = w // 2, int(h * 0.10)
    for i in range(220, 0, -1):
        r = int(i / 220 * max(w, h) * 1.15)
        t = i / 220
        col = (int(7 + 20 * (1 - t)), int(39 + 68 * (1 - t)), int(29 + 50 * (1 - t)))
        d.ellipse([cx - r, cy - r, cx + r, cy + int(r * 1.4)], fill=col)
    return bg

def centered(draw, text, y, f, fill):
    w = draw.textbbox((0, 0), text, font=f)[2]
    draw.text(((W - w) // 2, y), text, font=f, fill=fill)

def compose(raw_name, line1, line2, index):
    shot = Image.open(RAW / raw_name).convert('RGB')
    canvas = felt(W, H)
    draw = ImageDraw.Draw(canvas)

    f = font(96)
    centered(draw, line1, 96, f, WHITE)
    centered(draw, line2, 96 + 118, f, GOLD)

    # The capture keeps its aspect ratio and sits below the band, framed.
    avail_h = H - BAND - GAP * 2
    scale = min((W - 120) / shot.width, avail_h / shot.height)
    new = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)

    frame = Image.new('RGB', (new.width + 8, new.height + 8), (60, 48, 22))
    frame.paste(new, (4, 4))
    canvas.paste(frame, ((W - frame.width) // 2, BAND))

    out = OUT / f'screen-{index:02d}.png'
    canvas.save(out, optimize=True)
    print(f'{out.name}  <-  {raw_name}  ({line1} {line2})')

for i, (raw, l1, l2) in enumerate(SHOTS, start=1):
    compose(raw, l1, l2, i)

# Tablet sets. Play lists 7-inch and 10-inch separately, and a listing with
# both qualifies for tablet search surfaces; two shots each is the minimum.
TABLETS = [
    ('tab7', 1200, 1920, [
        ('t7-playing.png', 'Every seat, every hand,', 'on one screen'),
        ('t7-table-bet.png', 'Big cards you can', 'actually read'),
    ]),
    ('tab10', 1600, 2560, [
        ('t10-playing.png', 'Every seat, every hand,', 'on one screen'),
        ('t10-table.png', 'Big cards you can', 'actually read'),
    ]),
]

def compose_sized(raw_name, line1, line2, out_name, w, h):
    global W, H, BAND
    W, H, BAND = w, h, int(h * 0.15)
    shot = Image.open(RAW / raw_name).convert('RGB')
    canvas = felt(W, H)
    draw = ImageDraw.Draw(canvas)
    size = int(w * 0.068)
    f = font(size)
    centered(draw, line1, int(BAND * 0.20), f, WHITE)
    centered(draw, line2, int(BAND * 0.20) + int(size * 1.22), f, GOLD)

    avail_h = H - BAND - GAP * 2
    scale = min((W - 100) / shot.width, avail_h / shot.height)
    new = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)
    frame = Image.new('RGB', (new.width + 8, new.height + 8), (60, 48, 22))
    frame.paste(new, (4, 4))
    canvas.paste(frame, ((W - frame.width) // 2, BAND))
    out = OUT / out_name
    canvas.save(out, optimize=True)
    print(f'{out.name}  <-  {raw_name}  ({w}x{h})')

for prefix, w, h, shots in TABLETS:
    for i, (raw, l1, l2) in enumerate(shots, start=1):
        compose_sized(raw, l1, l2, f'{prefix}-{i:02d}.png', w, h)
