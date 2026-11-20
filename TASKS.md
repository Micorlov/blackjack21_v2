# Tasks

Plan written 2026-11-20, after 1.8.7 (19) was sent to Play review. Baselines come from Firebase Analytics,
AdMob and Play Console for Oct 23 – Nov 19, 2026, unless an item says otherwise.

## Active

### 1. Install the latest build on the Samsung
- **Why:** the phone has the 22:28 build from Nov 20, without the rewarded-video button on Out of chips.
- **Blocker:** adb keeps losing `R5GYB2NHR5D` even though macOS sees it on USB.
- **Steps:** use a data cable; set the USB mode to File transfer; accept "Allow USB debugging"; if it still drops, turn off
  Auto Blocker (Settings → Security and privacy). Then run the build and install command from `CLAUDE.md` and check
  `lastUpdateTime`.
- **Done when:** the phone runs the current `main`, and the Out of chips sheet shows the outline "Watch a video" button
  under the gold rebuy button, with a test ad loaded.

### 2. Prove that game-code exceptions are reported
- **Why:** Crashlytics shows 0 non-fatal events in 90 days and the Firestore `errors` collection is empty, but Analytics
  counted 3 `app_exception` events. Android-level crashes were verified on Nov 20; C# exceptions were not.
- **Steps:** needs item 1's USB connection. Add a temporary script that throws once 25 s after launch (never committed),
  build, install, check that a Crashlytics non-fatal and an `errors/{id}` document appear, then delete the script and
  rebuild.
- **Done when:** both pipelines show the test exception, or the missing one is fixed.

### 3. Check that 1.8.7 fixed sign-in for real players
- **When:** about 3 days after 1.8.7 goes live.
- **Steps:** Firebase → Events → compare `login` with `sign_in_failed`, split by `reason`.
- **Done when:** `sign_in_failed` with `reason=failed` is close to zero (`canceled` only means the player closed the
  picker). If not, read the warning in the device log: it now names the exception type and code.

### 4. Measure rewarded-ad uptake after 1.8.7
- **Baseline:** "Rewarded chips" had 353 requests and 5 impressions in the week to Nov 20; `ad_reward_earned` never fired.
- **Steps:** after one week on 1.8.7, compare AdMob rewarded impressions and the `ad_reward_earned` event.
- **Done when:** impressions are clearly up. If they are not, look at the lobby card and the low-chips offer next.

### 5. Re-measure the onboarding funnel
- **Baseline:** `first_open` 285 → `onboarding_entry_selected` 226 (79%) → `first_hand_completed` 195 (68%) →
  `ten_hands_completed` 121 (42%).
- **Why:** the first screen held the broken Google sign-in; part of the 21% drop should go away with 1.8.7.
- **Done when:** the numbers after one week on 1.8.7 are recorded here, and any step still losing more than 20% has an
  owner.

### 6. Find out where the `IN2025` traffic comes from
- **Why:** 45 of 335 users (20 of 42 on 1.8.6) share device model `IN2025` across many countries, which distorts
  retention and uninstall numbers. Play counted 114 device first opens where Firebase counted 285.
- **Steps:** check Play Console → Testing → Pre-launch report for its device list, and the Testers Community / closed-test
  history. If it is test traffic, add a GA4 comparison or data filter that excludes it.
- **Done when:** the source is named and the main reports can exclude it.

### 7. Find out why Play shows no ratings
- **Why:** `review_prompted` fired 183 times for 126 users, yet Play shows no ratings or reviews at all.
- **Steps:** read the `review_request_result` parameters (requested vs completed). Check whether Play's in-app review quota
  or the 1.8.6 "big win only" rule suppresses the card. Confirm the card shows on a production install.
- **Done when:** the cause is known, and either fixed or explained.

## Waiting On

- **Google review of 1.8.7 (19):** submitted to production on Nov 20 as a full rollout; managed publishing is off, so it
  goes live on approval. After that, watch Play Console → Production for the install base moving to 1.8.7.
- **AdMob → Firebase data:** linked on Nov 20; AdMob says metrics can take up to 48 hours. Then check that Firebase shows
  `ad_impression` revenue and that AdMob shows Ads ARPU.
- **Trader status (Michael):** Play Console asks for it by **Feb 1, 2027**. It needs Michael's own legal details, so it
  cannot be delegated.

## Someday

- **Play's recommended actions for the next release (1.8.8):** "Edge-to-edge may not display for all users",
  "deprecated APIs or parameters for edge-to-edge", and "Improve memory and performance with R8 optimization".
- **8 PM evening gift:** judge it after a week on 1.8.7 (`evening_gift_claimed`, `notif_permission_asked`). Only 7 users
  had been asked for notification permission by Nov 20.
- **AdMob impression-level ad revenue:** an account-wide setting covering all apps. It was declined on Nov 20 because it
  changes every app; turn it on if Firebase revenue looks incomplete.
- **Post-quantum signing key:** Play lists a beta post-quantum key next to the classical one. Its fingerprints are not in
  Firebase or `assetlinks.json`; add them only if Play starts signing installs with it.
- **Branch cleanup:** `fix/google-sign-in` and `fix/rewarded-button-deep-link` are merged into `main` and can be deleted
  locally and on GitHub (ask first).

## Done

- 2026-11-20: Google sign-in fixed twice (native account picker; guest linking onto an existing account), and
  `login` / `sign_in_failed` events added.
- 2026-11-20: Out of chips sheet offers the rewarded video even when a rebuy is ready.
- 2026-11-20: `assetlinks.json` lists both Play app-signing keys; deployed and verified live.
- 2026-11-20: AdMob app linked to Firebase project `blackjack21-v2`.
- 2026-11-20: Play's current app-signing key (SHA-1 `5F:47:26:BE…`, SHA-256 `F4:57:DB:FA…`) registered on the Firebase
  Android app; the previous key and the upload key were already there.
- 2026-11-20: Crashlytics verified for Android-level crashes (forced crash on an emulator reached the console).
- 2026-11-20: 1.8.7 (19) built, signed with the upload key and sent to Play production review.
