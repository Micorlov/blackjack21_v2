# Blackjack 21 — 1.8.6 (versionCode 18) report

**Branch:** `feat/1.8.6-consent` (`feat/in-app-review` left at ddfeba5). **Commit:** `9fa3dbc` (carries the uncommitted 1.8.5 work and the 1.8.6 changes together, because they were mixed in one working tree). QA-only files (`QaOverrides.cs`, `QaCleartextManifest.cs`, `.meta`) are NOT committed. Nothing pushed, merged, uploaded or installed on the phone.

## Changes
- `Core/ConsentRegions.cs`: empty/unknown region is no longer restricted; `AnalyticsPolicy.Allowed(optedIn, region, consentGranted)`; new `ConsentSignals`.
- `GameAds/AdMobService.cs`: under-age tag never set from region (only QA extra `bj_tfua=on`); Teen treatment always; `Consent` mapped from UMP status + IABTCF purpose consents (`analytics/ad_storage` = P1, `ad_user_data` = P1+P7, `ad_personalization` = P1+P3+P4); `ConsentChanged` event; `InterstitialReady`; `ShowInterstitial(closed)`. Ads still start only on `CanRequestAds()`.
- `GameFirebase/FirebaseAnalyticsService.cs`: `SetConsent` -> `FirebaseAnalytics.SetConsent` (4 types); collection starts on; comments updated. BJ_FIREBASE_EMULATOR still keeps live analytics off.
- `AndroidManifest.xml` (BlackjackExtras): removed `firebase_analytics_collection_enabled=false` and `firebase_crashlytics_collection_enabled=false`.
- `GameController.cs`: reset bug fixed (`AnalyticsOn = !saved.AnalyticsChoiceMade || saved.AnalyticsOn`); `ApplyAnalytics` also on boot for new players, reacts to `ConsentChanged`; `AnalyticsUsesConsentForm`, `AnalyticsCollecting`. `AppState`/`SavedGame`/`SavedGameJson`: `AnalyticsOn` defaults true; `AppState.AdBreakActive`.
- `SettingsScreen.cs`: switch never locked; in EEA/UK/CH (when UMP says privacy options are required) it opens the UMP form; link renamed "Privacy choices".
- `GameController.Ads.cs`, `Round.cs`, `UI/AppRoot.cs`: break ad waits 1 s after the Next Hand tap, only if due and loaded; full-screen transparent input blocker + controller guards (NextHand/DealRound) until the ad closes (120 s safety). No ad due = no delay. Pacing unchanged.
- `LegalContent.cs`, `hosting/privacy-policy.html` (date 17 Nov 2026), `README.md` (features, changelog), version bumps in `BuildTools.cs` and `ProjectSettings.asset`.
- Tests: `ConsentRegionTests`, `ControllerTests` updated/added (default on, explicit choice honoured, 1.8.4 false not sticky, EEA consent flow, delayed ad + input block).

## Tests / builds
- EditMode: 230/230 passed (before the final build; no code changes after). PlayMode RulesAudit not run (the Settings text and an invisible overlay changed; worth running before shipping).
- Release AAB (upload key, verified with jarsigner, manifest versionName 1.8.6, no collection flags, no QA/test-ads defines): `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18.aab` (also `blackjack21-unity.aab`).
- Release APK: not built (no bundletool installed).
- Test/debug APK (debug key, Google sample ads): `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18-debug-testads.apk`.
- QA EEA APK (BJ_FIREBASE_EMULATOR, never ship): `Unity/Builds/Android/blackjack21-unity-emulator-qa.apk`.
- 1.8.5 artifacts kept as `blackjack21-unity-1.8.5.aab/.apk`.

