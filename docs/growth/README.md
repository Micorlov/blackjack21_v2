# Big Cards activation and listing follow-up

Implemented locally on 2026-09-12. Production publication of this app build and the staged screenshots is **not recorded**. Do not attribute production changes to this work until it is released.

## What changed

- Native onboarding puts **Play now** first. It opens the Bronze table with coaching active and no chips spent. Google sign-in remains available; the web still requires sign-in.
- Core betting/actions, dealer/player labels, round results, the three-hand tutorial and reference rules use all ten existing locales. Lobby, social, legal documents and some accessibility descriptions still have English text. No claim of complete app localization is made.
- Review attempts start only after ten played hands and a quiet settlement, without selecting players by winning outcome. Leaving the table before the delay cancels the opportunity. Failure/unavailability waits seven days; an API call that completes waits 90 days, with at most three completed requests per local save. A completed API call does not confirm display or a rating. Legacy one-shot saves migrate to a persisted conservative cooldown.
- Existing analytics opt-out still applies. Events contain methods, counts and outcomes, without adding names, group codes or account IDs.

## Activation measurement

| Event | Meaning |
|---|---|
| `first_open` | Firebase SDK first open of this app instance; reinstall/reset can create another |
| `onboarding_entry_selected` | Native guest/Google choice, with `method` |
| `onboarding_complete` | Guest enters or Google sign-in succeeds |
| `table_entered` | Player enters a table; existing event |
| `first_hand_completed` | Saved hand count crosses one |
| `tutorial_completed` | Third coached round settles; once per save, not again on replay |
| `tutorial_skipped` | User explicitly skips coaching |
| `ten_hands_completed` | Saved hand count crosses ten, including split hands |
| `review_prompted` | Review service actually attempted |
| `review_request_result` | `request_completed` or `unavailable_or_failed`; never proof of review |

The report uses an ordered funnel from first open → entry choice → table → first hand → ten hands. Tutorial completion/skip are separate so skipping an optional tutorial does not automatically count as failed activation. Day-one return means activity on the next **calendar day** in the chosen reporting timezone, not 24 elapsed hours. Activation has a fixed seven-calendar-day window; only fully observed cohorts are included. The current custom analytics service is disabled on web; compare Android app cohorts.

Export event-level CSV from the linked Firebase/GA4 BigQuery dataset. `tool/growth_funnel.py` accepts `user_pseudo_id,event_timestamp,event_name,app_version`; timestamps may be UTC microseconds or ISO timestamps with offsets. IDs are used only to aggregate; the report contains no identifiers. Keep raw exports outside version control.

Example query (replace project/property and dates with the real values):

```sql
SELECT user_pseudo_id, event_timestamp, event_name, app_info.version AS app_version
FROM `PROJECT.analytics_PROPERTY.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20260913' AND '20261017'
  AND platform = 'ANDROID'
  AND app_info.id = 'com.micorlov.blackjack21_v2'
  AND event_name IN (
    'first_open', 'onboarding_entry_selected', 'onboarding_complete', 'table_entered',
    'first_hand_completed', 'ten_hands_completed', 'tutorial_completed', 'tutorial_skipped',
    'session_start', 'user_engagement', 'hand_played'
  )
```

Use only complete daily tables, allow reporting lag, and include six extra days after the last first-open cohort. These example dates do not assert publication. The fields follow Google's [export schema](https://support.google.com/analytics/answer/7029846?hl=en) and [query guidance](https://developers.google.com/analytics/bigquery/basic-queries).

```bash
python3 tool/growth_funnel.py /absolute/path/events.csv \
  --start 2026-09-13 --end 2026-10-10 --through 2026-10-17 \
  --timezone Asia/Jerusalem --version ACTUAL_RELEASE_VERSION > /absolute/path/funnel.json
python3 -m unittest discover -s tool -p test_growth_funnel.py
```

Do not compare the new custom milestones against pre-update zeros. Compare complete cohorts with this instrumentation, segment by first-open build version, and report sample counts. Analytics consent, reinstall behavior and missing identifiers limit device-level attribution. No live Firebase export has been analyzed for this update.

## Listing measurement and staged screenshots

The earlier ten-language title submission was accepted on 2026-09-12 at 20:36:13 UTC; that is not the public publication date. Backup, verification and the existing 28-day measurement record remain in `/Users/michael/.codex/outputs/blackjack-big-cards/20260912T203535Z/`.

Keep the existing 28-day before/after comparison for Explore impressions, listing visitors, install-button clicks and completed acquisitions, by country where available. Record actual public availability, exclude the partial publication day and respect reporting lag. Small samples, the earlier promotional-copy correction, and any app or screenshot release during the period are confounders.

The three English screenshots are staged in `play-assets/big-cards/en-US/`: big cards, guided play, sweep result. They are 1080×1920; the headline occupies 10.9% of the height. They render actual Flutter table widgets with deterministic valid game states and bundled fonts, without a phone frame or promotional claims. They are **not device-captured sessions** and have not been uploaded. Before publication, verify them against the released APK and keep their release date separate from the title change. Follow Google's [screenshot guidance](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).

```bash
flutter test --no-pub --dart-define=CAPTURE_STORE_SHOTS=true test/store_screenshot_capture_test.dart
```

A screenshot experiment can follow the name baseline, one creative change at a time. With the previously observed low traffic, inconclusive results are likely; do not declare a winner from a handful of installs.
