#!/usr/bin/env python3
"""Render every app icon in the repo from one master image.

Before this script the launcher PNGs were committed as loose binaries with no
generator, and `play-assets/icon-512.png` was an upscale of the 192px launcher
icon. Everything now comes from here, so a change to the mark is one edit and
one run rather than a hand-resize of fourteen files.

Two master styles are supported, picked up automatically:

- `play-assets/src/icon-master.png` (or .jpg/.jpeg/.webp): a **fully composed**
  icon — own background, border and any text already baked in. Used as-is: a
  plain resize for every flat target, and a scaled-down copy padded with its
  own corner colour wherever the OS applies its own mask on top (Android
  adaptive icons, maskable web icons). See `load_composed_master`. Takes
  priority when present.
- `play-assets/src/dealer-1024.png` (or .jpg/.jpeg/.webp): a **subject-only
  cutout** composited onto a programmatically drawn felt background with a
  gold ring; see `load_dealer`. Falls back to a flat-vector dealer
  (`draw_dealer`) it draws itself if no such file exists, so the build never
  breaks on a missing master.

Either way, `dealer-cutout-1024.png` and `dealer-bust-1024.png` are still
rendered from the dealer pipeline for `play-assets/feature-graphic.html`,
independent of which master drives the app icon itself.

Run: python3 tool/make_icons.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
PLAY = ROOT / 'play-assets'
WEB = ROOT / 'web'
SRC = PLAY / 'src'

# Palette is the app's, not a new one: the felt stops match
# play-assets/feature-graphic.html and GOLD matches tool/make_store_shots.py.
FELT_IN = (27, 107, 79)
FELT_MID = (14, 68, 51)
FELT_OUT = (7, 39, 29)
GOLD = (232, 182, 76)

SKIN = (241, 199, 165)
SKIN_SHADE = (214, 165, 130)
HAIR = (26, 19, 24)
HAIR_LIT = (64, 45, 56)
VEST = (17, 17, 21)
VEST_LIT = (30, 30, 37)
SHIRT = (247, 245, 238)
LIPS = (197, 45, 58)
CARD = (250, 248, 242)
PIP_RED = (196, 40, 52)
PIP_BLACK = (26, 26, 30)

# Everything is drawn in a 1024-unit design space and supersampled, so the
# curves stay clean all the way down to the 48px mdpi launcher icon.
DESIGN = 1024
SS = 4

# Android density buckets. Legacy bitmaps are the pre-Oreo icon; the adaptive
# layers are always 108dp, which is why they are the larger set.
LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
ADAPTIVE = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}

# An adaptive icon is a 108dp canvas of which only the centre 72dp is ever
# guaranteed visible (66dp once a launcher uses a circular mask). The dealer is
# fitted to that 72dp window so no mask can crop her head.
ADAPTIVE_SAFE = 72 / 108

# A maskable web icon is square edge to edge and must keep its content in the
# middle 80%, because the platform supplies the shape.
MASKABLE_SAFE = 0.80

IOS_ICONS = {
    'Icon-App-20x20@1x.png': 20, 'Icon-App-20x20@2x.png': 40, 'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29, 'Icon-App-29x29@2x.png': 58, 'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40, 'Icon-App-40x40@2x.png': 80, 'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120, 'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76, 'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}
MACOS_ICONS = {f'app_icon_{n}.png': n for n in (16, 32, 64, 128, 256, 512, 1024)}


def font(size, bold=True):
    """Same system-font probe the other tool scripts use."""
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


# --------------------------------------------------------------------------
# ground
# --------------------------------------------------------------------------

def felt(size):
    """The dark-to-green radial ground, matching the feature graphic's stops.

    The light centre sits high and left of middle, the same off-centre hotspot
    feature-graphic.html uses, so the icon and the store banner read as one
    piece of art. Computed small and scaled up — it is a smooth gradient, so
    nothing is lost and a 4096px per-pixel loop is avoided.
    """
    small = max(64, size // 4)
    img = Image.new('RGB', (small, small), FELT_OUT)
    px = img.load()
    cx, cy = small * 0.30, small * 0.32
    far = math.hypot(max(cx, small - cx), max(cy, small - cy))
    for y in range(small):
        for x in range(small):
            t = min(1.0, math.hypot(x - cx, y - cy) / far)
            if t < 0.55:
                k, a, b = t / 0.55, FELT_IN, FELT_MID
            else:
                k, a, b = (t - 0.55) / 0.45, FELT_MID, FELT_OUT
            k = k * k * (3 - 2 * k)  # smoothstep, so the two stops meet without a seam
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))
    return img.resize((size, size), Image.LANCZOS)


# --------------------------------------------------------------------------
# the dealer
# --------------------------------------------------------------------------

def _spade(d, cx, cy, w, colour):
    h = w * 1.15
    d.ellipse([cx - w * 0.52, cy - h * 0.10, cx, cy + h * 0.36], fill=colour)
    d.ellipse([cx, cy - h * 0.10, cx + w * 0.52, cy + h * 0.36], fill=colour)
    d.polygon([(cx, cy - h * 0.52), (cx - w * 0.54, cy + h * 0.16), (cx + w * 0.54, cy + h * 0.16)], fill=colour)
    d.polygon([(cx, cy + h * 0.14), (cx - w * 0.26, cy + h * 0.62), (cx + w * 0.26, cy + h * 0.62)], fill=colour)


def _heart(d, cx, cy, w, colour):
    r = w * 0.29
    top = cy - w * 0.32
    for sx in (-1, 1):
        bx = cx + sx * w * 0.29
        d.ellipse([bx - r, top - r, bx + r, top + r], fill=colour)
    d.polygon([(cx - w * 0.58, top), (cx + w * 0.58, top), (cx, cy + w * 0.62)], fill=colour)


def _card(w, h, rank, suit, tilt):
    """One playing card as its own layer, so it can be rotated cleanly."""
    pad = int(max(w, h) * 0.5)
    img = Image.new('RGBA', (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, y0 = pad, pad
    r = int(w * 0.10)
    d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=r, fill=CARD)
    d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=r, outline=(214, 208, 194), width=max(1, w // 44))

    colour = PIP_BLACK if suit == 's' else PIP_RED
    (_spade if suit == 's' else _heart)(d, x0 + w * 0.50, y0 + h * 0.56, w * 0.52, colour)
    d.text((x0 + w * 0.18, y0 + h * 0.11), rank, font=font(int(h * 0.22)), fill=colour, anchor='mm')
    return img.rotate(tilt, resample=Image.BICUBIC, expand=False)


def _bez(p0, p1, p2, n=26):
    """Quadratic bezier as a point list, so hair and shoulders get real curves."""
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
                    u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]))
    return out


def _oval(cx, cy, rx, ry, taper=0.0, n=96):
    """Ellipse as a point list. `taper` narrows the lower half into a chin."""
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        s = math.sin(t)
        w = rx * (1 - taper * max(0.0, s) ** 1.5)
        out.append((cx + w * math.cos(t), cy + ry * s))
    return out


def draw_dealer(size, with_cards=True):
    """Flat-vector croupier bust on transparency, fitted to a `size` square.

    Proportioned to fill the frame: head across the top third, shoulders
    running off both bottom corners, cards fanned into the bottom-right so the
    silhouette still reads as "dealer holding cards" at 48px. Wardrobe is the
    standard covered croupier kit - black waistcoat, white shirt, gold bow tie.

    `with_cards=False` gives the bust alone, for the feature graphic, which
    already carries its own fanned-card motif and does not need a second one.
    """
    s = size * SS
    k = s / DESIGN                      # design units -> pixels
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def B(x0, y0, x1, y1):
        return [x0 * k, y0 * k, x1 * k, y1 * k]

    def P(points):
        return [(x * k, y * k) for x, y in points]

    cx = 512

    # --- neck, drawn first so the collar and jaw sit over it ---
    d.rounded_rectangle(B(cx - 76, 536, cx + 76, 790), radius=56 * k, fill=SKIN)
    d.ellipse(B(cx - 120, 496, cx + 120, 652), fill=SKIN_SHADE)   # shadow under the jaw
    d.rounded_rectangle(B(cx - 76, 592, cx + 76, 790), radius=56 * k, fill=SKIN)

    # --- waistcoat: shoulders curve out and run off both bottom corners ---
    torso = (_bez((cx - 158, 742), (cx - 380, 774), (cx - 492, 1004))
             + [(cx - 548, 1140), (cx + 548, 1140)]
             + list(reversed(_bez((cx + 158, 742), (cx + 380, 774), (cx + 492, 1004)))))
    d.polygon(P(torso), fill=VEST)
    # a lit edge along the left shoulder, matching the felt's upper-left hotspot
    d.polygon(P(_bez((cx - 168, 744), (cx - 384, 776), (cx - 496, 1006))
                + [(cx - 552, 1140), (cx - 430, 1140)]
                + list(reversed(_bez((cx - 168, 830), (cx - 316, 862), (cx - 396, 1006))))),
              fill=VEST_LIT)

    # --- shirt panel, collar, then the lapels folding back over both ---
    d.polygon(P([(cx - 84, 726), (cx + 84, 726), (cx + 116, 1140), (cx - 116, 1140)]), fill=SHIRT)
    # collar wings, small — the waistcoat should be most of what the eye sees
    for sx in (-1, 1):
        d.polygon(P([(cx + sx * 34, 700), (cx + sx * 108, 716), (cx + sx * 46, 796), (cx, 762)]), fill=SHIRT)
    d.polygon(P([(cx - 214, 718), (cx - 26, 806), (cx - 150, 1140), (cx - 320, 1140)]), fill=VEST)
    d.polygon(P([(cx + 214, 718), (cx + 26, 806), (cx + 150, 1140), (cx + 320, 1140)]), fill=VEST)

    # --- gold bow tie at the collar ---
    d.polygon(P([(cx - 92, 748), (cx - 20, 784), (cx - 92, 820)]), fill=GOLD)
    d.polygon(P([(cx + 92, 748), (cx + 20, 784), (cx + 92, 820)]), fill=GOLD)
    d.rounded_rectangle(B(cx - 25, 766, cx + 25, 804), radius=11 * k, fill=(203, 154, 56))

    # --- hair mass and the pulled-back bun, behind the face ---
    d.ellipse(B(cx - 112, 62, cx + 112, 246), fill=HAIR)
    d.ellipse(B(cx - 66, 86, cx + 34, 158), fill=HAIR_LIT)   # soft sheen, on the bun only
    d.polygon(P(_oval(cx, 396, 238, 260)), fill=HAIR)

    # --- face, tapered to a chin rather than left as a circle ---
    d.polygon(P(_oval(cx, 404, 180, 218, taper=0.30)), fill=SKIN)

    # --- hair over the brow: swept low on the left, and locks at both temples ---
    crown = [pt for pt in _oval(cx, 396, 238, 260) if pt[1] < 300]
    crown.sort(key=lambda pt: -pt[0])
    d.polygon(P(_bez((cx - 200, 296), (cx - 40, 398), (cx + 128, 312)) + crown), fill=HAIR)
    for sx in (-1, 1):
        d.polygon(P(_bez((cx + sx * 200, 300), (cx + sx * 222, 470), (cx + sx * 152, 566))
                    + list(reversed(_bez((cx + sx * 138, 300), (cx + sx * 168, 452), (cx + sx * 116, 546))))),
                  fill=HAIR)

    # --- features. Few and high-contrast, so they survive the 48px downscale ---
    for sx in (-1, 1):
        ex = cx + sx * 84
        d.polygon(P(_oval(ex, 450, 48, 29)), fill=(255, 252, 247))
        d.ellipse(B(ex - 25, 427, ex + 25, 473), fill=PIP_BLACK)
        d.ellipse(B(ex - 9, 432, ex + 4, 447), fill=(255, 255, 255))
        d.arc(B(ex - 50, 418, ex + 50, 484), 184, 356, fill=HAIR, width=max(1, int(11 * k)))
        d.arc(B(ex - 54, 366, ex + 54, 424), 196, 344, fill=HAIR, width=max(1, int(14 * k)))
    d.ellipse(B(cx - 25, 520, cx + 25, 543), fill=SKIN_SHADE)
    d.polygon(P(_bez((cx - 58, 574), (cx - 29, 546), (cx, 566)) + _bez((cx, 566), (cx + 29, 546), (cx + 58, 574))
                + [(cx + 58, 582), (cx - 58, 582)]), fill=LIPS)
    d.polygon(P(_bez((cx - 56, 576), (cx, 630), (cx + 56, 576))), fill=LIPS)

    # --- the hand of cards, fanned into the bottom-right over the waistcoat ---
    if not with_cards:
        return img.resize((size, size), Image.LANCZOS)
    cw, ch = int(188 * k), int(262 * k)
    for rank, suit, tilt, ox, oy in (('K', 'h', -26, 690, 872), ('A', 's', 6, 846, 916)):
        card = _card(cw, ch, rank, suit, tilt)
        img.alpha_composite(card, (int(ox * k) - card.width // 2, int(oy * k) - card.height // 2))

    return img.resize((size, size), Image.LANCZOS)


# A fully composed icon (own background/border/text already baked in) takes
# priority over the dealer-cutout master below.
COMPOSED_MASTER_NAMES = ('icon-master.png', 'icon-master.jpg', 'icon-master.jpeg', 'icon-master.webp')


def _composed_master_path():
    for name in COMPOSED_MASTER_NAMES:
        candidate = SRC / name
        if candidate.exists():
            return candidate
    return None


def load_composed_master():
    """A pre-composed icon, square-cropped, at its native resolution.

    Never keyed or re-cropped to a subject — it already IS the icon, edge to
    edge, so every output below is a plain resize or a padded shrink of this.
    """
    img = Image.open(_composed_master_path()).convert('RGB')
    if img.width != img.height:
        side = min(img.size)
        left, top = (img.width - side) // 2, (img.height - side) // 2
        img = img.crop((left, top, left + side, top + side))
    return img


def composed_tile(master, size):
    """Plain resize, for every target shown edge to edge with no extra mask."""
    return master.resize((size, size), Image.LANCZOS)


def composed_inset(master, size, safe, bg_color):
    """Shrink the art into a safe window padded with its own corner colour.

    For targets where the OS applies its own mask on top (Android adaptive
    icons, maskable web icons) — this keeps the gold ring and corner text
    from being clipped by a circular or squircle crop.
    """
    canvas = Image.new('RGB', (size, size), bg_color)
    inner = max(1, round(size * safe))
    art = master.resize((inner, inner), Image.LANCZOS)
    pad = (size - inner) // 2
    canvas.paste(art, (pad, pad))
    return canvas


# Filenames accepted as a dropped-in dealer-cutout master, in order of preference.
MASTER_NAMES = ('dealer-1024.png', 'dealer.png', 'dealer.jpg', 'dealer.jpeg', 'dealer.webp')


def _master_path():
    for name in MASTER_NAMES:
        candidate = SRC / name
        if candidate.exists():
            return candidate
    return None


def _key_background(img):
    """Knock a flat background out to alpha, flood-filling in from the corners.

    A generated render arrives opaque, so the felt would otherwise sit behind a
    solid rectangle. Filling inward from the corners rather than matching one
    colour globally means a dark waistcoat is never mistaken for background.
    """
    scratch = img.convert('RGB')
    marker = (1, 254, 3)
    w, h = scratch.size
    for corner in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        ImageDraw.floodfill(scratch, corner, marker, thresh=44)

    mask = Image.new('L', scratch.size, 255)
    src_px, mask_px = scratch.load(), mask.load()
    for y in range(h):
        for x in range(w):
            if src_px[x, y] == marker:
                mask_px[x, y] = 0
    # A slight feather stops the cutout edge from crawling once downscaled.
    return mask.filter(ImageFilter.GaussianBlur(max(1.0, w / 900)))


def load_dealer(size):
    """The dealer master: a dropped-in illustration if there is one, else drawn.

    `play-assets/src/dealer-1024.png` is the swap point — any of MASTER_NAMES
    works. The file is keyed to alpha if it arrives opaque, cropped to the
    subject and re-framed bottom-centred, so a dropped-in render does not have
    to match the vector version's composition to land correctly.
    """
    master = _master_path()
    if master is None:
        return draw_dealer(size)

    art = Image.open(master).convert('RGBA')
    if art.getchannel('A').getextrema()[0] > 250:      # arrived fully opaque
        art.putalpha(_key_background(art))
        # A background close in colour to the shirt or skin, and touching the
        # frame edge, gets flood-filled straight through the subject. Say so
        # rather than quietly shipping a half-erased dealer.
        kept = sum(art.getchannel('A').histogram()[128:]) / (art.width * art.height)
        if kept < 0.15 or kept > 0.97:
            print(f'  ! {master.name}: keying kept {kept:.0%} of the frame. Re-generate the '
                  f'dealer on a flat background no other part of the image shares '
                  f'(bright magenta works), or supply a transparent PNG.')

    bbox = art.getchannel('A').getbbox()
    if bbox:
        art = art.crop(bbox)

    scale = min(size / art.width, size / art.height)
    art = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))), Image.LANCZOS)

    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(art, ((size - art.width) // 2, size - art.height))
    return canvas


# --------------------------------------------------------------------------
# composition
# --------------------------------------------------------------------------

def _compose(size, safe=1.0):
    """Dealer on the felt ground. `safe` shrinks the art into a safe zone.

    A blurred copy of her own silhouette goes down first: the waistcoat is
    nearly as dark as the felt's outer stop, and without that lift the
    shoulders dissolve into the background at small sizes.
    """
    ground = felt(size).convert('RGBA')
    inner = max(1, int(size * safe))
    art = load_dealer(inner)
    pad = (size - inner) // 2
    pos = (pad, size - inner - pad)

    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 130), pos, art.split()[3])
    ground.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(size * 0.035)))

    ground.alpha_composite(art, pos)
    return ground


def tile(size, radius_ratio=0.225, ring=True):
    """The launcher/store icon: the composition inside a rounded gold-ringed tile."""
    s = size * SS
    img = _compose(s)

    if ring:
        inset = s * 0.022
        ImageDraw.Draw(img).rounded_rectangle(
            [inset, inset, s - inset, s - inset],
            radius=s * radius_ratio * 0.86,
            outline=GOLD + (150,), width=max(1, int(s * 0.008)),
        )

    if radius_ratio > 0:
        mask = Image.new('L', (s, s), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, s - 1, s - 1], radius=s * radius_ratio, fill=255)
        img.putalpha(mask)

    return img.resize((size, size), Image.LANCZOS)


def square(size, safe=1.0):
    """Edge-to-edge variant with no alpha, for iOS and maskable web icons."""
    s = size * SS
    return _compose(s, safe=safe).convert('RGB').resize((size, size), Image.LANCZOS)


def adaptive_foreground(size):
    """Dealer only, on alpha, fitted to the adaptive icon's 72dp safe window."""
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    inner = max(1, int(size * ADAPTIVE_SAFE))
    pad = (size - inner) // 2
    # Sits on the safe window's baseline; the shoulders may be masked away,
    # which is what a portrait icon should look like.
    canvas.alpha_composite(load_dealer(inner), (pad, size - inner - pad))
    return canvas


