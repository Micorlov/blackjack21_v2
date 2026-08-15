import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/screens/onboarding_screen.dart';

void main() {
  Widget wrap({required bool isWeb}) =>
      ProviderScope(child: MaterialApp(home: OnboardingScreen(isWeb: isWeb)));

  testWidgets('shows "Play as Guest" on non-web platforms', (tester) async {
    await tester.pumpWidget(wrap(isWeb: false));

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Play as Guest'), findsOneWidget);
  });

  testWidgets('hides "Play as Guest" on web, since guest mode has no Firebase account', (tester) async {
    await tester.pumpWidget(wrap(isWeb: true));

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Play as Guest'), findsNothing);
  });

  testWidgets('offers the voice toggle, on by default, before the player is in', (tester) async {
    await tester.pumpWidget(wrap(isWeb: false));

    expect(find.text('Voice call-outs'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('turning the switch off silences the table before the first hand', (tester) async {
    await tester.pumpWidget(wrap(isWeb: false));

    // The toggle sits below the sign-in buttons, so on a short viewport it
    // starts below the fold inside the screen's scroll view.
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });
}
