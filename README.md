# blackjack21_v2

A Unity (Android) blackjack game with a multi-seat table and a friends race. Four tabs, one felt, no shop.

> **Contributor rule:** every change to this project must update this file in the same
> commit. See [CLAUDE.md](CLAUDE.md) for the exact requirements.

## Features

- **Play now** — guest entry opens the coached Bronze table directly, with no bet placed.
  Google sign-in stays available.
- **Activation measurement** — first-hand, ten-hand and tutorial milestones, entry-choice events,
  plus an export-based funnel and day-one retention report. See [growth measurement](docs/growth/README.md).

- **Blackjack table** — multi-seat felt with dealer area, hero hand, betting, insurance,
  splits/doubles, and settlement panels
- **Drawn for large type** — the game is for players in their sixties and up, so the table is
  big by default rather than behind a setting: 88-unit hero cards (66 for the dealer, never under
  42x60 for the other seats), 64-unit chips, 20–24 unit action buttons, and no character anywhere
  smaller than 12 units on screen — the felt's scaling included, which `RulesAudit` checks on four
  phone sizes. A short phone squeezes the gaps on the felt before it shrinks a single card
- **The Seat** — the whole app is drawn as a first-person seat at a casino table
  (`docs/design-concepts/the-seat/`): a dark room with warm lamps, a wooden dealer's edge, green felt with
  its print curved along the table, a stitched leather rail, the dealer's tray, shoe and discard holder, and
  every screen in the same browns, brass gold and ivory. Portrait only
- **Casino seat order** — the table plays the way a real one does: the two seats on your right (first
  base, Maya and Jordan) act before you, the two on your left (Sam and Priya) after you, then the
  dealer. A bust, surrender or natural on your side still lets the seats after you play, and their
  forfeited bets reach the sweep pot. A dealer natural still ends the hand before anyone acts
- **Turn timer** — your turn stands automatically after 20 seconds, as at a casino table; a gold bar
  and the seconds left sit above the action buttons and turn red for the last five. Each split hand
  gets a fresh clock (hitting does not restart it). The clock never runs on a coached tutorial hand
  and pauses while the app is in the background or the table chat or menu is open. On by default;
  Settings → At the table → Turn timer switches it off
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
  via `hosting/.well-known/assetlinks.json`); without the app it opens a landing page
  with a "Get it on Google Play" link. The Friends screen also pre-fills
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
- **Respectful review requests** — after ten hands, a quiet settlement can request the Play review
  sheet. Failed/unavailable requests wait seven days; completed calls wait 90 days, with a
  three-request cap. Attempts, outcomes and cooldowns survive relaunch. The timing logic is ported
  and tested, but the Unity build's review service is still a no-op: no sheet is shown yet.
- **Invite landing page** — https://blackjack21-v2.web.app serves the invite link and the privacy
  policy, auto-deployed by GitHub Actions on every push to `main`
- **Branded link preview** — sharing the invite URL (WhatsApp, iMessage, Facebook, etc.) shows a
  custom casino-themed card: an Ace of Spades and King of Hearts fanned on a felt table, the
  "Blackjack 21: Sweep the Pot" title, and a real description, instead of a generic placeholder
- **Multi-language gameplay** — Settings, core table controls and labels, results, the three-hand
  coaching and reference rules support English, Spanish, French, German, Portuguese, Russian,
  Chinese, Hebrew and Arabic (10 locales, `Unity/Assets/Resources/Locales/*.json`); Hebrew and
  Arabic render right-to-left, with Arabic letter shaping. Native onboarding benefits and entry buttons
  are translated too. Lobby, social, legal documents and some accessibility copy remain English.
