# blackjack21_v2

A Flutter blackjack game with a multi-seat table and a friends race. Four tabs, one felt, no shop.

> **Contributor rule:** every change to this project must update this file in the same
> commit. See [CLAUDE.md](CLAUDE.md) for the exact requirements.

## Features

- **Blackjack table** — multi-seat felt with dealer area, hero hand, betting, insurance,
  splits/doubles, and settlement panels
- **Drawn for large type** — the game is for players in their sixties and up, so the table is
  big by default rather than behind a setting: 66x96 cards, a 24px balance, 64px chips,
  20–24px action buttons, and a felt whose vertical budget is sized so a 384x832 phone draws
  the hand at full scale instead of the two-thirds it used to shrink to mid-round. Every seat
  shows the hand it is playing — 42x60 cards fanned *beside* the name, in the room the avatar
  takes before the deal, with the running total on the name line and `STAND`/`BUST` under it.
  The cards used to be a 27px fan above the plate, which the felt's own scaling then shrank to
  about 7px of rank
- **"Closest to 21" sweep pot** — seats that bust or lose to the dealer forfeit their bets to
  the best surviving hand; every settled hand names who took the pot, or says there was none.
  The pill above the dealer only ever quotes chips that have actually been forfeited — while
  every seat is still in, the pill stays off the felt altogether (its room is reserved, so the
  dealer's cards do not move when it appears)
- **A natural plays for the pot too** — being dealt 21 no longer ends the round on the spot.
  The seats play their hands and the dealer finishes its own, so bets can be forfeited and the
  blackjack takes the sweep pot as well as its 3:2. There is nothing to decide with 21, so the
  hero is never asked to act; the hand is marked `Blackjack!` from the deal and the table plays
  on around it. A *dealer* natural still ends everything before anyone acts — no bet can be
  forfeited to a pot when no seat has played
- **Enforced table limits** — each table's posted `$min – $max` is a real rule: the betting tray
  only offers chips a table can legally take (no $1,000 chip at a $500 table), a chip that would
  push the bet past the maximum is refused, and DEAL stays locked until the bet reaches the minimum
- **Live friends groups** — invite friends with a one-tap link (`blackjack21-v2.web.app/join/CODE`)
  over WhatsApp, the system share sheet, or a copied link; everyone who taps it (or types the
  6-character code by hand) shares one Firestore-backed group and appears live in the friends
  list, leaderboard, and table seats (guests get anonymous Firebase accounts, so no sign-in is
  required). Tapping the link on Android opens the app straight to the join (App Links, verified
  via `web/.well-known/assetlinks.json`); without the app it opens the playable web version, which
  joins automatically and shows a "Get it on Google Play" banner. The Friends screen also pre-fills
  the join field from the clipboard on first visit. The friends standings list only ever shows real
  people who joined — never the practice bots. The table itself always seats 4 opponents (hero + 4
  = 5 players in the room): real friends fill seats first (a friend actually seated at this table
  goes first of all), and practice bots pad any seats a small group leaves empty
- **Referral rewards that pay the inviter** — inviting and joining are both rewarded: a joiner gets
  +200 welcome chips the moment they join, and the inviter gets +100 chips per real friend who
  joins their link, with a toast and (when enabled) a local notification ("Maya joined your
  table!"). Credit is derived live from who invited whom, never a counter that can drift, and each
  join pays exactly once even across a relaunch
- **Real table presence** — a lobby table card shows real friends actually seated there right now
  ("Maya is here", with her avatar) and lets you tap straight in to join them — replacing the old
  hardcoded "2 friends here" placeholder text
- **Play-day streak** — playing at least one hand a day builds a streak that adds up to +250 chips
  on top of the daily bonus (+50 per consecutive day, capped at 5 days), with a local "your streak
  ends tonight" reminder if the day is about to lapse unplayed
- **Friends standings at the table** — while the other seats and the dealer play, the action
  panel shows your group's hourly race (your row always visible). Only once real friends have
  joined; with practice bots at the seats there is nothing to rank
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
- **Rebuy, on a cooldown** — dropping below a table's minimum offers a Rebuy to 1,000 chips, once
  every 4 hours (with a live countdown while cooling down). Replaces the old free, unlimited
  "Reset bankroll to 1,000" in Settings — without a real cost to running out of chips, there was no
  reason to ever claim the daily bonus or invite anyone to race you
- **Comeback dealing** — short-stacked or on a two-loss streak, your opening hand is the best of
  3 candidate pairs from the real shoe instead of one blind draw, so sessions last longer
- **Social table** — friends, lobby, leaderboard, seat plates with avatars, and a table-chat
  bottom sheet over the dimmed felt: named message bubbles (yours right-aligned in gold) plus
  quick-reply chips (GG, Nice hand, Ouch, One more, Dealer luck) that post a real "You" bubble
  and float the reaction over the table — canned replies only, so there is nothing to moderate
- **Progress that survives a relaunch** — your bankroll, all-time stats, recent-hand history,
  live hourly/daily points and settings are written to disk after every settled
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
- **Stats** — this session and all time (hands, wins, win rate, blackjacks, streaks) plus the
  last ten hands as a colour-and-glyph strip
- **A calm dark theme** — one flat gold accent on near-neutral charcoal surfaces; no gradients,
  glows or letter-spaced capitals outside the felt. Four bottom tabs: Home, Stats, Friends,
  Settings
- **Sound effects** — deal, chip, turn, win, lose, push, and blackjack cues, plus spoken
  "Stand"/"Bust" voice lines when an NPC seat finishes its turn
- **Spoken results** — every settled hand plays its outcome tone and then says the result:
  "Blackjack! You win, versus the dealer" on a natural — "Blackjack! You win, and take the sweep
  pot" when that natural sweeps — "You win, versus the dealer, and take the sweep pot" when any
  other hand sweeps the table, "Push" when the bet comes back, otherwise "You win, versus the
  dealer" or "Player lost". Taking the pot is followed by a drum flourish. A blackjack used to
  settle under a generic "Big win" that named neither the hand nor the pot
- **Spoken pot** — once every opponent seat has played and the figure has stopped moving, the
  dealer pill is read aloud: "Sweep pot, three hundred seventy five dollars", a second ahead of
  your own hand total. When no seat has forfeited a bet there is nothing to sweep, and the voice
  says what the pill says — "No sweep pot"
- **Spoken dealer** — the dealer says what it holds as it plays: "Dealer has fourteen" as the hole
  card turns over, then just the running total after every card it draws — "eighteen… twenty two"
  — since naming it once is enough. A natural is called by name ("Dealer has blackjack") and going
  over is called as what it is ("Dealer busts"), each with the result following it. The dealer
  waits for its own call-out to finish before touching the next card, so the cards never run ahead
  of the commentary
- **Hand-total circle** — your live card total toward 21 (the same number "Soft 19"/"Hard 17"
  already names) shows in its own circle next to the bet circle, gold-ringed normally, red when
  busted, and is read aloud as "You have [total]" when the table comes round to you — after every
  opponent seat has played, a second after the sweep pot has been called, as the last thing said
  before you act — and again after every hit, double, or split card. Going over 21 is called as
  "Player busts" rather than as a number
- **Dealer waits for the room** — the hole card turns over and the dealer then holds its two
  cards for two full seconds before drawing, so the spoken call-out of the hand you just
  finished is never talked over by the dealer's turn
- **One voice at a time** — every spoken line shares one channel and waits its turn: a seat's
  "Stand"/"Bust" never starts until the hand total before it has finished the word it is on. A
  line held more than 3s past its cue is dropped rather than said late
- **Voice toggle** — every spoken call-out above (hand totals, results, the sweep pot, and the
  NPC "Stand"/"Bust" lines) can be switched off without silencing the tones, from the onboarding
  screen before the first hand and from Settings → Sound & haptics afterwards. It sits under
  "Sound effects", so muting sound mutes the voice too and the Settings row dims while it is off
- **Haptics** — selection/light/medium/heavy impact and vibrate feedback, toggleable in settings,
  including a tap for each NPC seat's stand/bust
- **One rating ask, on a hand worth asking about** — after ten hands, the first time the player
  sweeps the pot, is dealt a natural, or wins a third hand in a row, Google Play's own review
  sheet slides up a second and a half behind the settlement card. Once per player, ever: the
  flag is set when the ask is made (not when it is answered) and persisted, so backgrounding the
  game mid-request or relaunching can never produce a second one. The decision itself
  (`utils/review_prompt.dart`) is pure and tested; nothing asks on a loss, a push, or a plain win
- **Web version** — runs in the browser at https://blackjack21-v2.web.app, auto-deployed by
  GitHub Actions on every push to `main`. Google sign-in is required on web (guest mode has no
  Firebase account behind it, so it's mobile/desktop only there)
- **Branded link preview** — sharing the web URL (WhatsApp, iMessage, Facebook, etc.) shows a
  custom casino-themed card: an Ace of Spades and King of Hearts fanned on a felt table, the
  "Blackjack 21: Sweep the Pot" title, and a real description, instead of the generic Flutter placeholder
- **Multi-language UI (in progress)** — Settings has a Language picker (Settings → Language),
  built on Flutter's standard `flutter_localizations`/ARB pipeline (`lib/l10n/`). The Settings
  screen itself ships translated into all 10 target languages — English, Spanish, French,
  German, Portuguese, Russian, Chinese, Japanese, Hebrew and Arabic; the picker lists every
  locale that has an `app_<lang>.arb` file, so it grows automatically as more screens are
  translated. The rest of the app's screens and data files are still English-only. The dealer's
  spoken call-outs are meant to follow the same language once the voice pipeline (currently
  English-only pre-recorded clips) gains per-language asset sets — not wired up yet
- **"More games: Video Poker" link** — Settings → About has a row (card icon, "Free video poker,
  no ads", translated into all 10 languages) that opens the developer's Video Poker game on
  Google Play in the Play app, tagged `utm_source=blackjack21` so those installs can be traced
  back here. If nothing on the device can open the link, a SnackBar says so instead of the tap
  silently doing nothing

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
├── screens/       # lobby, table, friends, settings, stats, onboarding
│   ├── legal/     # Terms + Privacy copy and the in-app reader (offline, no webview)
│   ├── shared/    # cross-screen pieces: tab_pill, async_action (pending state),
│   │              #   confirm_dialog, empty_state, avatar_initial
│   └── table/     # table sub-panels (felt, betting, action, chat sheet, settlement,
│                  #   table_layout (breakpoints + felt metrics), table_phase_banner,
│                  #   dealt_card, …)
├── services/      # sound_player, spoken_amount, social_service (Firestore), local_notifier,
│                  #   notification_support (web-safe "can we notify here?" check),
│                  #   daily_bonus_store (persists the last claim time + streak day),
│                  #   review_prompter (opens Play's in-app review sheet)
├── state/         # game_notifier (Riverpod)
├── theme/         # design tokens — app_colors (raw values incl. the light set),
│                  #   app_palette (semantic roles per brightness, a ThemeExtension),
│                  #   app_theme (ThemeData for both brightnesses), app_spacing
│                  #   (4/8dp scale, radii, 48dp touch minimum), app_motion
│                  #   (durations, curves, reduced-motion), app_text_styles (+ type ramp)
├── utils/         # formatters, leaderboard, points (hourly/daily buckets), comeback,
│                  #   daily_bonus (pure cooldown + 7-day streak logic),
│                  #   tutorial (pure "which coaching card, if any, right now?"),
│                  #   table_seats (pads real friends to 4 table seats with practice bots),
│                  #   review_prompt (pure "is this the hand to ask for a rating on?")
└── widgets/       # shared UI (buttons, overlays, cards, nav bar,
                   #   tutorial_coach_card, how_to_play_sheet, daily_bonus_dialog,
                   #   web_viewport_scaler)

tool/
├── make_icons.py             # renders every app icon (Android/iOS/macOS/web/Play) from one master
├── play_upload.py            # uploads a signed .aab to a Play track (Android Publisher API v3)
├── make_store_shots.py       # composes captioned store screenshots from raw device captures
├── play_images.py            # uploads the listing's images (screenshots, feature graphic, icon)
├── make_promo.py             # cuts the 30s vertical promo from a screenrecord of a real session
└── release_notes_en-US.txt   # en-US release notes passed to --notes-file

play-assets/                  # what the Play Store listing shows — the uploaded copies live on Play
├── icon-512.png              # 512×512 store icon, generated by tool/make_icons.py from the master
├── feature-graphic.png       # 1024×500 feature graphic
├── feature-graphic.html      # the source the feature graphic is rendered from
├── screenshot-frame.html     # caption-band template the screenshots are composed against
├── screen-01..08.png         # phone screenshots, 1344×2992, one benefit captioned on each
├── tab7-01..02.png           # 7-inch tablet screenshots, 1200×1920
├── tab10-01..02.png          # 10-inch tablet screenshots, 1600×2560
├── promo-vertical.mp4        # 31s 1080×1920 promo, for YouTube then the listing video slot
├── src/                      # icon-master.png (the app icon itself) + tool/make_icons.py's
│                              #   generated dealer cutouts for feature-graphic.html — see src/README.md
└── raw/                      # gitignored device captures the above are composed from
```

### Regenerating the store assets

Screenshots and the promo come from a real session, never a mockup. Capture on a device or an
emulator (`emulator -avd <name>`), install the release APK, then:

```bash
adb exec-out screencap -p > play-assets/raw/<name>.png      # one per screen listed in the script
python3 tool/make_store_shots.py                             # composes screen-*/tab*-*.png

adb shell screenrecord --size 1080x1920 --time-limit 90 /sdcard/promo.mp4
adb pull /sdcard/promo.mp4 /tmp/promo-raw.mp4
python3 tool/make_promo.py /tmp/promo-raw.mp4 play-assets/promo-vertical.mp4
```

Tablet captures come from the same emulator with `adb shell wm size 1200x1920` (and
`1600x2560`) plus a matching `wm density`; reset both with `wm size reset` / `wm density reset`
afterwards. The feature graphic is rendered from its HTML with headless Chrome at 1024×500.

Store *text* and *images* both go through the Play Developer API and need no browser:

```bash
python3 tool/play_images.py --language en-US    # feature graphic, icon, phone + tablet shots
```

Play rejects a screenshot whose long side is more than twice its short side, which is why the
phone set is composed at 1344x2688 rather than at the device's own 1344x2992.

Only three things still need the Console UI: the developer name, the app category and tags, and
the listing video (which must be a public YouTube link, so the MP4 is uploaded to YouTube first
and the watch URL is then set through the API).

### Publishing to Google Play

`tool/play_upload.py` does the whole release without touching the Play Console UI — the browser
route is a dead end here, because a release bundle is ~58 MB and browser file-upload automation
is capped well below that.

```bash
flutter build appbundle --release && python3 tool/play_upload.py --aab build/app/outputs/bundle/release/app-release.aab --track internal --release-name "1.0.0 (1)" --notes-file tool/release_notes_en-US.txt
```

Pass `--version-code N` instead of `--aab` to put a bundle that is already on Play onto a second
track — Play rejects a re-upload of a version code it already has. Now that the app has been
published, `alpha` accepts `--status completed` too; the draft-only restriction that once limited
`completed` to `internal` no longer applies.

Bump `version:` in `pubspec.yaml` before building — Gradle reads it as `flutter.versionCode` /
`flutter.versionName`, and Play rejects a bundle whose version code is already on the account.
Keep `tool/release_notes_en-US.txt` under **500 characters**; Play rejects anything longer.

Auth is a Google Cloud service account, `play-publisher@blackjack21-v2.iam.gserviceaccount.com`,
granted "Release apps to testing tracks" and "Manage testing tracks and edit tester lists" on this
app in Play Console. Its JSON key lives at `android/play-service-account.json` and is gitignored,
like `android/key.properties` — neither ever gets committed.

It can release to production as of 1.3.0 (4). Until then it could not: a `--track production` run
uploaded the bundle and staged the release, then failed on the final commit with `HttpError 403 …
The caller does not have permission`, discarding the whole edit — Play untouched, the version code
still free. The fix was ticking **Release to production, exclude devices, and use Play App
Signing** under **Users and permissions → play-publisher → App permissions**, alongside the
testing-track permissions it already had. A 403 on commit, with the upload itself succeeding, is
what that box being unticked looks like from the API.

**Managed publishing is off** for this app now, so a committed release goes to review by itself and
publishes when review passes — there is no longer a **Publish** button to remember in Publishing
overview. Anything else already sitting in **Changes in review** rides along with it.

### Verifying the invite deep link (Android App Links)

`web/.well-known/assetlinks.json` currently lists only the local debug keystore's SHA-256
fingerprint, so an invite link opens the app directly on a debug/`adb install`ed build but not yet
on a Play-distributed one. One-time manual steps to fix that:

1. Play Console → **Setup → App signing** → copy the **App signing key certificate**'s SHA-256 (not
   the upload key — Play re-signs the bundle with this one).
2. Add it to the `sha256_cert_fingerprints` array in `web/.well-known/assetlinks.json`, alongside
   the existing debug entry.
3. `flutter build web && firebase deploy --only hosting`.
4. Verify: `adb shell pm get-app-links com.micorlov.blackjack21_v2` should report the domain
   `verified`. Until it does, tapping a link still works — it just opens the web app (which
   auto-joins) instead of the installed app directly.

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management (`game_notifier`) |
| `audioplayers` | Sound effect playback |
| `cupertino_icons` | iOS-style icons |
| `firebase_core` / `firebase_auth` | Firebase app + Google/anonymous sign-in |
| `google_sign_in` | Google account picker for sign-in |
| `google_sign_in_web` | Renders Google's own Identity Services button on web — `authenticate()` isn't supported there |
| `cloud_firestore` | Friends groups and live hourly/daily score sync |
| `firebase_analytics` | Anonymous counts of what happens in the game — see **Privacy** below |
| `firebase_crashlytics` | Crash and non-fatal error reporting; installs the app's only `FlutterError.onError` / `PlatformDispatcher.onError` handlers |
| `url_launcher` | Opens WhatsApp with the prefilled invite link, and the Play Store from the web install banner |
| `share_plus` | The system share sheet for the invite link, alongside the WhatsApp button |
| `flutter_web_plugins` | `usePathUrlStrategy()`, so a web invite link resolves `/join/CODE` from the real URL path instead of the default `#/` hash fragment |
| `flutter_local_notifications` | "Friend passed you" leaderboard alerts, the daily-bonus reminder, and the play-streak reminder |
| `shared_preferences` | Saves the bankroll, stats, points, referral/streak/rebuy state and settings between launches (`game_store`), and the last daily-bonus claim time (`daily_bonus_store`) |
| `timezone` | Builds the `TZDateTime` the daily-bonus and streak reminders are scheduled against |
| `flutter_localizations` | Wires the Material/Widgets/Cupertino locale delegates the app-wide UI translation uses |
| `intl` | Backs `flutter gen-l10n`'s generated `AppLocalizations` class and ICU plural/placeholder syntax |
| `in_app_review` | Google Play's own rating sheet, asked for once per player after a well-won hand (`review_prompter`) |

Dev: `flutter_test`, `flutter_lints`, `integration_test`.

Typography is no longer a dependency: Sora, Instrument Serif and Space Mono ship inside the app
under `assets/fonts` (see **Assets**), replacing `google_fonts`, which fetched all three over the
network on first launch.

## Assets

`assets/fonts/` holds the three typefaces the design is drawn in, declared under `flutter: fonts:`
in `pubspec.yaml`:

| File | Family | Used for |
|---|---|---|
| `Sora-Variable.ttf` | `Sora` | Body and UI text. The upstream variable font — `AppText.sora` drives its `wght` axis through `fontVariations`, because Flutter will not do that from `fontWeight` alone |
| `InstrumentSerif-Italic.ttf` | `Instrument Serif` | Screen titles and display headings |
| `SpaceMono-Regular.ttf`, `SpaceMono-Bold.ttf` | `Space Mono` | Money, totals and uppercase labels |

They were fetched at runtime by `google_fonts` until 2026-09-05, so a cold first launch drew the
whole game in the platform fallback face and then reflowed once the download landed.

The app icon — Android (legacy + adaptive), iOS, macOS, web favicon/PWA icons and the Play Store
listing icon — is generated by `tool/make_icons.py` from a single master under `play-assets/src/`
rather than hand-resized per platform. See `play-assets/src/README.md` for the two master
conventions it supports; regenerate every size after swapping the master:

```bash
python3 tool/make_icons.py
```

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
| Result voice | `player_win.wav`, `player_lose.wav`, `player_push.wav`, `player_blackjack.wav`, `player_blackjack_pot.wav`, `player_pot.wav` | Your settled hand, 700ms after its tone — or later, if something is still speaking |
| Celebration | `pot_celebration.wav` | After the pot call-out — a synthesized drum roll, downbeat and major triad |
| Number words | `num/*.wav` — 0-19, the tens, `hundred`, `thousand`, `dollars`, `sweep_pot`, `no_sweep_pot`, `you_have`, `dealer_has`, `blackjack`, `player_bust`, `dealer_bust` | Stitched into the spoken pot call-out, your hand total, and the dealer's |

`assets/sfx/num/` needs its own `pubspec.yaml` entry: Flutter's asset folders are **not**
recursive, so a nested folder left out of the manifest is silently missing at runtime.

Pot figures are arbitrary multiples of the table minimum, so the sentence cannot be
pre-recorded. `spoken_amount.dart` turns the amount into words, and `SoundPlayer.playWords`
joins those clips into a single WAV in memory (45ms of silence between words) and plays it
through one `BytesSource` — playing them as separate calls would need each to report
completion before the next, and any gap would land mid-sentence.

Voice clips are synthesized speech (Kokoro, `am_michael` voice) rather than tones, so the
table reads as spoken call-outs. All are mono 16-bit 44.1kHz and peak-normalised to -6.5 dBFS
so no one line is louder than the rest.

Every clip must contain its whole word and decay naturally — a file cut short mid-syllable
still loads and plays, it just sounds like an unintelligible click, which is how a truncated
`npc_stand.wav` shipped once. `test/sfx_assets_test.dart` guards against that: it reads each
WAV and fails any clip still sounding above 10% of its own peak in its final 10ms.

`tool/gen_voice.py` re-cuts the whole spoken set in one command, so changing the table's voice
is a one-liner rather than 37 hand-trimmed files:

```bash
python3 tool/gen_voice.py --voice am_michael
```

It synthesizes each line, trims it to its own edges, resamples to 44.1kHz, peak-normalises and
fades it out. Clips are produced on the build machine and bundled, so Android and iOS play
byte-identical audio — nothing runs a TTS engine on the phone.

Kokoro's model is ~325MB and stays out of the repo, under `$KOKORO_HOME`
(default `~/.cache/blackjack21-voice`): a `kokoro-env/` venv with `kokoro-onnx` and
`soundfile`, plus `kokoro-v1.0.onnx` and `voices-v1.0.bin`. It also needs
`brew install espeak-ng` — the espeak bundled inside `espeakng-loader` has its data path
compiled in as a build-machine path that does not exist locally, so the tool redirects the
loader at Homebrew's copy.

The tool also speaks through macOS `say` (`--engine say`) for quick auditions. That path
fingerprints `say`'s fallback voice and refuses to run when the requested voice matches it:
`say -v Alex` on a machine without Alex returns success and audio in the fallback voice
instead of failing, which nearly shipped a whole set in the wrong voice.

## Testing

```bash
flutter analyze
flutter test
```

### Layout sweeps

`test/screen_overflow_test.dart` pumps **every screen and overlay** — onboarding, lobby, stats
(both tabs), friends, settings, the table in five states, the daily-bonus dialog, the
how-to-play sheet, the out-of-chips sheet and the friends standings card — on
five phone/tablet sizes at both text scales the app allows, and fails on any `RenderFlex`
overflow. Half the scenarios use "loaded account" data (a 35-character Google display name,
seven-figure bankrolls, a full hand history) because every row in the design was drawn around
"Guest" and "$1,150". `test/table_layout_test.dart` does the same for the felt's round phases
across seventeen device sizes (including the 384x832 phone the game is tuned on), and checks
that every bot seat shows its hand, that a bot card is never drawn under 32px wide on that
phone, that the empty pot pill stays hidden, and that the hero's cards draw at full size. `test/felt_metrics_test.dart` checks the felt's
vertical budget as plain arithmetic — the scale each phase gets on the target phone, and that
seat slots are the same height in every phase.

These sweeps only mean anything because `test/support/real_fonts.dart` loads the app's own three
faces from `assets/fonts`. Without it every glyph is a full em wide in `flutter test`, roughly
twice the shipped faces, and almost any row holding a sentence "overflows" in a test while being
fine on a phone. It used to substitute Roboto from the Flutter SDK cache, which measures about
10% narrower than Sora and so let two real overflows through.

Layout work that still has to be judged against the real fonts and real device metrics has a
driver test that walks the app from onboarding to a dealt round and then holds the table still:

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

### 2026-09-11
- docs: **admin.html** — new web-only admin panel (dark theme, green accent) with Google Sign-In
  gate (`micorlov@gmail.com`). Four tabs: Overview (live leaderboard stats), Players (full
  `leaderboard` collection, sortable/searchable), Groups (`groups` collection with member counts),
  Live Group (real-time `onSnapshot` listener for any group code). Read-only; backed by Firebase
  Firestore project `blackjack21-v2`.
- docs: **push-admin.html** — web-only Push Center page. Documents the current push notification
  state: local notifications (ID 210 daily bonus, ID 211 streak reminder) work via
  `flutter_local_notifications`; remote FCM is not configured (`firebase_messaging` absent).
  Includes an infrastructure checklist, local notification cards, a 5-step FCM setup guide, and a
  locked Compose preview. No APK rebuild required — static HTML files only.

### 2026-09-10
- feat: **new app icon.** A fully composed mark — the dealer holding the ace of spades and king
  of hearts, a gold "21" and ring on green felt, chip stacks in the corners — replaces the old
  dealer-on-felt icon across Android (legacy + adaptive), iOS, macOS, web/PWA and the Play Store
  listing icon. `tool/make_icons.py` gained a second master convention for this
  (`play-assets/src/icon-master.png`, used edge to edge with no felt/keying step) alongside the
  existing dealer-cutout one it still uses for `play-assets/feature-graphic.html`'s dealer bust —
  see `play-assets/src/README.md`.
- chore: **released 1.6.1 (8) to Google Play production at 100%**, carrying the new icon; the
  Play Store listing icon was refreshed to match via `tool/play_images.py --only icon`.

### 2026-09-09
- feat: **'More games: Video Poker' link in Settings** — a new row under Settings → About opens
  the developer's Video Poker game on Google Play (via `url_launcher`, external app, with a
  SnackBar fallback when the link cannot be opened). Its label and subtitle are localized in all
  ten ARB files; `_LinkRowData` gained an optional `leading` icon for it

### 2026-09-08 (3)
- chore: **released 1.6.0 (7) to Google Play production at 100%**, and rebuilt the listing around
  it: all 14 images uploaded through the Play Developer API (feature graphic, icon, eight phone
  screenshots, two 7-inch and two 10-inch tablet shots), the promo published to YouTube and
  attached as the listing video, the developer name changed to Orlov Games, and the category moved
  from Card to Casino with Blackjack and Card tags. `tool/play_images.py` is new and does the
  image half of that without a browser
- fix: **store screenshots are composed at 1344x2688, not 1344x2992.** Play rejects any screenshot
  taller than twice its width, so the first set would have been refused on upload

### 2026-09-08 (2)
- chore: **new Play Store listing, in eleven languages.** Title, short and full description
  rewritten around the words people actually search ("blackjack", "21", "card game") and pushed
  through the Play Developer API for en-US plus Arabic, German, Spanish, French, Hebrew,
  Japanese, Portuguese, Russian and Chinese. Each locale says plainly that the game itself is in
  English. Nothing claims offline play, because the game needs a connection
- feat: **new store art** — eight captioned phone screenshots, 7-inch and 10-inch tablet sets, a
  feature graphic carrying the new name, and a 31-second vertical promo cut from a real recorded
  session. All of it is generated by `tool/make_store_shots.py` and `tool/make_promo.py` from
  device captures, so it can be regenerated after any UI change instead of redrawn

### 2026-09-08
- feat: **the game is now Blackjack 21: Sweep the Pot.** "21 Sweet Pot" led with an invented
  brand in front of the word people actually search for, and the icon, feature graphic and
  onboarding screen all still said "Blackjack 21" — so the store title, the app and the art
  disagreed with each other. The in-app brand is "Blackjack 21" (launcher label, onboarding,
  legal copy, web title and link-preview card); the store listing carries the full
  "Blackjack 21: Sweep the Pot". Package id, Firebase project and the `blackjack21-v2.web.app`
  host are untouched, so no sign-in, deep link or saved game moves
- feat: **one in-app rating ask, on a hand worth asking about** — Play's own review sheet, after
  ten hands, on a sweep, a natural, or a third straight win. Once per player, persisted, never on
  a loss
- fix: **Settings → About shows the version you are running.** It was hardcoded at 1.2.0 (3)
  while the app shipped 1.5.0 (6), which made every bug report point at the wrong build

### 2026-09-06
- chore: **Released to Google Play as 1.5.0 (version code 6), at 100% rollout.** Carries the
  natural-plays-for-the-pot change and the result-card headline fix below. The store
  screenshots were left as they are: the phone was disconnected when the release was cut, so
  the result-card shot may still show the old sweep wording until it is retaken.

### 2026-09-05 (9)
- fix: **the result card no longer has its headline cut off.** The two sweep lines were the
  longest copy in the game at thirty and thirty-five characters, while every other outcome
  ("Dealer wins", "Blackjack! You win") is a handful of words. The card is laid out around the
  short ones — the headline shares its row with the round's net figure, so it gets about half
  the card's width — and at 115% system text the long line wrapped to three lines, at 130% to
  four. That grew the card past the panel's height cap, and because the panel scrolls from the
  bottom so the CTA stays in reach, what fell off the top was the headline itself. The sweep
  lines are now "You sweep the table" and "Blackjack — you sweep"; what the sweep paid and who
  paid it is still spelled out in the pot card below. The card's own padding and gaps were
  trimmed a few pixels each as well, so it now clears the panel at 100%, 115% and 130% text
  with room to spare rather than overflowing by 93px at the top end.

### 2026-09-05 (9)
- feat: **A blackjack plays for the sweep pot.** Being dealt 21 used to end the round in the
  same beat: the opponent seats were dealt cards that were thrown away, none of them played,
  the dealer never finished its hand, and no bet could be forfeited — so the best hand in the
  game was the one hand that could never win the pot this table is played for. It now runs the
  table like any other round, the hero simply having nothing to decide, and the 21 takes the
  pot on top of its 3:2. A dealer natural still ends the round before anyone acts.
- feat: **The natural is called by name.** "Blackjack! You win, versus the dealer", or
  "Blackjack! You win, and take the sweep pot" when it sweeps — replacing the generic "Big win"
  line, which named neither the hand nor the pot. The result card says "Blackjack — you sweep"
  where the sweep line used to overwrite the blackjack entirely (and the plain sweep headline is
  now "You sweep the table", short enough not to wrap off the card at 130% system text).
- fix: `test/outcome_call_out_test.dart` no longer fails a third of its runs. It asserted the
  dealer's *last* spoken line opened with "Dealer has", which is only ever said on the reveal —
  every card after it is the bare running total, so any deal where the dealer drew to a standing
  hand rather than busting failed.

### 2026-09-05 (8)
- chore: **Released to Google Play as 1.4.0 (version code 5), at 100% rollout.** The store
  listing carries four new phone screenshots taken from this build: a hand in play with every
  seat's cards showing, the sweep-pot result card, the betting tray, and the lobby.
- fix: the release bundle no longer requests `com.google.android.gms.permission.AD_ID`.
  Firebase Analytics contributes it through `play-services-measurement`, but the game shows no
  ads and the Play listing declares that it does not use an advertising ID — a mismatch Play
  rejects the release for. The manifest removes the permission with `tools:node="remove"`;
  analytics still works, it simply cannot read the advertising ID.

### 2026-09-05 (7)
- feat: **The table is drawn for players over sixty.** Everything on the screen is a size up
  and it is the default, not a setting: header title 24px and a shorter stake line
  (`$100–$1,000 · 3:2`) that no longer gets shrunk to fit; the phase banner at 18px; the bet
  figure at 28px with `ALL IN` a real pill; 64px chips (the tray closes its gaps before it
  scrolls, so five chips still fit a 375-wide phone); CLEAR/DEAL at 20px, HIT/STAND at 24px,
  DOUBLE/SPLIT at 20px; the insurance, waiting and result panels to match. On the felt: 66x96
  cards for the dealer and the hero, 46–52px avatars, the dealer total at 24px, the balance at
  24px, the running total at 32px, bet and total circles at 78px.
- fix: **The hand no longer shrinks while it is being played.** The felt scales itself to fit
  the height it is given, and mid-round it asked for 615 units against ~400 available on a
  384x832 phone — every card and figure was drawn at two-thirds size for the whole hand, and
  a bigger font would only have shrunk it further. Three things bought the room: the hero's
  bet circle, total circle and name plate share one row instead of stacking; the bot seats'
  card fans are gone (a 27px card was unreadable, and ~18px once scaled), replaced by the
  hand's total, `BUST`, `STAND`/`HIT` and the bet written on the plate, which also means one
  seat height in every phase so plates never jump; and the felt's monospaced figures take a
  1.15 line height (Space Mono's natural line box is 1.48x, which alone made a two-line plate
  outgrow its slot). The budget is now 314 units for betting and 512 mid-round, so that phone
  draws betting at 1.0 and the hand at 0.93–0.97 instead of 0.65; `referenceWidth` is 384.
- fix: the result card's showdown line ("YOU 14 · DEALER 19") has the full width of the card
  instead of sharing the message's column beside the net figure, where a phone cut it to
  "YOU 14 · DEALE…" — the dealer's half of the comparison the card exists to make. The net
  figure itself keeps its natural size up to 55% of its row and scales down past that rather
  than overflowing a 320-wide screen at 130% text. The result card may take 68% of the
  screen (other panels stay at 62%), so its headline is not scrolled off the top on the phone;
  during settlement the felt is a recap the card repeats, so it is the felt that gives way.
- feat: **You can see what everyone else is holding.** Each seat's hand is fanned beside its
  name at 42x60 — in the room the avatar occupies until the deal — so showing it costs the
  felt one 12-unit band rather than the 38 a row above the plate used to take, and the cards
  land at about 37px on the phone against roughly 18px before. The seat's total sits on the
  name line (red when it is over 21) with `STAND`/`BUST` under it.
- refactor: the empty `NO SWEEP POT` pill stays off the felt until a seat forfeits a bet; its
  30-unit slot is reserved so the dealer's cards do not move when it appears. The bot seats'
  `+$45` points figure is gone from the plate (it mirrored the rank strip removed in (6), and
  beside a `STAND` badge it forced the stack to half size). `ActionPillButton` gained a
  `horizontalPadding`. `FeltMetrics` exposes `cardHeight` and `seatBandGap`.
- test: `test/felt_metrics_test.dart` (the budget as arithmetic); the layout sweep gains the
  384x832 phone and assertions that seats draw no cards, that `BUST`/`STAND`/`19` appear on
  the plates, that the empty pill is hidden mid-round and `NO SWEEP` still shows at settlement,
  and that the hero's cards draw at ≥ 90% size on that phone.

### 2026-09-05 (6)
- refactor: **The app got simpler.** Removed outright: the Shop (chip packs, card backs, the
  Ocean/Ember felts, the avatar frame, the simulated "watch an ad" reward), the Weekend Cup,
  the three daily missions, XP and levels, achievements and the Awards tab, the rank strip
  ticker above every screen, the stories rail and overlay, the world leaderboard (hourly and
  daily global top lists), the referral-count milestone tiers, "Gift 100" between friends, and
  the one-time "Four things to know" tips screen. The lobby is now the player's name and
  balance, the daily bonus, and the three tables; the bottom bar has four tabs (Home, Stats,
  Friends, Settings). Saved games written by the previous build still load — the dropped keys
  are ignored, and the bankroll, stats and settings beside them restore as before.
- feat: **A calmer dark theme.** Surfaces lost their green cast and sit a step lighter; gold is
  a single flat fill rather than a three-stop gradient under a glow; section headings are
  sentence-case body type instead of letter-spaced mono capitals; buttons weigh w700 with no
  tracking; the nav bar is opaque and quiet instead of blurred and gold-lit; the daily-bonus
  card is a plain panel with one small gold button. The felt keeps its greens. All WCAG AA
  pairings still hold (`test/theme_contrast_test.dart`).
- refactor: `GameState` lost 22 fields and `GameNotifier` about 350 lines with the features
  above; `game_data.dart` keeps one felt and one card back. Deleted: `shop_screen`,
  `cup_screen`, `tips_screen`, `world_leaderboard_screen`, `rank_strip`, `level_up_sheet`,
  `achievement_toast`, `story_overlay`, `missions_card`, and the `cup`, `xp`, `missions`,
  `achievements` and `world_standings` utils with their tests.

### 2026-09-05 (5)
- refactor: **The design system stopped drifting.** `AppAlpha` names the ten opacity steps that
  were already doing the work — the app had 36 distinct alpha values, with 0.1/0.12/0.14/0.15 all
  serving the same role in different files, because a bare number gives the next person nothing to
  match against. `AppColors` gained `textBody`, `scrim`, `ringOcean` and `ringEmber` for hexes that
  were repeated as literals across five, eight and two files. Every `BorderRadius.circular(999)`
  is now `AppRadius.pill`, and the radii that map exactly onto tokens use them.
- refactor: **Four copies of the same button became one.** `OutlinePillButton` replaces the
  friends screen's two private pills and the shop's, and `CircleIconButton` replaces the table
  header's and the Cup screen's. The world-standings tab bar now uses the shared `TabPillRow`
  rather than its own copy, which had drifted to 13px type, a border that fails 3:1 contrast, and
  no minimum touch height — its tabs were about 44px against the 48dp floor the shared one keeps.
- fix: **No type below 12px anywhere.** The ramp documented a 12px floor and eleven places broke
  it at 10 or 11 — the dealer's pot pill, the sweep banner, the settlement breakdown, the bet
  label, the rank strip, the tutorial card. All raised, and the layout sweep confirms nothing
  overflows as a result.

### 2026-09-05 (4)
- feat: **The app can finally tell a broken build from a quiet week.** It shipped with no
  analytics and, more seriously, no error handlers at all: a framework error printed a red box in
  debug and did nothing in release, an error off the main isolate vanished outright, and the
  catch blocks in the social, save and notification services each `debugPrint`ed their failures
  into a console no player has. Firebase Crashlytics now takes both handler slots, and Firebase
  Analytics records counts of what happens — hands played and their result, daily bonuses,
  missions, achievements, levels, screens opened, invites shared.
- feat: **A privacy switch that actually switches something.** Settings → Privacy turns usage and
  crash reporting off, and the toggle reaches the SDKs' own collection flags rather than just
  stopping this app from calling them. Nothing logged carries a display name, a group code, an
  account identifier or anything typed.
- fix: **The Privacy Policy no longer says something untrue.** It claimed "no analytics SDK";
  it now describes exactly what is collected, names the two SDKs, and points at the switch.
  **Michael: the Play Console data-safety form needs updating to match before the next release.**
- chore: `firebase_auth` 6.5.6 → 6.6.1 and `cloud_firestore` 6.7.1 → 6.9.0, forced by the
  `firebase_core` 4.14.0 that the new packages pull in — 6.5.6 fails to compile against it.

### 2026-09-05 (3)
- feat: **Achievements finally do something.** The seven badges were recomputed from stats on
  every build, paid nothing and announced nothing — a player could cross their hundredth hand and
  find out days later by opening a tab. Each now carries a one-time chip reward (100–1,000),
  lands as a gold banner the moment it is earned, and is recorded in the save so it pays exactly
  once. The Awards list shows the reward and, for the ones that count toward something, how far
  along you are.
- feat: **Levels.** Every hand earns experience — more for a win, a blackjack, a sweep, and a
  bigger table — and experience only ever accumulates, so an hour of bad cards still leaves
  something behind. Levelling up interrupts the felt with a sheet listing what it unlocked, and
  the lobby header carries the level in place of "Welcome back". The Ember felt (level 5), the
  Crimson card back (level 8) and the gold avatar frame (level 3) are now things to reach rather
  than things that were always free.
- feat: **Three daily missions.** Drawn from the day's date, so every device agrees without
  storing anything; all reachable in one sitting; reset at midnight with nothing taken away for
  missing a day. They sit under the daily bonus on the lobby with a progress bar and a claim
  button each.
- feat: **A real way out of being broke.** Running dry used to show one "Rebuy in 3h 21m" pill in
  the betting panel: a player who found it on cooldown was finished, while a daily bonus, a
  finished mission and a referral reward might all have been waiting unmentioned. There is now a
  sheet listing every route back with its live state, and exactly one primary button — the one
  that is actually available right now.
- test: `test/achievements_test.dart`, `test/xp_test.dart` and `test/missions_test.dart` cover the
  new pure logic; `test/game_store_test.dart` covers the new persisted fields and, specifically,
  that an existing save with none of them restores as "nothing earned yet" so the rewards are
  paid rather than silently marked claimed.

### 2026-09-05 (2)
- feat: **Winning looks like winning.** Sweeping the table or hitting a natural 21 now bursts
  confetti over the felt and flies each beaten seat's chips across to your plate — the sweep pot
  is what this game is built around and the felt used to mark it with nothing but a changed
  number, while the audio side had a tone, a call-out and a drum flourish. Both layers are
  hand-painted (`lib/widgets/confetti_burst.dart`, `lib/screens/table/chip_flight_layer.dart`),
  ignore pointers so the READY button stays tappable underneath, and do not run at all under the
  system's reduce-motion setting. Reserved for blackjacks and sweeps: confetti on every $50 win
  would stop meaning anything by the tenth hand.
- feat: **The numbers count.** The bankroll, the round's net and the daily-bonus reward roll to
  their new value with a rate-capped haptic tick instead of switching between frames — a $400 win
  and a $50 loss used to look identical. `CountUpText` counts down as well as up, and arrives
  instantly under reduced motion. Covered by `test/count_up_text_test.dart`.
- feat: **A real chip, and a heavier celebration.** `ChipDisc` draws the rim, edge spots and inner
  ring that make a circle read as a casino chip; the daily-bonus dialog uses it in place of a flat
  gold disc, and the chips in flight are the same object. Blackjacks and sweeps get a short roll
  of haptic taps building to one heavy hit rather than the single tap a chip press gets.
- feat: dealt cards land with a few degrees of tilt that unwinds, so a card reads as dealt rather
  than as a rectangle appearing.
- fix: **The standings card stopped advertising to people playing alone.** With an empty group it
  opened on a page saying "No friends here yet — you play alone" under a gold invite button; the
  world race is real whether or not you have invited anyone, so that is the page it opens on
  instead, and the empty one is not built.
- refactor: the reaction float and the waiting pulse route their durations through `AppMotion`
  (`float`, `pulse`) like every other animation, so they collapse under reduced motion too.

### 2026-09-05
- fix: **The dealer's cards no longer land on top of the other players.** The felt reserved 164
  units for a dealer cluster that needs about 178 — 220 once the gold "TABLE SWEEP" banner
  appears — so from the fourth card on, the dealer's hand was painted over the two upper seat
  plates and their card fans. The band is now sized for what it holds, grows with the system font
  setting (most of the cluster is type), and a dealer who keeps drawing fans their cards instead
  of running off the table. `test/table_layout_test.dart` gained a five-card settled-with-sweep
  scenario and an assertion that no dealer card covers a seat.
- fix: **The dealer says BUST.** A revealed 23 used to be shown as a bare number while every
  losing seat got a red BUST tag — the one bust that pays the whole table was the only one the
  felt did not name.
- fix: **The sweep result stopped truncating.** "You win the sweep p…" is now "Sweep pot: yours",
  and the line wraps to two rather than clipping when a winner's display name is long.
- fix: **The Weekend Cup header no longer overflows** on a 320-wide phone at large text.
- feat: **One-tap rebet, and an ALL IN button.** Once you have dealt a hand, DEAL becomes
  "DEAL $50 AGAIN" and re-stakes it in a single tap; ALL IN puts the whole stack (capped at the
  table maximum) on the felt instead of twenty taps on a chip.
- feat: **The table gives you something to look at while the bots play.** The swipeable standings
  card moved out of the betting panel — where it ate a quarter of the screen at the moment you
  are choosing a chip, and, with an empty group, spent it saying "you play alone" — into the
  stretch where the other seats and the dealer are playing and you have nothing to do.
- feat: **One gold button per screen.** Insurance now leads with NO THANKS rather than INSURE;
  HIT and STAND are the same size, so the felt stops pointing at the card that busts on a hard 19;
  the lobby's recommended table carries a gold PLAY button, and the tournament card, the shop and
  the empty-state invites step down to outlines and text links. New `OutlinePillButton` replaces
  four hand-rolled copies of the same secondary button.
- feat: **The lobby stopped inventing friends.** The stories rail of four fictional players is
  hidden until real people are in your group, and table chat no longer types messages from
  "Maya T." at someone playing alone.
- feat: **Fonts ship with the app, and the splash is the app's own colour.** Sora, Instrument
  Serif and Space Mono are bundled instead of downloaded on first run, so the first frame is
  already right; Android's launch window is the felt black with the wordmark, not the template's
  white flash.
- test: layout sweeps now measure with the real bundled faces rather than a Roboto stand-in,
  which caught the two overflows fixed above.

### 2026-09-04 (7)
- fix: **The gold "TABLE SWEEP" banner no longer beats the hole card to the punch either.** Same
  root cause as the tone fix below: a natural blackjack reveals the dealer's hole card and sets
  `sweepAmount` in the same beat, but the banner had no entrance animation of its own, so it popped
  in fully formed while `FlipRevealCard` was still mid-turn. `DealerArea` is now a `StatefulWidget`
  that gates the banner's first render on the flip's actual duration (500ms via `AppMotion`, or
  instant under reduced motion) whenever `holeRevealed` just flipped true in the same update; a
  widget that mounts already past the reveal (hot reload, returning to a settled table) shows it at
  once, since there is no fresh flip to wait for.

### 2026-09-04 (6)
- feat: **Invite friends with one link instead of a 4-step manual instruction.** The WhatsApp
  invite used to send only a 6-character code and "Open the app → Friends → Join → type it in" —
  no link at all, and nothing on any platform could open one. It now shares
  `https://blackjack21-v2.web.app/join/CODE`: tapping it opens the app straight to the join
  (Android App Links, `flutter_deeplinking_enabled` + an `autoVerify` intent-filter in
  `AndroidManifest.xml`, verified via the new `web/.well-known/assetlinks.json`), or the playable
  web app if it isn't installed, which joins automatically and offers a Play Store banner. Added a
  system share sheet (`share_plus`) and a Copy link button alongside WhatsApp, and the Friends
  screen now pre-fills the join field from the clipboard on first visit. New pure module
  `lib/utils/invite_link.dart` builds and parses the link; `lib/main.dart` gained route generation
  (`onGenerateInitialRoutes`/`onGenerateRoute`) and a new `AppLifecycleBridge` widget to receive it
  on both cold start and while the app is already running.
- fix: **Referrals now credit the inviter, not the joiner.** `joinGroupByCode` used to increment
  the *joiner's* referral count — so creating a group and having five friends join it earned
  nothing, while joining five groups yourself earned the top referral tier. The joiner now gets
  +200 welcome chips on joining; the inviter gets +100 chips per real friend who joins their link,
  with a toast and (when the Settings "Social" notification toggle is on) a local notification.
  Firestore rows gained a write-once `invitedBy` field (validated server-side in `firestore.rules`
  — never the writer's own uid, always the group's actual creator), and referral credit is now
  derived live from who invited whom rather than a counter that could drift or reset on relaunch.
  New pure module `lib/utils/referrals.dart`.
- feat: **Real table presence — lobby cards show who is actually there.** `tableFriendsHereLabel`'s
  hardcoded "2 friends here" / "1 friend here" strings are gone. Friends' rows now carry a
  `tableKey` (written by `enterTable`/`exitTable` and every score report), so a lobby table card
  shows real friends currently seated there, with avatars, and tapping it seats you with them —
  `tableSeats()` puts a friend actually at this stake first. New pure module
  `lib/utils/table_presence.dart`.
- feat: **Play-day streak.** Playing at least one hand a day now builds a streak (separate from the
  daily-*claim* streak) worth up to +250 extra daily-bonus chips, and a scheduled local
  notification warns when today's streak is about to lapse unplayed. The app also finally responds
  to being backgrounded and resumed at all (`AppLifecycleBridge` + `GameNotifier.onAppResumed` /
  `onAppPaused`) — previously nothing did, so a resume waited out whatever was left of the
  60-second heartbeat and a background could lose a save still waiting out its debounce. New pure
  module `lib/utils/play_streak.dart`.
- feat: **Rebuy replaces the free, unlimited "Reset bankroll."** Dropping below a table's minimum
  now offers a Rebuy to 1,000 chips once every 4 hours, with a live countdown, instead of an
  unlimited free reset available from both the table and Settings. New pure module
  `lib/utils/rebuy.dart`.
- fix: **Signing in with Google no longer strands a guest's friends group.** `_completeGoogleSignIn`
  used `signInWithCredential`, which replaces the anonymous session with a brand-new uid — a guest
  who had already created or joined a group lost it silently the moment they signed in. It now
  links the Google credential onto the existing anonymous user (`linkWithCredential`), falling back
  to `signInWithCredential` plus re-adopting the device's group under the new uid only when that
  Google account already has its own separate identity elsewhere.

### 2026-09-04 (5)
- fix: **The win/blackjack/lose/push tone no longer beats the hole card to the punch.** A natural
  blackjack — on the initial deal, or right after an insurance decision — reveals the dealer's hole
  card and settles the round in the same beat, but `FlipRevealCard` still takes 500ms to visually
  turn the card over. `GameNotifier._settle()` played the outcome tone immediately in that case, so
  the "you win" chime landed before the card had turned face-up. `_settle()` now takes a
  `holeCardJustRevealed` flag (set only by those two fast paths) and holds the tone back 500ms —
  long enough for the flip to finish — through a new `_playOutcomeTone()` helper; the normal
  dealer-turn path, where the hole card has been showing for seconds already, is unaffected.

### 2026-09-04 (4)
- feat: **Translated the Settings screen into all 10 target languages.** Added
  `lib/l10n/app_{es,fr,de,pt,ru,zh,ja,he,ar}.arb`, so the Language picker (Settings → Language)
  now lists Spanish, French, German, Portuguese, Russian, Chinese, Japanese, Hebrew, and Arabic
  alongside English, instead of only English. These are a first LLM-generated translation pass of
  the Settings screen's strings only — the rest of the app's screens, the data files
  (`game_data.dart`, `tutorial_data.dart`), and the dealer's spoken voice are still English-only.

### 2026-09-04 (3)
- feat: **Win call-outs name the dealer.** The spoken result for a plain win changed from
  "Player wins" to "You win, versus the dealer", and the sweep-pot win from "Player wins the
  sweep pot" to "You win, versus the dealer, and take the sweep pot" — the old wording didn't say
  who was beaten, which reads as ambiguous now that "Closest to 21" lets you also sweep the other
  seats. `tool/gen_voice.py`'s `VOICE_LINES` for `player_win.wav`/`player_pot.wav` updated and both
  clips re-cut with Kokoro (`am_michael`, the shipping voice).

### 2026-09-04 (2)
- feat: **Localization infrastructure + Settings language picker.** Added Flutter's standard
  `flutter_localizations`/`intl`/ARB pipeline (`l10n.yaml`, `lib/l10n/app_en.arb`, generated
  `AppLocalizations`), wired into `MaterialApp` with a persisted `languageOverride` setting
  (`GameState`/`SavedGame`/`GameNotifier.setLanguage`, saved the same way as `soundOn`/`voiceOn`).
  The Settings screen is now fully extracted to localized strings and has a new Language section;
  the picker lists whichever locales have a translated `.arb` file, so it grows as more languages
  are added — only English exists today. First slice of a larger effort to translate the whole
  app and the dealer's spoken call-outs into Spanish, French, German, Portuguese, Russian,
  Chinese, Japanese, Hebrew and Arabic; the remaining screens, data files, and the voice pipeline
  are not converted yet.

### 2026-09-04
- chore: **1.3.0 (4) is on production, in review.** The first attempt uploaded the 59.6 MB bundle
  and staged the release, then failed the edit's commit with `403 … The caller does not have
  permission` — the `play-publisher` service account held "Release apps to testing tracks", and
  production is not a testing track. Play discarded that edit whole, so version code 4 survived
  for the retry. Granted the account **Release to production, exclude devices, and use Play App
  Signing** in Play Console, re-ran the same upload, and production now reads **1.3.0 (4), full
  rollout, completed**, with the three pending store-listing edits riding along in the same review.
  Managed publishing is off, so it publishes when review passes rather than waiting on a click.

### 2026-09-03 (25)
- chore: **cut 1.3.0 (4).** `pubspec.yaml` reads `1.3.0+4` and `tool/release_notes_en-US.txt` is
  rewritten for it (431 of Play's 500 characters).

### 2026-09-03 (24)
- feat: **going over 21 is called a bust, on both sides of the table.** "Player busts" and "Dealer
  busts" replace "You have twenty three" and "Dealer has twenty two" — the number left you to work
  out what had just happened to the round. On your bust the table passes straight to the dealer,
  and your own hand is called before the dealer's, not after it.
- feat: **a push says "Push".** It was the one outcome with a tone and no words, which is
  indistinguishable from a call-out that was missed. New clip `player_push.wav`.
- refactor: **"Dealer has" is said once.** The dealer names itself on the reveal and then just
  counts — "Dealer has fourteen… eighteen… twenty two" — instead of repeating the whole phrase
  card after card.

### 2026-09-03 (23)
- feat: **the dealer says what it holds, and waits for itself.** "Dealer has fourteen" as the hole
  card turns over, then its new total after every card it draws, with a natural called by name —
  "Dealer has blackjack", and the settlement result queued behind it. Its cards come 600ms apart
  and the sentences run longer than that, so the beats between them are now floors: the dealer
  waits out its own call-out before touching the next card, and the commentary can never fall a
  card behind. Two new clips, `dealer_has.wav` and `blackjack.wav`.
- feat: **"No sweep pot" is now said out loud.** The pill has always shown it; the voice used to
  say nothing at all, which was indistinguishable from a call-out that had been missed. Every
  hero turn is announced the same way now: what the table is playing for, a beat, then your hand.
  New clip `no_sweep_pot.wav`.

### 2026-09-03 (22)
- feat: **your turn is announced in one order now — pot, beat, hand.** "Sweep pot, one hundred
  dollars" lands on the turn cue, then a one-second pause, then "You have sixteen" as the last
  thing said before you hit or stand. The pause is measured from when the pot line actually
  finishes, so it is the same beat whatever the figure. With no pot to call the hand total follows
  the turn cue directly rather than after a stretch of silence.

### 2026-09-03 (21)
- feat: **"You have sixteen" is said when it is your turn, not at the deal.** It used to be
  announced as the cards landed, across the opponent seats calling out their own "Stand" and
  "Bust", so the one number you needed arrived in the middle of somebody else's turn. It now waits
  for every seat to finish and lands with the turn cue, ahead of the sweep-pot call-out. A hand
  that never reaches you — a natural, or a dealer blackjack — settles without it, as the result
  call-out already says what happened.

### 2026-09-03 (20)
- fix: **the table no longer talks over itself.** "You have sixteen" was cut off mid-word by a
  seat's "Bust": the hand total starts 350ms after the cards land and runs over a second, the
  first seat acts 520ms in, and the seat lines were filed under the sound effects, so they played
  on the tone channel where the voice queue could not hold them back. They are voice lines now,
  queued like every other spoken call-out, so each one is heard whole.

### 2026-09-03 (19)
- feat: **the dealer waits two seconds before playing.** The hole card flipped and the dealer
  started drawing 520ms later — while the spoken call-out of the hand you had just finished
  ("You have twenty", or the sweep-pot figure) was still playing. The reveal beat is now 2s, long
  enough to outlast those lines, so you hear your own hand, see the dealer's cards, and only then
  watch the dealer act. Draw and settle pacing are unchanged.

### 2026-09-03 (18)
- test: **landscape and tablet are covered now.** The redesign's largest rewrite — the felt's
  fixed 393px canvas becoming a constraint-driven layout with a side rail — shipped verified only
  by a throwaway probe that was then deleted, i.e. by nothing. `table_layout_test` gained five
  landscape and large-screen devices, so the whole existing matrix of round phases and text scales
  now runs against them: 1,384 tests, up from 1,094.
- fix: **the table overflowed in landscape at large text.** Adding that coverage immediately found
  it — 60 failures, all on short landscape phones at 1.3x text, where the coach card's header ran
  12px past the side rail in every round phase. The rail's minimum width goes 280 → 320: shrinking
  the "Full rules"/"Skip" links to fit would have taken their tap targets under 48dp, and the felt
  scales where text does not.

### 2026-09-03 (17)
- fix: **the back button no longer quits the game.** Navigation is an enum on the state, not a
  `Navigator` stack, so Android Back had nothing to pop and closed the app from wherever you
  were. It was fixed for the table first, which left the identical trap everywhere else — backing
  out of the Weekend Cup, Stats, Friends, Shop or Settings dropped you on your home screen. Back
  is now handled once for the whole app and peels one layer at a time: an open story, then the
  chat sheet, then the table menu, then the screen, then the app. Found by installing on a real
  phone; `test/back_button_test.dart` now covers every screen so a new one cannot miss the rule.

### 2026-09-03 (16)
- fix: **the dealer's turn is something you can watch.** `_playDealer` drew the whole hand in one
  synchronous loop and settled in the same frame, so `RoundPhase.dealer` never survived to be
  rendered: the hole-card flip and every draw fired at once, the result panel landed on top of
  them, and the "Dealer is playing…" indicator was unreachable code. The dealer is now paced like
  the NPC seats already were (520/600/480ms). Same cards in the same order — only the timing.
- feat: **the table says what is happening.** The five small phase pills are now a headline
  banner — "Place your bet", "Sam is playing", "Your turn · hand 2 of 2", "Dealer is playing" —
  gold-filled when the table is waiting on you, over a five-segment progress track.
- fix: **chips were below the minimum touch target on every device.** A `SizedBox(height: 46)` +
  scaling `FittedBox` meant the 60px chips always rendered at 46×46. They now stay full size and
  the tray scrolls if it will not fit. Header icon buttons went 46 → 48dp too.
- feat: cards are drawn, not typed — suits are painted vector shapes instead of Unicode glyphs
  that depended on a runtime-fetched font, and chips are rendered as real chips with edge spots,
  an inner ring and a rim highlight.
- feat: **the felt honours your text size.** It previously disabled scaling outright, so every
  live number in the game — dealer total, bet, hand total, balance, seat stacks — ignored the
  system setting. The fixed 393px canvas is gone, replaced by a constraint-driven layout with
  fractional seat positions, a scale cap (a tablet rendered everything at ~2×), landscape support
  with a side rail, and tablet gutters.
- fix: **onboarding replayed on every cold launch.** Nothing recorded that the sign-in gate had
  been passed, so returning players met it forever. Existing saves default to "done".
- fix: **the notification permission no longer fires on frame 1**, over a blank grey window,
  before the player knows what the app is. It is asked when a notification setting is switched
  on, and the switch reverts if the OS says no instead of sitting there lit and lying.
- feat: Terms and Privacy exist, in-app and offline, linked from the line that already claimed
  you had agreed to them; Settings gains an About panel with them and the version.
- fix: practice bots no longer pose as real friends — with working "Gift 100" buttons — in the
  friends list, lobby top players, Weekend Cup counts or shop highlights. Each is now a designed
  empty state with the invite CTA.
- fix: resetting your bankroll and signing out now ask first; sign-in, invite and join show that
  they are working instead of sitting idle through the whole round trip.
- feat: accessibility, where there was none — the codebase contained zero `Semantics` widgets.
  Cards announce themselves ("Ace of spades") instead of reading a suit glyph twice, buttons
  declare their role and why they are disabled, the stats history strip encodes results by glyph
  as well as colour, the toast is a live region, and every animation honours reduced motion.
- fix: SURRENDER was the largest button in its row and styled like the constructive ones; it is
  now the smallest with a destructive outline. HIT and STAND are debounced, so a fast double-tap
  no longer draws two cards.
- fix: the group-code field built a new `TextEditingController` on every rebuild — leaking one
  each time and forcing the caret to the end, so a typo mid-code could not be corrected.

### 2026-09-03 (15)
- refactor: **the app has a design system.** Colour, type, spacing, radii and motion were
  previously decided at each call site — 14 different text sizes between 10 and 48px, seven
  corner radii, and 31 raw colour literals outside `theme/`. `lib/theme/` now holds the tokens:
  `app_spacing` (a 4/8dp scale, radii, and the 48dp touch minimum), `app_motion` (durations
  chosen by what is moving, plus one reduced-motion helper), a named type ramp in
  `app_text_styles`, and `app_palette` mapping raw values to semantic roles.
- fix: **losses were nearly invisible on the table.** The loss red `#C1503F` scored **1.76:1**
  against the felt — below even the 3:1 floor for non-text, on the number telling you how much
  you just lost. Outcome colours now come in two forms: a fill colour, and an accessible variant
  for text on the felt (loss 4.53:1, win 5.75:1, push 4.53:1). Control outlines got the same
  treatment, since `border` sat at 1.71:1 and was the only thing defining some tappable edges.
- test: contrast is now enforced rather than audited. `test/theme_contrast_test.dart` checks every
  text-on-surface pairing in both themes against WCAG AA, including against the felt specifically
  — a token change that regresses a pairing fails the build instead of reaching players.
- feat: a light theme exists and is contrast-tested. It is not switched on yet: the screens still
  read colours straight from `AppColors`, so `themeMode` stays pinned to dark until they are
  migrated to the palette, rather than shipping light chrome around dark hand-styled panels.

### 2026-08-15 (14)
- chore: **bumped the app to 1.2.0 (3) and shipped it to Google Play.** `1.1.0 (2)` had been the
  build on both tracks since August 6, thirteen commits back — three features (the neural-voice
  re-cut, the hand-total circle, the voice on/off option) and six fixes (sweep pot, voice queue,
  five overflowing screens, the navigation-bar gap, Google Sign-In `DEVELOPER_ERROR`, the startup
  hang) had accumulated behind it, which is a minor bump rather than a patch.
- chore: uploaded the signed 58.9 MB bundle to **Internal testing**, then promoted the same
  version code to **Closed testing – Alpha** with `--version-code 3` — Play rejects a re-upload of
  a version code it already holds, so one build reaches both tracks. Both now read `1.2.0 (3)`,
  status `completed`, confirmed by reading the tracks back off the API.
- docs: rewrote `tool/release_notes_en-US.txt` for 1.2.0. The first draft ran 591 characters and
  would have been rejected — Play caps release notes at **500 per language** — so it ships at 467.
- docs: corrected **Publishing to Google Play**, which still claimed only `internal` accepts
  `--status completed` "while the app is still a draft". The app is published; `alpha` took
  `completed` without complaint. Added the version-bump and 500-character rules to the same section.
- note: managed publishing is on (see [2026-08-15 (12)](#2026-08-15-12)), so both releases land
  under **Changes ready to publish** once review clears, and reach testers only after
  **Publish** is clicked in the console. The API commit does not do that step.

### 2026-08-15 (13)
- fix: **the table no longer talks over itself.** The spoken call-outs were scheduled from three
  independent timers — the hand total 350ms after a card lands, the settlement result 700ms after
  its tone, the sweep-pot figure 700ms after the turn cue — and every one of them drove the same
  voice channel by stopping whatever was already playing. The windows overlap: "You have twenty
  five" runs 1.7s, so the result call-out 350ms behind it cut the total off after four syllables.
  Every bust, every double and every natural blackjack hit this, which is what made the table
  sound like it was saying the wrong thing.
- fix: `services/sound_player.dart` now treats the voice channel as a queue instead of a race. A
  line waits for the one in front of it rather than cutting it short, and a line held more than
  `SoundPlayer.kMaxVoiceWait` (3s) past its cue is dropped instead — by then the moment it
  described has passed. Pre-recorded lines are re-wrapped in the same canonical header as the
  stitched number words, so a clip's length is known from its byte count and whatever follows can
  be timed off it.
- fix: **the second split hand is announced when it becomes the active one.** `_advanceHand` said
  nothing when play moved from the first split hand to the second, so the last number spoken was
  the first hand's total while the circle on screen showed the second's.
- fix: muting now silences call-outs already handed to the queue. `toggleSound` and `toggleVoice`
  cancel their pending timers, but a queued line lives in `SoundPlayer` and only `silenceVoice()`
  can drop it.
- refactor: the sweep-pot drum flourish is scheduled from the moment the pot call-out actually
  finishes, reported back by the queue, rather than the fixed `_kPotVoiceLength` offset that
  constant is gone. With voice off it still follows the settlement tone directly.
- test: added `test/voice_queue_test.dart` — every clip is 44.1kHz mono 16-bit (the format the
  channel's byte-count arithmetic assumes), `SoundPlayer.wavDuration` matches each real clip to
  within a millisecond, and every reachable hand total 4-31 outlasts the 350ms gap between the
  two call-outs, so the overlap the queue exists to absorb cannot be quietly optimized away.

### 2026-08-15 (12)
- chore: **published the pending tester-list change, which is why Testers Community reported the
  app was unreachable.** Their support mail said their users could not access 21 Sweet Pot. The
  cause was on our side and had nothing to do with countries or the release: the two Closed
  testing – Alpha tester edits from [2026-08-15 (3)](#2026-08-15-3) ("Add 1 email list: Testers
  Community", "Remove email list") had cleared Google's review but were still sitting in
  Publishing overview under **Changes ready to publish**. Managed publishing is on, so the track
  was still serving the tester configuration published on **August 8** — the 135 community
  addresses were never live, and the console showed **Installed audience: 0**. Clicked **Publish
  2 changes**; the queue is now empty and the app reads *Last published on August 15, 2026*.
  Changes reach Google Play within about an hour. The track itself was never the problem: Active,
  1.1.0 (2) "available to selected testers", 177 countries / regions.
- note: the track attaches testers via **Email lists** (one list, "Testers Community", 135 users),
  not via **Google Groups**. Testers Community's mail flags the email-list route as a common
  setup mistake, because a scraped CSV snapshot never picks up members who join their pool later.
  Switching is a separate change — Play Console treats email lists and Google Groups as mutually
  exclusive options, so selecting Groups drops the 135-address list and needs its own review and
  publish cycle.

### 2026-08-15 (11)
- fix: **the table no longer promises a sweep pot that does not exist.** With every opponent
  seat still in — all four standing, the dealer's hole card down, nothing forfeited — the pill
  above the dealer used to read `TABLE POT $275` (every chip on the felt, including your own
  bet) and the call-out said "Sweep pot, two hundred seventy five dollars", naming money no
  one could win. `TablePot` now only ever counts forfeited bets: the pill reads `NO SWEEP POT`
  with no figure until a seat busts or loses to a revealed dealer hand, then switches to
  `SWEEP POT $x`, and the call-out stays silent until there is a pot to call. Settlement is
  unchanged (`YOU TAKE`/`JORDAN TAKES`/`DEALER TAKES`/`NO SWEEP`).
- test: `pot_outcome_test.dart` covers the mid-round pill and the call-out gate in both states

### 2026-08-15 (10)
- feat: **the spoken call-outs can now be switched off.** A "Voice call-outs" toggle appears in
  two places: on the onboarding screen, as a pill under the sign-in buttons, so a player can
  silence the table before the first hand instead of hearing it once and then hunting for the
  setting; and in Settings → Sound & haptics, with a sublabel naming what it covers. It gates
  every spoken clip — hand totals, settlement results, the sweep-pot figure, and the NPC
  "Stand"/"Bust" lines — while leaving the tones alone. The switch sits under "Sound effects"
  (voice needs the same output), so the Settings row greys out and stops taking taps while
  sound is off. Turning it back on answers in the voice itself, "You have twenty one". The
  sweep drum flourish, previously timed to follow the pot call-out, now follows the settlement
  tone directly when voice is off rather than landing after a stretch of silence.
- feat: `GameState.voiceOn` and `SavedGame.voiceOn` persist the choice in the `gameStateV1`
  blob. Schema version is unchanged: a save written before this toggle existed has no `voiceOn`
  key and restores as on, which is what that player has been hearing all along.
- refactor: `settings_screen.dart`'s toggle rows moved into a `_ToggleRow` widget with optional
  `sublabel` and `enabled`, so a row can explain itself and dim when the switch it depends on
  is off.
- test: `test/onboarding_screen_test.dart` covers the new toggle's default and its flip;
  `test/game_store_test.dart` covers the round-trip and the missing-key default.

### 2026-08-15 (9)
- feat: **the hand-total circle now says "You have [total]" instead of the bare number.**
  `tool/gen_voice.py` gained a `num/you_have.wav` clip ("You have", Kokoro `am_michael`, 0.64s,
  tail 0.5%) and an `--only` flag so a single clip can be regenerated without re-cutting the
  other 37; `_announceHandTotal` in `state/game_notifier.dart` now prepends `'you_have'` to the
  spoken number words.

### 2026-08-15 (8)
- fix: **no screen runs off the edge any more.** A whole-app layout sweep found five places
  where a row was drawn around short sample data and overflowed on a real account: the
  Settings account row pushed a Google display name straight off the panel (on *every* phone
  size — 2.8px on a 412-wide screen, 95px on a 320-wide one), the lobby's Daily Bonus card
  shoved its Claim button off the card at a large font scale, the Weekend Cup title ran past
  the screen edge, the shop's chip-pack tiles clipped their price line off the bottom, and the
  felt's pot pill pushed the pot figure off the table when the sweep winner had a long name.
  Each one now flexes, shrinks or ellipsises instead of overflowing.
- test: added `test/screen_overflow_test.dart` — 250 tests pumping every screen, dialog, sheet
  and overlay across five device sizes and both text scales, with long-name/high-bankroll data,
  asserting no `RenderFlex` overflows anywhere.
- test: added `test/support/real_fonts.dart`, which gives layout tests real font metrics by
  registering the Flutter SDK's bundled Roboto under the families `google_fonts` requests.
  `flutter test`'s fallback font makes every glyph a full em wide — about twice the shipped
  faces — which reported 94 overflows where only 19 were real.

### 2026-08-15 (7)
- feat: **the table now speaks in a human voice.** All 37 spoken clips — the four result
  call-outs, the two NPC lines and the 31 number words — were re-cut in Kokoro's `am_michael`,
  a local neural voice, replacing macOS `say`'s Samantha. Same lines, same timing, same
  format contract (mono 16-bit 44.1kHz, peak-normalised to -6.5 dBFS, faded out); every clip
  still passes `test/sfx_assets_test.dart`'s truncation guard, with tails at 1.2% of peak or
  below against the old set's 2.5%. `player_pot.wav` came out at 1442ms against the previous
  1510ms, still inside `_kPotVoiceLength`'s 1520ms, so the drum flourish is unchanged and
  starts 78ms after the line ends.
- feat: added `tool/gen_voice.py`, which regenerates the whole spoken set from one command
  instead of hand-trimming each file. Two engines: Kokoro (what ships) and macOS `say` (for
  auditions). The `say` path fingerprints the fallback voice and aborts when the requested
  voice matches it — `say -v Alex` on a machine without Alex returns success and audio in the
  fallback voice rather than failing, which nearly shipped the set in the voice it replaced.
  Clips are generated on the build machine and bundled, so Android and iOS stay byte-identical.

### 2026-08-15 (6)
- feat: **added a hand-total circle showing the hero's live card total, spoken aloud as it
  changes.** `screens/table/hero_hand_area.dart` gains a new gold-ringed circle next to the bet
  circle displaying `BlackjackRules.handValue(hand.cards)` (red-ringed on bust) — the same number
  the "Soft 19"/"Hard 17" text already names, now visible at a glance. `state/game_notifier.dart`
  speaks the total via the existing `SoundPlayer.playWords`/`spokenAmountWords` number-clip
  pipeline (English), 350ms after `deal.wav` so the tone finishes first, gated on `soundOn` exactly
  like the other voice call-outs: after the opening two-card deal, and again after every hit,
  double, and split.

### 2026-08-15 (5)
- fix: **the Android system navigation bar no longer covers the app's own controls.** The shell draws
  edge-to-edge (`SafeArea(bottom: false)` in `lib/main.dart`) and nothing consumed the bottom system
  inset, so on Android 15+ the gesture pill / three-button row was painted straight over the UI. Five
  surfaces were affected: the bottom-nav labels (`widgets/bottom_nav_bar.dart`), the table's
  bet/deal/hit/stand panel (`screens/table/table_action_panel.dart`, sitting 28px under the bar — its
  buttons were partly untappable), the table chat sheet (`screens/table/table_chat_panel.dart`), the
  Weekend Cup's last leaderboard row (`screens/cup_screen.dart`), and the onboarding terms line
  (`screens/onboarding_screen.dart`, a `Positioned` **sibling** of that screen's `SafeArea`, so the
  `SafeArea` never reached it). Each surface now insets its own content while its background still
  bleeds to the screen edge.
- test: added `test/system_inset_test.dart` — pumps a 412x915 viewport with a 48px bottom
  `FakeViewPadding` and asserts the onboarding terms line, all five tab labels, and the table betting
  panel stay above the system bar. All three cases fail against the pre-fix code.

### 2026-08-15 (4)
- chore: **submitted the app to Testers Community, starting the 14-day closed-testing clock.** Filed
  it as "21 Sweet Pot" on the Starter plan (15 testers, 1 of 3 credits spent) with the opt-in link
  `https://play.google.com/apps/testing/com.micorlov.blackjack21_v2`, the `play-assets/icon-512.png`
  icon, and a tester note that no login is needed because guest play works. Their dashboard now
  tracks it as Day 0 / 16. Testers opt in within 6 hours, so the Play Console tester-list change
  ([2026-08-15 (3)](#2026-08-15-3)) has to clear Google's review *and* be published before then, or
  early testers hit "Item not found".
- note: the iOS app icon (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`) is still the stock
  Flutter logo — only the Android launcher icons and `play-assets/` were ever branded. Harmless for
  the Play Store track, but any iOS/TestFlight build ships with the Flutter logo.

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
