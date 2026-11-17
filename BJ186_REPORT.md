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
