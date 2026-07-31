import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/hand.dart';
import '../models/playing_card.dart';
import '../models/social_models.dart';
import '../services/sound_player.dart';
import '../utils/formatters.dart';

class _SeatResult {
  final String name;
  final int bet;
  final int total;
  final bool lost;
  final bool busted;

  const _SeatResult({
    required this.name,
    required this.bet,
    required this.total,
    required this.lost,
    required this.busted,
  });
}

/// Ports the JS `Component` class from `Blackjack 21 v2.dc.html` 1:1 as a
/// Riverpod [StateNotifier]. See that file's `class Component extends DCLogic`
/// for the reference behavior this mirrors.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(const GameState(friends: kInitialFriends)) {
    _shoe = BlackjackRules.buildShoe(kDeckCount, _rng);
  }

  final Random _rng = Random();
  final SoundPlayer _sound = SoundPlayer();
  List<PlayingCard> _shoe = [];
  Timer? _npcTimer;
  Timer? _toastTimer;
  Timer? _reactTimer;
  Timer? _adWatchTimer;
  Timer? _adCooldownTimer;
  Timer? _voiceTimer;

  @override
  void dispose() {
    _npcTimer?.cancel();
    _toastTimer?.cancel();
    _reactTimer?.cancel();
    _adWatchTimer?.cancel();
    _adCooldownTimer?.cancel();
    _voiceTimer?.cancel();
    unawaited(_sound.dispose());
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Sound & haptic feedback — gated on the user's Settings toggles.
  // ---------------------------------------------------------------------

  void _playSfx(GameSfx sfx) {
    if (!state.soundOn) return;
    unawaited(_sound.play(sfx));
  }

  /// Held back so the settlement tone plays out first and the spoken result
  /// follows it rather than talking over it. Matches `blackjack.wav`, the
  /// longest of the outcome tones at 0.70s.
  static const _kVoiceLead = Duration(milliseconds: 700);

  /// Speaks the hand's result [_kVoiceLead] after the outcome tone. Re-checks
  /// `soundOn` when the timer fires, so muting mid-hand also mutes the pending
  /// call-out.
  void _playVoice(GameVoice voice) {
    if (!state.soundOn) return;
    _voiceTimer?.cancel();
    _voiceTimer = Timer(_kVoiceLead, () {
      if (!state.soundOn) return;
      unawaited(_sound.playVoice(voice));
    });
  }

  void _hapticSelection() {
    if (state.hapticsOn) HapticFeedback.selectionClick();
  }

  void _hapticLight() {
    if (state.hapticsOn) HapticFeedback.lightImpact();
  }

  void _hapticMedium() {
    if (state.hapticsOn) HapticFeedback.mediumImpact();
  }

  void _hapticHeavy() {
    if (state.hapticsOn) HapticFeedback.heavyImpact();
  }

  /// A longer, distinctly different buzz (vs. the short impact taps used
  /// elsewhere) so the player notices when action returns to them after
  /// watching the NPC seats play.
  void _hapticTurnAlert() {
    if (!state.hapticsOn) return;
    HapticFeedback.vibrate();
    Timer(const Duration(milliseconds: 220), () {
      if (state.hapticsOn) HapticFeedback.vibrate();
    });
  }

  void _notifyPlayerTurn() {
    _playSfx(GameSfx.turn);
    _hapticTurnAlert();
  }

  PlayingCard _drawCard() {
    if (_shoe.length < 15) _shoe = BlackjackRules.buildShoe(kDeckCount, _rng);
    return _shoe.removeLast();
  }

  // ---------------------------------------------------------------------
  // Navigation / auth
  // ---------------------------------------------------------------------

  void signInGoogle() => state = state.copyWith(signedIn: true, displayName: 'Alex Rivera', screen: AppScreen.lobby);

  void playGuest() => state = state.copyWith(signedIn: false, displayName: 'Guest', screen: AppScreen.lobby);

  void signOutUser() {
    state = state.copyWith(signedIn: false, displayName: 'Guest');
    _showToast('Signed out');
  }

  void goLobby() => state = state.copyWith(screen: AppScreen.lobby);
  void goStats() => state = state.copyWith(screen: AppScreen.stats);
  void goFriends() => state = state.copyWith(screen: AppScreen.friends);
  void goShop() => state = state.copyWith(screen: AppScreen.shop);
  void goSettings() => state = state.copyWith(screen: AppScreen.settings);

  // ---------------------------------------------------------------------
  // Table entry / NPC seat simulation
  // ---------------------------------------------------------------------

  void enterTable(TableStake t) {
    state = state.copyWith(
      screen: AppScreen.table,
      stake: t,
      phase: RoundPhase.betting,
      bet: 0,
      hands: const [Hand()],
      dealerHand: const [],
      activeHandIndex: 0,
      message: '',
      messageType: MessageType.none,
      visitedVIP: state.visitedVIP || t.key == 'vip',
      npcSeats: _rollNpcSeats(t.min),
    );
  }

  List<NpcSeat> _rollNpcSeats(int minBet) {
    const mults = [1, 1, 2, 2, 4];
    return state.friends.map((_) => NpcSeat(bet: minBet * mults[_rng.nextInt(mults.length)])).toList();
  }

  List<NpcSeat> _dealNpcCards() {
    return state.npcSeats.map((n) => n.copyWith(cards: [_drawCard(), _drawCard()], action: '', done: false)).toList();
  }

  void _patchNpc(int i, NpcSeat Function(NpcSeat) patch) {
    final seats = [...state.npcSeats];
    seats[i] = patch(seats[i]);
    state = state.copyWith(npcSeats: seats);
  }

  void _startNpcTurns() {
    final order = List.generate(state.npcSeats.length, (i) => i);
    if (order.isEmpty) {
      state = state.copyWith(phase: RoundPhase.playing, actingSeat: null);
      _notifyPlayerTurn();
      return;
    }
    state = state.copyWith(phase: RoundPhase.npcs);
    _stepNpc(order, 0);
  }

  void _stepNpc(List<int> order, int k) {
    if (state.screen != AppScreen.table) return;
    if (k >= order.length) {
      _npcTimer = Timer(const Duration(milliseconds: 380), () {
        state = state.copyWith(actingSeat: null, phase: RoundPhase.playing);
        _notifyPlayerTurn();
      });
      return;
    }
    state = state.copyWith(actingSeat: order[k]);
    _npcTimer = Timer(const Duration(milliseconds: 520), () => _npcDecide(order, k));
  }

  void _npcDecide(List<int> order, int k) {
    if (state.screen != AppScreen.table) return;
    final i = order[k];
    final n = state.npcSeats[i];
    final v = BlackjackRules.handValue(n.cards);
    if (v < 17) {
      final cards = [...n.cards, _drawCard()];
      final nv = BlackjackRules.handValue(cards);
      _patchNpc(i, (seat) => seat.copyWith(cards: cards, action: nv > 21 ? 'BUST' : 'HIT'));
      if (nv > 21) {
        _playSfx(GameSfx.npcBust);
        _hapticLight();
      }
      _npcTimer = Timer(const Duration(milliseconds: 600), () {
        if (nv > 21) {
          _patchNpc(i, (seat) => seat.copyWith(done: true));
          _stepNpc(order, k + 1);
        } else {
          _npcDecide(order, k);
        }
      });
    } else {
      _patchNpc(i, (seat) => seat.copyWith(action: 'STAND', done: true));
      _playSfx(GameSfx.npcStand);
      _hapticSelection();
      _npcTimer = Timer(const Duration(milliseconds: 480), () => _stepNpc(order, k + 1));
    }
  }

  void exitTable() {
    _npcTimer?.cancel();
    state = state.copyWith(screen: AppScreen.lobby, actingSeat: null);
  }

  // ---------------------------------------------------------------------
  // Toasts / reactions
  // ---------------------------------------------------------------------

  void _showToast(String text) {
    state = state.copyWith(toast: text);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      state = state.copyWith(toast: '');
    });
  }

  void sendReaction(String label) {
    state = state.copyWith(reactionFloat: label, reactionId: state.reactionId + 1);
    _reactTimer?.cancel();
    _reactTimer = Timer(const Duration(milliseconds: 1600), () {
      state = state.copyWith(reactionFloat: '');
    });
  }

  void claimDailyBonus() {
    if (state.dailyBonusClaimed) return;
    state = state.copyWith(chips: state.chips + 250, dailyBonusClaimed: true);
    _showToast('+250 chips claimed!');
    _playSfx(GameSfx.win);
    _hapticMedium();
  }

  // ---------------------------------------------------------------------
  // Betting / dealing
  // ---------------------------------------------------------------------

  void placeBet(int amount) {
    if (state.phase != RoundPhase.betting) return;
    if (state.bet + amount > state.chips) {
      _showToast('Not enough chips');
      return;
    }
    state = state.copyWith(bet: state.bet + amount);
    _playSfx(GameSfx.chip);
    _hapticSelection();
  }

  void clearBet() => state = state.copyWith(bet: 0);

  void dealRound() {
    final bet = state.bet;
    final chips = state.chips;
    if (state.phase != RoundPhase.betting || bet <= 0 || bet > chips) return;

    final npcSeats = _dealNpcCards();
    final playerCards = [_drawCard(), _drawCard()];
    final dealerCards = [_drawCard(), _drawCard()];
    final newChips = chips - bet;
    final dealerUpIsAce = dealerCards[0].rank == 'A';
    final playerBJ = BlackjackRules.handValue(playerCards) == 21;

    _playSfx(GameSfx.deal);
    _hapticMedium();

    if (dealerUpIsAce) {
      state = state.copyWith(
        chips: newChips,
        dealerHand: dealerCards,
        holeRevealed: false,
        npcSeats: npcSeats,
        hands: [Hand(cards: playerCards, bet: bet, status: HandStatus.active)],
        activeHandIndex: 0,
        phase: RoundPhase.insurance,
        insuranceBet: (bet / 2).floor(),
        message: '',
        messageType: MessageType.none,
      );
      return;
    }

    final dealerBJ = BlackjackRules.handValue(dealerCards) == 21;
    if (playerBJ || dealerBJ) {
      state = state.copyWith(
        chips: newChips,
        dealerHand: dealerCards,
        holeRevealed: true,
        hands: [Hand(cards: playerCards, bet: bet, status: playerBJ ? HandStatus.blackjack : HandStatus.active)],
        activeHandIndex: 0,
        phase: RoundPhase.dealer,
      );
      _settle();
      return;
    }

    state = state.copyWith(
      chips: newChips,
      dealerHand: dealerCards,
      holeRevealed: false,
      npcSeats: npcSeats,
      hands: [Hand(cards: playerCards, bet: bet, status: HandStatus.active)],
      activeHandIndex: 0,
      phase: RoundPhase.npcs,
      message: '',
      messageType: MessageType.none,
      actingSeat: null,
    );
    _startNpcTurns();
  }

  // ---------------------------------------------------------------------
  // Insurance
  // ---------------------------------------------------------------------

  void _resolveInsuranceThenContinue() {
    final dealerBJ = BlackjackRules.handValue(state.dealerHand) == 21;
    final playerBJ = BlackjackRules.handValue(state.hands[0].cards) == 21;
    if (dealerBJ || playerBJ) {
      final newHands = state.hands
          .map((h) => h.copyWith(status: (playerBJ && !dealerBJ) ? HandStatus.blackjack : h.status))
          .toList();
      state = state.copyWith(hands: newHands, holeRevealed: true, phase: RoundPhase.dealer);
      _settle();
    } else {
      _startNpcTurns();
    }
  }

  void takeInsurance() {
    state = state.copyWith(chips: state.chips - state.insuranceBet);
    _hapticSelection();
    _resolveInsuranceThenContinue();
  }

  void declineInsurance() {
    state = state.copyWith(insuranceBet: 0);
    _hapticSelection();
    _resolveInsuranceThenContinue();
  }

  // ---------------------------------------------------------------------
  // Player actions
  // ---------------------------------------------------------------------

  void playerHit() {
    final hand = state.hands[state.activeHandIndex];
    final newCards = [...hand.cards, _drawCard()];
    final val = BlackjackRules.handValue(newCards);
    final newHand = hand.copyWith(cards: newCards, status: val > 21 ? HandStatus.busted : HandStatus.active);
    final newHands = [...state.hands];
    newHands[state.activeHandIndex] = newHand;
    state = state.copyWith(hands: newHands);
    _playSfx(GameSfx.deal);
    _hapticLight();
    if (newHand.status == HandStatus.busted) _advanceHand();
  }

  void playerStand() {
    final newHands = [...state.hands];
    newHands[state.activeHandIndex] = newHands[state.activeHandIndex].copyWith(status: HandStatus.stood);
    state = state.copyWith(hands: newHands);
    _hapticSelection();
    _advanceHand();
  }

  void playerDouble() {
    final hand = state.hands[state.activeHandIndex];
    if (hand.cards.length != 2 || state.chips < hand.bet) return;
    final newCards = [...hand.cards, _drawCard()];
    final val = BlackjackRules.handValue(newCards);
    final newHand = hand.copyWith(
      cards: newCards,
      bet: hand.bet * 2,
      doubled: true,
      status: val > 21 ? HandStatus.busted : HandStatus.stood,
    );
    final newHands = [...state.hands];
    newHands[state.activeHandIndex] = newHand;
    state = state.copyWith(hands: newHands, chips: state.chips - hand.bet);
    _playSfx(GameSfx.deal);
    _hapticMedium();
    _advanceHand();
  }

  void playerSplit() {
    final hand = state.hands[state.activeHandIndex];
    if (state.hands.length > 1 ||
        hand.cards.length != 2 ||
        hand.cards[0].rank != hand.cards[1].rank ||
        state.chips < hand.bet) {
      return;
    }
    final c1 = _drawCard();
    final c2 = _drawCard();
    final handA = Hand(cards: [hand.cards[0], c1], bet: hand.bet, status: HandStatus.active);
    final handB = Hand(cards: [hand.cards[1], c2], bet: hand.bet, status: HandStatus.active);
    state = state.copyWith(hands: [handA, handB], activeHandIndex: 0, chips: state.chips - hand.bet);
    _playSfx(GameSfx.deal);
    _hapticMedium();
  }

  void playerSurrender() {
    final hand = state.hands[state.activeHandIndex];
    if (state.hands.length > 1 || hand.cards.length != 2) return;
    final refund = (hand.bet / 2).floor();
    final newHands = [...state.hands];
    newHands[state.activeHandIndex] = hand.copyWith(status: HandStatus.surrendered);
    state = state.copyWith(hands: newHands, chips: state.chips + refund);
    _hapticLight();
    _advanceHand();
  }

  void _advanceHand() {
    if (state.activeHandIndex < state.hands.length - 1) {
      state = state.copyWith(activeHandIndex: state.activeHandIndex + 1);
      return;
    }
    final allDone = state.hands.every((h) => h.status != HandStatus.active);
    if (!allDone) return;
    // The dealer always has to play its hand out here, even if every hero
    // hand surrendered: the NPC seats were already dealt real cards for this
    // round, and the "closest to 21" sweep pot settles their bets against
    // the dealer's *final* total, not its un-played opening two cards.
    _playDealer();
  }

  void _playDealer() {
    final dealerHand = [...state.dealerHand];
    bool shouldHit() {
      final v = BlackjackRules.handValue(dealerHand);
      if (v < 17) return true;
      if (v == 17 && kDealerHitsSoft17 && BlackjackRules.isSoft(dealerHand)) return true;
      return false;
    }

    while (shouldHit()) {
      dealerHand.add(_drawCard());
    }
    state = state.copyWith(dealerHand: dealerHand, holeRevealed: true, phase: RoundPhase.dealer);
    _settle();
  }

  // ---------------------------------------------------------------------
  // Settlement — "Closest to 21" sweep-pot logic ported from `settle()`
  // ---------------------------------------------------------------------

  void _settle() {
    final hands = state.hands;
    final dealerHand = state.dealerHand;
    final insuranceBet = state.insuranceBet;
    final dealerVal = BlackjackRules.handValue(dealerHand);
    final dealerBJ = dealerHand.length == 2 && dealerVal == 21;

    var chipsDelta = 0;
    final insurancePayout = (insuranceBet > 0 && dealerBJ) ? insuranceBet * 3 : 0;
    chipsDelta += insurancePayout;

    var sessionNetDelta = insurancePayout - insuranceBet;
    var winsDelta = 0, lossesDelta = 0, pushesDelta = 0, bjDelta = 0;
    final newHistory = [...state.history];
    final outcomes = <String>[];

    for (final hand in hands) {
      final val = BlackjackRules.handValue(hand.cards);
      final playerBJ = hand.cards.length == 2 && val == 21;
      String outcome;
      if (hand.status == HandStatus.surrendered) {
        outcome = 'lose';
        lossesDelta++;
        newHistory.add(RoundResult.loss);
        // playerSurrender() already refunded floor(bet/2) straight to chips,
        // so the net loss for this hand is the other half — round the same
        // way as that refund so the two always sum to exactly `bet`.
        sessionNetDelta -= hand.bet - (hand.bet / 2).floor();
      } else if (val > 21) {
        outcome = 'lose';
        lossesDelta++;
        newHistory.add(RoundResult.loss);
        sessionNetDelta -= hand.bet;
      } else if (dealerBJ && !playerBJ) {
        outcome = 'lose';
        lossesDelta++;
        newHistory.add(RoundResult.loss);
        sessionNetDelta -= hand.bet;
      } else if (playerBJ && !dealerBJ) {
        outcome = 'blackjack';
        final win = (hand.bet * 1.5).floor();
        chipsDelta += hand.bet + win;
        sessionNetDelta += win;
        winsDelta++;
        bjDelta++;
        newHistory.add(RoundResult.win);
      } else if (playerBJ && dealerBJ) {
        outcome = 'push';
        chipsDelta += hand.bet;
        pushesDelta++;
        newHistory.add(RoundResult.push);
      } else if (dealerVal > 21 || val > dealerVal) {
        outcome = 'win';
        chipsDelta += hand.bet * 2;
        sessionNetDelta += hand.bet;
        winsDelta++;
        newHistory.add(RoundResult.win);
      } else if (val == dealerVal) {
        outcome = 'push';
        chipsDelta += hand.bet;
        pushesDelta++;
        newHistory.add(RoundResult.push);
      } else {
        outcome = 'lose';
        lossesDelta++;
        newHistory.add(RoundResult.loss);
        sessionNetDelta -= hand.bet;
      }
      outcomes.add(outcome);
    }

    final bumpedHistory = newHistory.length > 10 ? newHistory.sublist(newHistory.length - 10) : newHistory;

    String message;
    MessageType messageType;
    if (dealerBJ && !outcomes.contains('blackjack') && !outcomes.contains('push')) {
      message = 'Dealer has blackjack';
      messageType = MessageType.lose;
    } else if (outcomes.contains('blackjack')) {
      message = 'Blackjack! You win';
      messageType = MessageType.win;
    } else if (outcomes.any((o) => o == 'win')) {
      message = 'You win!';
      messageType = MessageType.win;
    } else if (outcomes.every((o) => o == 'lose')) {
      message = 'Dealer wins';
      messageType = MessageType.lose;
    } else {
      message = 'Push';
      messageType = MessageType.push;
    }

    // "Closest to 21" — beat the dealer with the best live hand at the table
    // and sweep every bet the other seats lost.
    final seatResults = <_SeatResult>[];
    for (var i = 0; i < state.npcSeats.length; i++) {
      final n = state.npcSeats[i];
      if (n.cards.isEmpty) continue;
      final v = BlackjackRules.handValue(n.cards);
      final f = state.friends[i];
      final dealerBust = dealerVal > 21;
      seatResults.add(
        _SeatResult(
          name: f.firstName,
          bet: n.bet,
          total: v,
          lost: v > 21 || (!dealerBust && v <= dealerVal),
          busted: v > 21,
        ),
      );
    }

    final heroWon = outcomes.contains('win') || outcomes.contains('blackjack');
    final heroBestCandidates = [
      0,
      ...hands
          .where((h) => h.status != HandStatus.surrendered)
          .map((h) => BlackjackRules.handValue(h.cards))
          .where((v) => v <= 21),
    ];
    final heroBest = heroBestCandidates.reduce(max);
    final rivalBestCandidates = [0, ...seatResults.where((r) => !r.lost).map((r) => r.total)];
    final rivalBest = rivalBestCandidates.reduce(max);
    final tablePot = seatResults.where((r) => r.lost).fold(0, (sum, r) => sum + r.bet);

    var sweep = 0;
    final heroTakesPot = heroWon && tablePot > 0 && heroBest >= rivalBest;
    if (heroTakesPot) {
      sweep = tablePot;
      chipsDelta += sweep;
      sessionNetDelta += sweep;
      message = 'Closest to 21 — you sweep the table';
      messageType = MessageType.win;
    }

    // Tone first, then a spoken result. A push gets no call-out — there is no
    // win or loss to announce.
    if (outcomes.contains('blackjack')) {
      _playSfx(GameSfx.blackjack);
      _playVoice(GameVoice.bigWin);
      _hapticHeavy();
    } else if (messageType == MessageType.win) {
      _playSfx(GameSfx.win);
      _playVoice(heroTakesPot ? GameVoice.playerPot : GameVoice.playerWin);
      _hapticMedium();
    } else if (messageType == MessageType.lose) {
      _playSfx(GameSfx.lose);
      _playVoice(GameVoice.playerLose);
      _hapticLight();
    } else {
      _playSfx(GameSfx.push);
      _hapticSelection();
    }

    final potRivalCandidates = seatResults.where((r) => !r.lost).toList()..sort((a, b) => b.total.compareTo(a.total));
    final potRival = potRivalCandidates.isNotEmpty ? potRivalCandidates.first : null;
    final heroBetTotal = hands.fold(0, (t, h) => t + h.bet);
    final winnerBet = heroTakesPot ? heroBetTotal : (potRival?.bet ?? 0);
    final sweepInfo = tablePot == 0
        ? null
        : SweepInfo(
            pot: tablePot,
            winnerBet: winnerBet,
            totalWin: tablePot + winnerBet,
            winner: heroTakesPot ? 'You' : (potRival?.name ?? 'Nobody'),
            winnerTotal: heroTakesPot ? heroBest : (potRival?.total ?? 0),
            heroTook: heroTakesPot,
            contributors: seatResults
                .where((r) => r.lost)
                .map((r) => SweepContributor(name: r.name, amount: r.bet, reason: r.busted ? 'bust' : 'lost'))
                .toList(),
          );

    final streakWin = winsDelta > 0 && lossesDelta == 0;
    final newStreak = streakWin ? state.stats.currentStreak + 1 : 0;

    state = state.copyWith(
      chips: state.chips + chipsDelta,
      phase: RoundPhase.settlement,
      message: message,
      messageType: messageType,
      sweepAmount: sweep,
      roundNet: sessionNetDelta,
      roundStake: hands.fold(0, (t, h) => t + h.bet) + insuranceBet,
      roundHandNet: sessionNetDelta - sweep,
      sweepInfo: sweepInfo,
      history: bumpedHistory,
      stats: state.stats.copyWith(
        handsPlayed: state.stats.handsPlayed + hands.length,
        wins: state.stats.wins + winsDelta,
        losses: state.stats.losses + lossesDelta,
        pushes: state.stats.pushes + pushesDelta,
        blackjacks: state.stats.blackjacks + bjDelta,
        currentStreak: newStreak,
        bestStreak: max(state.stats.bestStreak, newStreak),
      ),
      session: state.session.copyWith(
        hands: state.session.hands + hands.length,
        wins: state.session.wins + winsDelta,
        net: state.session.net + sessionNetDelta,
      ),
    );
  }

  void nextHand() {
    const speakers = ['Maya T.', 'Jordan K.'];
    final speaker = speakers[_rng.nextInt(speakers.length)];
    final line = kChatPool[_rng.nextInt(kChatPool.length)];
    final newMessages = [
      ...state.chatMessages,
      ChatMessage(name: speaker, text: line, id: DateTime.now().millisecondsSinceEpoch),
    ];
    state = state.copyWith(
      phase: RoundPhase.betting,
      bet: 0,
      hands: const [Hand()],
      dealerHand: const [],
      activeHandIndex: 0,
      insuranceBet: 0,
      message: '',
      messageType: MessageType.none,
      holeRevealed: false,
      actingSeat: null,
      chatMessages: newMessages.length > 3 ? newMessages.sublist(newMessages.length - 3) : newMessages,
      npcSeats: _rollNpcSeats(state.stake?.min ?? 25),
      sweepAmount: 0,
      roundNet: 0,
      roundStake: 0,
      roundHandNet: 0,
      sweepInfo: null,
    );
  }

  void resetBankroll() => state = state.copyWith(chips: kStartingChips);

  // ---------------------------------------------------------------------
  // Stats / leaderboard tabs
  // ---------------------------------------------------------------------

  void setStatsRecent() => state = state.copyWith(statsTab: StatsTab.recent);
  void setStatsAlltime() => state = state.copyWith(statsTab: StatsTab.alltime);
  void setStatsAchievements() => state = state.copyWith(statsTab: StatsTab.achievements);
  void setLeaderboardHourly() => state = state.copyWith(leaderboardPeriod: LeaderboardPeriod.hourly);
  void setLeaderboardDaily() => state = state.copyWith(leaderboardPeriod: LeaderboardPeriod.daily);
  void setLeaderboardAlltime() => state = state.copyWith(leaderboardPeriod: LeaderboardPeriod.alltime);

  // ---------------------------------------------------------------------
  // Friends / referrals
  // ---------------------------------------------------------------------

  void onFriendCodeInput(String value) => state = state.copyWith(friendCodeInput: value.toUpperCase());

  void addFriendByCode() {
    final code = state.friendCodeInput.trim();
    if (code.isEmpty) return;
    _showToast('Friend request sent to $code');
    state = state.copyWith(friendCodeInput: '', referralsCount: state.referralsCount + 1);
  }

  void joinTournament() {
    if (state.tournamentJoined) return;
    state = state.copyWith(tournamentJoined: true);
    _showToast("You're in! Good luck in the Weekend Cup.");
  }

  void claimTier(String id, int need, int reward) {
    if (state.referralsCount < need || state.claimedTiers.contains(id)) return;
    state = state.copyWith(chips: state.chips + reward, claimedTiers: [...state.claimedTiers, id]);
    _showToast('+$reward chips claimed!');
  }

  void giftChips(String id) {
    if (state.chips < 100) {
      _showToast('Not enough chips to gift');
      return;
    }
    Friend? friend;
    final newFriends = state.friends.map((f) {
      if (f.id == id) {
        friend = f;
        return f.copyWith(chips: f.chips + 100);
      }
      return f;
    }).toList();
    state = state.copyWith(chips: state.chips - 100, friends: newFriends);
    _showToast('Gifted 100 chips to ${friend?.name ?? 'friend'}!');
  }

  void shareInviteLink() => _showToast('Invite link copied to clipboard');

  // ---------------------------------------------------------------------
  // Stories
  // ---------------------------------------------------------------------

  void openStory(String id) {
    final viewed = state.viewedStories.contains(id) ? state.viewedStories : [...state.viewedStories, id];
    state = state.copyWith(activeStoryId: id, viewedStories: viewed);
  }

  void closeStory() => state = state.copyWith(activeStoryId: null);

  void nextStory() {
    final idx = kStoriesData.indexWhere((s) => s.id == state.activeStoryId);
    if (idx < 0) return;
    if (idx < kStoriesData.length - 1) {
      openStory(kStoriesData[idx + 1].id);
    } else {
      closeStory();
    }
  }

  void sendGGActiveStory() {
    final matches = kStoriesData.where((s) => s.id == state.activeStoryId);
    _showToast('Sent GG to ${matches.isNotEmpty ? matches.first.name : 'friend'}!');
    closeStory();
  }

  // ---------------------------------------------------------------------
  // Shop / cosmetics / settings
  // ---------------------------------------------------------------------

  void selectAvatarColor(Color color) => state = state.copyWith(avatarColor: color);
  void selectCardBack(String id) => state = state.copyWith(cardBackSkin: id);
  void selectFelt(String id) => state = state.copyWith(themeChoice: id);
  void setAvatarFrame(bool gold) => state = state.copyWith(avatarFrameGold: gold);

  void toggleLike1() => state = state.copyWith(
    highlight1Liked: !state.highlight1Liked,
    highlight1Count: state.highlight1Count + (state.highlight1Liked ? -1 : 1),
  );

  void toggleLike2() => state = state.copyWith(
    highlight2Liked: !state.highlight2Liked,
    highlight2Count: state.highlight2Count + (state.highlight2Liked ? -1 : 1),
  );

  void sendGGHighlight1() => _showToast('Sent GG to Maya T.!');
  void sendGGHighlight2() => _showToast('Sent GG to Jordan K.!');

  void vipLearnMore() => _showToast('VIP Club — coming soon');

  void buyPack(ShopPackDef pack) {
    state = state.copyWith(chips: state.chips + pack.amount);
    _showToast('Purchased ${formatChips(pack.amount)} chips!');
    _playSfx(GameSfx.win);
    _hapticMedium();
  }

  void watchAd() {
    if (state.adState != AdState.ready) return;
    state = state.copyWith(adState: AdState.watching);
    _adWatchTimer = Timer(const Duration(milliseconds: 1200), () {
      state = state.copyWith(chips: state.chips + 200, adState: AdState.cooldown);
      _showToast('+200 chips!');
      _playSfx(GameSfx.win);
      _hapticMedium();
      _adCooldownTimer = Timer(const Duration(milliseconds: 8000), () {
        state = state.copyWith(adState: AdState.ready);
      });
    });
  }

  void selectThemeDefault() => state = state.copyWith(themeChoice: 'default');
  void selectThemeOcean() => state = state.copyWith(themeChoice: 'ocean');
  void selectThemeEmber() => state = state.copyWith(themeChoice: 'ember');
  void toggleHaptics() {
    final next = !state.hapticsOn;
    state = state.copyWith(hapticsOn: next);
    if (next) HapticFeedback.mediumImpact();
  }

  void toggleSound() {
    final next = !state.soundOn;
    state = state.copyWith(soundOn: next);
    if (next) unawaited(_sound.play(GameSfx.chip));
  }
  void toggleTableMenu() => state = state.copyWith(tableMenuOpen: !state.tableMenuOpen);
  void toggleTableChat() => state = state.copyWith(tableChatOpen: !state.tableChatOpen, tableMenuOpen: false);
  void toggleNotifSocial() => state = state.copyWith(notifSocial: !state.notifSocial);
  void toggleNotifLeaderboard() => state = state.copyWith(notifLeaderboard: !state.notifLeaderboard);
  void toggleNotifDaily() => state = state.copyWith(notifDaily: !state.notifDaily);
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());
