import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/main.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/screens/table/hero_hand_area.dart';
import 'package:blackjack21_v2/screens/table/seat_plate.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';

/// A notifier seeded with a fixed state so table layouts can be pumped
/// directly, without driving the round through its timers.
class _FixedGameNotifier extends GameNotifier {
  _FixedGameNotifier(GameState initial) {
    state = initial;
  }
}

class _Device {
  final String name;
  final Size size;
  final double topPadding;
  final double bottomPadding;

  const _Device(this.name, this.size, {this.topPadding = 24, this.bottomPadding = 0});
}

/// Phone sizes the app realistically ships to, from the smallest still-supported
/// screen (iPhone SE 1 / small Androids) up to a tablet.
const List<_Device> _devices = [
  _Device('small-320x568', Size(320, 568), topPadding: 20),
  _Device('android-360x640', Size(360, 640)),
  _Device('android-360x800', Size(360, 800), bottomPadding: 24),
  _Device('iphone-375x812', Size(375, 812), topPadding: 44, bottomPadding: 34),
  _Device('iphone-390x844', Size(390, 844), topPadding: 47, bottomPadding: 34),
  _Device('design-393x852', Size(393, 852), topPadding: 47, bottomPadding: 34),
  _Device('android-412x915', Size(412, 915), topPadding: 40, bottomPadding: 24),
  _Device('foldable-540x720', Size(540, 720), topPadding: 40, bottomPadding: 24),
  _Device('tablet-800x1280', Size(800, 1280)),
];

const _stake = TableStake(
  key: 'bronze',
  name: 'Bronze Table',
  min: 25,
  max: 500,
  tint: Color(0xFF4FAE8E),
  tintDim: Color(0x264FAE8E),
);

GameState _base({
  required RoundPhase phase,
  List<PlayingCard> dealerHand = const [],
  bool holeRevealed = false,
  List<Hand> hands = const [Hand()],
  List<NpcSeat> npcSeats = const [],
  int bet = 0,
  bool chatOpen = false,
  int sweepAmount = 0,
  SweepInfo? sweepInfo,
  String message = '',
  MessageType messageType = MessageType.none,
}) {
  return GameState(
    screen: AppScreen.table,
    displayName: 'Guest',
    chips: 1150,
    stake: _stake,
    bet: bet,
    phase: phase,
    dealerHand: dealerHand,
    holeRevealed: holeRevealed,
    hands: hands,
    friends: kInitialFriends,
    npcSeats: npcSeats,
    actingSeat: phase == RoundPhase.npcs ? 1 : null,
    tableChatOpen: chatOpen,
    sweepAmount: sweepAmount,
    sweepInfo: sweepInfo,
    message: message,
    messageType: messageType,
    roundNet: 125,
    roundStake: 50,
    roundHandNet: 50,
  );
}

/// Four seats mid-round, mirroring the busiest real-world table: long chip
/// stacks, several cards each, and a status badge on every seat.
const List<NpcSeat> _busySeats = [
  NpcSeat(
    bet: 100,
    cards: [
      PlayingCard(rank: '3', suit: '♥'),
      PlayingCard(rank: 'A', suit: '♠'),
      PlayingCard(rank: 'J', suit: '♦'),
      PlayingCard(rank: '10', suit: '♣'),
    ],
    action: 'BUST',
    done: true,
  ),
  NpcSeat(
    bet: 100,
    cards: [
      PlayingCard(rank: '7', suit: '♥'),
      PlayingCard(rank: '7', suit: '♠'),
      PlayingCard(rank: 'K', suit: '♦'),
    ],
    action: 'BUST',
    done: true,
  ),
  NpcSeat(
    bet: 50,
    cards: [
      PlayingCard(rank: '5', suit: '♠'),
      PlayingCard(rank: 'Q', suit: '♣'),
      PlayingCard(rank: '4', suit: '♦'),
    ],
    action: 'STAND',
    done: true,
  ),
  NpcSeat(
    bet: 50,
    cards: [
      PlayingCard(rank: '6', suit: '♦'),
      PlayingCard(rank: 'J', suit: '♠'),
      PlayingCard(rank: '7', suit: '♥'),
    ],
    action: 'BUST',
    done: true,
  ),
];

const _heroPair = [PlayingCard(rank: 'A', suit: '♥'), PlayingCard(rank: '2', suit: '♠')];

