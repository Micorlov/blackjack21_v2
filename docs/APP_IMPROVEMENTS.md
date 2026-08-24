# App Improvements

A quality and reliability roadmap for this app — distinct from [FEATURE_PLAN.md](../FEATURE_PLAN.md),
which is a scored list of candidate *features* to build next. This doc is about the quality of
what already exists: untested logic, silent failure paths, unfinished polish, and known
limitations that are documented but not resolved. Where an item overlaps with an open
FEATURE_PLAN.md item, it's linked rather than re-described.

## 1. Untested core logic (highest priority)

- **`lib/state/game_notifier.dart`** (1,506 lines) — the entire turn-flow/game-state engine: deal,
  hit/stand/double/split/surrender, dealer play, settlement, comeback dealing, tutorial gating,
  and every voice call-out. It has **no dedicated unit test file**. It's only exercised indirectly
  through `test/game_store_test.dart`, `test/points_test.dart`, and similar tests that each cover
  one narrow slice. A regression here is the costliest possible bug — it's money math and sweep-pot
  settlement — and the least likely to be caught by the existing suite.
  Recommend: follow the pattern already used for `utils/comeback.dart` and `models/table_pot.dart`
  (pure logic pulled out and unit-tested on its own) and add a `game_notifier_test.dart` that drives
  the notifier's public API — deal → act → settle — against a seeded/fake shoe.
- **`lib/services/social_service.dart`** (195 lines) — Firestore group sync, leaderboard publish,
  and presence. Also has no test file. Recommend a fake-Firestore-backed test for at least the pure
  transform logic (what gets written to Firestore per hand).

## 2. Swallowed errors / no crash visibility

`social_service.dart` has 6 sites that catch a Firestore/network failure and only `debugPrint` it
(lines 47, 50, 64, 88, 103, 146) — in a release build this means social sync can silently stop
working with zero signal to the player or the developer. This is the same gap as FEATURE_PLAN.md's
still-open Phase 1 item #2 (crash reporting / Crashlytics).

Recommend, short of full Crashlytics: surface a sync failure through the app's existing
local-notification or in-app toast path (already used for overtake alerts) so a broken sync isn't
silent.

## 3. App-identity gaps

iOS, macOS, and Windows still ship the stock Flutter logo instead of the branded "21 Sweet Pot"
mark. Already fully catalogued in [docs/APP_ICONS.md](APP_ICONS.md) — see that doc for the full
per-platform breakdown; not repeated here.

## 4. Documented-but-unresolved known limitations

Pulled forward from the README changelog, which already explains each in full:

- **Felt doesn't scale with the web viewport zoom.** On narrow web viewports the felt (seat plates,
  dealer, hero hand) stays at its native design size while the rest of the app zooms — see the
  README's 2026-08-03 (7) entry for why the obvious fix (widening the seat slots) makes it worse,
  not better.
- **No remote push notifications.** Needs a paid Apple developer account for an APNs entitlement;
  local notifications (already shipped, for overtake alerts and the daily-bonus reminder) are the
  ceiling on the current free personal team.

## 5. Other open FEATURE_PLAN.md items worth calling out here

These are quality-relevant, not just "more features" — one line each, see
[FEATURE_PLAN.md](../FEATURE_PLAN.md) for the full scoring:

- **Real table presence** (`tableKey`, Phase 2 #3) — right now there's no signal that a friend is
  actually mid-hand at a table.
- **Firestore rules hardening** (Phase 5 #14) — security-relevant, not cosmetic.
- **Hebrew localization** (Phase 5 #13) — worth noting given the primary user's day-to-day language.

## 6. Process / tooling gaps

- `flutter analyze` could not be run to produce this doc — there's no Flutter SDK in the
  environment it was written in. The findings above come from reading the code, not from tooling,
  so a real `flutter analyze` / `flutter test` pass before the next release may surface more.
- No `flutter_launcher_icons`-style generator for the branded mark — already noted in
  [docs/APP_ICONS.md](APP_ICONS.md)'s **Gaps** section.