## Emulator (PSK_Pixel_8_API_36, region US)
- No crash (no AndroidRuntime/FATAL).
- No consent form on non-EEA: `UMP: updated, status=NotRequired canRequestAds=True`, `Ads: region=US ageTreatment=Teen`.
- Analytics on: `Consent mode: analytics_storage=True ad_storage=True ad_user_data=True ad_personalization=True`, `FA: App measurement initialized`, `FA: App measurement collection enabled`, `Setting app measurement enabled (FE): true`. I did not see individual first_open/session_start lines in logcat.
- Break ad: after 5 hands the fifth Next Hand tap showed the table (button pressed, no ad) in a screenshot taken right after, and the AdActivity (test interstitial) was up within 3 s; a chip tap sent 0.2 s after was swallowed. After closing, the table was usable again. The exact 1.0 s delay is proven by the unit test, not measured on device.
- EEA QA build (`bj_geo=eea`): consent form shown (`status=Required canRequestAds=False`), after Consent `status=Obtained canRequestAds=True`, IABTCF purposes `11111111111`, consent mode all true. Normal test APK reinstalled afterwards.
- Screenshots: `/Users/micorlov/grokshots/bj186_01_launch.png`, `_02_table.png`, `_03_after_hand.png`, `_04_interstitial_or_next.png`, `_05_settings_privacy.png`, `bj186_ump_eea_consent.png`.

## Skipped / caveats
- R8/minification and Google Mobile Ads / Play Core upgrades: skipped (risky with IL2CPP + Firebase + UMP and not verifiable here); edge-to-edge deprecation warning not addressed.
- Settings screenshot of the EEA variant (switch opening the UMP form) not captured; covered by unit test only.
- On a real EEA device before UMP answers, collection is denied (region list); in an EEA country the device region may differ (e.g. travelling) and then UMP decides.
- Ads treatment is Teen everywhere (previously Child in EEA); this is conservative for a 13+ game.
- Privacy policy HTML is not deployed.

## Turn-order fix: hero acts last (same 1.8.6 / vc18)

**Root cause.** Not a regression: 1.8.5 deliberately seated the hero in the "middle chair" (`TableCatalog.SeatsBeforeHero = 2`).
Maya and Jordan acted in `RoundPhase.Npcs`, then the hero, then Sam and Priya in `NpcsAfter`. So the hero decided blind
against two rivals who had not played yet.

**Why that hurts the Sweet Pot.** The pot goes to the best surviving hand; seats that bust or lose to the dealer forfeit
their bets into it. Acting last, the hero sees who has busted and who stands on what, and can hit or stand to take the pot.
Acting before two seats, the hero commits first and those seats can then play to beat the hero's total.

