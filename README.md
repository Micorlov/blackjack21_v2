# blackjack21_v2

A Flutter blackjack game with a multi-seat table, social features, and a shop.

> **Contributor rule:** every change to this project must update this file in the same
> commit. See [CLAUDE.md](CLAUDE.md) for the exact requirements.

## Features

- **Blackjack table** — multi-seat felt with dealer area, hero hand, betting, insurance,
  splits/doubles, and settlement panels
- **"Closest to 21" sweep pot** — seats that bust or lose to the dealer forfeit their bets to
  the best surviving hand; every settled hand names who took the pot, or says there was none
- **Enforced table limits** — each table's posted `$min – $max` is a real rule: the betting tray
  only offers chips a table can legally take (no $1,000 chip at a $500 table), a chip that would
  push the bet past the maximum is refused, and DEAL stays locked until the bet reaches the minimum
- **Live friends groups** — invite friends over WhatsApp with a 6-character group code; everyone
  who joins the code shares one Firestore-backed group and appears live in the friends list,
  leaderboard, and table seats (guests get anonymous Firebase accounts, so no sign-in is required).
  The friends standings list only ever shows real people who joined by code — never the practice
  bots — and offers an inline WhatsApp invite button while you have nobody to race. The table
  itself always seats 4 opponents (hero + 4 = 5 players in the room): real friends fill seats
  first, and practice bots pad any seats a small group leaves empty
- **World leaderboard** — swipe the standings panel at the table between three pages: FRIENDS,
  WORLD · THIS HOUR, and WORLD · TODAY. The world pages are the live global top players by
  hourly and daily points; your own row stays visible even when you are outside the top
- **Always-visible rank strip** — a ticker above every screen, including the table, showing your
  live position vs your friends' hourly or daily points and who you're chasing (tap to flip
  hourly ↔ daily)
- **Hourly & daily points** — net chips won roll into real per-hour and per-day buckets that reset
  on the clock and sync to the group after every hand and once a minute
- **Overtake alerts** — when a friend's score passes yours, you get an in-app toast plus a local
  notification ("Maya just passed you on the hourly leaderboard"). Honors the Settings →
  leaderboard-notifications toggle. These are local notifications (app running); remote push
  needs an APNs entitlement a free personal Apple team cannot sign
- **Daily chips claim with a 7-day streak** — claiming opens a gold overlay with a D1–D7 streak
  ladder: days 1–6 pay +250 chips, day 7 pays +1,000, and the ladder then restarts. A claim made
  within 48 hours of the last one keeps the streak alive; later than that resets it to day 1. The
  last claim time and streak day are persisted (`shared_preferences`) so restarting the app can't
  re-arm the claim early or forget the streak. The lobby's Daily Bonus card shows the upcoming
  day's reward and a live "Next in 23h 59m" countdown while on cooldown, and a scheduled local
  notification quoting the right amount fires the moment it unlocks — even if the app is closed.
  Honors the Settings → Daily reminder toggle
- **Weekend Cup screen** — the lobby's Weekend Cup card now opens a real tournament screen: the
  5,000-chip prize pool with a live countdown to the end of the week (Monday 00:00 local), your
  standing in your group's daily points race, the prize table (2,000 / 1,200 / 800 / 200), and the
  top of the table built from the same friends standings the leaderboard uses. Joining is
  persisted, and "Play a Cup hand" drops you straight onto the Bronze table
- **New-player tips screen** — a one-time "Four things to know" primer between onboarding and the
  lobby for brand-new players (beat the dealer, 3:2 blackjack, the sweep pot, never go broke).
  "Deal me in" continues into the coached first hands; "I've played before — skip" also turns the
  tutorial off. Either way it never shows again (persisted)
- **Comeback dealing** — short-stacked or on a two-loss streak, your opening hand is the best of
  3 candidate pairs from the real shoe instead of one blind draw, so sessions last longer
- **Social table** — friends, lobby, leaderboard, seat plates with avatars, and a table-chat
  bottom sheet over the dimmed felt: named message bubbles (yours right-aligned in gold) plus
  quick-reply chips (GG, Nice hand, Ouch, One more, Dealer luck) that post a real "You" bubble
  and float the reaction over the table — canned replies only, so there is nothing to moderate
- **Progress that survives a relaunch** — your bankroll, all-time stats, recent-hand history,
  live hourly/daily points, settings and shop cosmetics are written to disk after every settled
  hand and every settings change, then restored before the app publishes anything to your
  friends' group. Point buckets still roll over on the clock, so a relaunch can never resurrect
  a finished hour's score, and the rebuy offer now appears whenever your stack falls below the
  table minimum rather than only at exactly zero
- **Three-hand tutorial** — a new player's first three hands are coached by a card above the
  action panel ("COACH · HAND 1 OF 3" with progress dots), one lesson per hand: playing a hand (bet → hit/stand → result), reading the
  dealer's up-card and what a push is, then the bigger moves (double/split/surrender) and the
  sweep pot. The card changes with the phase, explains insurance whenever the dealer shows an
  Ace, and quotes the real minimum of whichever table you walked into. "Skip" turns it off; the
  progress is saved, so a relaunch resumes at the right lesson and a player who already has
  hands on the clock is never re-tutored
- **How to play guide** — a full rules reference (goal, card values, every move, dealer rules,
  payouts, the sweep pot, chips and limits) in a bottom sheet, reachable from Settings → Help
  and from "Full rules" on the tutorial card without leaving a hand in progress. Settings → Help
  also replays the three-hand tutorial
- **Progression** — stats screen, shop, onboarding and story overlays
- **Sound effects** — deal, chip, turn, win, lose, push, and blackjack cues, plus spoken
  "Stand"/"Bust" voice lines when an NPC seat finishes its turn
- **Spoken results** — every settled hand plays its outcome tone and then says the result:
  "Big win" on a blackjack, "Player wins the sweep pot" when you sweep the table, otherwise
  "Player wins" or "Player lost". A push gets the tone only, and taking the pot is followed
  by a drum flourish
