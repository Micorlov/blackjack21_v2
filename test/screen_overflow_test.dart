import 'package:flutter/material.dart';
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
import 'package:blackjack21_v2/state/game_notifier.dart';
import 'package:blackjack21_v2/utils/points.dart';
import 'package:blackjack21_v2/widgets/daily_bonus_dialog.dart';
import 'package:blackjack21_v2/widgets/how_to_play_sheet.dart';

import 'support/real_fonts.dart';

/// Whole-app layout sweep: every screen and overlay, on every phone size the
/// app ships to, at both text scales the app allows — asserting nothing
/// overflows its box.
///
/// `table_layout_test.dart` does this for the felt; this file covers
/// everything else, and adds the data that test cannot: real display names run
/// as long as a Google account allows, real bankrolls reach seven figures, and
/// both land in rows laid out around "Guest" and "$1,150".
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

const List<_Device> _devices = [
  _Device('small-320x568', Size(320, 568), topPadding: 20),
  _Device('android-360x640', Size(360, 640)),
  _Device('iphone-390x844', Size(390, 844), topPadding: 47, bottomPadding: 34),
  _Device('android-412x915', Size(412, 915), topPadding: 40, bottomPadding: 24),
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

/// A name the length a real Google account hands the app — every practice bot
/// is a "Maya T.", so nothing in the built-in data stresses a row.
const _longName = 'Michaelangelo Rosenberg-Castellanos';

const List<Friend> _longNamedFriends = [
  Friend(
    id: 'f1',
    name: 'Alexandra Konstantinopoulos',
    chips: 1284500,
    online: true,
    dailyScore: 184320,
    hourlyScore: 45210,
  ),
  Friend(
    id: 'f2',
    name: 'Bartholomew Fitzgerald-Wright',
    chips: 982400,
    online: true,
    dailyScore: -121080,
    hourlyScore: 80640,
  ),
  Friend(id: 'f3', name: 'Sam R.', chips: 990, online: false, dailyScore: -60, hourlyScore: 15),
  Friend(
    id: 'f4',
    name: 'Priyadarshini Venkataraman',
    chips: 3120450,
    online: false,
    dailyScore: 540900,
    hourlyScore: 0,
  ),
];

GameState _state({
  required AppScreen screen,
  String displayName = 'Guest',
  int chips = 1150,
  List<Friend> friends = kInitialFriends,
  bool friendsAreLive = false,
  List<Friend> globalHourly = const [],
  List<Friend> globalDaily = const [],
  StatsTab statsTab = StatsTab.recent,
  LeaderboardPeriod leaderboardPeriod = LeaderboardPeriod.alltime,
  StatsSummary stats = const StatsSummary(),
  SessionSummary session = const SessionSummary(),
  List<RoundResult> history = const [],
  DateTime? lastDailyBonusClaimAt,
  int dailyBonusStreakDay = 0,
  bool tournamentJoined = false,
  int referralsCount = 0,
  List<String> claimedTiers = const [],
  String toast = '',
  String? groupCode,
  String? activeStoryId,
  int heroHourlyPoints = 0,
  int heroDailyPoints = 0,
  bool signedIn = false,
  RoundPhase phase = RoundPhase.betting,
  int bet = 0,
  List<Hand> hands = const [Hand()],
  List<NpcSeat> npcSeats = const [],
  List<PlayingCard> dealerHand = const [],
  bool holeRevealed = false,
  bool tableChatOpen = false,
  bool tableMenuOpen = false,
  List<ChatMessage> chatMessages = const [],
  SweepInfo? sweepInfo,
  int sweepAmount = 0,
  String message = '',
  MessageType messageType = MessageType.none,
  int roundNet = 0,
  int roundStake = 0,
  int roundHandNet = 0,
  int tutorialRoundsSeen = 0,
  bool tutorialDismissed = true,
}) {
  final now = DateTime.now();
  return GameState(
    screen: screen,
    signedIn: signedIn,
    displayName: displayName,
    chips: chips,
    stake: screen == AppScreen.table ? _stake : null,
    bet: bet,
    phase: phase,
    hands: hands,
    npcSeats: npcSeats,
    friends: friends,
    friendsAreLive: friendsAreLive,
    globalHourly: globalHourly,
    globalDaily: globalDaily,
    statsTab: statsTab,
    leaderboardPeriod: leaderboardPeriod,
    stats: stats,
    session: session,
    history: history,
    lastDailyBonusClaimAt: lastDailyBonusClaimAt,
    dailyBonusStreakDay: dailyBonusStreakDay,
    tipsSeen: true,
    tournamentJoined: tournamentJoined,
    referralsCount: referralsCount,
    claimedTiers: claimedTiers,
    toast: toast,
    groupCode: groupCode,
    activeStoryId: activeStoryId,
    heroHourlyPoints: heroHourlyPoints,
    heroDailyPoints: heroDailyPoints,
    heroHourKey: hourKeyOf(now),
    heroDayKey: dayKeyOf(now),
    dealerHand: dealerHand,
    holeRevealed: holeRevealed,
    tableChatOpen: tableChatOpen,
    tableMenuOpen: tableMenuOpen,
    chatMessages: chatMessages,
    sweepInfo: sweepInfo,
    sweepAmount: sweepAmount,
    message: message,
    messageType: messageType,
    roundNet: roundNet,
    roundStake: roundStake,
    roundHandNet: roundHandNet,
    actingSeat: phase == RoundPhase.npcs ? 1 : null,
    tutorialRoundsSeen: tutorialRoundsSeen,
    tutorialDismissed: tutorialDismissed,
  );
}

const _heroPair = [PlayingCard(rank: 'A', suit: '♥'), PlayingCard(rank: '2', suit: '♠')];

/// Four seats mid-round: several cards each and a status badge on every seat.
const List<NpcSeat> _busySeats = [
  NpcSeat(
    bet: 100,
    cards: [PlayingCard(rank: '3', suit: '♥'), PlayingCard(rank: 'A', suit: '♠'), PlayingCard(rank: 'J', suit: '♦')],
    action: 'BUST',
    done: true,
  ),
  NpcSeat(
    bet: 100,
    cards: [PlayingCard(rank: '7', suit: '♥'), PlayingCard(rank: '7', suit: '♠'), PlayingCard(rank: 'K', suit: '♦')],
    action: 'BUST',
    done: true,
  ),
  NpcSeat(
    bet: 50,
    cards: [PlayingCard(rank: '5', suit: '♠'), PlayingCard(rank: 'Q', suit: '♣')],
    action: 'STAND',
    done: true,
  ),
  NpcSeat(
    bet: 50,
    cards: [PlayingCard(rank: '6', suit: '♦'), PlayingCard(rank: 'J', suit: '♠')],
    action: 'STAND',
    done: true,
  ),
];

const _bigStats = StatsSummary(
  handsPlayed: 12480,
  wins: 6210,
  losses: 5900,
  pushes: 370,
  blackjacks: 842,
  currentStreak: 7,
  bestStreak: 19,
);

const _history = [
  RoundResult.win,
  RoundResult.loss,
  RoundResult.push,
  RoundResult.win,
  RoundResult.win,
  RoundResult.loss,
  RoundResult.win,
  RoundResult.loss,
];

/// Every screen the shell can show, in both a fresh-install shape and a
/// long-running-account shape (long names, seven-figure bankrolls, full
/// history, claimed rewards).
Map<String, GameState> _scenarios() {
  final claimedAt = DateTime.now().subtract(const Duration(hours: 3));

  return {
    'onboarding': _state(screen: AppScreen.onboarding),
    'tips': _state(screen: AppScreen.tips),

    'lobby-fresh': _state(screen: AppScreen.lobby),
    'lobby-bonus-cooldown': _state(
      screen: AppScreen.lobby,
      lastDailyBonusClaimAt: claimedAt,
      dailyBonusStreakDay: 6,
    ),
    'lobby-loaded': _state(
      screen: AppScreen.lobby,
      displayName: _longName,
      signedIn: true,
      chips: 1284500,
      friends: _longNamedFriends,
      friendsAreLive: true,
      stats: _bigStats,
      session: const SessionSummary(hands: 240, wins: 131, net: -184320),
      history: _history,
      heroHourlyPoints: 45210,
      heroDailyPoints: 184320,
      groupCode: 'A1B2C3',
    ),

    'stats-recent': _state(screen: AppScreen.stats, history: _history, stats: _bigStats),
    'stats-alltime': _state(
      screen: AppScreen.stats,
      statsTab: StatsTab.alltime,
      stats: _bigStats,
      history: _history,
      chips: 1284500,
      displayName: _longName,
      session: const SessionSummary(hands: 240, wins: 131, net: -184320),
    ),
    'stats-achievements': _state(
      screen: AppScreen.stats,
      statsTab: StatsTab.achievements,
      stats: _bigStats,
      chips: 1284500,
      referralsCount: 5,
    ),

    'friends-fresh': _state(screen: AppScreen.friends),
    'friends-loaded': _state(
      screen: AppScreen.friends,
      displayName: _longName,
      chips: 1284500,
      friends: _longNamedFriends,
      friendsAreLive: true,
      groupCode: 'A1B2C3',
      referralsCount: 5,
      claimedTiers: const ['r1', 'r3'],
      leaderboardPeriod: LeaderboardPeriod.hourly,
      heroHourlyPoints: 45210,
      heroDailyPoints: 184320,
    ),

    'shop': _state(screen: AppScreen.shop, chips: 1284500, displayName: _longName),
    'settings-guest': _state(screen: AppScreen.settings),
    'settings-signed-in': _state(
      screen: AppScreen.settings,
      signedIn: true,
      displayName: _longName,
      chips: 1284500,
    ),

    'cup-open': _state(screen: AppScreen.cup, friends: _longNamedFriends, friendsAreLive: true),
    'cup-joined': _state(
      screen: AppScreen.cup,
      tournamentJoined: true,
      displayName: _longName,
      friends: _longNamedFriends,
      friendsAreLive: true,
      heroDailyPoints: 184320,
      chips: 1284500,
    ),

    // The felt with real people at it. `table_layout_test.dart` covers every
    // round phase, but only ever with "Guest" and the built-in bots — these
    // put invited friends' full names on the seats, in the chat and in the
    // sweep-pot result.
    'table-betting-live': _state(
      screen: AppScreen.table,
      displayName: _longName,
      chips: 1284500,
      friends: _longNamedFriends,
      friendsAreLive: true,
      globalHourly: _longNamedFriends,
      globalDaily: _longNamedFriends,
      bet: 100,
      npcSeats: _busySeats,
      heroHourlyPoints: 45210,
      heroDailyPoints: 184320,
    ),
    'table-chat-live': _state(
      screen: AppScreen.table,
      displayName: _longName,
      friends: _longNamedFriends,
      friendsAreLive: true,
      phase: RoundPhase.playing,
      bet: 100,
      hands: const [Hand(cards: _heroPair, bet: 100)],
      npcSeats: _busySeats,
      dealerHand: const [PlayingCard(rank: '10', suit: '♠'), PlayingCard(rank: '9', suit: '♦')],
      tableChatOpen: true,
      chatMessages: const [
        ChatMessage(id: 1, name: 'Alexandra Konstantinopoulos', text: 'Dealer luck'),
        ChatMessage(id: 2, name: 'You', text: 'One more'),
        ChatMessage(id: 3, name: 'Bartholomew Fitzgerald-Wright', text: 'GG'),
      ],
    ),
    'table-menu-open': _state(
      screen: AppScreen.table,
      displayName: _longName,
      friends: _longNamedFriends,
      friendsAreLive: true,
      bet: 100,
      npcSeats: _busySeats,
      tableMenuOpen: true,
    ),
    'table-tutorial': _state(
      screen: AppScreen.table,
      phase: RoundPhase.playing,
      bet: 100,
      hands: const [Hand(cards: _heroPair, bet: 100)],
      npcSeats: _busySeats,
      dealerHand: const [PlayingCard(rank: '10', suit: '♠'), PlayingCard(rank: '9', suit: '♦')],
      tutorialDismissed: false,
    ),
    'table-settlement-live': _state(
      screen: AppScreen.table,
      displayName: _longName,
      chips: 1284500,
      friends: _longNamedFriends,
      friendsAreLive: true,
      phase: RoundPhase.settlement,
      bet: 100,
      holeRevealed: true,
      dealerHand: const [PlayingCard(rank: '10', suit: '♠'), PlayingCard(rank: '9', suit: '♦')],
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
      message: 'Konstantinopoulos wins the sweep pot',
      messageType: MessageType.lose,
      roundNet: -100,
      roundStake: 100,
      roundHandNet: -100,
      // The felt names seats by first name only (`Friend.firstName`), so the
      // stress here is a long *single-word* display name — which is exactly
      // what a one-word Google account name gives every one of these rows.
      sweepInfo: const SweepInfo(
        pot: 300,
        winnerBet: 100,
        totalWin: 400,
        winner: 'Konstantinopoulos',
        winnerTotal: 20,
        heroTook: false,
        contributors: [
          SweepContributor(name: 'Michaelangelo', amount: 100, reason: 'bust'),
          SweepContributor(name: 'Bartholomew', amount: 100, reason: 'bust'),
          SweepContributor(name: 'Priyadarshini', amount: 100, reason: 'lost'),
        ],
      ),
    ),

    // Overlays that sit on top of whatever screen is showing.
    'lobby-toast': _state(
      screen: AppScreen.lobby,
      displayName: _longName,
      friends: _longNamedFriends,
      toast: 'Bartholomew Fitzgerald-Wright just passed you on the hourly leaderboard',
    ),
    'lobby-story': _state(screen: AppScreen.lobby, activeStoryId: kStoriesData.first.id),
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

List<FlutterErrorDetails> _captureErrors() {
  final details = <FlutterErrorDetails>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    details.add(d);
    previousOnError?.call(d);
  };
  addTearDown(() => FlutterError.onError = previousOnError);
  return details;
}

void _sizeTo(WidgetTester tester, _Device device) {
  const dpr = 1.0;
  final padding = FakeViewPadding(top: device.topPadding * dpr, bottom: device.bottomPadding * dpr);
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = device.size * dpr
    ..padding = padding
    ..viewPadding = padding;
  addTearDown(tester.view.reset);
}

Future<List<FlutterErrorDetails>> _pumpScreen(
  WidgetTester tester,
  GameState state,
  _Device device,
  double textScale,
) async {
  final details = _captureErrors();
  _sizeTo(tester, device);

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

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadRealTestFonts();
  });

  final scenarios = _scenarios();

  for (final device in _devices) {
    for (final textScale in <double>[1.0, 1.3]) {
      for (final entry in scenarios.entries) {
        final label = '${device.name} @${textScale}x ${entry.key}';

        testWidgets('$label lays out without overflow', (tester) async {
          final details = await _pumpScreen(tester, entry.value, device, textScale);
          final exception = tester.takeException();
          expect(exception, isNull, reason: 'layout error on $label\n${_describe(exception, details)}');
        });
      }

      // Surfaces that only exist after a tap, so seeding state cannot reach
      // them.
      testWidgets('${device.name} @${textScale}x daily-bonus dialog lays out without overflow', (tester) async {
        final details = await _pumpScreen(
          tester,
          _state(screen: AppScreen.lobby, displayName: _longName, chips: 1284500, dailyBonusStreakDay: 6),
          device,
          textScale,
        );
        expect(tester.takeException(), isNull);

        final context = tester.element(find.byType(Scaffold).first);
        showDailyBonusDialog(context).ignore();
        await tester.pumpAndSettle();

        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'daily-bonus dialog overflows on ${device.name} @${textScale}x\n${_describe(exception, details)}',
        );
      });

      testWidgets('${device.name} @${textScale}x how-to-play sheet lays out without overflow', (tester) async {
        final details = await _pumpScreen(
          tester,
          _state(screen: AppScreen.settings, displayName: _longName),
          device,
          textScale,
        );
        expect(tester.takeException(), isNull);

        final context = tester.element(find.byType(Scaffold).first);
        showHowToPlaySheet(context).ignore();
        await tester.pumpAndSettle();

        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'how-to-play sheet overflows on ${device.name} @${textScale}x\n${_describe(exception, details)}',
        );
      });

      // The full standings list, reached by tapping the table's mini
      // standings card.
      testWidgets('${device.name} @${textScale}x world standings lays out without overflow', (tester) async {
        final details = await _pumpScreen(
          tester,
          _state(
            screen: AppScreen.table,
            displayName: _longName,
            chips: 1284500,
            friends: _longNamedFriends,
            friendsAreLive: true,
            globalHourly: _longNamedFriends,
            globalDaily: _longNamedFriends,
            heroHourlyPoints: 45210,
            heroDailyPoints: 184320,
          ),
          device,
          textScale,
        );
        expect(tester.takeException(), isNull, reason: _describe(null, details));

        await tester.tap(find.text('FRIENDS'));
        await tester.pumpAndSettle();

        for (final tab in ['Friends', 'World · this hour', 'World · today']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          final exception = tester.takeException();
          expect(
            exception,
            isNull,
            reason: 'standings tab "$tab" overflows on ${device.name} @${textScale}x\n'
                '${_describe(exception, details)}',
          );
        }
      });
    }
  }
}
