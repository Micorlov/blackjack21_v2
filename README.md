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
  leaderboard, and table seats (guests get anonymous Firebase accounts, so no sign-in is required)
- **Always-visible rank strip** — a ticker above every screen, including the table, showing your
  live position vs your friends' hourly or daily points and who you're chasing (tap to flip
  hourly ↔ daily)
- **Hourly & daily points** — net chips won roll into real per-hour and per-day buckets that reset
  on the clock and sync to the group after every hand and once a minute
- **Overtake alerts** — when a friend's score passes yours, you get an in-app toast plus a local
  notification ("Maya just passed you on the hourly leaderboard"). Honors the Settings →
  leaderboard-notifications toggle. These are local notifications (app running); remote push
  needs an APNs entitlement a free personal Apple team cannot sign
- **Comeback dealing** — short-stacked or on a two-loss streak, your opening hand is the best of
  3 candidate pairs from the real shoe instead of one blind draw, so sessions last longer
- **Social table** — friends, lobby, chat panel, leaderboard, seat plates with avatars
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

## Getting Started

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── data/          # static game data
├── models/        # enums, game_state, hand, playing_card, social_models, table_pot
├── screens/       # lobby, table, friends, settings, shop, stats, onboarding
│   └── table/     # table sub-panels (felt, betting, action, chat, settlement, …)
├── services/      # sound_player, spoken_amount, social_service (Firestore), local_notifier
├── state/         # game_notifier (Riverpod)
├── theme/         # app_colors, app_text_styles
├── utils/         # formatters, leaderboard, points (hourly/daily buckets), comeback
└── widgets/       # shared UI (buttons, overlays, cards, nav bar, rank_strip)
```

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management (`game_notifier`) |
| `google_fonts` | Typography |
| `audioplayers` | Sound effect playback |
| `cupertino_icons` | iOS-style icons |
| `firebase_core` / `firebase_auth` | Firebase app + Google/anonymous sign-in |
| `google_sign_in` | Google account picker for sign-in |
| `cloud_firestore` | Friends groups and live hourly/daily score sync |
| `url_launcher` | Opens WhatsApp with the prefilled group invite |
| `flutter_local_notifications` | "Friend passed you" leaderboard alerts |

Dev: `flutter_test`, `flutter_lints`, `integration_test`.

## Assets

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

## Changelog

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
