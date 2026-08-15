import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:blackjack21_v2/main.dart';

/// Drives a real device/simulator build from onboarding to a dealt round and
/// then holds still, so the table can be inspected (or screenshotted with
/// `xcrun simctl io <device> screenshot`) with the app's real fonts and real
/// device metrics — which widget tests, running on the fallback test font,
/// cannot show.
///
/// Run with: `flutter test integration_test/table_shot_test.dart -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('deals a round and holds the table still for inspection', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BlackjackApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play as Guest'));
    await tester.pumpAndSettle();

    // A player with no hands behind them lands on the tips primer first, so the
    // lobby is not reachable until it is dismissed. Skipping also keeps the
    // tutorial overlay off the table.
    final skipTips = find.text("I've played before — skip");
    if (skipTips.evaluate().isNotEmpty) {
      // The link sits below the tip cards, off-screen on shorter devices, so a
      // plain tap lands on nothing.
      await tester.ensureVisible(skipTips);
      await tester.pumpAndSettle();
      await tester.tap(skipTips);
      await tester.pumpAndSettle();
    }

    // Lobby: the first table tile in the "choose your table" list.
    await tester.tap(find.text('Bronze Table').first);
    await tester.pumpAndSettle();

    // Betting panel: put a chip down, then deal.
    await tester.tap(find.text('\$25').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DEAL'));

    // The round deals on timers; pump through them so every seat ends up with
    // cards and a hand total on its plate.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Hold the dealt table on screen long enough to capture it externally.
    await Future<void>.delayed(const Duration(seconds: 30));
  });
}
