# Blackjack 21: bugs found in simulator play

**Session:** 2026-10-14, about 23:06 to 23:14 (local). Exploratory play of the three coached hands at the Bronze Table, then checks of the lobby, Settings, relaunch, and orientation.

**Device:** Android emulator `blackjack-qa`, a new AVD (Pixel 7 profile, Android 16, google_apis, arm64, 1080×2340). The physical phone was not connected. The other running emulators (`dirtbike-play`, `showdown-e2e`) were not touched.

**Build:** `Unity/Builds/Android/blackjack21-unity.apk`, a development build signed with the debug key. It was built 23:02 to 23:04 from the working tree on top of `d300b67`, so it includes the uncommitted changes in CLAUDE.md, README.md, DealerView.cs, RulesAudit.cs, and Scenarios.cs.

**Network:** offline (Wi-Fi off, no active network). The build talks to the production Firebase project, so online features were not tested. See BUG-10.

**Evidence:** `e2e-artifacts/` (screenshots, `videos/bj-2.mp4` and `bj-3.mp4`, `logs/logcat.txt`). The folder is gitignored.

## Summary

| ID | Severity | Where | Bug |
|---|---|---|---|
| BUG-01 | High | Settlement | A bot seat's push is forfeited to the sweep pot |
| BUG-02 | Low, decision needed | Payouts | 3:2 and surrender round cents down |
| BUG-03 | Medium | Result sheet | The tutorial card is drawn over seat nameplates |
| BUG-04 | Low | Result sheet | The "YOU TAKE" pill doesn't match the net on the sheet |
| BUG-05 | Low | Result sheet | A "Push" lesson is shown under a loss |
| BUG-06 | Decision needed | Sweep pot | The dealer is named as taking the pot when every seat loses |
| BUG-07 | Low | Table | Nameplates sit on a neighboring seat's cards |
| BUG-08 | Low | Table | "Dealer stands on all 17s" touches the total pill |
| BUG-09 | Unconfirmed | Table | "Jordan bust" is shown with no cards |
| BUG-10 | Note | Build config | The dev build uses the production Firebase project |
| BUG-11 | Low | Launch, offline | An offline first run gives no feedback |

## BUG-01: High. A bot's push is forfeited to the sweep pot

- **Where:** Bronze Table, coached hand 3. Evidence: `e2e-artifacts/screenshots/14-hand3-progress.png`, zoom `e2e-artifacts/screenshots/14-zoom-maya-push.png`.
- **Steps:** Bet $25, then DEAL. The hero has blackjack and is not asked to act. The dealer stands on 18 (10♥ 8♥). Maya stands on 18 (3♣ 8♣ 7♦).
- **Expected:** An equal total is a push, so Maya's bet returns and her net is $0. The coaching text in hand 2 says the same: "An equal total is a push: your bet returns."
- **Actual:** Maya's seat reads "18 −$50". Her $50 counts as a forfeit, so it is part of the "+$175" sweep pot.
- **Impact:** A bot loses a bet it should keep, and the sweep pot the hero collects is overstated by $50.

## BUG-02: Low, decision needed. Cents are rounded down

- A $25 blackjack shows "Hand vs dealer +$37". The 3:2 payout is $37.50. Evidence: `e2e-artifacts/screenshots/07-settle-wait.png`.
- Surrender on $25 shows "keep $12". Half of $25 is $12.50. Evidence: `e2e-artifacts/screenshots/09-hand2-dealt.png`.
- Each rounding costs the player $0.50. The README doesn't say whether whole-chip rounding is intended.

## BUG-03: Medium. The tutorial card is drawn over the seat nameplates

- On the result sheet the coaching card sits on top of the seats. Its text runs across the "Sam" and "Jordan" nameplates and over the hero's cards. This happens after every hand. Evidence: `07-settle-wait.png`, `12-settlement-hand2.png`, `14-hand3-progress.png`.
- **Expected:** The card is hidden or moved while the result sheet is open, and the nameplates stay readable.

## BUG-04: Low. The "YOU TAKE" pill doesn't match the net on the sheet

- Hand 1: the pill says "YOU TAKE $75" and the sheet says "+$87" (`07-settle-wait.png`).
- Hand 3: the pill says "YOU TAKE $200" and the sheet says "+$212" (`14-hand3-progress.png`).
- The pill is the bet returned plus the pot. The 3:2 winnings are left out, and nothing says so.

