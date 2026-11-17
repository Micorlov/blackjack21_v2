# Blackjack 21 — 1.8.6 (vc18): Trio and Heads-Up rooms

Branch `feat/1.8.6-consent`, local commit only (nothing pushed, merged, uploaded or installed on the phone). Version unchanged (1.8.6 / vc18). QA-only files (`QaOverrides.cs`, `QaCleartextManifest.cs`, `.meta`) not committed; the keystore path rewrite in `ProjectSettings.asset` was reverted.

## What changed
- **Trio Table** (`trio`): $50-$1,000, you + 2 opponents (Maya, Jordan), sweep pot on. **Heads-Up** (`headsup`): $100-$2,000, you vs the dealer, no seats, no sweep pot.
- Placement: listed after Bronze/Silver/VIP (existing order, stakes and keys untouched). No unlocks exist in the catalog, so both are open from the start. `TableRecommendation` walks only the classic ladder (`TableCatalog.IsClassic`), so the lobby never recommends the new rooms over Bronze.
- `TableStake` gains `Opponents` (default 4) and `SweepPot` (default true). `RoundEngine.RollNpcSeats`/`FreshRound`, `Roster.TableSeats` (via `TableCatalog.OpponentsFor`), `TablePot.Live` and `Settlement` use them. Heads-up: no seats are dealt, the hero acts first and only, then the dealer; no pot is pooled, quoted or announced.
- Act order is unchanged: every opponent seat plays in `Npcs`, then the hero, then the dealer (trio: both NPCs first; heads-up: vacuous).
- Felt: `FeltMetrics.SeatSlot(index, seatCount)` / `CurveIndex`: two seats take first and third base (level, centred about the hero); four seats are identical to before. Heads-up hides the pot pill, the turn-order row and the "Playing with practice bots" line. The spoken pot call-out is skipped heads-up.
- Localization (en, de, es, fr, pt, ru, zh, ja, ar, he, all translated, no English placeholders): `gameTrioTable`, `gameHeadsUpTable`, `lobbyTrioNote`, `lobbyHeadsUpNote`, `guideRoomsTitle`, `guideRoomsBody` (a new "Table types" How-to-play section). Lobby cards show a one-line note per new room.
- Review prompt, 8 PM gift, ad pacing and stats do not depend on seat count; `IsBigWin` handles `SweepInfo == null` (a heads-up blackjack or 5x win still asks; a trio sweep asks).
- `firestore.rules`: `tableKey` allows `trio`/`headsup`. **Not deployed.** Until it is, the client reports table presence only for the classic rooms (otherwise the write would be refused and drop the score).

## Files
Core: `Models.cs`, `TableCatalog.cs`, `RoundEngine.cs`, `TablePot.cs`, `Settlement.cs`, `Friend.cs`, `Progression.cs`, `FeltMetrics.cs`, `Tutorial.cs`. Game: `GameController.Audio.cs`, `GameController.Social.cs`, `LobbyScreen.cs`, `FeltView.cs`, `SeatView.cs`, `TableCalc.cs`, `TablePanels.cs`, `TableScreen.cs`. Locales (10 json), `firestore.rules`, `README.md`, new `Tests/EditMode/RoomTests.cs`, this report.

## Tests
EditMode, full suite: **266/266 passed** (22 new in `RoomTests.cs`: catalog/stakes/ids, classic rooms unchanged and recommendation, seat counts, heads-up no pot/insurance/natural, trio act order and sweep, felt slots, controller flows, gift/ad/review hooks). Log `/tmp/bj186-rooms-edit.log`. PlayMode RulesAudit not run.

## Artifacts
- Release AAB (upload key, `jarsigner -verify`: verified): `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18.aab` (also `blackjack21-unity.aab`).
- Debug test-ads APK: `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18-debug-testads.apk`. 1.8.5 files kept.

## Emulator (emulator-5554, debug APK via `adb install -r`)
Screenshots in `/Users/micorlov/grokshots/`: `bj186_rooms_lobby.png` (all five rooms), `bj186_rooms_headsup.png` (hero + dealer only, no pot pill), `bj186_rooms_headsup_end.png` (win +$100, no pot line), `bj186_rooms_headsup_final.png` (rebuilt APK, practice-bots line gone), `bj186_rooms_trio_bet.png`, `bj186_rooms_3seat_npcs.png` (Maya playing, order row Maya, Jordan, You), `bj186_rooms_3seat_hero_turn.png`, `bj186_rooms_3seat.png` (result with the "No sweep $0" pot pill). No crash.

## Caveats
- The trio pot pill appears with a value only once a seat forfeits; I did not hit an actual sweep on the emulator (covered by unit/controller tests).
- Heads-up: the felt is empty of seats by design; it looks sparse but is not broken. No spacing re-tuning was done.
- The guest tutorial coach text still mentions the sweep pot if a new player opens Heads-Up during the coached hands.
- The lobby "friends here" presence is not shown for the new rooms until the Firestore rules are deployed.
- Firestore rules test file not extended or run (needs the emulator).
