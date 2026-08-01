# Feature Plan — blackjack21_v2

*Written 2026-08-02. A prioritized roadmap for making the app better and adding new features.*

## How this plan was made

Five product lenses (retention, social, gameplay, polish, technical health) each proposed
features grounded in the actual codebase — 30 proposals in total. Three independent judges
then scored every proposal 1–10 on:

- **Player value** — would a small group of real-life friends actually feel it?
- **Feasibility** — buildable solo, in this codebase, under the hard constraints
  (free personal Apple team → no remote push, Firebase free tier, no server)?
- **Product fit** — does it strengthen the app's identity: a live hourly/daily points
  race between WhatsApp friends, with a signature sweep-pot and a spoken, audio-rich table?

The phases below order the survivors so that each phase makes the next one more valuable.
The full scored ranking is in the appendix.

## Where the app stands

The social pivot shipped: groups over WhatsApp codes, live rank strip, overtake alerts,
friends' points at the table. But three cracks run under it:

1. **Nothing persists.** Chips reset to $1,000, stats zero out, and all achievements
   re-lock on every launch. Friends watch everyone's stack snap back constantly — the
   race's own currency evaporates.
2. **Some social surfaces are fake.** Table chat "friends", the Stories rail, the
   "friends here" table labels, and the Weekend Cup card are hardcoded fiction, which
   teaches users the real social features are fake too.
3. **Friends can't install the app.** A free personal Apple team means only Michael's
   phone runs it, and each build dies after 7 days.

The plan attacks these in order: make the game remember, make the race real, then amplify
the signature moments.

## The one decision that matters most

**Apple Developer Program ($99/year).** Not a code change — a decision. It unlocks
TestFlight (friends can actually install the app: the entire premise of the social pivot)
and the APNs entitlement (real push for overtake alerts, which the README explicitly names
as blocked). Every social feature below multiplies in value once friends are genuinely on
the app. Until then, the plan stays fully inside the free-team constraints.

---

## Phase 0 — Finish what's in flight

**Daily bonus** (uncommitted in the working tree): once-per-24h free-chips claim with a
scheduled local reminder. The pure timing logic in `lib/utils/daily_bonus.dart` is already
covered by 11 tests in `test/daily_bonus_test.dart`. Finish the lobby claim UI, update the
README, and ship it.

## Phase 1 — Foundation: the game must remember

*Everything else in this plan is fiction until a restart stops deleting the player's world.*

1. **Persist chips, stats, and settings across launches** — avg score 8.3, the #1 item.
   Generalize the `DailyBonusStore` SharedPreferences pattern into a `GameStore`: bankroll,
   all-time stats and history, hourly/daily point buckets with their keys, and the
   sound/haptics/notification toggles. Debounced writes after `_settle()` and settings
   changes; hydrate before `_initSocial()` publishes the first leaderboard row. Surface the
   existing `resetBankroll` as a "Rebuy" card so a player persisted below every table
   minimum is never soft-locked. Follow-on (optional): one-time chip rewards for the
   already-defined `kAchievementDefs`, which persistence finally makes reachable.

2. **Crash and error reporting** — Firebase is already integrated, so Crashlytics is one
   dependency plus `FlutterError.onError` / `PlatformDispatcher.onError` handlers (neither
   exists today). Convert the debugPrint-and-swallow sites in `SocialService` into recorded
   non-fatals. The moment friends play, their failures are invisible; this is the cheapest
   infrastructure win in the repo and a prerequisite for safely tightening Firestore rules
   later.

## Phase 2 — Make the race real

*Replace every fake social signal with a true one; give the race finish lines.*

3. **Real table presence — "Maya is at the Silver table right now"** (8.3, effort S).
   Write a `tableKey` field on the player's existing group row (piggybacking on
   `reportScore`, masked by the same 5-minute freshness window as the online dot). Lobby
   cards show real friend counts and avatars with a "Join Maya" tap. Replaces the hardcoded
   friends-here label. Simultaneous play is the multiplier for every other live feature —
   this is the cheapest way to get it.

4. **Real cross-device chat and taunt reactions** (7.7). The chat panel, reaction chips,
   float overlay, and settings toggle are all built and merely disconnected. Sync canned
   `kReactions` through a capped `groups/{code}/chat` subcollection (limit-20 stream),
   float a friend's reaction over their seat plate, and delete the fake message generator
   and hardcoded speaker names. Canned-only keeps abuse and moderation off the table.

