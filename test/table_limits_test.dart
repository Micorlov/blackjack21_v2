import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';

/// A notifier seeded with a fixed state so betting can be exercised without
/// driving a whole round through its timers.
class _FixedGameNotifier extends GameNotifier {
  _FixedGameNotifier(GameState initial) {
    state = initial;
  }
}

const _bronze = TableStake(
  key: 'bronze',
  name: 'Bronze Table',
  min: 25,
  max: 500,
  tint: Color(0xFF4FAE8E),
  tintDim: Color(0x264FAE8E),
);

const _vip = TableStake(
  key: 'vip',
  name: 'VIP Table',
  min: 500,
  max: 5000,
  tint: Color(0xFFE8C77A),
  tintDim: Color(0x26E8C77A),
);

GameState _bettingAt(TableStake stake) =>
    const GameState().copyWith(screen: AppScreen.table, stake: stake, phase: RoundPhase.betting, bet: 0, chips: 10000);

void main() {
  // GameNotifier builds a SoundPlayer, which needs the services binding and an
  // audioplayers plugin that does not exist in a unit test — stub it so the
  // plugin's async MissingPluginException cannot land on an unrelated test.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async => null);
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  group('chipDenomsFor', () {
    test('drops chips worth more than the table maximum', () {
      expect(chipDenomsFor(_bronze), [25, 50, 100, 500]);
    });

    test('keeps every chip when the table maximum is above them all', () {
      expect(chipDenomsFor(_vip), kChipDenoms);
    });

    test('falls back to the full tray when no table is joined', () {
      expect(chipDenomsFor(null), kChipDenoms);
    });

    test('never returns an empty tray', () {
      const tinyTable = TableStake(
        key: 'tiny',
        name: 'Tiny Table',
        min: 1,
        max: 5,
        tint: Color(0xFF4FAE8E),
        tintDim: Color(0x264FAE8E),
      );
      expect(chipDenomsFor(tinyTable), [kChipDenoms.first]);
    });
  });

  group('placeBet respects the table maximum', () {
    test('refuses a chip that would push the bet past the maximum', () {
      final notifier = _FixedGameNotifier(_bettingAt(_bronze));
      notifier.placeBet(500);
      notifier.placeBet(100);

      expect(notifier.state.bet, 500);
    });

    test('allows a bet that lands exactly on the maximum', () {
      final notifier = _FixedGameNotifier(_bettingAt(_bronze));
      notifier.placeBet(100);
      notifier.placeBet(300);
      notifier.placeBet(100);

      expect(notifier.state.bet, 500);
    });
  });

  group('dealRound respects the table minimum', () {
    test('does not deal below the table minimum', () {
      final notifier = _FixedGameNotifier(_bettingAt(_vip).copyWith(bet: 100));
      notifier.dealRound();

      expect(notifier.state.phase, RoundPhase.betting);
      expect(notifier.state.hands.first.cards, isEmpty);
    });

    test('deals once the bet reaches the table minimum', () {
      final notifier = _FixedGameNotifier(_bettingAt(_vip).copyWith(bet: 500));
      notifier.dealRound();

      expect(notifier.state.phase, isNot(RoundPhase.betting));
    });
  });
}