Map<String, GameState> _scenarios() {
  return {
    'betting': _base(phase: RoundPhase.betting, bet: 100),
    'insurance': _base(
      phase: RoundPhase.insurance,
      bet: 100,
      dealerHand: const [
        PlayingCard(rank: 'A', suit: '♠'),
        PlayingCard(rank: '9', suit: '♦'),
      ],
      hands: const [Hand(cards: _heroPair, bet: 100)],
      npcSeats: _busySeats,
    ),
    'npcs-waiting': _base(
      phase: RoundPhase.npcs,
      bet: 100,
      dealerHand: const [
        PlayingCard(rank: '10', suit: '♠'),
        PlayingCard(rank: '9', suit: '♦'),
      ],
      hands: const [Hand(cards: _heroPair, bet: 100)],
      npcSeats: _busySeats,
    ),
    'playing': _base(
      phase: RoundPhase.playing,
      bet: 100,
      dealerHand: const [
        PlayingCard(rank: '10', suit: '♠'),
        PlayingCard(rank: '9', suit: '♦'),
      ],
      hands: const [Hand(cards: _heroPair, bet: 100)],
      npcSeats: _busySeats,
    ),
    'playing-split': _base(
      phase: RoundPhase.playing,
      bet: 100,
      dealerHand: const [
        PlayingCard(rank: '10', suit: '♠'),
        PlayingCard(rank: '9', suit: '♦'),
      ],
      hands: const [
        Hand(
          cards: [
            PlayingCard(rank: '8', suit: '♥'),
            PlayingCard(rank: '3', suit: '♠'),
            PlayingCard(rank: '5', suit: '♣'),
          ],
          bet: 100,
        ),
        Hand(
          cards: [
            PlayingCard(rank: '8', suit: '♦'),
            PlayingCard(rank: 'K', suit: '♠'),
          ],
          bet: 100,
        ),
      ],
      npcSeats: _busySeats,
    ),
    'playing-chat-open': _base(
      phase: RoundPhase.playing,
      bet: 100,
      chatOpen: true,
      dealerHand: const [
        PlayingCard(rank: '10', suit: '♠'),
        PlayingCard(rank: '9', suit: '♦'),
      ],
      hands: const [Hand(cards: _heroPair, bet: 100)],
      npcSeats: _busySeats,
    ),
    'dealer': _base(
      phase: RoundPhase.dealer,
      bet: 100,
      holeRevealed: true,
      dealerHand: const [
        PlayingCard(rank: '10', suit: '♠'),
        PlayingCard(rank: '9', suit: '♦'),
      ],
      hands: const [
        Hand(
          cards: [
            PlayingCard(rank: 'A', suit: '♥'),
            PlayingCard(rank: '2', suit: '♠'),
            PlayingCard(rank: '4', suit: '♣'),
          ],
          bet: 100,
        ),
      ],
      npcSeats: _busySeats,
    ),
    'settlement-sweep': _base(
      phase: RoundPhase.settlement,
      bet: 100,
      holeRevealed: true,
      dealerHand: const [
        PlayingCard(rank: '10', suit: '♠'),
        PlayingCard(rank: '9', suit: '♦'),
      ],
      hands: const [
        Hand(
          cards: [
            PlayingCard(rank: 'A', suit: '♥'),
            PlayingCard(rank: '2', suit: '♠'),
            PlayingCard(rank: '7', suit: '♣'),
          ],
          bet: 100,
          status: HandStatus.stood,
        ),
      ],
      npcSeats: _busySeats,
      sweepAmount: 300,
      message: 'You win the sweep pot',
      messageType: MessageType.win,
      sweepInfo: const SweepInfo(
        pot: 300,
        winnerBet: 100,
        totalWin: 400,
        winner: 'Guest',
        winnerTotal: 20,
        heroTook: true,
        contributors: [
          SweepContributor(name: 'Maya', amount: 100, reason: 'bust'),
          SweepContributor(name: 'Jordan', amount: 100, reason: 'bust'),
          SweepContributor(name: 'Priya', amount: 100, reason: 'lost'),
        ],
      ),
    ),
    // No seat forfeited a bet, so there is no sweep pot — the result panel
    // still has to show a pot-outcome row saying so.
    'settlement-no-sweep': _base(
      phase: RoundPhase.settlement,
      bet: 100,
      holeRevealed: true,
      dealerHand: const [
        PlayingCard(rank: '10', suit: '♠'),
        PlayingCard(rank: '7', suit: '♦'),
      ],
      hands: const [
        Hand(
          cards: [
            PlayingCard(rank: 'K', suit: '♠'),
            PlayingCard(rank: 'Q', suit: '♠'),
          ],
          bet: 100,
          status: HandStatus.stood,
        ),
      ],
      npcSeats: _busySeats,
      message: 'You win!',
      messageType: MessageType.win,
    ),
  };
}

/// Overflow errors carry the offending widget in their information collector;
/// surfacing it turns "overflowed by 4 pixels" into an actionable failure.
String _describe(Object? exception, List<FlutterErrorDetails> details) {
  if (exception == null) return '';
  final match = details.where((d) => identical(d.exception, exception));
  final source = match.isEmpty ? details : match;
  return source
      .map((d) => [d.exception, ...?d.informationCollector?.call().map((n) => n.toString())].join('\n'))
      .join('\n');
}