5. **Hour and day champions — crowns with a champions ledger** (7.3). Today `rolledPoints`
   zeroes the bucket and an hour of grinding produces nothing. On rollover, any client
   derives the finished period's winner from rows it already holds and writes an idempotent
   `groups/{code}/results/{periodKey}` doc (create-only rule; all clients derive identical
   content). Crown counts on seat plates and the friends list become the meta-race.
   Winner-picking stays in pure `points.dart` functions, unit-tested.

6. **Make the Weekend Cup real** (7.0). `joinTournament()` currently flips a bool and the
   card shows hardcoded numbers. Entrants join `groups/{code}/cups/{weekendKey}`, a
   `weekend` points bucket reuses the tested `rolledPoints` key pattern, and scheduled local
   notifications ("Cup starts now", "Final hours — you're 2nd") fire even with the app
   closed, exactly like the daily-bonus reminder. Group-scoped, not global: it races the
   friends, not the world.

## Phase 3 — Amplify the signature moments

7. **Rolling sweep-pot jackpot — "Nobody swept, the pot rides"** (8.0). When no one sweeps,
   the forfeited chips roll into a carryover added to the next hand's pot, with a JACKPOT
   pill treatment and the existing spoken-pot pipeline reading the bigger figure aloud.
   Converts the sweep-pot's only dead outcome into anticipation. Cap the carryover
   (~10× table min) and settle the exit-table rule explicitly.

8. **Sweep-pot celebration: chip-flight, confetti, haptic drum roll** (7.7). The audio side
   of a sweep is fully built; the felt visually does nothing. Fly each losing seat's chips
   to the hero plate, burst confetti timed to `pot_celebration.wav`'s downbeat (the timing
   is already deterministic in `game_notifier.dart`), and choreograph haptics. Pin clip
   durations in `sfx_assets_test.dart` so a re-recorded clip can't desync the visuals.

9. **Quick juice wins** (all effort S):
   - **Rolling count-up** for the chip balance and settlement net figure with rate-capped
     haptic ticks (6.7) — best juice-per-line ratio on the list, a self-contained widget.
   - **All-in moments** (6.7) — an ALL IN button (fixes real many-tap friction) plus a
     hushed reveal, heartbeat haptics, and a "DOUBLE OR NOTHING" banner when at least half
     the stack is riding.
   - **Speak the settlement amount** (6.7) — "You win, two hundred fifty dollars" through
     the existing number-clip stitcher. Reserve it for big wins and sweeps so it stays
     special instead of turning repetitive.

## Phase 4 — The daily habit layer

*Only meaningful after Phase 1 persistence.*

10. **Daily-bonus claim streak** (S). Escalating chips for consecutive-day claims
    (250 → 1000, capped at day 7+), a 48h grace window, and a streak-saver notification
    ("Your 4-day streak ends tonight"). Near-pure reuse of the just-built daily-bonus
    plumbing; unit-test the window edges the way `points.dart` is tested.

11. **Real friend moments feed** (6.3). Replace the hardcoded Stories rail with real events
    (blackjack, sweep, crown) written from `_settle()` into a capped `moments`
    subcollection, with a working "Send GG". Lets friends who play at different hours stay
    in each other's race. Requires a `StoryDef` data-model refactor, not just a data swap.

12. **Daily missions** (5.7, optional). Three rotating challenges seeded from `dayKeyOf` —
    judges flagged this as generic solo filler, so ship it only if the group asks for more
    to do.

## Phase 5 — Hardening and growth

13. **Hebrew WhatsApp invite first, then scoped localization** (6.3). The friends are
    Hebrew speakers and the invite is the app's only growth loop, yet it's in English.
    Localize the invite text alone first (tiny, immediate conversion win), then overtake
    toasts/notifications, then the Friends and Settings screens with RTL — keeping the felt
    explicitly LTR, since card and seat geometry are positional. Hebrew number voice
    (macOS `say`, Carmit) is a separate later phase needing a grammar-aware word picker.

14. **Firestore rules hardening + write diet** (6.0). Rules currently validate nothing —
    any anonymous guest can write arbitrary leaderboard docs. Add schema and bounds
    validation, and cut the idle heartbeat's ~120 writes/hour/player (skip unchanged rows,
    stretch the idle heartbeat to 2 minutes — still inside the 5-minute online window).
    Deploy rules and client together, after crash reporting exists to surface rejections.