- **"More games: Video Poker" link** — Settings → About has a row (card icon, "Free video poker,
  no ads", translated into all 10 languages) that opens the developer's Video Poker game on
  Google Play in the Play app, tagged `utm_source=blackjack21` so those installs can be traced
  back here. If nothing on the device can open the link, a SnackBar says so instead of the tap
  silently doing nothing
- **Admin panel: time played per player** — `admin.html` shows each player's total time in the
  game (Overview leaderboard, and a sortable column on the Players tab), from foreground time the
  app reports to `leaderboard/{uid}.playSeconds`

## Getting Started

The game is a Unity 6000.3.25f1 project in `Unity/` (Android, IL2CPP ARM64). Everything — every screen,
dialog and the felt — is built in code at runtime, so the scene is empty and there are no prefabs.

```bash
# once per checkout: fetch Firebase (~760 MB, not committed) and configure the project
Unity/tools/install_firebase.sh

# build the development APK (signed with the debug key) -> Unity/Builds/Android/blackjack21-unity.apk
/Applications/Unity/Hub/Editor/6000.3.25f1/Unity.app/Contents/MacOS/Unity -batchmode -nographics -quit \
  -projectPath Unity -executeMethod Blackjack.EditorTools.BuildTools.BuildAndroid -logFile /tmp/build.log

adb -s <serial> install -r Unity/Builds/Android/blackjack21-unity.apk
```

Keep `-r`: it upgrades in place so the player's save survives. The build is signed with
`~/.android/debug.keystore`, the key the old Flutter build used, so it upgrades that install too (saved
Flutter data does not carry over).

## Project Structure

```
Unity/
├── Assets/
│   ├── Scripts/Core/          # rules engine as plain C# (Blackjack.Core, no UnityEngine): cards, shoe,
│   │                          #   round engine, settlement, progression, RTL (ArabicShaper, Bidi)
│   ├── Scripts/Game/          # GameController (paced NPC/dealer turns, audio/haptic cues, bonus, social),
│   │   │                      #   services behind interfaces with Null implementations
│   │   └── UI/                # runtime UI toolkit + every screen (onboarding, lobby, table, stats,
│   │                          #   friends, settings), dialogs, overlays, the felt shader view
│   ├── Scripts/GameFirebase/  # Firebase-backed services, compiled only when FIREBASE_SDK is defined
│   ├── Scripts/Editor/        # BuildTools (configure + Android build), ProjectSetup, audio import
│   ├── Resources/             # Locales (10 JSON files), Sfx (+ spoken amounts), Fonts, Felt shader
│   ├── Plugins/Android/       # BlackjackExtras.androidlib: permissions + invite-link intent filter
│   └── Tests/                 # EditMode (NUnit) and PlayMode (offscreen screenshots)
├── tools/                     # install_firebase.sh, unpack_unitypackage.py
docs/design-concepts/the-seat/ # the design reference: ten table states, the overview and the PDF
hosting/                       # Firebase Hosting: invite landing page, privacy policy, assetlinks.json
play-assets/  tool/            # Google Play listing artwork and the store upload scripts
firestore.rules  firestore.indexes.json  firebase.json  .firebaserc
admin.html  push-admin.html  dashboard.html   # admin pages (deploy-admin.yml publishes the first two)
```

`tool/gen_voice.py` and `tool/make_icons.py` were written for the removed Flutter tree and still target
its `assets/` and `android/` output paths; point them at `Unity/Assets/Resources/Sfx` and
`Unity/Assets/Icons` before using them again.

### Unity internals

- `Unity/Assets/Scripts/Core/` — the rules engine as plain C# (`Blackjack.Core` assembly, no Unity
  references). Every step is a pure function from one immutable `RoundState` to the next; timing is left
  to the caller (`GameController`).
- `Unity/Assets/Tests/EditMode/` — 172 NUnit tests (rules, betting, settlement, progression, controller,
  RTL, contrast, turn order, turn timer). `Unity/Assets/Tests/PlayMode/` holds the scenario registry (`Scenarios.cs`), the
  screenshot test (`ScenarioShots`) and the design-rules audit (`RulesAudit` + `rules-baseline.txt`).
- `Unity/Assets/Scripts/Game/UI/Type.cs` — the type ramp (`Type.Display` … `Type.Caption`, `Type.Numeral`)
  and `Type.Floor` (12); `TextFloor` keeps a label at the floor however its parents are scaled;
  `Core/Contrast.cs` is the WCAG luminance/ratio maths the audit uses. A `FloorScope` on the felt gives
  every label created under it a `TextFloor` automatically (the hero area opts out until its redesign).
- Turn order lives in `RoundEngine`: `SeatsActingIn(phase)` splits the seats around the hero
  (`TableCatalog.SeatsBeforeHero` = 2), `RoundPhase.NpcsAfter` is the third-base turn, and
  `FeltMetrics.SeatSlot(i)` places each seat on the curve of the felt in that order (first base on the
  right in every language). The turn clock is `GameController.TurnTimer.cs` (`RoundState.TurnDeadline`)
  and `TurnTimerView` draws it.
