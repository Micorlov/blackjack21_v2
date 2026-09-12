import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/l10n/generated/app_localizations.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/screens/table_screen.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';
import 'package:blackjack21_v2/theme/app_theme.dart';
import 'package:blackjack21_v2/theme/app_text_styles.dart';

import 'support/real_fonts.dart';

class _FixedGame extends GameNotifier {
  _FixedGame(GameState initial) {
    state = initial;
  }
}

const _ten = PlayingCard(rank: '10', suit: '♠');
const _eight = PlayingCard(rank: '8', suit: '♥');
const _king = PlayingCard(rank: 'K', suit: '♦');
const _six = PlayingCard(rank: '6', suit: '♣');
GameState _scene(int index) {
  final sweep = index == 2;
  return GameState(
    screen: AppScreen.table,
    phase: sweep ? RoundPhase.settlement : RoundPhase.playing,
    displayName: 'Guest',
    languageOverride: 'en',
    chips: sweep ? 1175 : 975,
    stake: kTables.first,
    bet: 25,
    soundOn: false,
    voiceOn: false,
    hapticsOn: false,
    tutorialDismissed: index != 1,
    hands: [
      Hand(
        bet: 25,
        status: sweep ? HandStatus.stood : HandStatus.active,
        cards: [
          _ten,
          _eight,
          if (sweep) const PlayingCard(rank: '3', suit: '♥'),
        ],
      ),
    ],
    dealerHand: sweep ? [_king, _six, const PlayingCard(rank: '2', suit: '♠')] : [_six, _king],
    holeRevealed: sweep,
    npcSeats: const [
      NpcSeat(bet: 25, cards: [_king, _eight, _six], action: 'BUST', done: true),
      NpcSeat(bet: 25, cards: [_ten, _six], action: 'STAND', done: true),
      NpcSeat(bet: 50, cards: [_ten, _king, _six], action: 'BUST', done: true),
      NpcSeat(bet: 25, cards: [_king, _six], action: 'STAND', done: true),
    ],
    message: sweep ? 'You sweep the table' : '',
    messageType: sweep ? MessageType.win : MessageType.none,
    roundNet: sweep ? 175 : 0,
    roundStake: 25,
    roundHandNet: 25,
    sweepAmount: sweep ? 150 : 0,
    sweepInfo: sweep
        ? const SweepInfo(
            pot: 125,
            winnerBet: 25,
            totalWin: 150,
            winner: 'You',
            winnerTotal: 21,
            heroTook: true,
            contributors: [
              SweepContributor(name: 'Maya', amount: 25, reason: 'bust'),
              SweepContributor(name: 'Sam', amount: 50, reason: 'bust'),
              SweepContributor(name: 'Jordan', amount: 25, reason: 'lost'),
              SweepContributor(name: 'Priya', amount: 25, reason: 'lost'),
            ],
          )
        : null,
  );
}

void main() {
  const capture = bool.fromEnvironment('CAPTURE_STORE_SHOTS');
  setUpAll(() async {
    await loadRealTestFonts();
    SharedPreferences.setMockInitialValues({});
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in ['xyz.luan/audioplayers.global', 'xyz.luan/audioplayers.global/events']) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
    }
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async {
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        messenger.setMockMethodCallHandler(MethodChannel('xyz.luan/audioplayers/events/$id'), (_) async => null);
      }
      return null;
    });
  });
  testWidgets('capture real table widgets for staged English listing screenshots', (tester) async {
    tester.view.physicalSize = const Size(432, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey = GlobalKey();
    final l = lookupAppLocalizations(const Locale('en'));
    final captions = [l.shotBigCards, l.shotLearn, l.shotSweep];
    for (var i = 0; i < 3; i++) {
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(i),
          overrides: [gameProvider.overrideWith((ref) => _FixedGame(_scene(i)))],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: RepaintBoundary(
              key: boundaryKey,
              child: Scaffold(
                body: Column(
                  children: [
                    Container(
                      height: 84,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: const Color(0xFF081D16),
                      child: Text(
                        captions[i],
                        textAlign: TextAlign.center,
                        style: AppText.sora(30, weight: FontWeight.w700),
                      ),
                    ),
                    const Expanded(child: TableScreen()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('play-assets/big-cards/en-US/0${i + 1}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !capture);
}
