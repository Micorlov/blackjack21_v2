import 'package:blackjack21_v2/utils/flags.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 20 decorative flags `flagForId` may return. Restated here on purpose:
/// the pool is private to the implementation, so listing it independently keeps
/// this an actual check rather than a mirror of the code under test.
const _pool = [
  '🇺🇸', '🇬🇧', '🇨🇦', '🇦🇺', '🇩🇪', '🇫🇷', '🇮🇹', '🇪🇸', '🇧🇷', '🇯🇵',
  '🇰🇷', '🇮🇳', '🇲🇽', '🇳🇱', '🇸🇪', '🇮🇱', '🇿🇦', '🇦🇷', '🇹🇷', '🇵🇱',
];

void main() {
  group('flagForId', () {
    test('always returns a flag from the pool', () {
      for (var i = 0; i < 500; i++) {
        expect(_pool, contains(flagForId('player-$i')));
      }
    });

    test('is deterministic for the same id', () {
      for (final id in ['hero', 'wbot3', 'user-42', 'ид-Ω']) {
        expect(flagForId(id), flagForId(id));
      }
    });

    test('falls back to the first flag for an empty id', () {
      expect(flagForId(''), _pool.first);
    });

    // The implementation deliberately avoids String.hashCode, which Dart does
    // not guarantee to be stable across platforms or runs. Pinning concrete
    // pairs is what actually catches a regression back to hashCode — a
    // property-only test would still pass if the hash were swapped out.
    test('maps known ids to stable flags across platforms', () {
      expect(flagForId('hero'), '🇰🇷');
      expect(flagForId('wbot1'), '🇳🇱');
      expect(flagForId('abc'), '🇸🇪');
      expect(flagForId('user-42'), '🇲🇽');
      expect(flagForId('Liam'), '🇦🇷');
    });

    test('spreads ids across most of the pool rather than clustering', () {
      final seen = {for (var i = 0; i < 200; i++) flagForId('uid-$i')};
      expect(seen.length, greaterThanOrEqualTo(_pool.length - 2));
    });

    test('distinguishes ids that differ only by character order', () {
      expect(flagForId('ab'), isNot(flagForId('ba')));
    });
  });
}
