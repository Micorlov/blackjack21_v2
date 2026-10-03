import 'package:blackjack21_v2/utils/play_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Duration now;
  PlayTimeTracker tracker() => PlayTimeTracker(clock: () => now);

  setUp(() => now = Duration.zero);

  test('counts foreground time from construction', () {
    final t = tracker();
    now = const Duration(seconds: 42);
    expect(t.takeSeconds(), 42);
  });

  test('takeSeconds resets the count so each second is reported once', () {
    final t = tracker();
    now = const Duration(seconds: 60);
    expect(t.takeSeconds(), 60);
    now = const Duration(seconds: 75);
    expect(t.takeSeconds(), 15);
    expect(t.takeSeconds(), 0);
  });

  test('carries the sub-second remainder instead of rounding it away', () {
    final t = tracker();
    now = const Duration(milliseconds: 1700);
    expect(t.takeSeconds(), 1);
    now = const Duration(milliseconds: 3400);
    expect(t.takeSeconds(), 2);
  });

  test('time spent in the background is not counted', () {
    final t = tracker();
    now = const Duration(seconds: 30);
    t.pause();
    now = const Duration(hours: 5);
    t.resume();
    now = const Duration(hours: 5, seconds: 10);
    expect(t.takeSeconds(), 40);
  });

  test('time banked at pause is still reported while paused', () {
    final t = tracker();
    now = const Duration(seconds: 20);
    t.pause();
    now = const Duration(minutes: 10);
    expect(t.takeSeconds(), 20);
    expect(t.takeSeconds(), 0);
  });

  test('repeated pause and resume calls are idempotent', () {
    final t = tracker();
    now = const Duration(seconds: 5);
    t.pause();
    t.pause();
    now = const Duration(seconds: 50);
    t.resume();
    now = const Duration(seconds: 60);
    t.resume();
    now = const Duration(seconds: 65);
    expect(t.takeSeconds(), 20);
  });
}