- The Seat's art: `Resources/Shaders/Felt.shader` (room, wood edge, felt, seat arc, leather rail — the
  rail's curve comes in as `_Rail`), `Game/UI/Gfx.Seat.cs` (cards, chips, chip stacks, tray, shoe,
  discard holder, the room backdrop with its bokeh, each baked once and cached) and `Game/UI/ArcText.cs`.
- The felt (`Game/UI/Screens/Table/`): `FeltView` owns the canvas, fixtures and print and lays out
  `DealerView`, four `SeatView`s (cards on one layer, name pills on a layer above every card) and
  `HeroView`; `FeltBits` holds the shared pills, chip stacks, bet rings and glows; `FeltEffects` flies
  chips from each seat's ring to yours, and pins the ribbons and the result float. Every row comes from
  `FeltMetrics` (`Y()`, `X()`, `SeatSlot`). `TablePanels` builds the controls from `W.SeatButton` (gold,
  leather, felt and loss finishes) and `W.OutlineChip` in `Game/UI/Widgets.Seat.cs`; `TurnTimerView`
  is the turn row.

Firebase (Auth, Firestore, Analytics, Crashlytics — SDK 13.17.0) is **not committed**: it is ~760 MB of
native libraries. `Unity/tools/install_firebase.sh` downloads Google's official zip, verifies its SHA-256,
unpacks the four `.unitypackage`s into `Unity/Assets` with `tools/unpack_unitypackage.py` (Unity's own
importer hangs headless once the External Dependency Manager starts); the Firebase console
`Assets/google-services.json` (public client keys) is committed. `BuildTools.Configure` then defines
`FIREBASE_SDK`, which switches on the `Blackjack.Game.Firebase` assembly (`FirebaseSocialService`,
`FirebaseAnalyticsService`, `FirebaseRegistration`). Without the SDK the game runs on the offline Null
services. Firestore collections and fields (`players`, `groups/{code}/players`, `leaderboard`,
`config/features`) are unchanged, so a group created on an older build still works.

Not yet verified: Google sign-in (needs an interactive account on a device) and Play in-app review
(still a no-op).

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
python3 tool/play_images.py --all-languages --only icon,featureGraphic
```

The icon and the feature graphic are stored **per locale**, not once per app. A locale with no
screenshots of its own falls back to the default listing, but a locale that already has an icon
keeps showing that icon forever. So an upload naming only `--language en-US` leaves the Hebrew,
Russian, Arabic and every other listing on the previous artwork — use `--all-languages` whenever
the icon or the feature graphic changes.

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
python3 tool/play_upload.py --aab <path-to>.aab --track internal --release-name "1.0.0 (1)" --notes-file tool/release_notes_en-US.txt
```

Pass `--version-code N` instead of `--aab` to put a bundle that is already on Play onto a second
track — Play rejects a re-upload of a version code it already has. Now that the app has been
published, `alpha` accepts `--status completed` too; the draft-only restriction that once limited
`completed` to `internal` no longer applies.

Bump `VersionName` / `VersionCode` in `Unity/Assets/Scripts/Editor/BuildTools.cs` before building — Play
rejects a bundle whose version code is already on the account. `BuildAndroid` currently writes a
development APK (`buildAppBundle = false`); a Play release needs an `.aab` signed with the upload key,
which is not wired up yet.
Keep `tool/release_notes_en-US.txt` under **500 characters**; Play rejects anything longer.

Auth is a Google Cloud service account, `play-publisher@blackjack21-v2.iam.gserviceaccount.com`,
granted "Release apps to testing tracks" and "Manage testing tracks and edit tester lists" on this
app in Play Console. Its JSON key lives at `android/play-service-account.json` (path used by `tool/play_upload.py`) and is
gitignored — it never gets committed.

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

`hosting/.well-known/assetlinks.json` currently lists only the local debug keystore's SHA-256
fingerprint, so an invite link opens the app directly on a debug/`adb install`ed build but not yet
on a Play-distributed one. One-time manual steps to fix that:

1. Play Console → **Setup → App signing** → copy the **App signing key certificate**'s SHA-256 (not
   the upload key — Play re-signs the bundle with this one).
2. Add it to the `sha256_cert_fingerprints` array in `hosting/.well-known/assetlinks.json`, alongside
   the existing debug entry.