**Fix.** `RoundEngine.SeatsActingIn(Npcs)` now returns every opponent seat, `NpcsAfter` returns none (enum value kept, unused),
`SeatsBeforeHero` is removed. Flow: all seats, then hero, then dealer. Bust, surrender and natural go straight to the dealer
(seats already played); a dealer natural still ends the hand first. Turn-order strip puts "You" last; the note above the
buttons now says "you play last" (key `turnYouPlayLast`, 10 languages; it said "you play third"). Felt layout is unchanged.
Files: Core/RoundEngine.cs, Enums.cs, TableCatalog.cs, FeltMetrics.cs (comment), GameController.Round.cs (comment),
TablePanels.cs, TurnTimerView.cs (comment), Resources/Locales/*.json, README.md, tests (RoundFlowTests, ControllerTests, SettlementTests comment).
Tutorial first hands: no special path touches seat order, covered by existing tests.

**Tests.** EditMode 232/232 passed (`/tmp/bj186-order-edit.log`, `.xml`). New cases: all seats act before the hero, dealer
follows the hero directly, hero sees earlier busts, bust/surrender/natural go to the dealer. PlayMode RulesAudit not run.

**Builds (1.8.6 / vc18).**
- AAB: `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18.aab` (jarsigner: jar verified; also `blackjack21-unity.aab`)
- Debug test-ads APK: `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18-debug-testads.apk` (also `blackjack21-unity.apk`)
- 1.8.5 artifacts untouched. QA files are `#if BJ_FIREBASE_EMULATOR`/editor-only and uncommitted.

**Emulator (emulator-5554, PSK_Pixel_8_API_36), new APK installed with `adb install -r`.** Silver table, one hand: Maya, then Sam
played with the hero buttons absent, then "Your turn" with all four seats done, then the dealer. Screenshots:
`~/grokshots/bj186_order_01_npcs_acting.png`, `_02_more_npcs.png`, `_03_hero_turn.png`, `_04_dealer.png`.

**Skipped / caveats.** Not installed on the physical phone (per instructions). Only one hand was watched on the emulator; the
hero hand timed out and auto-stood on the turn timer. Seats act right-to-left across the felt, so Priya (far left) is last.

## Big-win review + 8 PM evening gift (same 1.8.6 / vc18)

### What changed
**Review after a big win** (reuses `ReviewPrompt` / `PlayReview` / `IReviewPrompter` / `FeatureFlag.ReviewPrompt`, no second stack)
- `ReviewPrompt.IsBigWin(before, settled)`: a won hand where the hero took the Sweet Pot (`SweepInfo.HeroTook`), or the natural-blackjack count went up, or `RoundNet >= 5 x RoundStake`. `RoundNet` already includes the 3:2 on a natural and any sweep pot; `RoundStake` is bets plus insurance.
- `ShouldPrompt(bigWin, now, firstSeenAtMs, lastAttemptAtMs, completedRequests, lastSucceeded)`: big win only; **never in the first 24 h** (new persisted `FirstSeenAtMs`, set at first boot; saves from before this field count as long-standing); 30 d after a completed ask, 7 d after a failed launch, max 3 asks (unchanged).
- Play policy: only the official Play in-app review API. No pre-prompt, no reward, no rating gate.
- Logs `[Review] big win: requesting the Google Play in-app review`.

**8 PM evening gift** (extends `UnityNotifier` / `ILocalNotifier`; no FCM)
- `Core/EveningGift.cs`: `NextFire(now)` (today 20:00 if still ahead, else tomorrow), `KeyOf` (local date), `CanGrant`; `NotifPermissionPrompt.ShouldAsk`.
- `ILocalNotifier` gains `ScheduleEveningGift(DateTime)`, `CancelEveningGift()`, `ConsumeEveningGiftTap()`. Android: id 212, channel `evening_gift`, repeating daily, title "Your free $500 chips are waiting!", body "Tap to collect your evening gift. Play chips for the game only, no real money."
- Tap detection: the notification's launch intent (`GetLastNotificationIntent`); after reading it the activity intent is replaced by an empty one, so a stale tap is never counted twice.
- `GameController.Bonus.cs`: `SyncEveningGift` runs on boot, every resume (new day, time-zone change, moved clock) and when the Daily reminder switch flips (off cancels, on re-arms). `ClaimEveningGift` credits +500 once per local date (`EveningGiftKey`, persisted), toast "+$500 play chips - your evening gift!", SFX, analytics `evening_gift_claimed`, then re-arms. The tap is processed 0.8 s after launch/resume (a toast raised in the first frame expired before it rendered; found on the emulator).
- It is independent of `ClaimDailyBonus` and the play streak: a tap never claims the ladder, and the ladder still pays its own reward.
- Permission: asked once, after a won hand with >= 5 hands played, only when the Daily reminder is on and the permission is missing, and never while the review request is pending (`NotifPermissionAsked` persisted; analytics `notif_permission_asked`). Not asked at cold start. The Settings switch still asks when turned on.
- Settings sublabel (English only) now: "Free play chips at 8 PM, plus a nudge when your daily bonus or streak needs you". The other nine locales still carry the old cooldown wording (not translated here).
- Existing daily-bonus-ready and streak reminders are unchanged, so a player can get up to three local notifications a day.

**Dev-only hook (not in the release)**: `Game/Services/QaNotifHook.cs` is compiled only with `BJ_QA_NOTIF`, which `BuildTools.BuildAndroid` (the adb APK) adds and `BuildAndroidRelease` does not. Launch extras: `bj_qa_gift_secs N` (one-off test notification id 213), `bj_qa_seasoned true` (install treated as 3 days old), `bj_qa_bigwin true` (every win counts as big). Verified absent from the AAB (`global-metadata.dat` has none of the QA strings).

### Files
Core: `Progression.cs`, `EveningGift.cs` (new), `SavedGame.cs`. Game: `AppState.cs`, `GameController.cs`, `.Bonus.cs`, `.Round.cs`, `Services/Interfaces.cs`, `NullServices.cs`, `SavedGameJson.cs`, `UnityNotifier.cs`, `QaNotifHook.cs` (new). Editor: `BuildTools.cs`. Locale: `en.json`. Tests: `ProgressionTests.cs`, `EveningGiftTests.cs` (new). Docs: `README.md`, this report. Not committed: `QaOverrides.cs`, `QaCleartextManifest.cs` and their `.meta`.

### Tests
EditMode **244/244 passed** (`/tmp/bj186-eng-edit.log`, results `/tmp/bj186-eng-results.xml`). New: big-win definition (sweep, natural, exactly 5x, 499 not, old natural not counted, losses, zero stake), first-day block, 24 h boundary, cooldowns and cap, `NextFire` (before/at/after 20:00, year end, clock moved), date key (first tap, same day no-op, next day pays), toggle cancel/re-arm, permission timing, no permission request at boot, ladder untouched, toast text says play chips, save round trip.

### Artifacts (1.8.6 / vc18; 1.8.5 files kept)
- Release AAB, upload-key signed, `jarsigner -verify`: `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18.aab` (also `blackjack21-unity.aab`). No QA, test ads, `BJ_FIREBASE_EMULATOR`, UMP debug geography or test-notification hook.
- Debug test-ads APK: `Unity/Builds/Android/blackjack21-unity-1.8.6-vc18-debug-testads.apk`.
- Not installed on the physical phone (instructed).

### Emulator (PSK_Pixel_8_API_36, debug APK)
- Notification permission dialog appeared after the first won hand once >= 5 hands were played: `bj186_notif_permission.png`; log `[Notif] asking for notification permission after a win`. On a fresh install in the first hands it did not appear.
- Review: a real Sweet Pot win ("You sweep the table +$500") happened on the Silver table; with the dev `bj_qa_bigwin` extra a normal win also requested it: `[Review] big win: requesting the Google Play in-app review`, followed by Play Core `ReviewService : requestInAppReview` binding to `com.android.vending` (the card itself did not show on the emulator). Screenshot `bj186_review.png`. Before clearing data, a run with the earlier state requested nothing, consistent with the 30-day cooldown from earlier emulator tests.
- Settings: `bj186_notif_settings.png` shows the new Daily reminder text. Turning it off removed the pending 20:00 alarm from `dumpsys alarm`, on restored it.
- Test notification: `bj186_notif_shade.png`; tap opens the app, log `evening gift credited +500 (balance 1000 -> 1500)`, toast "+$500 play chips - your evening gift!" in `bj186_notif_tap_reward.png`, table balance 1,500. A second notification tapped the same day logged `already taken for 2026-11-17, no credit` and the balance stayed 1,600 (earlier run, 1,100 -> 1,600 -> 1,600).
- Extras: `bj186_table_after_win.png`.

### Caveats
- Android delivers the daily alarm inexactly (no exact-alarm permission): on the emulator a 15-100 s test notification arrived within seconds to ~3 minutes. A real 20:00 may land a few minutes late.
- A tap while the app is already in the foreground (no pause/resume) is only noticed on the next resume.
- A big win by the numbers is frequent (any natural or sweep); the 30 d / 3 ask cap is what limits asks.
- The Play card did not render on the emulator; only the request was verified.
- Time-zone change is handled by re-scheduling on resume and covered by `NextFire` tests, not by changing the emulator's zone.
- PlayMode RulesAudit not run for the changed Settings text.
- The release build rewrites the upload-keystore path into `ProjectSettings.asset`; I reverted that and did not commit it.