15. **App identity cleanup** (the free-team subset of the App Store pack). Real app icon,
    proper display name, pubspec description, version discipline, `PrivacyInfo.xcprivacy`.
    The TestFlight and APNs half waits on the Apple Developer decision above.

## Deliberately not planned

The judges scored these low on product fit — they pull toward "another blackjack sim"
instead of the friends race: Perfect Pairs / 21+3 side bets (fit 3), basic-strategy coach
(fit 4), shoe heat meter (fit 3), per-table dealer personalities (fit 4), milestone
cosmetics (fit 4), and golden tests for the table UI (fit 3 — the existing integration
screenshot test already covers that need).

## Appendix — full scored ranking

| Avg | Feature | Impact | Effort | Value | Feas. | Fit |
|-----|---------|--------|--------|-------|-------|-----|
| 8.3 | Persist chips/stats/settings across launches | 5 | M | 9 | 8 | 8 |
| 8.3 | Real table presence ("Maya is at the Silver table") | 4 | S | 7 | 9 | 9 |
| 8.0 | Rolling sweep-pot jackpot ("the pot rides") | 5 | M | 7 | 8 | 9 |
| 7.7 | Real cross-device chat + taunt reactions | 5 | M | 7 | 7 | 9 |
| 7.7 | Persistent progression + achievement rewards | 5 | M | 9 | 8 | 6 |
| 7.7 | Sweep-pot celebration (chip-flight, confetti) | 5 | M | 7 | 7 | 9 |
| 7.3 | Hour/day champions with crowns ledger | 5 | M | 6 | 7 | 9 |
| 7.0 | Weekend Cup as real group tournament | 4 | M | 6 | 7 | 8 |
| 6.7 | Weekend Cup on global weekly leaderboard | 4 | L | 6 | 7 | 7 |
| 6.7 | Speak the settlement amount | 3 | S | 4 | 8 | 8 |
| 6.7 | Count-up chips/net figures + haptic ticks | 4 | S | 5 | 9 | 6 |
| 6.7 | All-in moments (button + presentation) | 3 | S | 6 | 8 | 6 |
| 6.3 | Real friend moments feed (replaces Stories) | 3 | M | 5 | 7 | 7 |
| 6.3 | Hot-streak celebrations + table bonuses | 3 | S | 5 | 9 | 5 |
| 6.3 | Daily-bonus claim streak | 5 | S | 5 | 9 | 5 |
| 6.3 | Hebrew localization + RTL (invite first) | 4 | L | 5 | 6 | 8 |
| 6.0 | Offline/lifecycle resilience for social layer | 3 | S | 4 | 8 | 6 |
| 6.0 | Firestore rules hardening + write diet | 4 | M | 3 | 8 | 7 |
| 6.0 | TestFlight / App Store readiness pack | 5 | M | 8 | 2 | 8 |
| 6.0 | Deal-in card animation + flying chip | 4 | M | 6 | 7 | 5 |
| 5.7 | Crash and error reporting (Crashlytics) | 4 | S | 3 | 8 | 6 |
| 5.7 | Head-to-head 30-minute duels | 4 | L | 4 | 6 | 7 |
| 5.7 | Daily missions (day-key seeded) | 4 | M | 5 | 8 | 4 |
| 5.7 | Perfect Pairs + 21+3 side bets | 4 | M | 6 | 8 | 3 |
| 5.3 | Turn spotlight + reduce-motion + Semantics | 3 | M | 4 | 8 | 4 |
| 5.3 | Basic-strategy coach + book-accuracy stat | 4 | M | 5 | 7 | 4 |
| 5.0 | Milestone-unlocked shop cosmetics | 3 | S | 3 | 8 | 4 |
| 4.7 | Shoe heat meter (count flavor) | 3 | S | 3 | 8 | 3 |
| 4.7 | Per-table rules + named dealer identity | 4 | M | 3 | 7 | 4 |
| 4.3 | Golden tests for table UI | 3 | M | 2 | 8 | 3 |

*Value = player-value judge, Feas. = feasibility judge, Fit = product-fit judge; Avg is
their mean. Impact (1–5) and Effort (S/M/L) are the proposing lens's own estimates.*