Future<List<FlutterErrorDetails>> _pumpTable(
  WidgetTester tester,
  GameState state,
  _Device device,
  double textScale,
) async {
  final details = <FlutterErrorDetails>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    details.add(d);
    previousOnError?.call(d);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  const dpr = 1.0;
  final padding = FakeViewPadding(top: device.topPadding * dpr, bottom: device.bottomPadding * dpr);
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = device.size * dpr
    ..padding = padding
    ..viewPadding = padding;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [gameProvider.overrideWith((ref) => _FixedGameNotifier(state))],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const BlackjackApp(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return details;
}

bool _overlaps(Rect a, Rect b) {
  const tolerance = 0.5;
  return a.deflate(tolerance).overlaps(b.deflate(tolerance));
}

bool _contains(Rect outer, Rect inner) {
  const tolerance = 0.5;
  return inner.left >= outer.left - tolerance &&
      inner.top >= outer.top - tolerance &&
      inner.right <= outer.right + tolerance &&
      inner.bottom <= outer.bottom + tolerance;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final scenarios = _scenarios();

  for (final device in _devices) {
    for (final textScale in <double>[1.0, 1.3]) {
      for (final entry in scenarios.entries) {
        final label = '${device.name} @${textScale}x ${entry.key}';

        testWidgets('$label lays out without overflow', (tester) async {
          final details = await _pumpTable(tester, entry.value, device, textScale);
          final exception = tester.takeException();
          expect(exception, isNull, reason: 'layout error on $label\n${_describe(exception, details)}');
        });

        // The showdown line is the comparison the result panel exists to
        // make, so it must never be the part of its row that gets sacrificed
        // — clipping it drops the dealer's total ("YOU 20 · DEALER …").
        // Widths here are measured in the test font, which is far wider than
        // the shipped mono, so the assertion is on the layout rule rather
        // than on absolute pixels: whenever the label does not fit, it must
        // still have been handed every pixel the card strip left behind.
        if (entry.key.startsWith('settlement')) {
          testWidgets('$label gives the showdown line all the room there is', (tester) async {
            await _pumpTable(tester, entry.value, device, textScale);
            expect(tester.takeException(), isNull);

            final showdown = find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').startsWith('YOU ') && w.data!.contains('DEALER'),
              description: 'showdown label',
            );
            expect(showdown, findsOneWidget, reason: 'no showdown label on $label');

            final paragraph = tester.renderObject<RenderParagraph>(showdown);
            if (!paragraph.didExceedMaxLines) return; // whole line visible

            final labelRect = tester.getRect(showdown);
            final rowRect = tester.getRect(find.ancestor(of: showdown, matching: find.byType(Row)).first);
            expect(
              labelRect.right,
              closeTo(rowRect.right, 0.5),
              reason: 'showdown label is clipped on $label while ${rowRect.right - labelRect.right}px '
                  'of its row sat unused: "${tester.widget<Text>(showdown).data}"',
            );
          });
        }

        testWidgets('$label keeps seats and hero hand apart', (tester) async {
          final details = await _pumpTable(tester, entry.value, device, textScale);
          final exception = tester.takeException();
          expect(exception, isNull, reason: _describe(exception, details));

          final screen = Rect.fromLTWH(0, 0, device.size.width, device.size.height);
          final seatFinder = find.byType(SeatPlate);
          final seatRects = <Rect>[
            for (var i = 0; i < seatFinder.evaluate().length; i++) tester.getRect(seatFinder.at(i)),
          ];

          for (var i = 0; i < seatRects.length; i++) {
            expect(
              _contains(screen, seatRects[i]),
              isTrue,
              reason: 'seat $i is off-screen on $label: ${seatRects[i]} vs $screen',
            );
            for (var j = i + 1; j < seatRects.length; j++) {
              expect(
                _overlaps(seatRects[i], seatRects[j]),
                isFalse,
                reason: 'seat $i overlaps seat $j on $label: ${seatRects[i]} vs ${seatRects[j]}',
              );
            }
          }

          final heroFinder = find.byType(HeroHandArea);
          if (heroFinder.evaluate().isNotEmpty) {
            final heroRect = tester.getRect(heroFinder);
            expect(
              _contains(screen, heroRect),
              isTrue,
              reason: 'hero hand is off-screen on $label: $heroRect vs $screen',
            );
            for (var i = 0; i < seatRects.length; i++) {
              expect(
                _overlaps(seatRects[i], heroRect),
                isFalse,
                reason: 'seat $i overlaps the hero hand on $label: ${seatRects[i]} vs $heroRect',
              );
            }
          }
        });
      }
    }
  }
}