- **Spoken pot** — once every opponent seat has played and the figure has stopped moving, the
  dealer pill is read aloud: "Sweep pot, three hundred seventy five dollars"
- **Haptics** — selection/light/medium/heavy impact and vibrate feedback, toggleable in settings,
  including a tap for each NPC seat's stand/bust
- **Web version** — runs in the browser at https://blackjack21-v2.web.app, auto-deployed by
  GitHub Actions on every push to `main`. Google sign-in is required on web (guest mode has no
  Firebase account behind it, so it's mobile/desktop only there)
- **Branded link preview** — sharing the web URL (WhatsApp, iMessage, Facebook, etc.) shows a
  custom casino-themed card: an Ace of Spades and King of Hearts fanned on a felt table, the
  "21 Sweet Pot" title, and a real description, instead of the generic Flutter placeholder

## Getting Started

```bash
flutter pub get
flutter run
```

Run the web build locally:

```bash
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart
├── data/          # static game data, tutorial_data (3 lessons + "How to play" guide copy)
├── models/        # enums, game_state, hand, playing_card, social_models, table_pot
├── screens/       # lobby, table, friends, settings, shop, stats, onboarding,
│   │              #   tips (one-time new-player primer), cup (Weekend Cup tournament)
│   └── table/     # table sub-panels (felt, betting, action, chat sheet, settlement, …)
├── services/      # sound_player, spoken_amount, social_service (Firestore), local_notifier,
│                  #   notification_support (web-safe "can we notify here?" check),
│                  #   daily_bonus_store (persists the last claim time + streak day)
├── state/         # game_notifier (Riverpod)
├── theme/         # app_colors, app_text_styles
├── utils/         # formatters, leaderboard, points (hourly/daily buckets), comeback,
│                  #   daily_bonus (pure cooldown + 7-day streak logic),
│                  #   cup (pure Weekend Cup countdown/prizes),
│                  #   tutorial (pure "which coaching card, if any, right now?"),
│                  #   table_seats (pads real friends to 4 table seats with practice bots)
└── widgets/       # shared UI (buttons, overlays, cards, nav bar, rank_strip,
                   #   tutorial_coach_card, how_to_play_sheet, daily_bonus_dialog,
                   #   web_viewport_scaler)

tool/
├── play_upload.py            # uploads a signed .aab to a Play track (Android Publisher API v3)
└── release_notes_en-US.txt   # en-US release notes passed to --notes-file

play-assets/                  # what the Play Store listing shows — the uploaded copies live on Play
├── icon-512.png              # 512×512 store icon, upscaled from the 192px Android launcher icon
├── feature-graphic.png       # 1024×500 feature graphic
├── feature-graphic.html      # the source the feature graphic is rendered from
└── screen-01..04.png         # phone screenshots, cropped to 2:1 (Play rejects taller than that)
```

### Publishing to Google Play

`tool/play_upload.py` does the whole release without touching the Play Console UI — the browser
route is a dead end here, because a release bundle is ~58 MB and browser file-upload automation
is capped well below that.

```bash
flutter build appbundle --release && python3 tool/play_upload.py --aab build/app/outputs/bundle/release/app-release.aab --track internal --release-name "1.0.0 (1)" --notes-file tool/release_notes_en-US.txt
```

Pass `--version-code N` instead of `--aab` to put a bundle that is already on Play onto a second
track — Play rejects a re-upload of a version code it already has. While the app is still a draft
(never published), only `internal` accepts `--status completed`; every other track needs
`--status draft`.

Auth is a Google Cloud service account, `play-publisher@blackjack21-v2.iam.gserviceaccount.com`,
granted "Release apps to testing tracks" and "Manage testing tracks and edit tester lists" on this
app in Play Console. Its JSON key lives at `android/play-service-account.json` and is gitignored,
like `android/key.properties` — neither ever gets committed.

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management (`game_notifier`) |
| `google_fonts` | Typography |
| `audioplayers` | Sound effect playback |
| `cupertino_icons` | iOS-style icons |
| `firebase_core` / `firebase_auth` | Firebase app + Google/anonymous sign-in |
| `google_sign_in` | Google account picker for sign-in |
| `google_sign_in_web` | Renders Google's own Identity Services button on web — `authenticate()` isn't supported there |
| `cloud_firestore` | Friends groups and live hourly/daily score sync |
| `url_launcher` | Opens WhatsApp with the prefilled group invite |
| `flutter_local_notifications` | "Friend passed you" leaderboard alerts and the daily-bonus reminder |
| `shared_preferences` | Saves the bankroll, stats, points and settings between launches (`game_store`), and the last daily-bonus claim time (`daily_bonus_store`) |
| `timezone` | Builds the `TZDateTime` the daily-bonus reminder is scheduled against |

Dev: `flutter_test`, `flutter_lints`, `integration_test`.

## Assets

`web/og-image.jpg` is the 1200×630 social/link-preview banner (Open Graph + Twitter Card) referenced
from `web/index.html`; `web/favicon.png` and `web/icons/Icon-*.png` (including the `-maskable-`
variants) are the matching browser-tab and PWA/home-screen icons. All five are generated by a
one-off Pillow script (not checked in) rather than hand-drawn — regenerate by re-running the same
casino-green/gold Ace-of-Spades-and-"21" design if the branding ever changes.

`web/privacy-policy.html` is a standalone static page (not part of the Flutter app) served at
`https://blackjack21-v2.web.app/privacy-policy.html` — it's the Privacy Policy URL required by the
Google Play Store listing. Firebase Hosting serves static files under `web/` ahead of the SPA
catch-all rewrite, so this loads directly without going through `index.html`.

`assets/sfx/` holds two kinds of clip, all registered wholesale by the `- assets/sfx/` entry
under `flutter: assets:` in `pubspec.yaml` — a new file in the folder needs no pubspec change.

| Kind | Files | Plays on |
|---|---|---|
| Tones | `deal.wav`, `chip.wav`, `turn.wav`, `win.wav`, `lose.wav`, `push.wav`, `blackjack.wav` | Dealing, betting, your turn, and hand outcomes |
| NPC voice | `npc_stand.wav`, `npc_bust.wav` | An opponent seat standing or busting |
| Result voice | `player_win.wav`, `player_lose.wav`, `big_win.wav`, `player_pot.wav` | Your settled hand, 700ms after its tone |
| Celebration | `pot_celebration.wav` | After the pot call-out — a synthesized drum roll, downbeat and major triad |
| Number words | `num/*.wav` — 0-19, the tens, `hundred`, `thousand`, `dollars`, `sweep_pot` | Stitched into the spoken pot figure |

`assets/sfx/num/` needs its own `pubspec.yaml` entry: Flutter's asset folders are **not**
recursive, so a nested folder left out of the manifest is silently missing at runtime.

Pot figures are arbitrary multiples of the table minimum, so the sentence cannot be
pre-recorded. `spoken_amount.dart` turns the amount into words, and `SoundPlayer.playWords`
joins those clips into a single WAV in memory (45ms of silence between words) and plays it
through one `BytesSource` — playing them as separate calls would need each to report
completion before the next, and any gap would land mid-sentence.

Voice clips are synthesized speech (macOS `say`, Samantha voice) rather than tones, so the
table reads as spoken call-outs. All are mono 16-bit 44.1kHz and peak-normalised to -6.5 dBFS
so no one line is louder than the rest.

Every clip must contain its whole word and decay naturally — a file cut short mid-syllable
still loads and plays, it just sounds like an unintelligible click, which is how a truncated
`npc_stand.wav` shipped once. `test/sfx_assets_test.dart` guards against that: it reads each
WAV and fails any clip still sounding above 10% of its own peak in its final 10ms.

## Testing

```bash
flutter analyze
flutter test
```

Layout work that has to be judged against real fonts and real device metrics — which widget
tests, running on the fallback test font, cannot show — has a driver test that walks the app
from onboarding to a dealt round and then holds the table still:

```bash
flutter test integration_test/table_shot_test.dart -d <device-id>
# while it holds: xcrun simctl io <device-id> screenshot shot.png
```

### Android emulator

The `bj21_test` AVD needs **4 GB of RAM and hardware GPU** to run this app. It was originally
created with `hw.ramSize = 2G` and `hw.gpu.enabled = no`, and under that configuration the
Android 16 system image plus Play Services plus a Flutter debug build does not fit in memory:
the kernel OOM-kills `com.android.systemui` (the screen goes black while the activity is still
resumed) and then the app process itself, which surfaces in `flutter run` as
`Lost connection to device`. It looks exactly like an app crash and is not one — the crash
buffer stays empty and `logcat` shows `mem-pressure-event` instead.

The AVD config now carries the fix, so `flutter emulators --launch bj21_test` is enough. To
force it explicitly, or for a fresh AVD:

```bash
emulator -avd bj21_test -memory 4096 -gpu host
```

Google sign-in returns `DEVELOPER_ERROR` on the emulator unless that machine's debug-keystore
SHA-1 is registered in the Firebase project. **Play as Guest** is unaffected — use it for
emulator testing.

## Changelog

### 2026-08-15 (3)
- chore: **added the Testers Community tester pool to the Closed testing – Alpha track.** Created a
  developer-account email list named "Testers Community" holding the 135 addresses from
  `https://www.testerscommunity.com/testers-emails.csv`, ticked it on the track's Testers tab, and
  sent the change to Google for review. The track's country targeting already covered all 177
  available countries/regions, so no change was needed there. Managed publishing is on, so once
  Google approves, the change still has to be published manually from Publishing overview before
  testers can install the app — until then the Play Store shows them "Item not found".

### 2026-08-15 (2)
- fix: **Google Sign-In failed on release builds (`DEVELOPER_ERROR`).** The Firebase Android app
  only had the debug keystore's SHA-1 registered, so any build signed with the real upload keystore
  (`~/.android-keys/blackjack21_v2_upload.jks`) had no matching OAuth client and Google rejected the
  sign-in. Registered the upload keystore's SHA-1 and SHA-256 fingerprints on the Firebase Android
  app and pulled the refreshed `google-services.json` into the project. Google Play App Signing uses
  a separate certificate for Play-distributed installs — its fingerprint still needs to be added the
  same way, from Play Console → Setup → App integrity → App signing, or this will resurface for
  users who install from Play rather than a sideloaded build.

### 2026-08-15
- fix: **startup no longer hangs forever on a stalled Firebase/Google Sign-In init.** Both calls
  used to be awaited with no timeout, so a wiped install where `GoogleSignIn.instance.initialize()`
  never resolved left the player stuck on the launch splash with no UI and no error. Each init now
  has an 8-second timeout and failures are swallowed with a debug log — the game still plays offline
  against bots and guest play still works even if Firebase/Google Sign-In never come up. Updated the
  table-shot integration test to dismiss the "skip tips" primer before reaching the lobby.

### 2026-08-06 (6)
- feat: **renamed the app to "21 Sweet Pot"** (was "Blackjack 21" / "Blackjack21 V2"). Updated the
  Android launcher label, iOS `CFBundleDisplayName`, the in-app title/onboarding logo text, the
  WhatsApp invite copy, the settings notification-preview strings, the web `<title>`/PWA
  manifest/Open Graph & Twitter card metadata, and the privacy-policy page. Left the package id
  (`com.micorlov.blackjack21_v2`), the Firebase project, and the `blackjack21-v2.web.app` hosting
  domain unchanged — those are internal identifiers, not the display name, and renaming them would
  mean standing up a new Play Store listing from scratch
- chore: bumped the app to **1.1.0 (2)** and shipped it to Google Play's internal testing track —
  the first release since 1.0.0 (1) to include the All-Screens design doc work, the felt-sizing
  fix, and this rename

### 2026-08-06 (5)
- fix: **the betting-phase felt renders ~30% larger.** Before the deal nothing on the felt has
  cards, yet every seat slot still reserved its empty 38px card row and the rows sat at their
  mid-round positions — so the whole canvas asked for 490px of height, got ~300 on a phone, and
  scaled everything down to ~0.62x (the "plates are too small" report). The betting phase now uses
  a compact layout: card rows dropped, seat rows pulled up under the dealer, canvas height 372px.
  The spread layout returns at deal time, under the dealing animation, and holds steady for the
  whole hand so plates never jump mid-round. This is the "reduce the felt's required height" lever
  the 2026-08-03 (7) known-limitation note called for, applied to the phase where players linger

### 2026-08-06 (4)
- feat: **daily bonus streak** — claiming now opens a design-matched overlay with a D1–D7 ladder:
  days 1–6 pay +250, day 7 pays +1,000, a claim within 48h keeps the streak, later resets it.
  Streak day persists across launches and the reminder notification quotes the right amount
- feat: **Weekend Cup screen** — the lobby card now opens a real tournament screen (live countdown
  to Monday 00:00, your standing, prize table, top of the table from real group standings, "Play a
  Cup hand" CTA); joining the Cup finally persists across launches
- feat: **new-player tips screen** — one-time "Four things to know" primer after onboarding for
  players with no hands played; skipping it as an experienced player also disables the tutorial
- feat: **table chat redesigned as a bottom sheet** — dimmed felt, named bubbles with your own
  right-aligned in gold, and design quick-replies (GG / Nice hand / Ouch / One more / Dealer luck)
  that post a real "You" message; chat log grows to the last 6 lines
- fix: **table felt themes actually restyle the table** — the Appearance choice (and the Shop's
  Table Felt section) now repaints the screen background and the felt ellipse (Casino Green /
  Deep Ocean / Ember); previously only the swatch check-mark moved. Felt picked in the Shop and
  the avatar color picked in Settings are now persisted too
- fix: the tutorial coach card badge reads "COACH · HAND x OF 3" with progress dots, per the design
- test: streak logic (6 cases), reward ladder (2), and Weekend Cup timing/labels (9) are unit-tested
  in `test/daily_bonus_test.dart` and the new `test/cup_test.dart`
- docs: all of the above ships from the claude.ai/design "Blackjack 21 — All Screens" document
  (screens 10–15 were the proposed additions)

### 2026-08-06 (3)
- feat: **closed testing is live.** Google approved the submission and Closed testing — Alpha went
  **Active** at 1:19 AM with 1.0.0 (1) "available to selected testers" in 177 countries. Testers
  opt in at `play.google.com/apps/testing/com.micorlov.blackjack21_v2`, then install from
  `play.google.com/store/apps/details?id=com.micorlov.blackjack21_v2`. The 14-day production clock
  does not start until 12 of them have actually opted in — invited is not opted in.

### 2026-08-06 (2)
- feat: **Blackjack 21 was submitted to Google Play** — 16 changes sent for review. The store listing is
  complete (category Card, contact email and website, short and full description, 512px icon,
  1024×500 feature graphic, four phone screenshots), internal testing has a tester list, and closed
  testing — Alpha targets 176 countries plus rest-of-world with all four tester lists (113 addresses)
  attached. Play warns the game is excluded from Korea pending its GRAC rating, which is expected for
  a simulated-gambling title. Production is still locked: it needs 12 testers opted in to the closed
  test for 14 days, then an application.
- feat: added `play-assets/` — the store icon, the feature graphic and its HTML source, and four
  phone screenshots captured off the Android emulator. Screenshots are cropped to 2:1 because Play
  rejects anything taller, and the emulator's 1344×2992 frame is 2.23:1.
- chore: granted the `play-publisher` service account "Manage store presence" as well, so the store
  listing text and every image go up over the API. Uploading the images was never the problem —
  committing the edit was, and that is the permission the commit needs.

### 2026-08-06
- feat: the first signed release bundle is on Google Play. `1.0.0 (1)` (versionCode 1, 58.3 MB) is
  live on the **internal testing** track and staged as a **draft** on **closed testing — Alpha**.
  Neither track is reachable yet: internal testing still needs a tester list, and closed testing
  needs testers plus countries. Production is not an option on this account — Play answers "You
  don't have access to production yet", which a personal developer account only clears by running
  a closed test with 12 testers for 14 days and then applying.
- feat: added `tool/play_upload.py` + `tool/release_notes_en-US.txt`, which upload a bundle and roll
  out a track over the Android Publisher API. This replaces the Play Console UI for releases, and
  it is not a convenience: a 58 MB bundle is far past what browser file-upload automation carries,
  so the console route could not deliver the .aab at all. See **Project Structure → Publishing to
  Google Play**.
- chore: created the `play-publisher` service account in the `blackjack21-v2` Cloud project, enabled
  the Google Play Android Developer API on it, and granted it "Release apps to testing tracks" and
  "Manage testing tracks and edit tester lists" for this app. Its key is gitignored at
  `android/play-service-account.json`.

### 2026-08-05 (2)
- test: covered the three leaderboard utilities that had no tests at all —
  `utils/leaderboard.dart`, `utils/world_standings.dart`, and `utils/flags.dart` (34 new cases in
  `test/leaderboard_test.dart`, `test/world_standings_test.dart`, `test/flags_test.dart`). These
  pin the ranking order, the hourly/daily/all-time score labels, stale point buckets rolling to
  zero, the world list's filler-bot padding, and the platform-stable id→flag hash.
- docs: recorded that the `bj21_test` Android emulator, not the app, caused the "app crashed"
  report — see **Testing → Android emulator** below. No app code changed.

### 2026-08-05
- chore: created the "Blackjack 21" listing in Google Play Console (`com.micorlov.blackjack21_v2`)
  and completed all nine app-content policy declarations (privacy policy, sign-in details, ads,
  content rating, target audience, data safety, government apps, financial features, health).
  The content rating questionnaire honestly declares simulated gambling (it's a blackjack betting
  game), which rates the app Teen/18+ depending on region — expected and unavoidable for this
  genre, not a bug. Store listing title/descriptions saved; app icon, feature graphic, and
  screenshots generated and handed off for manual upload (browser automation can't reach local
  files outside its shared session folder); the release AAB upload has the same constraint

### 2026-08-04
- feat: set up the Android build for Google Play submission — branded the app icon and label
  (previously the default Flutter logo/"blackjack21_v2"), added core library desugaring
  (required by `flutter_local_notifications`), and wired a real release signing config
  (`android/key.properties`, gitignored) so `flutter build appbundle --release` produces a
  properly signed `.aab` instead of debug-signing the release build
- docs: added `web/privacy-policy.html`, a static privacy policy page hosted at
  `blackjack21-v2.web.app/privacy-policy.html` — required for the Play Store listing; none existed
  before despite the onboarding screen's "Terms & Privacy Policy" disclaimer text

### 2026-08-03 (7)
- fix: the web app's text was still too small on a phone browser for this app's 60+ players. The
  previous entry's zoom pinned the canvas to the 393 design width, so a 430-wide phone browser
  zoomed by only 1.09 — invisible in practice, which is why it read as "no change" on a phone even
  though desktop looked right. `WebViewportScaler` now bounds the zoom by *canvas floors* instead:
  it never hands the app a canvas narrower or shorter than 320x560, the smallest size
  `table_layout_test.dart` already proves the layout survives. A phone browser now zooms ~1.33x
  (header, phase pills, bet amount, chip buttons, CLEAR/DEAL, lobby and every panel are all a third
  larger); desktop is mathematically unchanged, since height already drove the scale there.
  Added `test/web_viewport_scaler_test.dart` (calibration + canvas-floor guarantees) and a
  `web-zoom-323x560` entry to the table layout suite, so the exact canvas a phone browser produces
  is now covered across every round phase at both 1.0x and 1.3x system text scale
- known limitation: the felt itself (seat plates, dealer, hero hand) is **not** affected by this
  zoom and renders at the same size as before. The felt scales by
  `min(width / 393, height / requiredHeight)`, and on every viewport that matters it is the
  *height* term that wins — the bottom action panel may take up to 62% of the screen, so the felt
  is routinely left with far less height than the ~490 design px its contents ask for. The surplus
  width is then spent widening the canvas (`width / scale`), which only pushes the two seat columns
  further apart, and the plates stay small.
  **Do not try to fix this by growing the seat slots on a wide canvas.** A wide canvas is a
  *symptom* of being height-starved, not evidence of spare room: growing the slots raises
  `requiredHeight`, which lowers the very scale it was meant to raise. That was tried on
  2026-08-03 and made the felt ~18% smaller on a 1280x800 browser; it was reverted unshipped.
  The only lever that helps is *reducing* the felt's required height — e.g. laying the four seats
  out in one row instead of two on wide viewports, which would trade the wasted width for scale
  across the whole felt. That is a real redesign and is not done

### 2026-08-03 (6)
- fix: the web app rendered at native 1:1 CSS-pixel size, so on a desktop browser it sat as a small
  mobile-width column pinned to the top-left corner with most of the window left empty — text and
  the onboarding art read far smaller than on the phone app. Added
  `widgets/web_viewport_scaler.dart`, which scales the whole app up on web (native platforms are
  untouched) using the same design-canvas + `Transform.scale` technique `TableFelt` already uses
  for the table: it derives a scale from the viewport width (capped so a very short window can't
  starve non-scrolling screens of height, and capped overall at 2.5x so it doesn't blow up on
  ultra-wide monitors), then overrides `MediaQuery`'s size so every screen still lays out against
  its normal ~393px-wide design metrics. Also centered `OnboardingScreen`'s content horizontally
  (it was relying on `Stack`'s default top-left alignment, which only looked centered because the
  viewport used to be exactly as wide as the content) and made it scroll instead of overflow if a
  short/wide web window leaves it less height than it needs

### 2026-08-03 (5)
- fix: "Continue with Google" silently did nothing on web — `GoogleSignIn.authenticate()` throws
  `UnimplementedError` there (confirmed via an unminified stack trace: "authenticate is not
  supported on the web. Instead, use renderButton to create a sign-in widget"), and that error
  type wasn't caught by the existing `GoogleSignInException` handler, so it failed silently.
  Added `widgets/google_signin_button.dart` — a platform-conditional wrapper that renders Google's
  own Identity Services button on web (`google_sign_in_web`'s `renderButton`) instead of our
  custom one, since GIS requires its own DOM-rendered button. The result now arrives through
  `GoogleSignIn.instance.authenticationEvents`, which `GameNotifier` subscribes to on web only
  (mobile keeps calling `authenticate()` directly, unchanged). Also fixed a real misconfiguration
  found along the way: the OAuth client's Authorized JavaScript origins was missing
  `https://blackjack21-v2.web.app` entirely

### 2026-08-03 (4)
- feat: the web app now shares with a proper branded link preview instead of the generic Flutter
  "A new Flutter project." card — `web/index.html` gained Open Graph and Twitter Card meta tags
  (title, description, `og:image`) pointing at a new casino-themed banner
  (`web/og-image.jpg`, an Ace of Spades and King of Hearts fanned on a felt table, gold "Blackjack
  21" title, and feature badges). The favicon and PWA/home-screen icons
  (`web/favicon.png`, `web/icons/Icon-*.png`) were also replaced with a matching spade-and-"21"
  mark, and `web/manifest.json`'s name/description now say "Blackjack 21" instead of the
  Flutter template defaults

### 2026-08-03 (3)
- test: cover `OnboardingScreen`'s web-only guest-mode hiding — added an injectable `isWeb`
  constructor param (defaults to the real `kIsWeb`) so `test/onboarding_screen_test.dart` can
  pump both branches directly, instead of only being reachable via the web test runner

### 2026-08-03 (2)
- refactor: drop the custom `<meta name="viewport">` tag from `web/index.html` — verified on
  a real mobile viewport that Flutter Web's own bootstrap script replaces any existing viewport
  tag at runtime, so the custom one never took effect and was dead code

### 2026-08-03
- feat: add a web version — Flutter Web is now a supported platform. Registered a Firebase Web
  app (`flutterfire configure`), wired the auto-created Google OAuth web client into
  `web/index.html` so "Continue with Google" works in the browser, and added a mobile viewport
  meta tag so it renders correctly on phone browsers too. "Play as Guest" is hidden on web only,
  since guest mode has no Firebase account behind it — web visitors must sign in with Google
- chore: deploy the web build to Firebase Hosting automatically via GitHub Actions
  (`.github/workflows/firebase-hosting-merge.yml`) on every push to `main`, authenticated with a
  scoped service account set up through `firebase init hosting:github`

### 2026-08-02 (9)
- fix: a friends group with fewer than 4 real members left the table looking sparse — only as
  many seats were dealt and rendered as there were real friends, so two friends meant a
  three-player room (hero + 2) instead of a full table. The room now always seats 4 opponents:
  real friends fill seats first, and practice bots pad whatever is left, so hero + 4 seats = 5
  players every time. The friends list, rank strip, and leaderboards are unaffected — they still
  show only real friends, never the padding bots (new `tableSeats()` helper in
  `lib/utils/table_seats.dart`, covered by `test/table_seats_test.dart`)

### 2026-08-02 (8)
- feat: a first-run tutorial coaches the first three hands from a card above the action panel —
  one lesson per hand (play a hand → read the dealer → bigger moves and the sweep pot), with the
  text changing by phase, an insurance explanation whenever the dealer shows an Ace, and the real
  table minimum quoted in place. Skippable from the card, replayable from Settings → Help, and
  saved to disk so a relaunch resumes at the right lesson
- feat: a "How to play" guide sheet (goal, card values, moves, dealer rules, payouts, the sweep
  pot, chips and limits) opens from Settings → Help, or from "Full rules" on the tutorial card
  without disturbing a hand in progress
- chore: `tutorialRoundsSeen` and `tutorialDismissed` join the saved-game blob; a save written
  before the tutorial existed falls back to hands played, so existing players are never re-tutored

### 2026-08-02 (7)
- fix: the felt's scale factor was capped at 1.0x, so on phones with more room than the
  393pt-wide design assumes (e.g. an iPhone 15 Pro Max, per the previous entry) the felt sat
  pinned at its native design size instead of growing into the extra space, leaving visible
  black margin around the table. The cap is removed — the felt now scales up to fill whatever
  space the `Expanded` felt slot actually gives it, same as it already scaled down on smaller
  phones

### 2026-08-02 (6)
- fix: the felt (dealer badge, seat plates, avatars, bet chip badges) rendered noticeably small
  on real phones during the betting phase — its whole canvas is scaled to fit the space the
  `Expanded` felt slot is actually given, but that slot's required height always reserved room
  for the hero's card row even before any cards were dealt, forcing the felt to scale down (as
  low as ~0.66x on an iPhone 15/16) for space it wasn't using yet. The betting-phase reservation
  now drops the unused card row, landing the felt at ~0.85x on standard phones and a full 1.0x
  (no shrink at all) on an iPhone 15 Pro Max

### 2026-08-02 (5)
- fix: upgraded Flutter from stable 3.44.8 to beta 3.47.0-0.3.pre to fix a crash on iOS 26 —
  the engine's `VSyncClient`/`CADisplayLink` initialization caused a null-pointer `SIGSEGV`
  immediately on launch on devices running iPhone OS 26.3.1

### 2026-08-02 (4)
- feat: the daily chips claim now runs on a real, persisted 24-hour cooldown instead of a
  once-ever flag — restarting the app can't re-arm it early, the lobby's Daily Bonus card shows
  a live countdown while it's on cooldown, and a scheduled local notification ("Your daily chips
  are ready!") fires the moment it unlocks, even with the app closed. Off by default is no longer
  possible to get stuck in — the Settings → Daily reminder toggle now defaults on
- test: added `test/daily_bonus_test.dart` covering the cooldown/readiness/countdown logic in
  `utils/daily_bonus.dart`

### 2026-08-02 (3)
- feat: the table standings panel is now swipeable across three pages — FRIENDS, WORLD · THIS
  HOUR, and WORLD · TODAY — so the race against real players worldwide is one swipe away
- feat: the FRIENDS page lists only real people who joined through a WhatsApp invite code; the
  practice bots no longer pad it. With no friends yet the page says so and offers the WhatsApp
  invite button inline
- feat: every player now publishes their score to a global `leaderboard` collection, read back
  live as the world top list for the current hour and day (composite indexes in
  `firestore.indexes.json`, rules in `firestore.rules`)
- fix: notifications are asked for only where a plugin is actually registered (iOS/Android, never
  under `flutter test`), via a web-safe conditional-import check in `notification_support.dart` —
  touching the plugin under test threw a `LateInitializationError` no `on` clause could catch

### 2026-08-02 (2)
- feat: the game finally remembers you. Chips, all-time stats, recent-hand history, the live
  hourly/daily point buckets, every settings toggle and your shop cosmetics now persist to
  `shared_preferences` through the new `lib/services/game_store.dart`, and are restored before
  `_initSocial()` publishes your row — so friends never see the placeholder $1,000 stack that a
  relaunch used to invent. Saved buckets are re-rolled against the current hour/day on load, so
  a finished period's score cannot come back from disk. This was the #1 item in
  [FEATURE_PLAN.md](FEATURE_PLAN.md): every restart previously wiped the bankroll the whole
  friends race is scored on
- fix: the rebuy offer appears whenever the stack is below the table minimum, not only at
  exactly $0. With a bankroll that survives relaunch, a player stranded at $10 on the
  `$25 – $500` Bronze table could otherwise never bet again
- test: added `test/game_store_test.dart` — 12 tests covering the save/load round trip, missing
  and wrong-typed keys falling back to `GameState` defaults, unreadable history entries being
  dropped rather than guessed (a wrong result would silently change whether comeback dealing
  fires), history trimming keeping the newest hands, and unknown-schema and corrupted blobs
  degrading to "nothing saved" instead of throwing

### 2026-08-02
- docs: added [FEATURE_PLAN.md](FEATURE_PLAN.md) — a prioritized roadmap of 30 candidate
  features, each scored by three independent judges on player value, feasibility under the
  free-Apple-team/Firebase-free-tier constraints, and fit with the friends-race identity.
  Phased so persistence lands first (chips and stats currently reset on every launch), then
  the fake social surfaces are replaced with real ones, then the sweep-pot moments get their
  celebration

### 2026-08-01 (3)
- feat: every seat plate at the table now shows that friend's live points next to their chip
  stack, green when up and red when down, for the same period (hourly/daily) the rank strip is
  showing — tap the strip to flip both together
- feat: the betting panel is more compact (single-line bet readout, smaller chip tray and
  buttons) and gains a friends table: everyone in the race ranked by the current
  hourly/daily points, with your own row in gold

### 2026-08-01 (2)
- feat: the app is now social-first — invite friends into a live group over WhatsApp with a
  6-character code; group members appear in the friends list, leaderboard, and table seats with
  real hourly/daily points synced through Firestore after every hand
- feat: an always-visible rank strip above every screen (table included) shows your live position
  vs your friends' hourly or daily points and the next player to catch; tap flips the period
- feat: overtake alerts — a toast plus a local notification the moment a friend's hourly or daily
  score passes yours (gated by the existing leaderboard-notifications setting)
- feat: comeback dealing — when short-stacked or two losses down, the opening hand is the best of
  three candidate pairs from the real shoe, keeping sessions alive longer
- feat: Google sign-in on the onboarding screen (restores on relaunch); guests play under an
  anonymous Firebase identity so they can join groups too

### 2026-08-01
- fix: the two right-hand friend seats now line up in one straight column. The bottom-right seat
  was anchored to the right edge of the felt but collapsed toward the *left* of its slot whenever
  its plate shrank to fit, so it sat indented from the seat above it
- docs: the delivery rule now installs with `xcrun devicectl device install app` instead of
  `flutter install`. `flutter install` uninstalls the app first, and because the app is signed
  with a free personal Apple team, iOS dropped the developer-trust entry on every uninstall —
  which is why the phone showed "Untrusted Developer" after each delivery. `devicectl` upgrades
  in place, so the trust survives
- fix: a table's posted limits are now enforced instead of being decoration. The betting tray
  hides chips worth more than the table maximum (the Bronze `$25 – $500` table no longer offers a
  $1,000 chip), a chip that would take the bet over the maximum is greyed out and refused with a
  "Table maximum is $500" toast, and DEAL is disabled — with a "Table minimum" hint — until the
  bet reaches the table minimum
- test: added `test/table_limits_test.dart` covering `chipDenomsFor`, the maximum guard in
  `placeBet`, and the minimum guard in `dealRound`
- fix: the pot is only ever called a sweep pot now. The dealer pill's call-out always opens
  with "Sweep pot …" instead of switching to "Table pot …" while every seat is still in, and
  a swept hand says "Player wins the sweep pot" rather than "Player wins the pot"
  (`player_pot.wav` re-recorded in the same Samantha voice, 1.14s → 1.51s, so the drum
  flourish waits for the longer line). The now-unused `num/table_pot.wav` clip was removed
- fix: a friend seat's cards now stay the same size no matter how many it holds. A long hand
  overlaps its cards more tightly instead of shrinking them, and the card row keeps its space
  between hands so the plate no longer rides up under the dealer's cards during settlement.
- feat: the table pot is now read aloud once every opponent seat has played and the figure has
  stopped moving — "Table pot, three hundred seventy five dollars", or "Sweep pot …" when a
  seat has already forfeited its bet and the pill switches figures. Amounts are arbitrary
  multiples of the table minimum, so instead of pre-recording sentences each number word is
  its own clip in `assets/sfx/num/`; `spoken_amount.dart` picks the words and
  `SoundPlayer.playWords` joins them into one WAV in memory.
- feat: taking the sweep pot is now followed by a drum flourish (`pot_celebration.wav`) once
  the "Player wins the pot" call-out finishes — a synthesized roll, downbeat and major triad.
- refactor: the pot figure moved out of `TableCalc` into `models/table_pot.dart`, so the pill
  and the spoken call-out read the same number instead of each computing its own.
- fix: the losing call-out now says "Player lost" rather than "Player loses".
- test: added `test/spoken_amount_test.dart` covering the number-to-words reading and
  asserting every word any reachable pot amount can produce has a clip on disk — a missing
  one is silent at runtime. `test/sfx_assets_test.dart` now walks `assets/sfx/` recursively so
  the number words get the same truncation guard as everything else.
- feat: settled hands are now announced out loud. After the outcome tone the table says
  "Big win" on a blackjack, "Player wins the pot" when you take the sweep pot, and otherwise
  "Player wins" or "Player loses"; a push stays tone-only. Four new clips in `assets/sfx/`,
  and `SoundPlayer` gained a second `AudioPlayer` so the tone and the call-out play on
  separate channels instead of cutting each other off.
- test: added `test/sfx_assets_test.dart`, which reads every WAV in `assets/sfx/` and fails
  any clip that is still sounding above 10% of its peak in its final 10ms — the truncation
  that made the "Stand" line unintelligible, caught at the asset level where the app cannot
  detect it.
- docs: added a mandatory Delivery Rule to `CLAUDE.md` — every fix and every feature is now
  installed on Michael's iPhone and committed to the local git repo automatically, with the
  install result and commit subject reported back. Also recorded the project Language Rule
  (Hebrew in, English out).
- fix: a friend's seat plate no longer changes size with the number of cards in their hand. The
  card fan and the name plate shared one `FittedBox`, so a long hand (six cards plus a BUST
  badge) overflowed the seat's width, got scaled down, and left a shorter card row — which meant
  that seat's plate was scaled down less than everyone else's and rendered ~8.5% larger in both
  dimensions. The card row is now pinned to one card's height, so card count can't drive plate
  size. Measured on device: all four plates are within 1px of each other, was 40px apart.
- test: added `integration_test/table_shot_test.dart`, a driver test that walks from onboarding
  to a dealt round and holds the table still, so seat layout can be checked against real fonts
  and real device metrics instead of the widget-test fallback font.
- fix: all four friend seat plates are now exactly the same size. The far pair was drawn in a
  narrower slot (186 vs 196) and scaled to 0.9 as a perspective hint, which made two
  identically-built plates read as two different components. Both rows now use one 196-wide
  slot at full scale, and the lower row moved from y=250 to y=262 so the now-taller upper row
  still clears it.
- fix: an opponent's "Stand" call-out is now audible as an actual word. `npc_stand.wav` was
  0.21s long and ended mid-syllable at 47% of full amplitude — the clip had been truncated,
  so all that played was the front of "Sta…" plus a hard cut. Regenerated from the same
  voice (macOS `say`, Samantha) at the full 0.53s, peak-matched to `npc_bust.wav` (-6.5 dBFS)
  and given a 15ms fade-out so it decays instead of clipping.
- fix: friend seat plates now line their two rows up straight — the name and hand total share
  one text baseline, and the chip stack and bet share the next. They were previously two
  independent columns of different heights, centred against each other, so the 14px name sat
  off-line from the 17px total and the small bet label drifted away from the stack figure.

### 2026-07-31 (5)
- fix: a surrendered hand's net loss never showed up — `_settle()`'s `surrendered` branch
  updated `lossesDelta`/history but never touched `sessionNetDelta`, so the settlement
  panel's "Hand vs dealer" row read `+$0` and the Stats screen's "Net chips this session"
  stat silently over-counted, even though the player actually lost half their bet
  (confirmed live: chips went 900→950 on a $100 bet, but the panel showed no loss at all).
  `sessionNetDelta` now subtracts the other half of the bet, matching the refund
  `playerSurrender()` already pays out.
- test: extended `test/surrender_dealer_play_test.dart` to assert `chips` and
  `roundHandNet` reflect the real -$50 loss on a $100 surrender

### 2026-07-31 (4)
- fix: surrendering left the dealer's hand un-played — `_advanceHand()` only routed to
  `_playDealer()` when a hero hand had stood or busted, so a `surrendered` hand (the only
  status reachable with a single hero hand at that point) skipped it entirely. The table's
  "closest to 21" sweep pot still settles the NPC seats against `dealerVal` in `_settle()`,
  so those seats were unfairly judged against the dealer's un-played opening two cards
  instead of a completed hand. The dealer now always plays out once every hero hand is
  resolved, since the NPC seats are always live by that point.
- test: added `test/surrender_dealer_play_test.dart`, seeding a low (5-value) dealer
  opening hand and a live NPC seat, then asserting the dealer's hand reaches 17+ after
  `playerSurrender()`

### 2026-07-31 (3)
- fix: the Stats screen rendered completely blank on every launch — its "session" and
  "all time" stat-tile rows used `Row(crossAxisAlignment: CrossAxisAlignment.stretch)`
  directly inside the screen's `SingleChildScrollView`, which gives a `Row` unbounded
  height and throws `BoxConstraints forces an infinite height`, failing the whole
  screen's layout; wrapped both rows in `IntrinsicHeight` so the equal-height stat tiles
  resolve correctly
- test: added a bottom-nav smoke test (`test/widget_test.dart`) that visits Stats,
  Friends, Shop, and Settings and asserts no exception, so a screen that's never
  reached by the existing scenario-based tests can't silently break again

### 2026-07-31 (2)
- feat: NPC seats now get sound + haptic feedback when they stand or bust — a spoken
  "Stand"/"Bust" voice line (`assets/sfx/npc_stand.wav`, `assets/sfx/npc_bust.wav`, synthesized
  with macOS `say`) plus a matching haptic tap, gated by the existing sound/haptics settings
  toggles, wired into `GameNotifier._npcDecide`

### 2026-07-31
- fix: the result panel no longer clips the dealer's total — the showdown line read
  `YOU 20 · DEALER …` because the row split its width by a fixed 1:4 ratio and the share
  reserved for the mini card strip went unused; the line is now laid out first and the
  card strip shrinks into whatever is left
- test: added a `foldable-540x720` device to the layout matrix and a showdown-line check
  asserting the label is never starved of room the card strip did not use
- fix: a settled hand now always names who took the table pot — the result panel shows a
  pot-outcome row on every hand (including "No sweep pot" when no seat forfeited a bet), and
  the felt pill resolves to `YOU TAKE` / `<NAME> TAKES` / `DEALER TAKES` / `NO SWEEP` instead
  of staying on the live `TABLE POT $x`
- test: added `test/pot_outcome_test.dart` and a `settlement-no-sweep` layout scenario
  covering the pot-outcome labels and card
- docs: added the mandatory doc-update rule (`CLAUDE.md`) and rewrote this README with
  Features, Project Structure, Dependencies, Assets, and Changelog sections
- feat: added sound effects (`audioplayers` + `assets/sfx/`) and haptic feedback wired
  through `game_notifier`, with a settings toggle
