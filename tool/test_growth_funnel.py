import unittest
from datetime import date
from growth_funnel import summarize, STAGES


def event(user, name, time, version='2'):
    return dict(user_pseudo_id=user, event_name=name, event_timestamp=time, app_version=version)


class FunnelTest(unittest.TestCase):
    def report(self, rows, **kwargs):
        return summarize(rows, date(2026, 9, 1), date(2026, 9, 9), date(2026, 9, 9), **kwargs)

    def test_order_duplicates_and_day1(self):
        rows = [event('a', stage, f'2026-09-01T10:0{i}:00Z') for i, stage in enumerate(STAGES)]
        rows += rows[:] + [event('a', 'session_start', '2026-09-02T13:00:00Z')]
        rows += [event('b', 'table_entered', '2026-09-01T09:00:00Z'),
                 event('b', 'first_open', '2026-09-01T10:00:00Z')]
        r = self.report(rows)
        self.assertEqual([x['devices'] for x in r['ordered_funnel']], [2, 1, 1, 1, 1])
        self.assertEqual(r['day1_retention_percent'], 50)

    def test_incomplete_and_other_version_excluded(self):
        rows = [event('a', 'first_open', '2026-09-09T12:00:00Z'),
                event('b', 'first_open', '2026-09-01T12:00:00Z', version='1')]
        r = self.report(rows, version='2')
        self.assertEqual(r['mature_devices'], 0)
        self.assertIsNone(r['day1_retention_percent'])

    def test_local_calendar_day_not_elapsed_24_hours(self):
        rows = [event('a', 'first_open', '2026-09-01T20:50:00Z'),
                event('a', 'session_start', '2026-09-01T21:10:00Z')]
        self.assertEqual(self.report(rows, tz='Asia/Jerusalem')['day1_returned_devices'], 1)
        self.assertEqual(self.report(rows)['day1_returned_devices'], 0)


if __name__ == '__main__':
    unittest.main()
