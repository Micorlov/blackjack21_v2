# Icon master

`tool/make_icons.py` builds every icon in the repo — 5 Android launcher bitmaps, 10 adaptive
layers, the 512 Play icon, 5 web/PWA icons, 15 iOS and 7 macOS icons — from one master image.
Two master styles are supported; drop in one of them and run:

```bash
python3 tool/make_icons.py
```

## Composed master (current icon)

**`icon-master.png`** (or `.jpg`/`.jpeg`/`.webp`) — a **fully composed** icon: own background,
gold ring and any text (the "21 BLACKJACK" wordmark, chip stacks, felt) already baked in by
whatever generated it. Square, 1024px or larger.

Used as-is, edge to edge: every flat target (iOS, macOS, web, Play, the Android legacy bitmap)
is a plain resize. Android adaptive icons and maskable web icons — where the OS applies its own
circular/squircle mask on top — get a shrunk copy padded with the master's own corner colour, so
the ring and corner text are never clipped. This master takes priority over `dealer-1024.png`
below when both are present.

## Dealer-cutout master (fallback / feature graphic)

`dealer-1024.png` (or `.png`/`.jpg`/`.jpeg`/`.webp` as `dealer.*`) is the **older, still-supported**
convention: a subject-only cutout that the script keys, crops and composites onto a
programmatically drawn felt background with a gold ring. It only drives the app icon when no
`icon-master.*` is present, but it still feeds `dealer-cutout-1024.png` /
`dealer-bust-1024.png` for `play-assets/feature-graphic.html` regardless — see **Generated
files** below.

If neither master is present the script falls back to a flat-vector dealer it draws itself, so
the build never breaks on a missing file.

The rest of this file (framing rules, the generation prompt) describes the dealer-cutout master
specifically — it does not apply to `icon-master.png`, which is used exactly as delivered.

### What the script does to your image

You do not have to match any particular framing. On load it will:

1. Key the background out to alpha, flood-filling inward from the four corners — skipped if the
   file already has transparency.
2. Crop to the subject.
3. Scale and re-frame it bottom-centred inside the icon tile.

### Two rules for the source image

**Use a flat background in a colour that appears nowhere else in the picture — bright magenta
(`#FF00FF`) is ideal.** A white or light-grey background bleeds through a white dress shirt where
the shirt touches the frame edge, and the flood fill then erases both. The script prints a warning
when keying keeps an implausible share of the frame, but a well-chosen background colour avoids
the problem outright. A PNG that is already transparent is better still and skips step 1 entirely.

**Keep the whole subject inside the frame with margin on all sides.** Nothing cropped, especially
not the crown of the head.

Square, 1024×1024 or larger. PNG preferred; `dealer.png`, `dealer.jpg`, `dealer.jpeg` and
`dealer.webp` are also picked up.

### Prompt

Tuned for the Play Store: a Casino-category listing gets extra review, and the Store Listing and
Promotion policy holds the app icon to a stricter bar than screenshots, so the wardrobe here is
the covered croupier kit that top-grossing casino apps ship.

> Mobile game app icon character art. A waist-up female blackjack casino dealer, centred, facing
> the viewer, isolated on a completely flat uniform bright magenta background with no shadow cast
> on the background.
>
> Wardrobe: fitted black satin waistcoat over a crisp white long-sleeve dress shirt, black bow
> tie, elegant and fully covered, professional casino croupier attire. Confident warm smile, red
> lipstick, dark hair swept back into a neat low bun, small gold stud earrings.
>
> Action: she holds two playing cards fanned open in one hand, raised to chest height and angled
> toward the viewer — the ace of spades and the king of hearts, faces clearly visible and crisp.
>
> Style: polished semi-realistic render, rich saturated colour, warm golden rim light from the
> upper left, soft fill from the right, strong clean silhouette that still reads when shrunk very
> small.
>
> Framing: head and shoulders large in frame, the full crown of her head and both shoulders well
> inside the edges with generous margin on all sides, nothing cropped.
>
> Negative: no text, no letters, no numbers, no logos, no watermark, no signature, no border, no
> frame, no background scenery, no table, no chips, no background gradient, no extra fingers, no
> deformed hands, no cropped head.

## Generated files

`dealer-cutout-1024.png` (bust with the cards) and `dealer-bust-1024.png` (bust alone, embedded by
`play-assets/feature-graphic.html`) are **outputs** of the script, not inputs. They are rewritten
on every run.