3. `firebase deploy --only hosting` (or merge to `main`; the workflow deploys `hosting/`).
4. Verify: `adb shell pm get-app-links com.micorlov.blackjack21_v2` should report the domain
   `verified`. Until it does, tapping a link still works — it just opens the web app (which
   auto-joins) instead of the installed app directly.

## Dependencies

| Package | Why |
|---|---|
| Unity 6000.3.25f1 | Engine; built-in render pipeline, Gamma colour space, uGUI + TextMeshPro |
| `com.unity.mobile.notifications` | Local daily-bonus and friends-activity notifications (Android channels) |
| `com.unity.test-framework` | EditMode and PlayMode tests |
| Firebase Unity SDK 13.17.0 | Auth, Firestore, Analytics, Crashlytics — fetched by `Unity/tools/install_firebase.sh` |
| External Dependency Manager | Bundled with Firebase; resolves its Android Gradle dependencies |

## Assets

- `Unity/Assets/Resources/Locales/*.json` — the 10 UI languages (en, he, ar, es, fr, de, pt, ru, ja, zh),
  202 keys each; `ar` and `he` render right-to-left.
- `Unity/Assets/Resources/Sfx/` — sound effects and the spoken call-outs (`Sfx/num/` holds the spoken
  amounts, so adding a clip is just adding the file).
- `Unity/Assets/Resources/Fonts/` — Sora (Regular/SemiBold/Bold static instances), Instrument Serif
  Italic, Space Mono, and Cinzel Bold (a static 700 instance cut from the OFL variable font in
  `google/fonts`, used only for print on the felt; licence in `Unity/Assets/Licenses/Cinzel-OFL.txt`).
  OS fonts are added as fallbacks per language.
- `Unity/Assets/Icons/` — launcher (adaptive foreground/background, legacy) and notification icons.
- `hosting/` — `privacy-policy.html` is the Privacy Policy URL the Play listing requires, served at
  `https://blackjack21-v2.web.app/privacy-policy.html`; `index.html` is the invite landing page;
  `og-image.jpg` is the 1200×630 link-preview banner.
- `play-assets/` — Play Store listing artwork; see **Regenerating the store assets**.

## Testing

EditMode (rules, betting, settlement, progression, controller, RTL — no graphics needed):

```bash
/Applications/Unity/Hub/Editor/6000.3.25f1/Unity.app/Contents/MacOS/Unity -batchmode -nographics \
  -projectPath Unity -runTests -testPlatform EditMode -testResults /tmp/unity-results.xml
```

PlayMode tests render offscreen (needs graphics, so no `-nographics`); set `BJ_SHOTS` to the output
folder:

```bash
BJ_SHOTS=/tmp/shots /Applications/Unity/Hub/Editor/6000.3.25f1/Unity.app/Contents/MacOS/Unity -batchmode \
  -projectPath Unity -runTests -testPlatform PlayMode -testResults /tmp/play-results.xml
```

- `ScenarioShots` writes one PNG per entry of `Tests/PlayMode/Scenarios.cs` — every screen, the ten
  Seat table states, every dialog and sheet, and the Hebrew/Arabic views.
- `RulesAudit` draws every scenario on four phone sizes (1080×2340, 720×1600, 1080×1920, 1600×2560) and
  checks the design rules in `CLAUDE.md`: no character under 12 units on screen (the felt's scale
  included), no tap target under 48×48, text at 4.5:1 and control outlines at 3:1 against the pixels
  really behind them. Known violations are listed in `Tests/PlayMode/rules-baseline.txt`; a new one fails
  the test, and so does a fixed one whose line is still there. `BJ_SHOTS/rules-report.txt` lists every
  violation with its worst value. `BJ_RULES_BASELINE=write` rewrites the baseline from a full run;
  `BJ_SCENARIO=seat_` narrows either test to matching scenario names. The baseline is empty: any violation
  fails the test. The registry includes Hebrew and Arabic Seat states (`rtl_*`).

A Core change is not done until the EditMode suite passes. Check on a device or emulator
(`adb -s <serial> logcat --pid=$(adb -s <serial> shell pidof com.micorlov.blackjack21_v2)`): the Firebase
lines show the SDK initialising and the anonymous sign-in.

## Changelog

### 2026-10-14 (settings fix)
- fix: the switch rows in Settings (sound and haptics, the turn timer, notifications, privacy) no longer
  sit on a white strip — the row's tap area was given a default white image before its clear one.
