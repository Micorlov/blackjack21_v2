# App Icons

A catalogue of every icon in this repo: the platform launcher icons (where each lives, what size
it is, and whether it's the branded "21 Sweet Pot" mark or still the stock Flutter template logo),
and every icon glyph used inside the app's own buttons and UI. Regenerate branded launcher icons
from the same casino-green/gold Ace-of-Spades-and-"21" design described in
[README.md → Assets](../README.md#assets) if the design ever changes; there is no checked-in
source file or generator script for the icon set today, so a design change means re-exporting
every size below by hand (or wiring up a generator, see **Gaps** at the bottom).

## Branded (21 Sweet Pot mark)

| Platform | Preview | Path | Sizes |
|---|---|---|---|
| Android launcher | ![Android icon](../android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png) | `android/app/src/main/res/mipmap-*/ic_launcher.png` | 48×48 (mdpi), 72×72 (hdpi), 96×96 (xhdpi), 144×144 (xxhdpi), 192×192 (xxxhdpi) |
| Google Play Store listing | ![Play Store icon](../play-assets/icon-512.png) | `play-assets/icon-512.png` | 512×512 |
| Web favicon | ![Web favicon](../web/favicon.png) | `web/favicon.png` | 196×196 |
| Web / PWA home-screen | ![Web PWA icon](../web/icons/Icon-512.png) | `web/icons/Icon-192.png`, `web/icons/Icon-512.png` | 192×192, 512×512 |
| Web / PWA maskable | ![Web maskable icon](../web/icons/Icon-maskable-512.png) | `web/icons/Icon-maskable-192.png`, `web/icons/Icon-maskable-512.png` | 192×192, 512×512 |

Android has no `ic_launcher_round.png` in any density folder — the launcher uses the square
`ic_launcher.png` on every density, so round-icon launchers (most stock Android skins) crop it
into a circle at display time rather than using a purpose-drawn round asset.

## Not yet branded (stock Flutter logo)

| Platform | Preview | Path | Sizes |
|---|---|---|---|
| iOS / TestFlight | ![iOS icon](../ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png` | 20, 29, 40, 60, 76, 83.5pt at 1x/2x/3x (20×20 up to 180×180), plus 1024×1024 |
| macOS | ![macOS icon](../macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png) | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png` | 16, 32, 64, 128, 256, 512, 1024 |
| Windows | *(`.ico`, not previewable inline)* | `windows/runner/resources/app_icon.ico` | 256×256 down to 16×16, multi-res `.ico` |
| Linux | — | no icon configured | Flutter's Linux template ships without a bundled app icon; the window manager's default is used |

This matches the note in the README changelog (2026-08-15 (4)): only the Android launcher icons
and `play-assets/` were ever branded, and the iOS build still ships the Flutter logo. That gap now
also covers macOS and Windows, which use the same stock template assets iOS does.

## In-app button icons

Separate from the platform launcher icons above: every icon drawn *inside* the app's own UI —
nav bar tabs, header buttons, panel affordances. These aren't image files; each is a glyph from
Flutter's built-in `Icons` (Material Symbols) font, referenced by `Icons.<name>` and drawn with an
`Icon` widget. There is no custom icon font or SVG set in the app — `cupertino_icons` is a listed
dependency (the Flutter template default) but nothing in `lib/` actually uses `CupertinoIcons`.

| Icon | Used on | Where |
|---|---|---|
| `Icons.diamond_rounded` | Bottom nav — Lobby tab | `widgets/bottom_nav_bar.dart` |
| `Icons.bar_chart_rounded` | Bottom nav — Stats tab | `widgets/bottom_nav_bar.dart` |
| `Icons.people_alt_rounded` | Bottom nav — Friends tab | `widgets/bottom_nav_bar.dart` |
| `Icons.storefront_rounded` | Bottom nav — Shop tab | `widgets/bottom_nav_bar.dart` |
| `Icons.tune_rounded` | Bottom nav — Settings tab | `widgets/bottom_nav_bar.dart` |
| `Icons.chevron_left` | Table header — exit-table button | `screens/table/table_header.dart` |
| `Icons.chat_bubble_outline` | Table header — open table-chat sheet | `screens/table/table_header.dart` |
| `Icons.more_vert` | Table header — table menu | `screens/table/table_header.dart` |
| `Icons.arrow_back` | World leaderboard screen — back button | `screens/table/world_leaderboard_screen.dart` |
| `Icons.chevron_left` | Weekend Cup screen — back button | `screens/cup_screen.dart` |
| `Icons.open_in_full` | Betting panel — friends-table page-swipe hint | `screens/table/table_betting_panel.dart` |
| `Icons.chevron_right` | Lobby — table-card disclosure | `screens/lobby_screen.dart` |
| `Icons.check_circle` | Lobby — Daily Bonus card "Claimed" state | `screens/lobby_screen.dart` |
| `Icons.chevron_right` | Settings — link-row disclosure (About, Help, etc.) | `screens/settings_screen.dart` |
| `Icons.trending_up` | Settings — streak-nudge banner badge | `screens/settings_screen.dart` |
| `Icons.check` | Daily bonus overlay — claimed-day badge on the D1–D7 ladder | `widgets/daily_bonus_dialog.dart` |
| `Icons.close` | How-to-play sheet — close button | `widgets/how_to_play_sheet.dart` |
| `Icons.close` | Story overlay — close button | `widgets/story_overlay.dart` |
| `Icons.check_rounded` | Stats — achievement row unlocked badge | `screens/stats_screen.dart` |
| `Icons.workspace_premium` | Shop — VIP/premium banner | `screens/shop_screen.dart` |
| `Icons.favorite` / `Icons.favorite_border` | Shop — like button on a cosmetic item | `screens/shop_screen.dart` |
| `Icons.monetization_on_outlined` | Shop — chip-pack tile icon | `screens/shop_screen.dart` |
| `Icons.check` | Shop — selected felt/avatar swatch checkmark | `screens/shop_screen.dart` |
| `Icons.play_arrow` | Shop — sound-preview play button | `screens/shop_screen.dart` |

## Gaps

- No source `.svg`/`.ai`/`.psd` for the "21 Sweet Pot" mark is checked in — the web assets were
  produced by a one-off Pillow script (see README → Assets) that isn't in the repo either, so
  reproducing the exact mark at a new size means recreating that script or exporting from
  whatever local file generated it.
- iOS, macOS, and Windows icons need to be branded to match Android/Play/web before a real
  App Store or desktop release — right now they'd ship the generic Flutter logo.
- Consider a `flutter_launcher_icons`-style config so future rebrands regenerate every platform's
  icon set from one master image instead of hand-exporting each size again.
