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
}
