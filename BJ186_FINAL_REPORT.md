# Blackjack 21 — 1.8.6 (versionCode 18) final report

Branch `feat/1.8.6-consent`. Nothing pushed, merged or installed on a phone. **Play upload and en-US listing update did NOT happen** (no service-account key on this Mac, see below).

## Commits
- `5aff758` feat: disclosed Comeback Boost, rotating 8 PM reminder, more ads, Settings translations
- (this report) docs: 1.8.6 final report

## What changed
- **Comeback Boost**: Settings switch, on by default, persisted (`comebackOn`; old saves stay on), one-line explanation, How to play section. Off = straight deal (`Comeback.TriesFor(..., enabled)` returns 1). README no longer calls it hidden.
- **Ads (exact numbers)**: between-hands interstitial needs **3 hands AND 90 s** since the last (was 5 hands / 4 min), only after Next Hand, 1 s delay + input block unchanged, never in the tutorial, never on open/exit. Rewarded: **500 chips, 30 min cooldown, 5 per local day** (was 1 h, no cap), via a lobby card "Watch an ad for free chips", the Out of chips sheet, and a dismissible low-chips offer (stack under **3 minimum bets**, once per dip, never together with an interstitial). Banner: the existing single adaptive banner under the nav on every screen; layout reserves its height so it covers nothing. UMP, Teen treatment, test vs real units untouched. Constants live in `AdPacing` / `AdReward` (Core/Progression.cs).
- **8 PM reminder**: 5 title/body variants chosen by local date (`EveningGift.VariantFor`), one per day, next 7 days scheduled (non-repeating; re-armed on launch/resume/language change). +$500 once-per-date grant unchanged. Titles:
  1. Your free $500 chips are waiting! 2. The dealer is on a losing streak 3. The sweep pot is up for grabs 4. Keep your streak alive 5. The table is open. All localized in 10 languages, play-money wording only.
- **Translations**: whole Settings screen (Privacy, Usage & crash reports, Privacy choices, Account ID, Delete account), stale Daily reminder sublabel, daily-bonus/streak notifications, chip-gift/out-of-chips/lobby/nav/toast strings, Comeback and rewarded copy: de es fr pt ru zh ja ar he. All locales have every English key. Still English-only (not Settings): Stats, Friends, table-chat labels, friend-alert notifications.
- **Friends presence**: now reported for every room incl. Trio and Heads-Up.
- Files: Core (Shoe, RoundState, RoundEngine, EveningGift, Progression, SavedGame, Tutorial), Game (AppState, GameController*, SavedGameJson, UnityNotifier, AppRoot, Dialogs, LobbyScreen, SettingsScreen), 10 locale JSONs, `BoostAdsRotationTests.cs`, `firestore-tests/rules.test.cjs`, `tool/play_listing.py`, `tool/listing_en-US.json`, `tool/release_notes_en-US.txt`, README.

## Tests
- EditMode: **285/285 passed** (`/tmp/bj186-final-edit.log`, results `/tmp/unity-results-2.xml`); new tests cover Comeback on/off/default/persistence, ad constants, between-hands-only, rewarded cap and day reset, low-chips offer, no-ads/no-consent, reminder rotation, locale coverage.
- Firestore rules: **42/42 passed** on the emulator (firebase-tools 14.27, Java 17), including new trio/headsup test.
- Firestore deploy: `firebase deploy --only firestore:rules --project blackjack21-v2` succeeded (rules released to cloud.firestore).

## Builds (version 1.8.6 / versionCode 18, kept)
- `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18.aab` (and `blackjack21-unity.aab`), signed with the upload key, `jarsigner -verify`: jar verified. No QA, test-ads or emulator defines in the release log.
- `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18-debug-testads.apk`.
- 1.8.5 artifacts preserved. `ProjectSettings.asset` keystore change reverted, not committed.
- vc18 on Play is **unverified**: the Play API could not be queried. The repo shows 1.8.5 as the last upload and 1.8.6 never uploaded.