- test: `settings_middle` and `settings_bottom` scroll the Settings list before the design-rules audit,
  which only reads what is on screen; content below the fold is now held to the rules too.

### 2026-10-14 (The Seat, phase 6: portrait, right-to-left, reference)
- chore: portrait only — `BuildTools.Configure` switches every landscape and upside-down rotation off, so
  the Seat (drawn for a phone held upright) can never be turned sideways.
- test: Hebrew and Arabic Seat scenarios (your turn, a split, a seat playing, the result) join the
  registry and pass the design rules: the table keeps casino order in every language (first base on the
  right) while the text, panels, pills and turn order mirror.
- docs: `docs/design-concepts/the-seat/` (the ten screens, the overview and the PDF) is tracked as the
  design reference. The Play screenshots are not refreshed yet: the rule for them is a real session on a
  device (see **Regenerating the store assets**), and they still show the previous look.

### 2026-10-14 (The Seat, phase 5: the rest of the app)
- feat: the lobby, stats, friends, settings, onboarding, the navigation bar, dialogs and sheets move into
  The Seat's language — the room backdrop behind every screen, leather-dark panels with warm keylines,
  ivory type, serif titles, brass-gold buttons, a gold active tab. Sizes move onto the type ramp and
  radii and padding onto the tokens; the lobby's silver mark and Google's blue become tokens.
- fix: every on/off row in Settings (and the voice row on the first screen) is now one 48-unit target —
  the 52x30 switch alone was too small to hit; table-chat reactions are 48 tall; the Join button is
  96 wide; invite outlines and outline pills reach 3:1; avatar initials pick ivory or ink for 4.5:1 and
  never drop under 12 units, and the green, blue and violet avatar colours are a shade deeper for it.
- test: the design-rules baseline is empty — every screen, table state and dialog passes the type
  floor, 48x48 targets and contrast on all four phone sizes. Any new violation now fails `RulesAudit`.

### 2026-10-14 (The Seat, phase 4: table controls)
- feat: the controls under the felt follow The Seat. Your turn shows a turn row (gold label, the clock's
  bar, the seconds), DOUBLE / SPLIT / SURRENDER at 52 units with what each costs or why it is off ("+$100",
  "pairs only", "keep $50", "not after split"), and leather STAND / gold HIT at 64 units on a pressed lip.
  Betting shows the bet, ALL IN as a 48-unit pill, the house chips and CLEAR / DEAL. While others play:
  who is playing and that you play third, the turn order in casino order (done names struck through, the
  acting one in gold), and 48-unit quick-chat chips ("GG", "Nice hand", Chat). The dealer's turn says
  what it has and why it draws. Insurance is an offer card over INSURE / NO THANKS (declining stays the
  gold primary: insurance is a losing bet).
- feat: the result is a sheet over the felt (the table keeps its full size behind it): the outcome in the
  serif with the net figure, then You bet / Hand vs dealer / Sweep pot / Balance and READY FOR NEXT HAND.
  Ribbons pop over the felt print for a double, a split, a blackjack and a bust, and the round's result
  floats up from your bet ring. The coach card's Rules and Skip links are full 48-unit targets.
- fix: a split no longer leaves the first card at the old 88-unit size beside its new 66-unit partner; the
  dealer's box never covers a card or runs off the felt; the rail follows the table on wide screens; the
  pot no longer recomputes every frame of the result; flying chips take the colour of the bet; the felt
  material is freed on a language change. 22 new strings in all 10 languages. Baseline 67 → 48.

### 2026-10-14 (The Seat, phase 3: seats, hero and chips on the curve)
- feat: the felt is laid out as The Seat — one 384x520 design canvas (`FeltMetrics`) that squeezes only the
  gaps above your hand on a short phone (so nothing shrinks and the bet stays clear of your cards) before
  it scales. The dealer's cards sit under the chip tray with a "Dealer 6 + ?" box beside them ("16 ·
  draws", "25 · bust"); the placard, discard holder and shoe take their places; "Blackjack pays 3 to 2 /
  Dealer stands on all 17s" is printed along the curve; "Place your bets" shows while the table bets.
- feat: the four opponents sit on the curve in casino order (Maya and Jordan on your right, Sam and Priya
  on your left), each a name/total pill over a fan of cards turned toward the dealer and a bet ring with
  its chips; the seat acting glows and its pill turns gold; a seat that busts is cleared to an empty
  dashed ring; at the result each pill shows what that seat won or lost. Names sit above every card.
