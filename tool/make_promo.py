#!/usr/bin/env python3
"""Cut the 30s Play/YouTube promo from a real gameplay recording.

Input is an `adb shell screenrecord` capture of an actual session (never a
mockup), plus the sweep-win still as the payoff shot. Captions are rendered
to RGBA overlays with Pillow and burned in by ffmpeg, which keeps the text
crisp and avoids depending on ffmpeg's font configuration.

Run: python3 tool/make_promo.py <recording.mp4> <out.mp4>
"""
import subprocess, sys, tempfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
W, H, FPS = 1080, 1920, 30
GOLD = (232, 182, 76, 255)
WHITE = (255, 255, 255, 255)
FELT = (11, 61, 45)

# Height of the caption band every gameplay shot is composed under.
BAND_H = 300

# `screenrecord --size 1080x1920` pillarboxes a 1344x2992 screen, so the black
# bars are cropped away first; the felt is then framed below the caption band
# rather than scaled to fit, which would make the cards too small to read.
def gameplay_vf(y):
    """y is how far down the upscaled screen the visible window starts, so each
    beat can frame what it is actually about: the chips, the felt, or the
    action buttons."""
    return (f'crop=862:{H}:109:0,scale={W}:-2,crop={W}:{H - BAND_H}:0:{y},'
            f'pad={W}:{H}:0:{BAND_H}:color=0x071b14,fps={FPS}')

def font(size, bold=True):
    for p in ('/System/Library/Fonts/Helvetica.ttc',
              '/System/Library/Fonts/Supplemental/Arial Bold.ttf'):
        if Path(p).exists():
            try:
                return ImageFont.truetype(p, size, index=1 if p.endswith('.ttc') and bold else 0)
            except OSError:
                pass
    return ImageFont.load_default(size)

def run(*args):
    subprocess.run(list(args), check=True, capture_output=True)

def caption_png(path, line1, line2=None, size=78):
    """Transparent overlay: a dark scrim behind two centred lines."""
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    band_h = BAND_H
    fade = 46
    for y in range(band_h + fade):
        a = 255 if y < band_h else int(255 * (1 - (y - band_h) / fade))
        d.line([(0, y), (W, y)], fill=(6, 30, 22, a))
    f = font(size)
    def centre(text, y, fill):
        w = d.textbbox((0, 0), text, font=f)[2]
        d.text(((W - w) // 2, y), text, font=f, fill=fill)
    centre(line1, 56, WHITE)
    if line2:
        centre(line2, 56 + int(size * 1.25), GOLD)
    img.save(path)

def card_png(path, line1, line2, sub=None):
    """Full-frame title or end card on the felt ground."""
    img = Image.new('RGB', (W, H), FELT)
    d = ImageDraw.Draw(img)
    for i in range(240, 0, -1):
        r = int(i / 240 * H * 0.95)
        t = i / 240
        d.ellipse([W // 2 - r, int(H * 0.42) - r, W // 2 + r, int(H * 0.42) + r],
                  fill=(int(7 + 20 * (1 - t)), int(39 + 70 * (1 - t)), int(29 + 52 * (1 - t))))
    f1, f2 = font(112), font(58)
    def centre(text, y, fnt, fill):
        w = d.textbbox((0, 0), text, font=fnt)[2]
        d.text(((W - w) // 2, y), text, font=fnt, fill=fill[:3])
    centre(line1, int(H * 0.36), f1, WHITE)
    centre(line2, int(H * 0.36) + 130, f1, GOLD)
    if sub:
        centre(sub, int(H * 0.36) + 300, f2, (206, 228, 216, 255))
    img.save(path)

def clip(src, start, dur, cap, out, framing):
    """One gameplay段: trimmed, scaled to frame, caption burned on top."""
    run('ffmpeg', '-v', 'error', '-y', '-ss', str(start), '-t', str(dur), '-i', str(src),
        '-i', str(cap),
        '-filter_complex',
        f'[0:v]{gameplay_vf(framing)}[v];[v][1:v]overlay=0:0[o]',
        '-map', '[o]', '-an', '-c:v', 'libx264', '-preset', 'medium', '-crf', '20',
        '-pix_fmt', 'yuv420p', str(out))

def still(src, dur, out, zoom=True, cap=None):
    """A held frame, optionally with a slow push-in so it does not read as a freeze.

    zoompan emits `d` frames per *input* frame, so the input is fed at the
    output frame rate with d=1 and the zoom driven off the frame counter —
    otherwise a 5s still expands into minutes of video.
    """
    vf = (f'scale={W*2}:-2,zoompan=z=\'min(1+0.00035*on,1.10)\':d=1:'
          f's={W}x{H}:fps={FPS}') if zoom else f'scale={W}:{H}:force_original_aspect_ratio=decrease,'
    if not zoom:
        vf += f'pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color=0x0b3d2d,fps={FPS}'
    args = ['ffmpeg', '-v', 'error', '-y', '-loop', '1', '-framerate', str(FPS),
            '-t', str(dur), '-i', str(src)]
    if cap:
        args += ['-i', str(cap), '-filter_complex', f'[0:v]{vf}[v];[v][1:v]overlay=0:0[o]', '-map', '[o]']
    else:
        args += ['-vf', vf]
    args += ['-an', '-c:v', 'libx264', '-preset', 'medium', '-crf', '20', '-pix_fmt', 'yuv420p', str(out)]
    run(*args)

def main():
    src = Path(sys.argv[1])
    out = Path(sys.argv[2])
    tmp = Path(tempfile.mkdtemp())
    parts = []

    card_png(tmp / 'title.png', 'Blackjack 21', 'Sweep the Pot', 'Free · No ads · No purchases')
    still(tmp / 'title.png', 2.2, tmp / '00.mp4', zoom=False)
    parts.append(tmp / '00.mp4')

    # (start, duration, line 1, line 2, framing offset) — timings read off the
    # recording, offsets chosen so each beat shows what its caption promises.
    beats = [
        (3.5, 5.5, 'Five seats, one dealer', 'and one pot', 520),
        (9.5, 6.0, 'Every seat plays', 'for the sweep pot', 300),
        (16.0, 6.0, 'Hit, stand, double,', 'split, surrender', 780),
    ]
    for i, (s, d, l1, l2, fr) in enumerate(beats, start=1):
        cap = tmp / f'cap{i}.png'
        caption_png(cap, l1, l2)
        clip(src, s, d, cap, tmp / f'{i:02d}.mp4', fr)
        parts.append(tmp / f'{i:02d}.mp4')

    cap = tmp / 'cap-win.png'
    caption_png(cap, 'Beat every hand', 'and sweep the table')
    still(ROOT / 'play-assets' / 'raw' / '07-sweep-win.png', 5.5, tmp / '90.mp4', zoom=True, cap=cap)
    parts.append(tmp / '90.mp4')

    card_png(tmp / 'end.png', 'Blackjack 21', 'Sweep the Pot', 'Free on Google Play')
    still(tmp / 'end.png', 4.0, tmp / '99.mp4', zoom=False)
    parts.append(tmp / '99.mp4')

    listing = tmp / 'list.txt'
    listing.write_text(''.join(f"file '{p}'\n" for p in parts))
    run('ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', str(listing),
        '-c:v', 'libx264', '-preset', 'medium', '-crf', '20', '-pix_fmt', 'yuv420p', str(out))
    print('wrote', out)

if __name__ == '__main__':
    main()
