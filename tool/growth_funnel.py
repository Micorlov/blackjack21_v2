#!/usr/bin/env python3
"""Aggregate a Firebase event CSV without including device identifiers in output."""
import argparse
import csv
import json
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

STAGES = ('first_open', 'onboarding_entry_selected', 'table_entered',
          'first_hand_completed', 'ten_hands_completed')


def summarize(rows, start, end, through, tz='UTC', version=None):
    zone = ZoneInfo(tz)
    people = defaultdict(list)
    for row in rows:
        uid = row['user_pseudo_id'].strip()
        if not uid:
            continue  # consent-limited rows cannot be joined into device cohorts
        raw = row['event_timestamp'].strip()
        dt = (datetime.fromtimestamp(int(raw) / 1_000_000, timezone.utc)
              if raw.isdigit() else datetime.fromisoformat(raw.replace('Z', '+00:00')))
        if dt.tzinfo is None:
            raise ValueError('ISO timestamps must contain an offset; GA4 microseconds are also accepted')
        dt = dt.astimezone(zone)
        if dt.date() <= through:
            people[uid].append((dt, row['event_name'], row.get('app_version', '')))
    counts = dict.fromkeys(STAGES, 0)
    complete = skipped = d1_eligible = d1_returned = 0
    for events in people.values():
        events.sort()
        opens = [e for e in events if e[1] == 'first_open']
        if not opens:
            continue
        opened = opens[0]
        if not start <= opened[0].date() <= end or (version and opened[2] != version):
            continue
        # Use a fixed seven-calendar-day activation window for comparable cohorts.
        window_end = opened[0].date() + timedelta(days=6)
        if window_end > through:
            continue
        cohort_events = [e for e in events if opened[0] <= e[0] and e[0].date() <= window_end]
        next_stage = 0
        # Timestamps may tie, especially in fixtures. Within a tie use funnel order.
        cohort_events.sort(key=lambda e: (e[0], STAGES.index(e[1]) if e[1] in STAGES else 99))
        for _, event, _ in cohort_events:
            if next_stage < len(STAGES) and event == STAGES[next_stage]:
                counts[event] += 1
                next_stage += 1
        names = {e[1] for e in cohort_events}
        complete += 'tutorial_completed' in names
        skipped += 'tutorial_skipped' in names
        next_day = opened[0].date() + timedelta(days=1)
        d1_eligible += 1
        d1_returned += any(e[0].date() == next_day and e[1] in
                          ('session_start', 'user_engagement', 'hand_played') for e in events)
    total = counts['first_open']
    return {
        'cohort_start': str(start), 'cohort_end': str(end), 'data_complete_through': str(through),
        'timezone': tz, 'first_open_version': version, 'activation_window_calendar_days': 7,
        'mature_devices': total,
        'ordered_funnel': [{'event': stage, 'devices': count,
                            'percent_of_first_open': round(count / total * 100, 2) if total else None}
                           for stage, count in counts.items()],
        'tutorial_completed_devices': complete, 'tutorial_skipped_devices': skipped,
        'day1_eligible_devices': d1_eligible, 'day1_returned_devices': d1_returned,
        'day1_retention_percent': round(d1_returned / d1_eligible * 100, 2) if d1_eligible else None,
        'limitations': ['Device cohorts, not people; reinstall/reset may create another first_open.',
                       'Opt-outs and missing identifiers are excluded; incomplete cohorts are excluded.',
                       'Tutorial skip and completion are independent; replay can produce both.',
                       'New milestones only exist after this app update reaches users.',
                       'These are in-app activation metrics, not Play listing clicks or acquisitions.'],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('csv')
    for field in ('start', 'end', 'through'):
        parser.add_argument('--' + field, required=True, type=date.fromisoformat)
    parser.add_argument('--timezone', default='UTC')
    parser.add_argument('--version')
    args = parser.parse_args()
    if args.start > args.end or args.end > args.through:
        parser.error('Require start <= end <= through (last fully reported day)')
    with open(args.csv, newline='', encoding='utf-8-sig') as source:
        reader = csv.DictReader(source)
        required = {'user_pseudo_id', 'event_timestamp', 'event_name'}
        if not required <= set(reader.fieldnames or []):
            parser.error('CSV requires ' + ', '.join(sorted(required)))
        if args.version and 'app_version' not in reader.fieldnames:
            parser.error('--version requires app_version in the CSV')
        print(json.dumps(summarize(reader, args.start, args.end, args.through,
                                   args.timezone, args.version), indent=2))


if __name__ == '__main__':
    main()