- feat: your hand is 88 units wide under a gold total badge ("11 hard", "21 doubled", "21 blackjack",
  "25 bust", "21 you win"); a double is dealt sideways across the hand; a split lays both hands side by
  side at the dealer's card size, the one in play lit and the other dimmed, each with its own ring and a
  "Hand 1 11" label. Your bet stands in a ring as chip stacks; your balance is racked on the rail.
- feat: the table header is an Instrument Serif title with Space Mono stakes and gold-ringed 48-unit
  round buttons; the five-segment track is now one sentence-case phase pill. 20 new strings in all 10
  languages.
- fix (rules): seat pills are 80% black (the design's 66% washed ivory text out over cards), the felt
  print is solid, the card red is a shade deeper, the idle split hand counts as inactive, and the room's
  lamps are dimmer behind the title. Design-rules baseline: 111 → 67.

### 2026-10-14 (The Seat, phase 2: felt art)
- feat: the table is drawn as The Seat — a dark room with out-of-focus lamps behind it, a wooden edge on
  the dealer's side, the green felt with a dashed arc of betting spots, and a padded leather rail with a
  stitched seam curving across the bottom (`Felt.shader`, all closed-form, no loops or noise).
- feat: classic cards (rank and suit in the corner, a large centre pip, a framed court panel, the
  mirrored index on the 88-wide hero cards) on 256x372 art, with red cross-hatched backs; casino chips
  with white edge spots in the house colours (25 green, 50 orange, 100 black, 500 purple, 1000 yellow),
  labelled by figure in whichever of ivory or ink reads better; the dealer's racked chip tray, the shoe
  and the discard holder.
- feat: `ArcText` bends a label along an arc after shaping, for the felt print ("Blackjack pays 3 to 2",
  "Dealer stands on all 17s", in Cinzel for Latin-script languages and Sora elsewhere) and the table
  placard ("Min $25 / Max $500"); 4 new strings in all 10 languages. Both are placed by the phase 3 layout.
- fix: card shadows follow the design's size (they were wide enough to grey the index of the card
  beneath), and a chip's figure no longer sits on its white ring. Design-rules baseline: 125 → 111.

### 2026-10-14 (turn timer fixes)
- fix: switching to another app on your turn no longer comes back to a hand stood by "Time's up" — the
  clock banks its seconds the moment the app is backgrounded, not on the next frame (a phone runs none
  while away).
- fix: leaving the table during the dealer's turn settles the hand at once, and re-entering a table
  cancels any dealer beat left over, so it can never draw a card into the next round.

### 2026-10-14 (The Seat, phase 1: casino turn order and turn timer)
- feat: seats act in casino order — Maya and Jordan before you, Sam and Priya after you, then the dealer
  (new `RoundPhase.NpcsAfter`); your bust, surrender or natural no longer skips the seats on your left.
- feat: 20-second turn timer that stands your hand, with a gold countdown bar; fresh clock per split
  hand, none on tutorial hands, paused in the background or with the chat/menu open; Settings →
  At the table → Turn timer (on by default, saved as `turnTimerOn`). 5 new strings in all 10 languages.
- fix: leaving the table after your turn while the seats on your left are still playing now plays them
  and the dealer out and settles the bet, instead of leaving the round stranded.
- fix: every label on the felt keeps the 12-unit floor however far the felt scales down (`FloorScope`);
  a seat hides its bankroll while it shows STAND/BUST so the two no longer overlap. The design-rules
  baseline drops from 221 to 125 entries.
- test: the audit no longer treats a label's fallback-font sub-mesh or a hollow outline as an opaque
  cover, and ignores control outlines scrolled off screen; `TextFloor` re-reads its authored size
  safely and ignores mid-animation scales.

### 2026-10-14 (The Seat, phase 0: design rules)
- test: `RulesAudit` checks every screen, table state and dialog on four phone sizes for the design rules
  (12-unit text floor, 48×48 targets, 4.5:1 text and 3:1 outline contrast) against a shrinking
  `rules-baseline.txt`; `ScenarioShots` replaces the separate table/screen screenshot tests with one
  registry (`Scenarios.cs`) that adds the ten Seat states, the table menu, a toast and the sign-out dialog.
