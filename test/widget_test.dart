import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/main.dart';

void main() {
  testWidgets('shows the onboarding screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BlackjackApp()));

    expect(find.text('Blackjack 21'), findsOneWidget);
    expect(find.text('Play as Guest'), findsOneWidget);
  });

  testWidgets('playing as guest navigates to the lobby', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BlackjackApp()));

    await tester.tap(find.text('Play as Guest'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  // Regression: StatsScreen used Row(crossAxisAlignment: stretch) directly
  // inside a SingleChildScrollView's unbounded-height Column, which throws
  // "BoxConstraints forces an infinite height" and blanks the whole screen.
  // Covers every bottom-nav destination so the same class of bug can't hide
  // in an unvisited tab again.
  testWidgets('every bottom nav destination renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BlackjackApp()));
    await tester.tap(find.text('Play as Guest'));
    await tester.pumpAndSettle();

    for (final label in ['Stats', 'Friends', 'Shop', 'Settings', 'Lobby']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'navigating to $label threw');
    }
  });
}
