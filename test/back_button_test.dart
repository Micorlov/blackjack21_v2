import 'package:blackjack21_v2/main.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Android Back, for every screen.
///
/// Navigation is an enum on the state rather than a `Navigator` stack, so
/// there is nothing for the framework to pop and Back closed the app from
/// wherever the player was. It was fixed on the table first — and that left
/// the identical trap on every other full-screen surface, which is how a real
/// device found it: backing out of the Weekend Cup quit the game.
///
/// These tests exist because nothing here was covered. A screen added to
/// [AppScreen] without a Back rule should fail this file, not ship.
void main() {
  /// Presses the system Back button.
  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  // The notifier is owned by the ProviderScope and disposed with the tree —
  // disposing it here as well throws "Tried to use GameNotifier after dispose".
  Future<GameNotifier> pumpAppOn(WidgetTester tester, AppScreen screen) async {
    late GameNotifier notifier;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            notifier = ref.read(gameProvider.notifier);
            return const BlackjackApp();
          },
        ),
      ),
    );
    await tester.pump();
    notifier.state = notifier.state.copyWith(screen: screen);
    await tester.pumpAndSettle();
    return notifier;
  }

  for (final screen in <AppScreen>[
    AppScreen.cup,
    AppScreen.stats,
    AppScreen.friends,
    AppScreen.shop,
    AppScreen.settings,
  ]) {
    testWidgets('back from ${screen.name} returns to the lobby', (tester) async {
      final notifier = await pumpAppOn(tester, screen);

      await pressBack(tester);

      expect(
        notifier.state.screen,
        AppScreen.lobby,
        reason: 'Back on ${screen.name} must return to the lobby, not quit the '
            'app — there is no Navigator stack to fall back on',
      );
    });
  }

  testWidgets('back from the table leaves the table', (tester) async {
    final notifier = await pumpAppOn(tester, AppScreen.table);

    await pressBack(tester);

    expect(notifier.state.screen, AppScreen.lobby);
    expect(
      notifier.state.actingSeat,
      isNull,
      reason: 'leaving must go through exitTable, which also cancels the '
          "round's timers — not a bare screen change",
    );
  });

  testWidgets('back peels the chat sheet before leaving the table',
      (tester) async {
    final notifier = await pumpAppOn(tester, AppScreen.table);
    notifier.state = notifier.state.copyWith(tableChatOpen: true);
    await tester.pumpAndSettle();

    await pressBack(tester);

    expect(notifier.state.tableChatOpen, isFalse);
    expect(
      notifier.state.screen,
      AppScreen.table,
      reason: 'one press closes one layer; the player stays at the table',
    );
  });

  testWidgets('back closes an open story before anything else', (tester) async {
    final notifier = await pumpAppOn(tester, AppScreen.lobby);
    notifier.state = notifier.state.copyWith(activeStoryId: 'maya');
    await tester.pumpAndSettle();

    await pressBack(tester);

    expect(notifier.state.activeStoryId, isNull);
  });
}
