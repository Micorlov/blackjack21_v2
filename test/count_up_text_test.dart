import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/theme/app_text_styles.dart';
import 'package:blackjack21_v2/widgets/count_up_text.dart';

/// The rolling figure is the app's only numeric animation, and it sits on the
/// two numbers a player actually watches — the bankroll and the round's net —
/// so it has to be right about where it starts, where it ends, and what it
/// does when the player has asked for less motion.
Future<void> _pump(WidgetTester tester, int value, {bool reduceMotion = false}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: CountUpText(value: value, prefix: r'$', signed: true, style: AppText.mono(20))),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the real figure on first build rather than counting up to it', (tester) async {
    // A balance that rolls up from zero every time the table opens is a slot
    // machine, not a bankroll.
    await _pump(tester, 1200);
    expect(find.text(r'+$1,200'), findsOneWidget);
  });

  testWidgets('rolls from the old value and lands exactly on the new one', (tester) async {
    await _pump(tester, 1000);
    await _pump(tester, 1400);

    await tester.pump(const Duration(milliseconds: 200));
    final midway = tester.widget<Text>(find.byType(Text)).data!;
    expect(midway, isNot(r'+$1,000'), reason: 'the figure never left its old value');
    expect(midway, isNot(r'+$1,400'), reason: 'the figure jumped straight to the new value');

    await tester.pumpAndSettle();
    expect(find.text(r'+$1,400'), findsOneWidget);
  });

  testWidgets('counts down as well as up, so a loss is felt too', (tester) async {
    await _pump(tester, 1400);
    await _pump(tester, 900);
    await tester.pumpAndSettle();
    expect(find.text(r'+$900'), findsOneWidget);
  });

  testWidgets('signs negative figures', (tester) async {
    await _pump(tester, -250);
    expect(find.text(r'-$250'), findsOneWidget);
  });

  testWidgets('arrives immediately under reduced motion', (tester) async {
    await _pump(tester, 1000, reduceMotion: true);
    await _pump(tester, 1400, reduceMotion: true);
    await tester.pump();
    expect(find.text(r'+$1,400'), findsOneWidget);
  });
}