- feat: Seat design tokens (room, wood, leather, stitch, brass, ivory, felt print) and felt/panel-safe
  variants of the faint and loss colours; the type ramp (`Type.cs`) with `Ui.Text` overloads; Cinzel
  Bold for felt print; `TextFloor` for scaled labels; `Core/Contrast.cs`.
- fix: `Ui.Shrink` no longer shrinks a label below 12 units.

### 2026-10-14 (Flutter removed)
- chore: delete the Flutter app (`lib/`, `test/`, `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/`,
  `assets/`, `integration_test/`, `pubspec.*`) — the Unity build is now the only game. It stays in git
  history before this commit. Static hosting content (invite landing page, privacy policy, `assetlinks.json`,
  link-preview image) moved to `hosting/` and `firebase.json` serves it; the hosting workflow no longer builds
  Flutter. Entries below describe the Flutter app as it was.

### 2026-10-14
- feat: Unity port — Firebase: Auth (anonymous + Google via `FederatedOAuthProvider`), Firestore friends groups
  and leaderboards with the Flutter collections/fields, Analytics and Crashlytics, the install ping and error
  log. SDK is fetched by `Unity/tools/install_firebase.sh` and guarded by the `FIREBASE_SDK` define.
- chore: stop tracking `Unity/.utmp` (CMake/Gradle scratch that was committed by mistake) and ignore it.
- feat: Unity port — Hebrew and Arabic: Arabic letter shaping and a bidirectional reorderer in the tested Core,
  a text component that wraps and reorders per line, mirrored rows and alignment, and a full UI rebuild when the
  language changes. Labels shrink to fit instead of using ellipsis.
- feat: Unity port — Android build: `Blackjack.EditorTools.BuildTools.BuildAndroid` builds an IL2CPP ARM64 APK
  (`com.micorlov.blackjack21_v2`, 1.7.0 / versionCode 9, signed with the debug key so it upgrades the Flutter app
  in place) with the invite-link filter, vibration/notification permissions, notification icons and launcher
  icons; verified installing and playing a hand on an emulator.
- feat: Unity port — all screens built in code (onboarding, lobby, table with the tilted felt drawn by a shader,
  stats, friends, settings, legal pages, daily-bonus dialog, out-of-chips and how-to-play sheets, table chat,
  coach cards, confetti and chip flights) on a runtime UI toolkit; reviewed through offscreen PlayMode
  screenshots (`Unity/Assets/Tests/PlayMode`).
- feat: Unity port — the game controller (`Blackjack.Game`): paced NPC/dealer turns, voice and haptic cueing
  with the Flutter timings, daily bonus and play-streak reminders, rebuy, tutorial, referral rewards, the
  friends-group/sign-in flow behind an `ISocialService` seam, and a Flutter-compatible save blob. Runs on a
  fake clock in tests (124 EditMode tests). UI toolkit (runtime sprites, TextMeshPro fonts, builders) and a
  PlayMode screenshot harness added; screens come next.
- feat: Unity port — progression logic (daily bonus, play streak, points and ranking, rebuy, referrals,
  invite links, review prompt, table presence and seats, play-time tracker), the save record, spoken
  numbers and tutorial coach mapping are now in `Blackjack.Core` (105 tests); locale JSON converted from
  the ARB files and the sfx/voice clips and fonts copied into `Unity/Assets`.
- feat: start the Unity port in `Unity/` — the blackjack rules engine (shoe, comeback dealing, betting
  limits, insurance, split/double/surrender, opponent seats, dealer play, sweep-pot settlement) is now
  plain C# with 49 passing EditMode tests. The Flutter app is unchanged and remains the shipping build.

### 2026-10-03
- feat: **admin panel — Time Played column.** The Overview leaderboard and the Players tab
  (sortable) now show how long each player has spent in the game, e.g. `4h 12m` or `3d 5h`. The
  app counts foreground time with a monotonic clock (`lib/utils/play_time.dart`, so device clock
  changes and screen-off sleep never count) and adds it to a new `leaderboard/{uid}.playSeconds`
  total as a server-side increment: folded into the existing score report (every action plus the
  60-second heartbeat, so no extra writes) and flushed on its own when the app is backgrounded —
  `AppLifecycleBridge` now treats `hidden` like `paused`, since a backgrounded web tab or desktop
  window never reaches `paused` and would otherwise keep counting.
  Counting starts with this release, so players who have not opened the new build yet show `—`,
  and a guest who reinstalls gets a new anonymous uid and starts again from zero.