## Emulator (emulator-5554, new debug APK installed with -r)
Screenshots in /Users/micorlov/grokshots/: `bj186_final_settings_en.png` (Comeback Boost on + Daily reminder 8 PM text), `bj186_final_settings_he.png` (Hebrew Comeback and toggles), `bj186_final_lobby_banner.png` (banner under nav), `bj186_final_rewarded.png` (Hebrew lobby "watch an ad" card, +500, 5 left today), `bj186_final_hand.png` (a Bronze hand dealt). Not exercised on-device: the low-chips sheet and the notification itself (covered by unit tests).

## Play upload and listing
- **Blocked**: `~/.config/play/key.json` does not exist and a Mac-wide search found no `play-service-account*.json` or file naming play-publisher@gen-lang-client-0324046629. I did not fall back to the Console, did not create a new key, and did not upload. AAB is ready at the path above. To finish: put the key at `~/.config/play/key.json`, then run
  `python3 tool/play_upload.py --aab Unity/Builds/Android/blackjack21-unity-1.8.6-vc18.aab --track production --status completed --release-name "1.8.6 (18)" --notes-file tool/release_notes_en-US.txt --key ~/.config/play/key.json --package com.micorlov.blackjack21_v2`
  and `python3 tool/play_listing.py --key ~/.config/play/key.json`. If Play says versionCode 18 exists, bump to 1.8.7/19 and rebuild.
- Release notes (418 chars) are written in `tool/release_notes_en-US.txt`.

### Proposed en-US listing (NOT applied; texts in `tool/listing_en-US.json`)
**Title (22):** Blackjack 21 Big Cards

**Short description (77):** Free blackjack 21 with big, easy-to-read cards. Play offline, no wifi needed.

**Full description (2195):**

Blackjack 21 Big Cards is a free card game built for easy reading: large cards, clear numbers and a calm green felt table. Play blackjack (21) anywhere, even offline with no wifi, and keep your free chips.

PLAY MONEY ONLY. This game uses free in-game chips. There is no real-money gambling, no cash out and no prizes of real-world value.

CHOOSE YOUR ROOM
• Bronze, Silver and VIP tables with four other players and a sweep pot to win
• NEW: Trio, you and two players at the table
• NEW: Heads-Up, a 1v1 duel against the dealer with no sweep pot

BIG CARDS, EASY TO READ
• Large cards and clear totals, comfortable on any phone
• Hit, stand, double down, split, insurance and surrender
• A short coached tutorial for your first hands, plus a How to play guide any time

FREE CHIPS
• A daily bonus that grows with your play streak
• NEW: a daily 8 PM chip gift, with a friendly reminder (you can turn it off in Settings)
• Optional: watch a short ad for extra chips whenever you choose
• Invite friends and you both get chips

HOW THE TABLE WORKS
• NEW: you act last among the players, just before the dealer, like at a real table
• Spoken call-outs for your total and the result, in your language
• A turn timer keeps the game moving (you can turn it off)

OPTIONAL COMEBACK BOOST
If you are on a losing streak or low on chips, the game may deal you a stronger starting hand. It is shown openly in Settings and in How to play, it is on by default, and you can switch it off any time for a straight deal from the shuffled deck.

PLAY WITH FRIENDS
Create a friends group, share your link and race on the hourly and daily leaderboards. Sign in with Google to keep your name and progress.

YOUR CHOICES
The game has ads between hands and a banner. Where required (the EU, UK and Switzerland) you are asked for your consent, and you can change it later under Settings > Privacy choices. You can also delete your account and data from Settings.

LANGUAGES
English, Deutsch, Español, Français, Português, Русский, 中文, 日本語, العربية and עברית.

Download Blackjack 21 Big Cards and take a seat. 21 is waiting. For ages 13 and over. Free chips are for entertainment only and cannot be exchanged for money.

"Offline / no wifi" is claimed because hands, bots and saves run locally (README records an offline-launch check); ads and online features need a network.

## Caveats
- Interstitials now take effect only for players with ads loaded; real-unit fill and revenue are unmeasured.
- Reminders: only 7 days ahead; a player away longer stops getting them until the next launch.
- The emulator is shared with another app (Video Poker was in front at first); I only launched Blackjack.
