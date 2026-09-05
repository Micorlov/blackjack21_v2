import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/main.dart';
import 'package:blackjack21_v2/screens/table/table_betting_panel.dart';

/// Regression cover for the edge-to-edge system navigation bar.
///
/// The app shell draws behind the system bars (`SafeArea(bottom: false)` in
/// `main.dart`), so every bottom-anchored surface has to keep its own content
/// clear of them. When it doesn't, Android paints the gesture pill or the
/// three-button row straight over the UI: the bug that hid the bottom-nav
/// labels, the table's bet/deal buttons, and the onboarding terms line.
const double _systemBarHeight = 48;

/// A phone-shaped viewport with a three-button navigation bar at the bottom.
void _useEdgeToEdgePhone(WidgetTester tester) {
  const padding = FakeViewPadding(bottom: _systemBarHeight);
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 915)
    ..padding = padding
    ..viewPadding = padding;
  addTearDown(tester.view.reset);
}

/// The lowest y a widget may reach before the system bar covers it.
double _systemBarTop(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio - _systemBarHeight;

/// Walks a fresh install through guest entry, which is where
/// `widget_test.dart` also starts a lobby-side journey.
Future<void> _enterLobbyAsGuest(WidgetTester tester) async {
  await tester.tap(find.text('Play as Guest'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding terms line clears the system navigation bar', (tester) async {
    _useEdgeToEdgePhone(tester);
    await tester.pumpWidget(const ProviderScope(child: BlackjackApp()));
    await tester.pumpAndSettle();

    final terms = find.textContaining('By continuing you agree');
    expect(terms, findsOneWidget);
    expect(tester.getRect(terms).bottom, lessThanOrEqualTo(_systemBarTop(tester)));
  });

  testWidgets('bottom nav labels clear the system navigation bar', (tester) async {
    _useEdgeToEdgePhone(tester);
    await tester.pumpWidget(const ProviderScope(child: BlackjackApp()));
    await tester.pumpAndSettle();
    await _enterLobbyAsGuest(tester);

    final limit = _systemBarTop(tester);
    for (final label in ['Home', 'Stats', 'Friends', 'Settings']) {
      expect(
        tester.getRect(find.text(label)).bottom,
        lessThanOrEqualTo(limit),
        reason: 'the "$label" tab label runs under the system navigation bar',
      );
    }
  });

  testWidgets('table action panel clears the system navigation bar', (tester) async {
    _useEdgeToEdgePhone(tester);
    await tester.pumpWidget(const ProviderScope(child: BlackjackApp()));
    await tester.pumpAndSettle();
    await _enterLobbyAsGuest(tester);

    await tester.tap(find.text('Bronze Table'));
    await tester.pumpAndSettle();

    final panel = find.byType(TableBettingPanel);
    expect(panel, findsOneWidget);
    expect(
      tester.getRect(panel).bottom,
      lessThanOrEqualTo(_systemBarTop(tester)),
      reason: 'the bet/deal controls run under the system navigation bar',
    );
  });
}
