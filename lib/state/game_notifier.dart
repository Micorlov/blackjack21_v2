import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/game_data.dart';
import '../data/tutorial_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/hand.dart';
import '../models/playing_card.dart';
import '../models/social_models.dart';
import '../models/table_pot.dart';
import '../services/daily_bonus_store.dart';
import '../services/game_store.dart';
import '../services/local_notifier.dart';
import '../services/social_service.dart';
import '../services/sound_player.dart';
import '../services/spoken_amount.dart';
import '../utils/comeback.dart';
import '../utils/daily_bonus.dart';
import '../utils/formatters.dart';
import '../utils/points.dart';
import '../utils/table_seats.dart';

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
    unawaited(_boot());
  }

  final Random _rng = Random();
  final SoundPlayer _sound = SoundPlayer();
  final SocialService _social = SocialService();
  final LocalNotifier _notifs = LocalNotifier();
  final DailyBonusStore _bonusStore = DailyBonusStore();
  final GameStore _store = GameStore();
  Timer? _saveTimer;
  StreamSubscription<List<Friend>>? _groupSub;
  StreamSubscription<List<Friend>>? _hourlySub;
  StreamSubscription<List<Friend>>? _dailySub;
  String _hourlySubKey = '';
  String _dailySubKey = '';
  Timer? _heartbeatTimer;

  /// True once a live (non-empty) member snapshot has arrived, so the first
  /// snapshot after subscribing never fires overtake alerts.
  bool _groupLive = false;
  List<PlayingCard> _shoe = [];
  Timer? _npcTimer;
  Timer? _toastTimer;
  Timer? _reactTimer;
  Timer? _adWatchTimer;
  Timer? _adCooldownTimer;
  Timer? _voiceTimer;
  Timer? _potTimer;
  Timer? _celebrationTimer;

  /// Long enough to absorb a burst of state changes, short enough that a
  /// force-quit right after a hand still finds the result on disk.
  static const Duration _kSaveDebounce = Duration(milliseconds: 600);

  @override
  void dispose() {
    // A save still waiting out its debounce would be lost with the timer, so
    // flush it first — that pending write is the hand just played.
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      unawaited(_store.save(_snapshot()));
    }
    _saveTimer?.cancel();
    _npcTimer?.cancel();
    _toastTimer?.cancel();
    _reactTimer?.cancel();
    _adWatchTimer?.cancel();
    _adCooldownTimer?.cancel();
    _voiceTimer?.cancel();
    _potTimer?.cancel();
    _celebrationTimer?.cancel();
    _heartbeatTimer?.cancel();
    unawaited(_groupSub?.cancel());
    unawaited(_hourlySub?.cancel());
    unawaited(_dailySub?.cancel());
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

  /// Length of `player_pot.wav` ("Player wins the sweep pot"), 1.51s.
  static const _kPotVoiceLength = Duration(milliseconds: 1520);

  /// Drum flourish once the pot call-out has finished. Sweeping the table is
  /// the best result a round can produce, so it gets more than a tone. Plays
  /// on the tone channel, which the voice line does not use, so the two never
  /// cut each other off even if the timing drifts.
  void _celebrateSweep() {
    if (!state.soundOn) return;
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(
      _kVoiceLead + _kPotVoiceLength,
      () => _playSfx(GameSfx.potCelebration),
    );
  }

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
    _announceTablePot();
  }

  /// Reads the dealer pill out loud — "Sweep pot, three hundred seventy five
  /// dollars" — now that every opponent seat has played and the figure has
  /// stopped moving. Reads the same [TablePot] the pill renders, so the two
  /// can never disagree about the figure. The call-out always opens with
  /// "sweep pot", whichever figure the pill happens to be showing.
  void _announceTablePot() {
    if (!state.soundOn) return;
    final pot = TablePot.live(state);
    final amount = spokenAmountWords(pot.amount);
    if (amount.isEmpty) return;

    _potTimer?.cancel();
    _potTimer = Timer(_kPotAnnouncementLead, () {
      if (!state.soundOn) return;
      unawaited(
        _sound.playWords([
          'sweep_pot',
          ...amount,
          'dollars',
        ]),
      );
    });
  }

  /// Held back so the turn cue (`turn.wav`, 0.60s) finishes first.
  static const _kPotAnnouncementLead = Duration(milliseconds: 700);

  PlayingCard _drawCard() {
    if (_shoe.length < 15) _shoe = BlackjackRules.buildShoe(kDeckCount, _rng);
    return _shoe.removeLast();
  }

  // ---------------------------------------------------------------------
  // Social: live friends group, invites, score sync, overtake alerts
  // ---------------------------------------------------------------------

  /// Restore the saved player *before* any social work starts. `_initSocial`
  /// ends up publishing this player's row to the group, and publishing the
  /// default $1,000 stack before the real one loads would show friends a
  /// bankroll that never existed.
  Future<void> _boot() async {
    await _hydrate();
    if (!mounted) return;
    await _initSocial();
  }

  Future<void> _hydrate() async {
    final saved = await _store.load();
    if (saved == null || !mounted) return;
    final now = DateTime.now();
    final hourKey = hourKeyOf(now);
    final dayKey = dayKeyOf(now);
    state = state.copyWith(
      chips: saved.chips,
      stats: saved.stats,
      history: saved.history,
      // Points saved in an earlier hour/day are worth nothing now — the same
      // rollover the heartbeat applies, so a relaunch cannot resurrect a
      // finished period's score.
      heroHourlyPoints: rolledPoints(saved.hourlyPoints, saved.hourKey, hourKey),
      heroDailyPoints: rolledPoints(saved.dailyPoints, saved.dayKey, dayKey),
      heroHourKey: hourKey,
      heroDayKey: dayKey,
      soundOn: saved.soundOn,
      hapticsOn: saved.hapticsOn,
      notifSocial: saved.notifSocial,
      notifLeaderboard: saved.notifLeaderboard,
      notifDaily: saved.notifDaily,
      themeChoice: saved.themeChoice,
      cardBackSkin: saved.cardBackSkin,
      avatarFrameGold: saved.avatarFrameGold,
      claimedTiers: saved.claimedTiers,
      tutorialRoundsSeen: saved.tutorialRoundsSeen,
      tutorialDismissed: saved.tutorialDismissed,
    );
  }

  SavedGame _snapshot() => SavedGame(
    chips: state.chips,
    stats: state.stats,
    history: state.history,
    hourlyPoints: state.heroHourlyPoints,
    dailyPoints: state.heroDailyPoints,
    hourKey: state.heroHourKey,
    dayKey: state.heroDayKey,
    soundOn: state.soundOn,
    hapticsOn: state.hapticsOn,
    notifSocial: state.notifSocial,
    notifLeaderboard: state.notifLeaderboard,
    notifDaily: state.notifDaily,
    themeChoice: state.themeChoice,
    cardBackSkin: state.cardBackSkin,
    avatarFrameGold: state.avatarFrameGold,
    claimedTiers: state.claimedTiers,
    tutorialRoundsSeen: state.tutorialRoundsSeen,
    tutorialDismissed: state.tutorialDismissed,
  );

  /// Coalesces the writes a fast player generates — settling a hand, flipping
  /// a toggle and buying a skin inside the same second become one disk write.
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_kSaveDebounce, () => unawaited(_store.save(_snapshot())));
  }

  Future<void> _initSocial() async {
    // Sign-in is kicked off immediately, same as before notifications
    // existed here; notifications and the daily-bonus restore then run
    // alongside it rather than blocking on it, so both still work offline.
    final signInFuture = _social.ensureSignedIn();
    await _notifs.init();
    if (!mounted) return;
    await _restoreDailyBonus();
    if (!mounted) return;
    final ok = await signInFuture;
    if (!mounted || !ok) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous && !state.signedIn) {
      // A Google session survived from a previous launch — restore identity.
      state = state.copyWith(signedIn: true, displayName: user.displayName ?? 'Player', photoUrl: user.photoURL);
    }
    state = state.copyWith(socialReady: true, heroUid: _social.uid);
    _subscribeGlobals();
    // Publish immediately so this player exists on the world list from the
    // first launch, not only after the first settled hand.
    _reportScore();
    final code = await _social.fetchMyGroupCode();
    if (!mounted) return;
    if (code != null) _subscribeGroup(code);
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) => _heartbeat());
  }

  /// Leaderboard name: the Google name when signed in, otherwise a stable
  /// guest tag derived from the anonymous uid so two guests never collide.
  String get _playerName {
    if (state.signedIn) return state.displayName;
    final u = _social.uid;
    return (u == null || u.length < 4) ? 'Guest' : 'Guest ${u.substring(0, 4).toUpperCase()}';
  }

  void _subscribeGroup(String code) {
    unawaited(_groupSub?.cancel());
    _groupLive = false;
    state = state.copyWith(groupCode: code);
    _groupSub = _social.watchMembers(code).listen(
      _onGroupUpdate,
      // A broken stream (offline, rules) must not kill the game; the last
      // known friends list simply stays on screen until it recovers.
      onError: (Object e) => debugPrint('group stream error: $e'),
    );
  }

  void _onGroupUpdate(List<Friend> members) {
    final now = DateTime.now();
    final heroId = _social.uid ?? 'hero';
    final heroHourly = rolledPoints(state.heroHourlyPoints, state.heroHourKey, hourKeyOf(now));
    final heroDaily = rolledPoints(state.heroDailyPoints, state.heroDayKey, dayKeyOf(now));

    List<RankedPlayer> ranked(List<Friend> fs, int heroPts, {required bool hourly}) => [
      for (final f in fs) RankedPlayer(id: f.id, name: f.firstName, points: hourly ? f.hourlyScore : f.dailyScore),
      RankedPlayer(id: heroId, name: 'You', points: heroPts),
    ];

    if (_groupLive && state.notifLeaderboard) {
      final overHourly = overtakers(
        before: ranked(state.friends, heroHourly, hourly: true),
        after: ranked(members, heroHourly, hourly: true),
        heroId: heroId,
      );
      final overDaily = overtakers(
        before: ranked(state.friends, heroDaily, hourly: false),
        after: ranked(members, heroDaily, hourly: false),
        heroId: heroId,
      );
      _notifyOvertaken(overHourly, overDaily);
    }

    _groupLive = members.isNotEmpty;
    // Alone in the group → practice bots keep the table lively, but
    // `friendsAreLive` stays false so friend lists can tell bots from people.
    state = state.copyWith(
      friends: members.isEmpty ? kInitialFriends : members,
      friendsAreLive: members.isNotEmpty,
    );
  }

  void _notifyOvertaken(List<RankedPlayer> hourly, List<RankedPlayer> daily) {
    if (hourly.isEmpty && daily.isEmpty) return;
    final leadName = (hourly.isNotEmpty ? hourly : daily).first.name;
    final period = hourly.isNotEmpty ? 'hourly' : 'daily';
    final count = {for (final p in [...hourly, ...daily]) p.id}.length;
    final body = count == 1
        ? '$leadName just passed you on the $period leaderboard. Win your spot back!'
        : '$count friends just passed you on the leaderboard. Win your spot back!';
    _showToast(body);
    unawaited(_notifs.show('You lost your spot!', body));
  }

  /// Once a minute: roll stale point buckets and refresh this player's row
  /// (which also keeps the "online" dot alive for friends).
  void _heartbeat() {
    final now = DateTime.now();
    final hourKey = hourKeyOf(now);
    final dayKey = dayKeyOf(now);
    if (hourKey != state.heroHourKey || dayKey != state.heroDayKey) {
      state = state.copyWith(
        heroHourlyPoints: rolledPoints(state.heroHourlyPoints, state.heroHourKey, hourKey),
        heroDailyPoints: rolledPoints(state.heroDailyPoints, state.heroDayKey, dayKey),
        heroHourKey: hourKey,
        heroDayKey: dayKey,
      );
    }
    _subscribeGlobals();
    _reportScore();
  }

  /// (Re)subscribes the world top-10 streams; called at init and again from
  /// the heartbeat so a new hour/day swaps in a fresh query.
  void _subscribeGlobals() {
    final now = DateTime.now();
    final hourKey = hourKeyOf(now);
    final dayKey = dayKeyOf(now);
    if (_hourlySubKey != hourKey) {
      _hourlySubKey = hourKey;
      unawaited(_hourlySub?.cancel());
      _hourlySub = _social.watchTopPlayers(hourly: true, periodKey: hourKey).listen(
        (players) => state = state.copyWith(globalHourly: players),
        onError: (Object e) => debugPrint('world hourly stream error: $e'),
      );
    }
    if (_dailySubKey != dayKey) {
      _dailySubKey = dayKey;
      unawaited(_dailySub?.cancel());
      _dailySub = _social.watchTopPlayers(hourly: false, periodKey: dayKey).listen(
        (players) => state = state.copyWith(globalDaily: players),
        onError: (Object e) => debugPrint('world daily stream error: $e'),
      );
    }
  }

  void _reportScore() {
    if (!state.socialReady) return;
    unawaited(
      _social.reportScore(
        code: state.groupCode,
        name: _playerName,
        chips: state.chips,
        hourly: state.heroHourlyPoints,
        daily: state.heroDailyPoints,
        hourKey: state.heroHourKey,
        dayKey: state.heroDayKey,
      ),
    );
  }

  /// Creates the group on first use, then opens WhatsApp with a ready-to-send
  /// invite so the user can drop it into any group chat.
  Future<void> shareInviteWhatsApp() async {
    if (!state.socialReady) {
      _showToast('No connection — try again in a moment');
      return;
    }
    var code = state.groupCode;
    code ??= await _social.createGroup(_playerName, _rng);
    if (!mounted) return;
    if (code == null) {
      _showToast('Could not create your group — try again');
      return;
    }
    if (state.groupCode == null) _subscribeGroup(code);
    _reportScore();

    final text = Uri.encodeComponent(
      '🃏 Come play Blackjack 21 with me!\n'
      'Join my friends table and try to beat my hourly score.\n\n'
      'Group code: $code\n\n'
      'Open Blackjack 21 → Friends → Join a friends group → enter $code',
    );
    final opened = await _openExternal(Uri.parse('https://wa.me/?text=$text'));
    if (!opened) _showToast('Could not open WhatsApp');
  }

  Future<bool> _openExternal(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }

  Future<void> joinGroupByCode() async {
    final code = state.friendCodeInput.trim().toUpperCase();
    if (code.length != SocialService.codeLength) {
      _showToast('Enter the ${SocialService.codeLength}-character group code');
      return;
    }
    if (!state.socialReady) {
      _showToast('No connection — try again in a moment');
      return;
    }
    final ok = await _social.joinGroup(code, _playerName);
    if (!mounted) return;
    if (!ok) {
      _showToast('Group $code not found');
      return;
    }
    state = state.copyWith(friendCodeInput: '', referralsCount: state.referralsCount + 1);
    _subscribeGroup(code);
    _reportScore();
    _showToast('Joined group $code!');
    _playSfx(GameSfx.win);
    _hapticMedium();
  }

  void toggleBadgePeriod() => state = state.copyWith(badgeHourly: !state.badgeHourly);

  /// Comeback dealing: when the hero is short-stacked or on a losing streak,
  /// the opening hand is the best of [kComebackTries] candidate pairs instead
  /// of one blind draw. See `utils/comeback.dart` for the mechanics.
  int _comebackTries() {
    final minBet = state.stake?.min ?? kChipDenoms.first;
    final shortStack = state.chips < minBet * kComebackMinBetCover;
    final h = state.history;
    final losingStreak =
        h.length >= kComebackLossStreak &&
        h.sublist(h.length - kComebackLossStreak).every((r) => r == RoundResult.loss);
    return (shortStack || losingStreak) ? kComebackTries : 1;
  }

  // ---------------------------------------------------------------------
  // Navigation / auth
  // ---------------------------------------------------------------------

  Future<void> signInGoogle() async {
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _showToast('Google sign-in failed. Please try again.');
      }
      return;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      _showToast('Google sign-in failed. Please try again.');
      return;
    }

    try {
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      state = state.copyWith(
        signedIn: true,
        displayName: user?.displayName ?? account.displayName ?? 'Player',
        photoUrl: user?.photoURL ?? account.photoUrl,
        screen: AppScreen.lobby,
      );
      _reportScore();
    } on FirebaseAuthException {
      _showToast('Google sign-in failed. Please try again.');
    }
  }

  void playGuest() =>
      state = state.copyWith(signedIn: false, displayName: 'Guest', photoUrl: null, screen: AppScreen.lobby);

  Future<void> signOutUser() async {
    await Future.wait([GoogleSignIn.instance.signOut(), FirebaseAuth.instance.signOut()]);
    state = state.copyWith(signedIn: false, displayName: 'Guest', photoUrl: null);
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
    return tableSeats(state).map((_) => NpcSeat(bet: minBet * mults[_rng.nextInt(mults.length)])).toList();
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

  // ---------------------------------------------------------------------
  // Daily bonus: once-per-24h chips claim + scheduled reminder
  // ---------------------------------------------------------------------

  /// Restores the persisted last-claim time on launch, then re-arms the
  /// reminder — the fixed notification id makes re-scheduling idempotent, so
  /// this also heals a reminder lost to a reinstall.
  Future<void> _restoreDailyBonus() async {
    final last = await _bonusStore.loadLastClaim();
    if (!mounted || last == null) return;
    state = state.copyWith(lastDailyBonusClaimAt: last);
    await _syncDailyBonusReminder();
  }

  /// Keeps at most one pending "daily chips ready" notification, matching the
  /// current cooldown and the Settings "Daily reminder" toggle.
  Future<void> _syncDailyBonusReminder() async {
    final now = DateTime.now();
    final last = state.lastDailyBonusClaimAt;
    if (!state.notifDaily || last == null || isDailyBonusReady(last, now)) {
      await _notifs.cancelDailyBonusReminder();
      return;
    }
    await _notifs.scheduleDailyBonusReminder(
      after: last.add(kDailyBonusCooldown).difference(now),
      chips: kDailyBonusChips,
    );
  }

  void claimDailyBonus() {
    final now = DateTime.now();
    if (!isDailyBonusReady(state.lastDailyBonusClaimAt, now)) return;
    state = state.copyWith(chips: state.chips + kDailyBonusChips, lastDailyBonusClaimAt: now);
    unawaited(_bonusStore.saveLastClaim(now));
    unawaited(_syncDailyBonusReminder());
    _scheduleSave();
    _showToast('+$kDailyBonusChips chips claimed!');
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
    final tableMax = state.stake?.max;
    if (tableMax != null && state.bet + amount > tableMax) {
      _showToast('Table maximum is \$${formatChips(tableMax)}');
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
    final stake = state.stake;
    if (state.phase != RoundPhase.betting || bet <= 0 || bet > chips) return;
    // The table limits are a rule, not decoration: a bet outside them never deals.
    if (stake != null && (bet < stake.min || bet > stake.max)) return;

    final npcSeats = _dealNpcCards();
    if (_shoe.length < 15) _shoe = BlackjackRules.buildShoe(kDeckCount, _rng);
    final playerCards = drawStartingPair(_shoe, tries: _comebackTries());
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
    final seats = tableSeats(state);
    for (var i = 0; i < state.npcSeats.length; i++) {
      final n = state.npcSeats[i];
      if (n.cards.isEmpty) continue;
      final v = BlackjackRules.handValue(n.cards);
      // Live friends can change mid-round; never index past the current list.
      final seatName = i < seats.length ? seats[i].firstName : 'Player';
      final dealerBust = dealerVal > 21;
      seatResults.add(
        _SeatResult(
          name: seatName,
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
      if (heroTakesPot) {
        _playVoice(GameVoice.playerPot);
        _celebrateSweep();
      } else {
        _playVoice(GameVoice.playerWin);
      }
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

    // Hourly/daily point buckets roll over when the clock period changed
    // since the last hand, then absorb this round's net result.
    final now = DateTime.now();
    final hourKey = hourKeyOf(now);
    final dayKey = dayKeyOf(now);
    final heroHourly = rolledPoints(state.heroHourlyPoints, state.heroHourKey, hourKey) + sessionNetDelta;
    final heroDaily = rolledPoints(state.heroDailyPoints, state.heroDayKey, dayKey) + sessionNetDelta;

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
      heroHourlyPoints: heroHourly,
      heroDailyPoints: heroDaily,
      heroHourKey: hourKey,
      heroDayKey: dayKey,
    );
    _reportScore();
    _scheduleSave();
  }

  void nextHand() {
    // The tutorial advances here rather than at settlement, so the last card
    // of a hand is still the recap of the hand the player just finished.
    final tutorialSeen = min(state.tutorialRoundsSeen + 1, kTutorialRounds);
    final tutorialAdvanced = tutorialSeen != state.tutorialRoundsSeen;

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
      tutorialRoundsSeen: tutorialSeen,
    );
    // Only the first few hands move this, so veterans pay no extra disk write.
    if (tutorialAdvanced) _scheduleSave();
  }

  // ---------------------------------------------------------------------
  // Tutorial — the coached first hands and their off/replay switches
  // ---------------------------------------------------------------------

  /// "Skip" on the coach card. The cards stop immediately and stay off until
  /// the player replays the tutorial from Settings.
  void skipTutorial() {
    if (state.tutorialDismissed) return;
    state = state.copyWith(tutorialDismissed: true);
    _scheduleSave();
    _hapticSelection();
    _showToast('Tutorial off — replay it any time from Settings');
  }

  /// Settings → "Replay the tutorial": back to lesson one from the next bet.
  void restartTutorial() {
    state = state.copyWith(tutorialRoundsSeen: 0, tutorialDismissed: false);
    _scheduleSave();
    _hapticSelection();
    _showToast('Tutorial on — deal a hand to start it');
  }

  void resetBankroll() {
    state = state.copyWith(chips: kStartingChips);
    _scheduleSave();
  }

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


  void joinTournament() {
    if (state.tournamentJoined) return;
    state = state.copyWith(tournamentJoined: true);
    _showToast("You're in! Good luck in the Weekend Cup.");
  }

  void claimTier(String id, int need, int reward) {
    if (state.referralsCount < need || state.claimedTiers.contains(id)) return;
    state = state.copyWith(chips: state.chips + reward, claimedTiers: [...state.claimedTiers, id]);
    _scheduleSave();
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
  void selectCardBack(String id) {
    state = state.copyWith(cardBackSkin: id);
    _scheduleSave();
  }
  void selectFelt(String id) => state = state.copyWith(themeChoice: id);
  void setAvatarFrame(bool gold) {
    state = state.copyWith(avatarFrameGold: gold);
    _scheduleSave();
  }

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

  void _setTheme(String choice) {
    state = state.copyWith(themeChoice: choice);
    _scheduleSave();
  }

  void selectThemeDefault() => _setTheme('default');
  void selectThemeOcean() => _setTheme('ocean');
  void selectThemeEmber() => _setTheme('ember');
  void toggleHaptics() {
    final next = !state.hapticsOn;
    state = state.copyWith(hapticsOn: next);
    if (next) HapticFeedback.mediumImpact();
    _scheduleSave();
  }

  void toggleSound() {
    final next = !state.soundOn;
    state = state.copyWith(soundOn: next);
    if (next) unawaited(_sound.play(GameSfx.chip));
    _scheduleSave();
  }
  void toggleTableMenu() => state = state.copyWith(tableMenuOpen: !state.tableMenuOpen);
  void toggleTableChat() => state = state.copyWith(tableChatOpen: !state.tableChatOpen, tableMenuOpen: false);
  void toggleNotifSocial() {
    state = state.copyWith(notifSocial: !state.notifSocial);
    _scheduleSave();
  }

  void toggleNotifLeaderboard() {
    state = state.copyWith(notifLeaderboard: !state.notifLeaderboard);
    _scheduleSave();
  }

  void toggleNotifDaily() {
    state = state.copyWith(notifDaily: !state.notifDaily);
    // Off cancels the pending reminder; on re-arms it mid-cooldown.
    unawaited(_syncDailyBonusReminder());
    _scheduleSave();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());