### 2026-09-30
- feat: **admin panel — Analytics, Health, and Feature Toggles tabs.** `admin.html` gains three
  tabs matching the layout of the `video-poker-game` admin: new-players-per-week/month, app
  version × platform, country and chip-balance histograms (Analytics); fatal-error and
  cold-start-install breakdowns by version and platform (Health); remote on/off switches for the
  Play review prompt and referral chip rewards (Feature Toggles). Backed by three new Firestore
  surfaces the app now writes: `leaderboard/{uid}` gains `appVersion`/`platform`/`country` (every
  score report) and a one-time `createdAt` stamp (`SocialService.ensureCreatedAtStamped`, called
  once per cold start); `errors/{id}` and `installs/{id}` mirror fatal crashes and cold-start
  pings (`lib/services/error_reporter.dart`, wired into `main.dart`'s existing
  `FlutterError.onError`/`PlatformDispatcher.onError` handlers — Crashlytics has no
  client-readable API, so this is the admin panel's only view into what's breaking in the field);
  `config/features` holds the toggles themselves (`lib/services/feature_flags.dart`, read once at
  boot after the anonymous sign-in completes — the rules require a signed-in reader — and fails
  open so a missing doc or offline read never silently disables a feature). The install ping
  likewise waits for the first signed-in auth state; web and emulator runs on 2026-10-01 caught
  both racing sign-in and getting `permission-denied` before this ordering was added. New
  Firestore rules restrict `config/features` writes and `errors`/`installs` reads to the admin
  account, while any signed-in client may write the latter two (append-only, no update/delete).

### 2026-09-29
- fix: **the Play Store showed the old app icon in every language except English.** Play stores
  the listing icon and feature graphic per locale, and the September 18 upload named only
  `en-US`, so the Hebrew listing (and the eight other locales) kept serving the previous
  artwork in Play search. `tool/play_images.py` gained `--all-languages`, and the current icon
  and feature graphic were pushed to all ten locales.

### 2026-09-18
- feat: **new app icon — blonde dealer with A♦ K♠ in a casino hall.** The photoreal artwork was
  cropped to a 1194×1194 square and dropped in as `play-assets/src/icon-master.png` (composed
  master convention, used edge to edge); `tool/make_icons.py` regenerated every Android launcher
  bitmap and adaptive layer, the iOS/macOS sets, the web favicon/PWA icons and the 512 Play icon.
  The Play Store listing icon was replaced through `tool/play_images.py --only icon` (edit
  committed to the en-US listing); the in-app launcher icon ships with the next release build.

### 2026-09-12 — Big Cards activation follow-up
- feat: Make native Play now enter the coached beginner table without sign-in or spending chips.
- feat: Translate core table controls, outcomes and coaching/rules across all ten existing locales.
- fix: Replace permanent review lockout with persisted attempt/outcome cooldowns and a request cap.
- feat: Track activation milestones and provide a tested export-based funnel and day-one report.
- chore: Stage three English 1080×1920 screenshots separately from the live naming change.
- test: Cover review migration/retry/cancellation, first-session entry and multilingual small-screen layouts.
- chore: Use a null-aware membership-map entry to satisfy the current analyzer without changing behavior.

### 2026-09-12
- feat: **admin Players tab — Group Code + UID columns** — Players table now also fetches the
  `players` collection and joins it so each row shows the player's active group code and Firebase
  UID alongside the existing chips/hourly/daily/last-active/period-key columns.

### 2026-09-11 (3)
- feat: **admin Players tab — Last active date filter** — dropdown lets admin filter players by
  last-active window: 7 days, 30 days, 3 months (default), or All time. Leaderboard fetch limit
  raised from 500 → 2000 so older players are included in the result set.

### 2026-09-11 (2)
- chore: **Admin Center deployed to GitHub Pages** — `deploy-admin.yml` publishes `admin.html`
  (as `index.html`) and `push-admin.html` to the `gh-pages` branch under `/admin/` on every push
  to `main` that touches either file. Admin pages are kept entirely separate from the Flutter web
  app and its service worker. URLs: `https://micorlov.github.io/blackjack21_v2/admin/` and
  `.../admin/push-admin.html`.

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
  `AndroidManifest.xml`, verified via the new `hosting/.well-known/assetlinks.json`), or the playable
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