# --------------------------------------------------------------------------
# outputs
# --------------------------------------------------------------------------

def save(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f'  {path.relative_to(ROOT)}  {img.width}x{img.height}')


def _generate_icons_from_composed_master():
    master = load_composed_master()
    bg_color = master.getpixel((1, 1))  # corner colour, for adaptive/maskable padding

    print('android launcher (legacy bitmap)')
    for bucket, px in LEGACY.items():
        save(composed_tile(master, px), RES / f'mipmap-{bucket}' / 'ic_launcher.png')

    print('android launcher (adaptive layers)')
    for bucket, px in ADAPTIVE.items():
        save(composed_inset(master, px, ADAPTIVE_SAFE, bg_color),
             RES / f'mipmap-{bucket}' / 'ic_launcher_foreground.png')
        save(Image.new('RGB', (px, px), bg_color), RES / f'mipmap-{bucket}' / 'ic_launcher_background.png')

    print('play store')
    save(composed_tile(master, 512), PLAY / 'icon-512.png')

    print('web / pwa')
    save(composed_tile(master, 196), WEB / 'favicon.png')
    save(composed_tile(master, 192), WEB / 'icons' / 'Icon-192.png')
    save(composed_tile(master, 512), WEB / 'icons' / 'Icon-512.png')
    for px in (192, 512):
        save(composed_inset(master, px, MASKABLE_SAFE, bg_color), WEB / 'icons' / f'Icon-maskable-{px}.png')

    print('ios (App Store rejects an icon with an alpha channel)')
    for name, px in IOS_ICONS.items():
        save(composed_tile(master, px), ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset' / name)

    print('macos')
    for name, px in MACOS_ICONS.items():
        save(composed_tile(master, px), ROOT / 'macos' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset' / name)


def _generate_icons_from_dealer():
    print('android launcher (legacy bitmap)')
    for bucket, px in LEGACY.items():
        save(tile(px), RES / f'mipmap-{bucket}' / 'ic_launcher.png')

    print('android launcher (adaptive layers)')
    for bucket, px in ADAPTIVE.items():
        save(adaptive_foreground(px), RES / f'mipmap-{bucket}' / 'ic_launcher_foreground.png')
        save(felt(px), RES / f'mipmap-{bucket}' / 'ic_launcher_background.png')

    print('play store')
    save(tile(512), PLAY / 'icon-512.png')

    print('web / pwa')
    save(tile(196), WEB / 'favicon.png')
    save(tile(192), WEB / 'icons' / 'Icon-192.png')
    save(tile(512), WEB / 'icons' / 'Icon-512.png')
    for px in (192, 512):
        save(square(px, safe=MASKABLE_SAFE), WEB / 'icons' / f'Icon-maskable-{px}.png')

    print('ios (App Store rejects an icon with an alpha channel)')
    for name, px in IOS_ICONS.items():
        save(square(px), ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset' / name)

    print('macos')
    for name, px in MACOS_ICONS.items():
        save(tile(px), ROOT / 'macos' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset' / name)


def main():
    composed = _composed_master_path()
    if composed:
        print(f'composed icon master: {composed.relative_to(ROOT)}')
        _generate_icons_from_composed_master()
    else:
        _generate_icons_from_dealer()

    print('dealer cutouts (play-assets/feature-graphic.html embeds the bust)')
    save(load_dealer(1024), SRC / 'dealer-cutout-1024.png')
    save(draw_dealer(1024, with_cards=False), SRC / 'dealer-bust-1024.png')


if __name__ == '__main__':
    main()
