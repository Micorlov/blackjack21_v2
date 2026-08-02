import '../models/enums.dart';
import '../utils/daily_bonus.dart';

/// How many hands the first-run tutorial coaches the player through. One
/// lesson per hand; after the third settles, the coach card stops appearing.
const int kTutorialRounds = 3;

/// A single coaching card: a short title and one or two sentences of body.
/// `{min}` in [body] is replaced with the current table's minimum bet by
/// `tutorialTipFor` — see `utils/tutorial.dart`.
class TutorialTip {
  final String title;
  final String body;

  const TutorialTip({required this.title, required this.body});
}

/// One lesson covers one hand. [tips] holds the card shown in each phase of
/// that hand; a phase with no entry shows no card at all, so the coach stays
/// out of the way once its point has been made.
class TutorialLesson {
  final String name;
  final Map<RoundPhase, TutorialTip> tips;

  const TutorialLesson({required this.name, required this.tips});
}

/// Shown whenever the dealer's up-card is an Ace, in any lesson: the offer is
/// dealt at random, so it cannot be taught on a fixed hand.
const TutorialTip kInsuranceTip = TutorialTip(
  title: 'The dealer is showing an Ace',
  body:
      'Insurance costs half your bet and only pays — at 2:1 — if the dealer turns over a blackjack. '
      'Most players decline it.',
);

/// The three first-hand lessons, in order. Each one teaches exactly one idea:
/// how a hand is played, how to read the dealer, and what the extra moves and
/// the table pot are for.
const List<TutorialLesson> kTutorialLessons = [
  TutorialLesson(
    name: 'Play a hand',
    tips: {
      RoundPhase.betting: TutorialTip(
        title: 'Put chips on the table',
        body: 'Tap a chip to add it to your bet, then press DEAL. This table plays for {min} a hand and up.',
      ),
      RoundPhase.npcs: TutorialTip(
        title: 'The other seats play first',
        body: 'Every seat plays its hand before you do. Your turn starts the moment HIT and STAND light up.',
      ),
      RoundPhase.playing: TutorialTip(
        title: 'Hit or stand',
        body:
            'Get closer to 21 than the dealer without going over. HIT takes one more card, STAND ends your turn. '
            'Over 21 is a bust and the hand is gone.',
      ),
      RoundPhase.settlement: TutorialTip(
        title: 'That is one hand',
        body: 'Beating the dealer pays even money — your bet back and the same again. Deal the next one when ready.',
      ),
    },
  ),
  TutorialLesson(
    name: 'Read the dealer',
    tips: {
      RoundPhase.betting: TutorialTip(
        title: 'Bet again',
        body: 'Winnings go straight into your balance. Anything from {min} up to the table maximum is a legal bet.',
      ),
      RoundPhase.playing: TutorialTip(
        title: "Watch the dealer's up-card",
        body:
            'The dealer must draw under 17 and stand on 17 or more. Against a 2 through 6 the dealer busts often, '
            'so stand early; against a 7 through Ace, keep drawing toward 17.',
      ),
      RoundPhase.settlement: TutorialTip(
        title: 'A tie is a push',
        body: "Matching the dealer's total returns your bet untouched. Only busting or finishing lower costs chips.",
      ),
    },
  ),
  TutorialLesson(
    name: 'Bigger moves',
    tips: {
      RoundPhase.betting: TutorialTip(
        title: 'Play for the table pot',
        body:
            'Every seat is betting too, and each bet they lose to the dealer drops into the pot on the felt. '
            'Finish closest to 21 and the whole pot is yours.',
      ),
      RoundPhase.playing: TutorialTip(
        title: 'Double, split, surrender',
        body:
            'DOUBLE doubles your bet for exactly one more card — strongest on 10 or 11. SPLIT turns a pair into two '
            'hands. SURRENDER gives back half your bet on a hopeless start.',
      ),
      RoundPhase.settlement: TutorialTip(
        title: 'You are on your own now',
        body: 'That is the tutorial. The full rules stay in Settings → How to play whenever you want them.',
      ),
    },
  ),
];

/// A section of the "How to play" guide: a heading and its lines. A line that
/// starts with '· ' is rendered as a hanging-indented bullet by the sheet.
class GuideSection {
  final String title;
  final List<String> lines;

  const GuideSection({required this.title, required this.lines});
}

/// The reference guide behind "How to play". Every figure here is one the game
/// actually pays out — see `_settle()` in `state/game_notifier.dart`.
const List<GuideSection> kGuideSections = [
  GuideSection(
    title: 'The goal',
    lines: [
      'Finish with a hand closer to 21 than the dealer, without going over. '
          'Every seat plays its own hand against the dealer, never against you.',
    ],
  ),
  GuideSection(
    title: 'What the cards are worth',
    lines: [
      'Number cards are worth their face value, and J, Q and K are worth 10.',
      'An Ace counts 11 until that would take you over 21, and 1 after that — so A + 6 is 17 or 7, '
          'whichever helps.',
    ],
  ),
  GuideSection(
    title: 'Your moves',
    lines: [
      '· HIT — take one more card. Over 21 and the hand is lost immediately.',
      '· STAND — keep your total and end your turn.',
      '· DOUBLE — double the bet and take exactly one more card. First two cards only.',
      '· SPLIT — turn a pair into two separate hands, each with its own bet.',
      '· SURRENDER — fold the opening hand and take back half the bet.',
      '· INSURANCE — offered only when the dealer shows an Ace. Costs half your bet, pays 2:1 if the dealer '
          'has blackjack.',
    ],
  ),
  GuideSection(
    title: 'How the dealer plays',
    lines: [
      'Once every seat has acted, the dealer turns the hole card over and draws until reaching 17. '
          'The dealer stands on any 17, soft ones included.',
      'If the dealer busts, every hand still standing wins.',
    ],
  ),
  GuideSection(
    title: 'What it pays',
    lines: [
      '· A winning hand pays even money — your bet back, plus the same again.',
      '· Blackjack — an Ace with a ten-card on the first two cards — pays 3:2.',
      '· A push returns your bet.',
      '· Surrender returns half your bet.',
    ],
  ),
  GuideSection(
    title: 'The sweep pot',
    lines: [
      'Every bet the other seats lose to the dealer goes into the table pot shown on the felt.',
      'Beat the dealer and finish at least as close to 21 as every seat still standing, and you take the whole '
          'pot on top of your own win. Otherwise the best seat takes it.',
    ],
  ),
  GuideSection(
    title: 'Chips and limits',
    lines: [
      'Each table has its own minimum and maximum bet — the lobby lists them, and the betting panel reminds '
          'you until your bet clears the minimum.',
      'Drop below the minimum and the table hands you 1,000 complimentary chips. The lobby also pays a '
          '$kDailyBonusChips-chip daily bonus every 24 hours.',
    ],
  ),
];
