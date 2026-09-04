import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/l10n/generated/app_localizations.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/screens/friends_screen.dart';
import 'package:blackjack21_v2/screens/onboarding_screen.dart';
import 'package:blackjack21_v2/screens/settings_screen.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';
import 'package:blackjack21_v2/theme/app_theme.dart';

/// Cover for the two Phase 4 defects that had no test at all: the legal
/// documents the onboarding consent line promised but never linked to, and
/// practice bots being presented as real friends.
class _FixedGameNotifier extends GameNotifier {
  _FixedGameNotifier(GameState initial) {
    state = initial;
  }
}

Widget _wrap(GameState state, Widget screen) {
  return ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _FixedGameNotifier(state))],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: screen),
    ),
  );
}

const _liveFriends = [Friend(id: 'f1', name: 'Dana', chips: 2400, online: true, dailyScore: 300, hourlyScore: 90)];

void main() {
  
  group('legal documents', () {
    testWidgets('onboarding links the consent line to the Terms', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: OnboardingScreen(isWeb: false))));

      expect(find.textContaining('By continuing you agree'), findsOneWidget);
      await tester.ensureVisible(find.text('Terms'));
      await tester.tap(find.text('Terms'));
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('This is a game, not gambling'), findsOneWidget);
    });

    testWidgets('onboarding links the consent line to the Privacy Policy', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: OnboardingScreen(isWeb: false))));

      await tester.ensureVisible(find.text('Privacy'));
      await tester.tap(find.text('Privacy'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('No advertising or analytics'), findsOneWidget);
    });

    testWidgets('settings offers both documents and the build version', (tester) async {
      await tester.pumpWidget(_wrap(const GameState(screen: AppScreen.settings), const SettingsScreen()));

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
    });
  });

  group('friends are only friends when they are live', () {
    testWidgets('seeded practice bots are not listed, and cannot be gifted', (tester) async {
      await tester.pumpWidget(
        _wrap(const GameState(screen: AppScreen.friends, friends: kInitialFriends, chips: 5000), const FriendsScreen()),
      );

      // kInitialFriends is the practice-bot roster.
      expect(find.text(kInitialFriends.first.name), findsNothing);
      expect(find.text('Gift 100'), findsNothing);
      expect(find.text('No friends in your group yet'), findsOneWidget);
    });

    testWidgets('real group members are listed with their gift action', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GameState(screen: AppScreen.friends, friends: _liveFriends, friendsAreLive: true, chips: 5000),
          const FriendsScreen(),
        ),
      );

      // Once in the leaderboard, once in the friends list.
      expect(find.text('Dana'), findsNWidgets(2));
      expect(find.text('Gift 100'), findsOneWidget);
      expect(find.text('No friends in your group yet'), findsNothing);
    });
  });
}
