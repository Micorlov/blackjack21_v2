import 'package:blackjack21_v2/utils/rebuy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rebuy = DateTime(2026, 9, 4, 12, 0, 0);

  group('isRebuyReady', () {
    test('is ready when never taken', () {
      expect(isRebuyReady(null, rebuy), isTrue);
    });

    test('is not ready immediately after a rebuy', () {
      expect(isRebuyReady(rebuy, rebuy.add(const Duration(seconds: 1))), isFalse);
    });

    test('is not ready one minute before the cooldown ends', () {
      final now = rebuy.add(kRebuyCooldown - const Duration(minutes: 1));
      expect(isRebuyReady(rebuy, now), isFalse);
    });

    test('is ready exactly when the cooldown ends', () {
      expect(isRebuyReady(rebuy, rebuy.add(kRebuyCooldown)), isTrue);
    });

    test('is ready long after the cooldown ends', () {
      expect(isRebuyReady(rebuy, rebuy.add(const Duration(days: 1))), isTrue);
    });
  });

  group('rebuyCountdownLabel', () {
    test('rounds up to hours and minutes', () {
      final now = rebuy.add(const Duration(hours: 1, minutes: 30));
      expect(rebuyCountdownLabel(rebuy, now), '2h 30m');
    });

    test('drops to just minutes under an hour left', () {
      final now = rebuy.add(kRebuyCooldown - const Duration(minutes: 41));
      expect(rebuyCountdownLabel(rebuy, now), '41m');
    });

    test('empty once ready', () {
      expect(rebuyCountdownLabel(rebuy, rebuy.add(kRebuyCooldown)), '');
    });
  });
}