## BUG-05: Low. A "Push" lesson is shown under a loss

- Hand 2 was the hero's 18 against the dealer's 21. The sheet says "Dealer wins −$25" and "18 lost". The coaching card is titled "Push" and says "An equal total is a push: your bet returns." Evidence: `12-settlement-hand2.png`.
- **Expected:** The card explains this result, or the lesson isn't presented as the result.

## BUG-06: Decision needed. The dealer is named as taking the pot when every seat loses

- Hand 2: the four bots and the hero all lost to the dealer's 21. The pill reads "DEALER TAKES $100" (`12-settlement-hand2.png`). During the dealer's turn it read "Sweep pot $100" (`11-after-stand.png`).
- The README says every settled hand "names who took the pot, or says there was none." This names the dealer instead.
- The hero's own $25 loss is not in the $100 pill. It only appears as "Hand vs dealer −$25". Decide whether the dealer should take the pot or the copy should say "none", and whether the hero's loss belongs in the pot.

## BUG-07: Low. Nameplates sit on a neighboring seat's cards

- "Sam 20" sits on the lower edge of Priya's 9♠ 8♥. "Jordan 18 stand" sits on Maya's cards. It isn't clear which hand each plate labels. Evidence: `10-after-hit.png`, `11-after-stand.png`. Not checked at pixel level.

## BUG-08: Low. The status line touches the total pill

- "Dealer stands on all 17s" sits directly on the "18 hard" pill with no gap. Evidence: `10-after-hit.png`. Not checked at pixel level.

## BUG-09: Unconfirmed. "Jordan bust" is shown with no cards

- During hand 3 the top pill read "Jordan is playing", the label read "Jordan bust", and Jordan's seat showed no cards. Evidence: `13-hand3-dealt.png`. It may be a transition frame. Check `videos/bj-2.mp4` around 23:11.

## BUG-10: Note. The development build talks to the production Firebase project

- Logcat shows "Using Auth Prod for testing." and an anonymous sign-in attempt at launch (`logs/logcat.txt`, 23:06:38 to 23:06:39).
- Offline, the attempt failed, so no account was created. Online, every fresh install creates an anonymous account in `blackjack21-v2` and writes friends, leaderboard, and analytics data there. Test runs therefore leave production data behind. Consider a development Firebase project for test builds.

## BUG-11: Low. An offline first run gives no feedback

- With no network, the sign-in fails in the background and the title screen shows nothing. "Play now" still opens the Bronze Table, about 20 seconds later. Evidence: `03-after-play-now.png` (still the title screen), `04-play-now-wait.png` (the table).
- **Expected:** A short "You're offline" message, or a visible wait.

## Checked, no bug found

- Natural blackjack: the hero is not asked to act, the 3:2 payout applies, and the blackjack takes the sweep pot (hand 1).
- Dealer rule: 10 + hidden 6 = 16, draws a 5 for 21, and stands. The on-screen text matches.
- Actions: SPLIT is disabled for a non-pair. DOUBLE and SURRENDER are disabled after the first two cards. SURRENDER shows its refund amount.
- Chip limit: the $500 chip is dimmed at a $25 bet, since it would exceed the $500 maximum.
- Balances: 1,000, then 975 after the bet, 1,087 after hand 1, 1,062 after hand 2, 1,037 after the bet on hand 3, and 1,274 after hand 3.
- Progress: after a force-stop and relaunch, the balance was still $1,274 and the app returned to the lobby.
- Orientation: forcing landscape on the Settings screen kept the screen in portrait. This was not checked on the table.
- Crashes: no crash or ANR for the game appears in the device log.

## Not tested

- Online features: friends and invites, leaderboard, referrals, and daily-bonus sync. Google sign-in was not attempted because it would use a real account.
- Stats tab, table ⋮ menu and chat, the 20-second turn timer, tutorial skip and replay, rebuy, the Silver and VIP tables, language switching, and audio. Audio was checked only in logcat, not by ear.

## Environment notes (not app bugs)

- `android.hardware.audio ... pcm_writei failed` lines come from the emulator's host audio backend.
- `logs/logcat.txt` stops writing at about 23:08. Later checks used the device log buffer.
- `videos/` has no `bj-1.mp4`, so the first recording segment was not saved.
