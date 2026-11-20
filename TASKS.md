# Tasks

Plan written 2026-11-20, after 1.8.7 (19) was sent to Play review. Baselines come from Firebase Analytics,
AdMob and Play Console for Oct 23 – Nov 19, 2026, unless an item says otherwise.

## Active

### 3. Check that 1.8.7 fixed sign-in for real players
- **When:** about 3 days after 1.8.7 goes live.
- **Steps:** Firebase → Events → compare `login` with `sign_in_failed`, split by `reason`.
- **Done when:** `sign_in_failed` with `reason=failed` is close to zero (`canceled` only means the player closed the
  picker). If not, read the warning in the device log: it now names the exception type and code.

### 4. Measure rewarded-ad uptake after 1.8.7
- **Baseline:** "Rewarded chips" had 353 requests and 5 impressions in the week to Nov 20; `ad_reward_earned` never fired.
- **Steps:** after one week on 1.8.7, compare AdMob rewarded impressions and the `ad_reward_earned` event.
- **Done when:** impressions are clearly up. If they are not, look at the lobby card and the low-chips offer next.
- **Note:** 1.8.7 has the two-button Out of chips sheet (gold rebuy, outline video). On Nov 20 one tap in the centre of the
  outline button on the Samsung did a rebuy and showed no ad; the code path looks right and it was seen once, so it is
  unexplained. If uptake on 1.8.7 stays flat, suspect that first. `main` no longer has that layout: out of chips now offers
  only the video while one can play (next release), so measure again one week after that release too.

### 5. Re-measure the onboarding funnel
- **Baseline:** `first_open` 285 → `onboarding_entry_selected` 226 (79%) → `first_hand_completed` 195 (68%) →
  `ten_hands_completed` 121 (42%).
- **Why:** the first screen held the broken Google sign-in; part of the 21% drop should go away with 1.8.7.
- **Note:** read it through the GA4 comparison "Real players (no IN2025)": all 45 `IN2025` runs logged `first_open`
  and almost nothing after it, so they sit in the baseline's first step and inflate the drop.
- **Done when:** the numbers after one week on 1.8.7 are recorded here, and any step still losing more than 20% has an
  owner.

### 9. Re-measure review prompts and ratings on 1.8.6 and later
- **Baseline:** only 3 `review_prompted` events from 2 users came from a build that really asks Play (1.8.6); see Done.
- **Steps:** after two weeks on 1.8.7, count `review_prompted` on 1.8.6+ and compare with Play Console → Ratings. The
  card itself can only be seen on a Play-installed build (internal testing track or production), never on the adb build.
- **Done when:** ratings appear, or prompts on 1.8.6+ pass about 50 users with still no rating, which would point at
  Play's quota or the big-win rule (natural blackjack, sweep pot, or a net win of 5× the stake, after the first day).

## Waiting On

- **Google review of 1.8.8 (20):** sent to production on Nov 21 as a full rollout, replacing 1.8.7 (19), which never went
  live. Managed publishing is off, so it goes live on approval. Items 3–5 now count from 1.8.8, not 1.8.7.
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

- 2026-11-20: Out of chips offers only the rewarded video while one can play, on the table and in the sheet; the rebuy and
  the other routes are the fallback. On `main`, not in 1.8.7.
- 2026-11-20: Samsung runs the current `main` (installed 23:15:44). The Out of chips sheet shows the outline "Watch a video"
  button under the gold rebuy button, and the test rewarded ad plays and pays 500 chips. adb was losing the phone because a
  second, orphaned adb server on port 5093 held its USB interface; see the Delivery Rule in `CLAUDE.md`.
- 2026-11-20: C# exceptions are reported by both pipelines. A temporary script threw 25 s after launch on two launches:
  Firestore `errors` got both documents and Crashlytics shows 2 non-fatals under `TempThrowOnce` (sent on the next launch).
  The script is deleted and the phone has a clean build. So 0 non-fatals in 90 days means none were thrown where collection
  was allowed; `app_exception` in Analytics counts fatal crashes, a different thing.
- 2026-11-20: `IN2025` traffic is automated runs outside Play, not players. 45 users, 16 s average, in two one-day bursts
  (Nov 2: 18 on 1.8.1; Nov 18: 19 on 1.8.6, the day after 1.8.6 was uploaded), spread evenly over nine countries (4 each in
  Chile, Colombia, Pakistan, Russia, Spain, Thailand). Play counted 4 device acquisitions in total on Nov 18, so these were
  not Play installs. Not the pre-launch report (one "Google Medium Phone" virtual device per build) and not Testers Community
  (that closed test ran in August). Who runs them is not visible in any console. GA4 has a saved comparison
  **"Real players (no IN2025)"** that excludes them: 30-day actives 338 → 292, 7-day 66 → 44.
- 2026-11-20: Play shows no ratings because nearly every "prompt" went nowhere. 180 of 183 `review_prompted` events
  (125 of 126 users) came from 1.8.2, where the review service was still the `NullReview` stub: the event was logged and
  Play was never asked. The real Play card shipped in 1.8.6 (Nov 17) and has been requested 3 times by 2 users.
  `review_request_result` cannot say more: its `outcome` only records that the call was made, and Play never reports
  whether the card was shown.
- 2026-11-20: Google sign-in fixed twice (native account picker; guest linking onto an existing account), and
  `login` / `sign_in_failed` events added.
- 2026-11-20: Out of chips sheet offers the rewarded video even when a rebuy is ready.
- 2026-11-20: `assetlinks.json` lists both Play app-signing keys; deployed and verified live.
- 2026-11-20: AdMob app linked to Firebase project `blackjack21-v2`.
- 2026-11-20: Play's current app-signing key (SHA-1 `5F:47:26:BE…`, SHA-256 `F4:57:DB:FA…`) registered on the Firebase
  Android app; the previous key and the upload key were already there.
- 2026-11-20: Crashlytics verified for Android-level crashes (forced crash on an emulator reached the console).
- 2026-11-20: 1.8.7 (19) built, signed with the upload key and sent to Play production review.
