import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/main.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/screens/table/dealer_area.dart';
import 'package:blackjack21_v2/screens/table/hero_hand_area.dart';
import 'package:blackjack21_v2/screens/table/seat_plate.dart';
import 'package:blackjack21_v2/screens/table/table_settlement_panel.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';
import 'package:blackjack21_v2/widgets/playing_card_widget.dart';

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
///
/// `web-zoom-323x560` is not a device: it is the *canvas* `WebViewportScaler`
/// hands the app inside a 430x745 phone browser (an iPhone 15 Pro Max in
/// Safari) once its legibility zoom is applied. The zoom buys larger text by
/// shrinking the canvas, so the canvas has to be covered here exactly like a
/// real screen size — it is shorter than any physical device in this list.
const List<_Device> _devices = [
  _Device('web-zoom-323x560', Size(323, 560), topPadding: 20),
  _Device('small-320x568', Size(320, 568), topPadding: 20),
  _Device('android-360x640', Size(360, 640)),
  _Device('android-360x800', Size(360, 800), bottomPadding: 24),
  _Device('iphone-375x812', Size(375, 812), topPadding: 44, bottomPadding: 34),
  _Device('iphone-390x844', Size(390, 844), topPadding: 47, bottomPadding: 34),
  _Device('design-393x852', Size(393, 852), topPadding: 47, bottomPadding: 34),
  // The phone the game is tuned on (a 1080x2340 Samsung at 450dpi), with a
  // three-button navigation bar — the felt budget is sized so this device
  // draws every phase at full scale.
  _Device('galaxy-384x832', Size(384, 832), topPadding: 40, bottomPadding: 48),
  _Device('android-412x915', Size(412, 915), topPadding: 40, bottomPadding: 24),
  _Device('foldable-540x720', Size(540, 720), topPadding: 40, bottomPadding: 24),
  _Device('tablet-800x1280', Size(800, 1280)),

  // Landscape and large screens.
  //
  // These were the 2026-09-03 redesign's largest rewrite — the felt's fixed
  // 393px canvas became a constraint-driven layout with a side rail — and for
  // a while they were also its least tested: the work was checked once by a
  // throwaway probe and then had no coverage at all, which is no coverage.
  // Nothing locks orientation, so every one of these is reachable by simply
  // turning the phone.
  //
  // Landscape padding is asymmetric on purpose: the notch and the gesture bar
  // move to the sides, and the side rail is exactly where they land.
  _Device('landscape-640x360', Size(640, 360), topPadding: 0, bottomPadding: 24),
  _Device('landscape-812x375', Size(812, 375), topPadding: 0, bottomPadding: 21),
  _Device('landscape-915x412', Size(915, 412), topPadding: 0, bottomPadding: 24),
  _Device('landscape-780x360', Size(780, 360), topPadding: 0, bottomPadding: 24),
  _Device('tablet-landscape-1280x800', Size(1280, 800)),
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
    // The dealer drawing out is the case that broke on device: five cards,
    // the "TABLE SWEEP" banner above them, and the two upper seat plates
    // directly below. The cluster was taller than the band reserved for it, so
    // the dealer's cards were painted over the seats and their fans.
    'settlement-long-dealer': _base(
      phase: RoundPhase.settlement,
      bet: 100,
      holeRevealed: true,
      dealerHand: const [
        PlayingCard(rank: 'A', suit: '♦'),
        PlayingCard(rank: '4', suit: '♥'),
        PlayingCard(rank: '2', suit: '♣'),
        PlayingCard(rank: '9', suit: '♥'),
        PlayingCard(rank: '9', suit: '♠'),
      ],
      hands: const [
        Hand(
          cards: [
            PlayingCard(rank: '9', suit: '♠'),
            PlayingCard(rank: 'Q', suit: '♥'),
          ],
          bet: 100,
          status: HandStatus.stood,
        ),
      ],
      npcSeats: _busySeats,
      sweepAmount: 100,
      message: 'Sweep pot: yours',
      messageType: MessageType.win,
      sweepInfo: const SweepInfo(
        pot: 100,
        winnerBet: 100,
        totalWin: 200,
        winner: 'Guest',
        winnerTotal: 19,
        heroTook: true,
        contributors: [SweepContributor(name: 'Priya', amount: 100, reason: 'bust')],
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

        // The dealer's cards and the seat plates share the top half of the
        // felt. The band reserved for the dealer used to be 164 canvas units
        // against a cluster that needs ~178 — ~220 once the sweep banner
        // appears — so from the fourth dealer card onward the cards were drawn
        // straight over the two upper seats.
        testWidgets('$label keeps the dealer cards clear of the seats', (tester) async {
          final details = await _pumpTable(tester, entry.value, device, textScale);
          final exception = tester.takeException();
          expect(exception, isNull, reason: _describe(exception, details));

          final cardFinder = find.descendant(
            of: find.byType(DealerArea),
            matching: find.byType(PlayingCardFace),
          );
          if (cardFinder.evaluate().isEmpty) return;

          // Measured as a share of the card, not as "touches at all": a seat's
          // box is its slot, including the empty strip its own card fan sits
          // in, so the dealer's bottom edge has always kissed the top of that
          // strip by a pixel or two by design. What broke was a card sitting
          // squarely on a plate, which is a fifth of the card or more.
          const tolerance = 0.05;
          final seatFinder = find.byType(SeatPlate);
          for (var c = 0; c < cardFinder.evaluate().length; c++) {
            final cardRect = tester.getRect(cardFinder.at(c));
            final cardArea = cardRect.width * cardRect.height;
            for (var i = 0; i < seatFinder.evaluate().length; i++) {
              final seatRect = tester.getRect(seatFinder.at(i));
              final overlap = cardRect.intersect(seatRect);
              if (overlap.isEmpty) continue;
              final share = (overlap.width * overlap.height) / cardArea;
              expect(
                share,
                lessThan(tolerance),
                reason: 'dealer card $c covers ${(share * 100).toStringAsFixed(0)}% of seat $i on '
                    '$label: $cardRect vs $seatRect',
              );
            }
          }
        });

        // Every seat shows the hand it is playing, beside its name, at a size
        // a player can actually read — the fan used to be 27x38 cards above
        // the plate, drawn at about 7px of rank once the felt scaled down.
        if (entry.key == 'playing') {
          testWidgets('$label shows each bot hand beside its name', (tester) async {
            await _pumpTable(tester, entry.value, device, textScale);
            expect(tester.takeException(), isNull);

            final seats = find.byType(SeatPlate);
            // `_busySeats`: seat 0 holds four cards, seat 2 stands on 19.
            expect(
              find.descendant(of: seats.at(0), matching: find.byType(PlayingCardFace)),
              findsNWidgets(4),
              reason: 'seat 0 is not showing its hand on $label',
            );
            expect(find.descendant(of: seats.at(2), matching: find.text('STAND')), findsOneWidget);
            expect(find.descendant(of: seats.at(2), matching: find.text('19')), findsOneWidget);
            // Mid-round with nothing forfeited there is no pot to announce.
            expect(find.text('NO SWEEP POT'), findsNothing, reason: 'the empty pot pill is back on $label');
          });
        }

        // A seat's cards are the point of showing them, so they must not be
        // shrunk into illegibility by the felt's own scale.
        if (device.name == 'galaxy-384x832' && textScale == 1.0 && entry.key == 'playing') {
          testWidgets('$label draws the bot hands large enough to read', (tester) async {
            await _pumpTable(tester, entry.value.copyWith(tutorialDismissed: true), device, textScale);
            expect(tester.takeException(), isNull);

            // Seat 2 holds three cards, the common mid-round hand. A longer
            // hand scales the whole fan down rather than overlapping it
            // tighter, so it draws smaller — but never below the floor every
            // seat is checked against.
            final seats = find.byType(SeatPlate);
            final threeCardHand = find.descendant(of: seats.at(2), matching: find.byType(PlayingCardFace));
            expect(tester.getRect(threeCardHand.first).width, greaterThanOrEqualTo(36));

            final every = find.descendant(of: find.byType(SeatPlate), matching: find.byType(PlayingCardFace));
            for (var i = 0; i < every.evaluate().length; i++) {
              final width = tester.getRect(every.at(i)).width;
              expect(width, greaterThanOrEqualTo(28), reason: 'a bot card is only ${width}px wide on $label');
            }
          });
        }

        // The felt is scaled to fit the height it is given, and on the target
        // phone the play phase used to fit only at ~0.65 — every card and
        // figure at two-thirds size for the whole hand. The band budget in
        // `FeltMetrics` is sized so that phone draws the hand near full size.
        if (device.name == 'galaxy-384x832' && textScale == 1.0 && entry.key == 'playing') {
          testWidgets('$label draws the hero cards at full size', (tester) async {
            // Measured once the first-run coach card is gone: that card sits
            // above the action panel for the first three hands only, and
            // takes ~100px of felt while it does.
            await _pumpTable(tester, entry.value.copyWith(tutorialDismissed: true), device, textScale);
            expect(tester.takeException(), isNull);

            final heroCard = find.descendant(of: find.byType(HeroHandArea), matching: find.byType(PlayingCardFace));
            expect(heroCard, findsWidgets);
            final width = tester.getRect(heroCard.first).width;
            expect(width, greaterThanOrEqualTo(0.9 * 66), reason: 'hero card drawn at ${width}px on $label');
          });
        }

        // The result card is bottom-anchored and scrolls, so content taller
        // than its cap loses its *top* — which is where the outcome is
        // written. On the target phone at the largest text the app allows,
        // the whole card has to fit.
        if (device.name == 'galaxy-384x832' && entry.key.startsWith('settlement')) {
          testWidgets('$label keeps the result headline on screen', (tester) async {
            await _pumpTable(tester, entry.value, device, textScale);
            expect(tester.takeException(), isNull);

            final screen = Rect.fromLTWH(0, 0, device.size.width, device.size.height);
            // The card's own headline, by its serif face: the same words can
            // also appear inside the pot-detail row below it.
            final message = find.descendant(
              of: find.byType(TableSettlementPanel),
              matching: find.byWidgetPredicate(
                (w) => w is Text && w.data == entry.value.message && w.style?.fontFamily == 'Instrument Serif',
                description: 'result headline',
              ),
            );
            expect(message, findsOneWidget, reason: 'no outcome message on $label');
            final rect = tester.getRect(message);
            expect(
              _contains(screen, rect),
              isTrue,
              reason: 'the outcome message is cut off on $label: $rect vs $screen',
            );
          });
        }

        if (entry.key == 'settlement-no-sweep') {
          testWidgets('$label still names the pot outcome once settled', (tester) async {
            await _pumpTable(tester, entry.value, device, textScale);
            expect(tester.takeException(), isNull);
            expect(find.text('NO SWEEP'), findsOneWidget);
          });
        }

        // The four seats read as two columns, so the pair on each side has to
        // share one vertical edge. A plate that shrinks inside its slot
        // collapses toward the slot's origin, and a seat anchored to the wrong
        // origin drifts inward — leaving one plate visibly indented from the
        // one above it.
        testWidgets("$label keeps each side's seats in one straight column", (tester) async {
          final details = await _pumpTable(tester, entry.value, device, textScale);
          final exception = tester.takeException();
          expect(exception, isNull, reason: _describe(exception, details));

          final seatFinder = find.byType(SeatPlate);
          final seatRects = <Rect>[
            for (var i = 0; i < seatFinder.evaluate().length; i++) tester.getRect(seatFinder.at(i)),
          ];
          if (seatRects.length < 4) return;

          // Seats alternate left, right, left, right (`rightSide: i.isOdd`).
          expect(
            seatRects[2].left,
            closeTo(seatRects[0].left, 0.5),
            reason: 'left-hand seats are out of line on $label: ${seatRects[0]} vs ${seatRects[2]}',
          );
          expect(
            seatRects[3].right,
            closeTo(seatRects[1].right, 0.5),
            reason: 'right-hand seats are out of line on $label: ${seatRects[1]} vs ${seatRects[3]}',
          );
        });
      }
    }
  }
}
