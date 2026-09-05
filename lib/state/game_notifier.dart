import 'dart:async';
import 'dart:math';

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/game_data.dart';
import '../data/tutorial_data.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/hand.dart';
import '../models/playing_card.dart';
import '../models/social_models.dart';
import '../models/table_pot.dart';
import '../services/analytics.dart';
import '../services/daily_bonus_store.dart';
import '../services/game_store.dart';
import '../services/local_notifier.dart';
import '../services/social_service.dart';
import '../services/sound_player.dart';
import '../services/spoken_amount.dart';
import '../utils/achievements.dart';
import '../utils/comeback.dart';
import '../utils/daily_bonus.dart';
import '../utils/formatters.dart';
import '../utils/invite_link.dart';
import '../utils/missions.dart';
import '../utils/play_streak.dart';
import '../utils/points.dart';
import '../utils/rebuy.dart';
import '../utils/referrals.dart';
import '../utils/table_seats.dart';
import '../utils/xp.dart';

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
  /// [sound] is a seam for tests, which need to see which channel a call-out
  /// was handed to — the app always builds its own.
  GameNotifier({@visibleForTesting SoundPlayer? sound, @visibleForTesting Analytics? analytics})
      : _sound = sound ?? SoundPlayer(),
        _analytics = analytics ?? _defaultAnalytics(),
        super(const GameState(friends: kInitialFriends)) {
    _shoe = BlackjackRules.buildShoe(kDeckCount, _rng);
    // `authenticate()` throws UnimplementedError on web — Google Identity
    // Services requires its own rendered button there (see
    // widgets/google_signin_button_web.dart), and delivers the result
    // through this stream instead of a return value.
    if (kIsWeb) {
      _authEventsSub = GoogleSignIn.instance.authenticationEvents.listen(_handleAuthEvent);
    }
    unawaited(_boot());
  }

  /// Reporting is off on web (Crashlytics has no web implementation) and in
  /// tests, where a null pair makes every call a no-op rather than making each
  /// call site guard.
  static Analytics _defaultAnalytics() {
    if (kIsWeb) return Analytics();
    try {
      return Analytics(analytics: FirebaseAnalytics.instance, crashlytics: FirebaseCrashlytics.instance);
    } on Object catch (e) {
      debugPrint('Analytics unavailable: $e');
      return Analytics();
    }
  }

  final Random _rng = Random();
  final SoundPlayer _sound;
  final Analytics _analytics;
  final SocialService _social = SocialService();
  final LocalNotifier _notifs = LocalNotifier();
  final DailyBonusStore _bonusStore = DailyBonusStore();
  final GameStore _store = GameStore();
  Timer? _saveTimer;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSub;
  StreamSubscription<List<Friend>>? _groupSub;
  StreamSubscription<List<Friend>>? _hourlySub;
  StreamSubscription<List<Friend>>? _dailySub;
  String _hourlySubKey = '';
  String _dailySubKey = '';
  Timer? _heartbeatTimer;

  /// True once a live (non-empty) member snapshot has arrived, so the first
  /// snapshot after subscribing never fires overtake alerts.
  bool _groupLive = false;

  /// Guards [prefillJoinFromClipboard] to at most once per launch — repeated
  /// visits to the Friends screen must not keep re-reading the clipboard.
  bool _clipboardChecked = false;
  List<PlayingCard> _shoe = [];
  Timer? _npcTimer;

  /// Paces the dealer's turn. Deliberately *not* cancelled by [exitTable] —
  /// see [_dealerDrawStep], which settles the hand immediately instead, so
  /// leaving the table can never strand a bet.
  Timer? _dealerTimer;
  Timer? _toastTimer;
  Timer? _reactTimer;
  Timer? _adWatchTimer;
  Timer? _adCooldownTimer;
  Timer? _voiceTimer;
  Timer? _potTimer;
  Timer? _celebrationTimer;
  Timer? _handTotalTimer;
  Timer? _dealerTotalTimer;

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
    _dealerTimer?.cancel();
    _toastTimer?.cancel();
    _reactTimer?.cancel();
    _adWatchTimer?.cancel();
    _adCooldownTimer?.cancel();
    _voiceTimer?.cancel();
    _potTimer?.cancel();
    _celebrationTimer?.cancel();
    _handTotalTimer?.cancel();
    _dealerTotalTimer?.cancel();
    _heartbeatTimer?.cancel();
    unawaited(_authEventsSub?.cancel());
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

  /// `FlipRevealCard` (see `screens/table/dealer_area.dart`) takes half a
  /// second to turn the hole card face-up — `AppMotion.spatial + AppMotion.fast`
  /// in `theme/app_motion.dart`, duplicated here as a literal since state has
  /// no business importing the widget layer.
  static const Duration _kHoleCardFlipPause = Duration(milliseconds: 500);

  /// Plays a round-outcome tone (win/lose/push/blackjack).
  ///
  /// [afterFlip] holds it back until the hole-card flip has visually finished.
  /// A natural blackjack reveals the hole card and settles in the same beat —
  /// without the pause the tone fired the instant the flip *started*, so the
  /// player heard "you win" before the card had turned over. Every other path
  /// into [_settle] reveals the hole card well ahead of this call, so the tone
  /// can play at once there.
  void _playOutcomeTone(GameSfx sfx, {required bool afterFlip}) {
    if (!afterFlip) {
      _playSfx(sfx);
      return;
    }
    Timer(_kHoleCardFlipPause, () {
      if (!mounted) return;
      _playSfx(sfx);
    });
  }

  /// Whether a word may be spoken right now. Voice sits under the master
  /// sound toggle, so a player who mutes the game never hears a call-out
  /// regardless of how the voice switch is left.
  bool get _voiceOn => state.soundOn && state.voiceOn;

  /// An NPC seat's "Stand"/"Bust" line, spoken as the seat acts.
  ///
  /// Goes on the voice channel — queued behind whatever is already speaking —
  /// rather than the tone channel, where nothing held it back. That is how the
  /// opening deal came to talk over itself: the hero's "You have sixteen" was
  /// said as the cards landed and the first seat's "Bust" fired 170ms later,
  /// on the other channel, cutting it off mid-word. The total now waits for
  /// the hero's turn (see [_announceHandTotal]) so the two no longer collide
  /// at all, and the queue keeps the seats from clipping each other as they
  /// act [kNpcDecisionLead] apart.
  ///
  /// No lead of its own: the queue decides when it can be said. If the wait
  /// ever ran past [SoundPlayer.kMaxVoiceWait] the line is dropped rather than
  /// spoken over the wrong seat.
  void _playSpokenVoice(GameVoice voice) {
    if (!_voiceOn) return;
    unawaited(_sound.playVoice(voice));
  }

  /// Held back so the settlement tone plays out first and the spoken result
  /// follows it rather than talking over it. Matches `blackjack.wav`, the
  /// longest of the outcome tones at 0.70s.
  static const kVoiceLead = Duration(milliseconds: 700);

  /// Drum flourish once the pot call-out has finished. Sweeping the table is
  /// the best result a round can produce, so it gets more than a tone.
  ///
  /// With voice on, [_playVoice] schedules this itself — only the voice queue
  /// knows when the call-out actually lands, since it may be waiting behind
  /// the hand total from the player's last card. With voice off there is no
  /// call-out to clear, so the flourish follows the settlement tone directly
  /// rather than after a stretch of silence.
  void _celebrateSweep() {
    if (!state.soundOn || _voiceOn) return;
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(kVoiceLead, () => _playSfx(GameSfx.potCelebration));
  }

  /// Speaks the hand's result [kVoiceLead] after the outcome tone. Re-checks
  /// the toggles when the timer fires, so muting mid-hand also mutes the
  /// pending call-out.
  ///
  /// [celebrate] chases the line with the sweep-pot drum. It is scheduled from
  /// the moment the words actually finish rather than a fixed offset, because
  /// the queue may have held the line back behind the hand total.
  void _playVoice(GameVoice voice, {bool celebrate = false}) {
    if (!_voiceOn) return;
    _voiceTimer?.cancel();
    _voiceTimer = Timer(kVoiceLead, () async {
      if (!_voiceOn) return;
      final endsAt = await _sound.playVoice(voice);
      if (!celebrate || endsAt == null || !state.soundOn) return;
      _celebrationTimer?.cancel();
      _celebrationTimer = Timer(
        endsAt.difference(DateTime.now()),
        () => _playSfx(GameSfx.potCelebration),
      );
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

  /// A short roll of taps building to one heavy hit, for the two results
  /// worth marking: a natural blackjack, and sweeping the table.
  ///
  /// The felt now throws confetti and flies the beaten seats' chips over to
  /// the player for these; a single `mediumImpact` under all of that felt like
  /// the same acknowledgement a chip tap gets.
  void _hapticCelebrate() {
    if (!state.hapticsOn) return;
    HapticFeedback.mediumImpact();
    for (var i = 1; i <= 2; i++) {
      Timer(Duration(milliseconds: 90 * i), () {
        if (state.hapticsOn) HapticFeedback.mediumImpact();
      });
    }
    Timer(const Duration(milliseconds: 320), () {
      if (state.hapticsOn) HapticFeedback.heavyImpact();
    });
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
    _announceTurn();
  }

  /// The two spoken lines that greet the hero's turn, in the order they are
  /// heard: what the table is playing for, a beat to let that land, then the
  /// hand they have to play it with — the last thing said before they act.
  void _announceTurn() {
    if (!_voiceOn) return;
    final cards = state.hands[state.activeHandIndex].cards;
    final pot = _potWords();

    _potTimer?.cancel();
    _potTimer = Timer(kTurnVoiceLead, () async {
      if (!_voiceOn) return;
      final endsAt = await _sound.playWords(pot);
      // The pot line's length depends on the figure, so the pause after it is
      // measured from when it actually finishes rather than a fixed offset.
      final remaining = endsAt?.difference(DateTime.now()) ?? Duration.zero;
      final lead = (remaining.isNegative ? Duration.zero : remaining) + kPostPotPause;

      // A quick player can hit or stand while the pot is still being called.
      // Their own move announces the hand it produced, so this line would be
      // both a repeat and out of date.
      if (state.phase != RoundPhase.playing) return;
      if (!listEquals(state.hands[state.activeHandIndex].cards, cards)) return;
      _announceHandTotal(cards, lead: lead);
    });
  }

  /// What the table is playing for, as words — reading out the same dealer
  /// pill the felt shows, so the two can never disagree.
  ///
  /// "No sweep pot" when no seat has forfeited a bet yet: with every opponent
  /// still in there is nothing to sweep, and calling the chips on the felt as
  /// one would promise a pot that does not exist. The pill says exactly that,
  /// and now so does the voice — silence left the player wondering whether the
  /// call-out had been missed.
  List<String> _potWords() {
    final pot = TablePot.live(state);
    if (!pot.isSweep) return const ['no_sweep_pot'];
    final amount = spokenAmountWords(pot.amount);
    if (amount.isEmpty) return const ['no_sweep_pot'];
    return ['sweep_pot', ...amount, 'dollars'];
  }

  /// A beat between the pot call-out and the hand total, so the two arrive as
  /// separate pieces of news rather than one run-on sentence.
  static const Duration kPostPotPause = Duration(seconds: 1);


  /// Speaks the hero's hand total — the number shown in the hand-total circle
  /// in [HeroHandArea] — when the action reaches them, and again after every
  /// card they take: a hit, a double, or a split. Going over 21 is called as
  /// a bust rather than a number, the same way the dealer's is: "Player busts"
  /// is what just happened to the hand, and "You have twenty three" leaves the
  /// player to work that out for themselves.
  ///
  /// It used to be said at the deal instead, over the top of the opponent
  /// seats: they start acting [kNpcDecisionLead] in and call out "Stand" or
  /// "Bust" as they go, so the hero's own total arrived in the middle of
  /// somebody else's turn. Held until the table comes round to them, it is
  /// about the hand they are being asked to play.
  ///
  /// [lead] holds the line back until the tone that cued it has finished:
  /// [kHandTotalVoiceLead] clears `deal.wav` (0.09s) as a card lands,
  /// [kTurnVoiceLead] clears the longer `turn.wav` (0.60s) at the hero's turn.
  void _announceHandTotal(
    List<PlayingCard> cards, {
    Duration lead = kHandTotalVoiceLead,
  }) {
    if (!_voiceOn) return;
    final value = BlackjackRules.handValue(cards);
    final List<String> line;
    if (value > 21) {
      line = const ['player_bust'];
    } else {
      final words = spokenAmountWords(value);
      if (words.isEmpty) return;
      line = ['you_have', ...words];
    }
    _handTotalTimer?.cancel();
    _handTotalTimer = Timer(lead, () {
      if (!_voiceOn) return;
      unawaited(_sound.playWords(line));
    });
  }

  static const kHandTotalVoiceLead = Duration(milliseconds: 350);

  /// What the dealer holds, as words — the number its badge shows, named as
  /// the dealer's only on the [opening] call, and except for the two totals
  /// that are news rather than arithmetic:
  ///
  /// * a natural is called by name — "Dealer has blackjack" is the hand that
  ///   ends the round on the spot, and the settlement call-out queues behind
  ///   it: "Dealer has blackjack. Player lost."
  /// * going over 21 is called as a bust — "Dealer busts" is why the hand was
  ///   won, and hearing "Dealer has twenty three" instead leaves the player to
  ///   work that out for themselves.
  ///
  /// Null when there is nothing to say: the voice is off, or the total has no
  /// words.
  List<String>? _dealerTotalWords({required bool opening}) {
    if (!_voiceOn) return null;
    final hand = state.dealerHand;
    final value = BlackjackRules.handValue(hand);
    if (value > 21) return const ['dealer_bust'];
    if (hand.length == 2 && value == 21) return const ['dealer_has', 'blackjack'];
    final words = spokenAmountWords(value);
    if (words.isEmpty) return null;
    // "Dealer has" is said once, on the reveal, and the draws that follow are
    // just the running total: "Dealer has fourteen… eighteen… twenty two."
    // Repeating the whole phrase every card made the dealer's turn a chant.
    return opening ? ['dealer_has', ...words] : words;
  }

  /// Speaks the dealer's total where nothing follows it — the natural that
  /// settles the round the moment the hole card turns over.
  void _announceDealerTotal() {
    final words = _dealerTotalWords(opening: true);
    if (words == null) return;
    _dealerTotalTimer?.cancel();
    _dealerTotalTimer = Timer(kDealerVoiceLead, () {
      if (!_voiceOn) return;
      unawaited(_sound.playWords(words));
    });
  }

  /// Long enough for a fresh card to be seen landing; `deal.wav` (0.09s) is
  /// over well before it.
  static const kDealerVoiceLead = Duration(milliseconds: 200);

  /// The hole card's own lead is longer, because the reveal follows the hero's
  /// last card rather than the dealer's own: that card's call-out is cued
  /// [kHandTotalVoiceLead] after it lands, and the player should hear what
  /// became of their hand — "Player busts" — before hearing what the dealer
  /// turned over. Cued after it, the voice channel keeps them in that order.
  static const kDealerRevealVoiceLead = Duration(milliseconds: 500);

  /// A breath between the dealer saying what it holds and touching the next
  /// card, so the two do not run together.
  static const kDealerVoiceTail = Duration(milliseconds: 250);

  /// Held back so the turn cue (`turn.wav`, 0.60s) finishes first. The first
  /// line due at the hero's turn waits it out; see [_announceTurn].
  static const kTurnVoiceLead = Duration(milliseconds: 700);

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
      voiceOn: saved.voiceOn,
      languageOverride: saved.languageOverride,
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
      tipsSeen: saved.tipsSeen,
      tournamentJoined: saved.tournamentJoined,
      // Send a returning player where they belong instead of back through the
      // sign-in gate. `screen` itself is never persisted — dropping someone
      // onto the felt mid-round is not "where I left off" — so onboarding
      // resolves to the same destination it would have after signing in.
      screen: saved.onboardingDone ? _postOnboardingScreenFor(saved) : null,
      avatarColor: saved.avatarColor == 0 ? null : Color(saved.avatarColor),
      rewardedReferralIds: saved.rewardedReferralIds,
      playDayStreak: saved.playDayStreak,
      lastPlayDayKey: saved.lastPlayDayKey,
      lastRebuyAt: saved.lastRebuyAtMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(saved.lastRebuyAtMs),
      analyticsOn: saved.analyticsOn,
      unlockedAchievements: saved.unlockedAchievements,
      xp: saved.xp,
      // Yesterday's missions are not today's: the set is redrawn from the day
      // key, so stale progress has to go with it or a player would open the
      // app to three new goals already part-finished.
      missionDayKey: saved.missionDayKey == dayKey ? saved.missionDayKey : dayKey,
      missionProgress: saved.missionDayKey == dayKey ? saved.missionProgress : const {},
      missionsClaimed: saved.missionDayKey == dayKey ? saved.missionsClaimed : const [],
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
    voiceOn: state.voiceOn,
    languageOverride: state.languageOverride,
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
    tipsSeen: state.tipsSeen,
    tournamentJoined: state.tournamentJoined,
    // Anywhere past the gate counts as done: the player got in, whether by
    // signing in or as a guest.
    onboardingDone: state.screen != AppScreen.onboarding,
    avatarColor: state.avatarColor.toARGB32(),
    rewardedReferralIds: state.rewardedReferralIds,
    playDayStreak: state.playDayStreak,
    lastPlayDayKey: state.lastPlayDayKey,
    lastRebuyAtMs: state.lastRebuyAt?.millisecondsSinceEpoch ?? 0,
    analyticsOn: state.analyticsOn,
    unlockedAchievements: state.unlockedAchievements,
    xp: state.xp,
    missionDayKey: state.missionDayKey,
    missionProgress: state.missionProgress,
    missionsClaimed: state.missionsClaimed,
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
    if (code != null) {
      _subscribeGroup(code);
    } else if (state.pendingJoinCode != null) {
      // A deep link arrived before the social layer was ready (cold start) —
      // act on it now that it is.
      unawaited(_joinCode(state.pendingJoinCode!, viaLink: true));
    }
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

    final wasGroupLive = _groupLive;
    _groupLive = members.isNotEmpty;
    // Alone in the group → practice bots keep the table lively, but
    // `friendsAreLive` stays false so friend lists can tell bots from people.
    state = state.copyWith(
      friends: members.isEmpty ? kInitialFriends : members,
      friendsAreLive: members.isNotEmpty,
    );

    _payOutstandingReferrals(members, wasWatchingBefore: wasGroupLive);
  }

  /// Pays the inviter for every referred friend not yet rewarded, and
  /// republishes the honest, derived referral count. Runs on every snapshot
  /// (not just a fresh join) so a friend who joined while this device was
  /// offline still gets credited the moment the stream reconnects.
  void _payOutstandingReferrals(List<Friend> members, {required bool wasWatchingBefore}) {
    final me = _social.uid;
    if (me == null) return;
    final unpaid = unrewardedReferrals(members, me, state.rewardedReferralIds);
    if (unpaid.isNotEmpty) {
      state = state.copyWith(
        chips: state.chips + unpaid.length * kReferralJoinChips,
        rewardedReferralIds: [...state.rewardedReferralIds, ...unpaid.map((f) => f.id)],
      );
      _scheduleSave();
      final name = unpaid.first.firstName;
      final body = unpaid.length == 1
          ? '$name joined your table! +$kReferralJoinChips chips'
          : '${unpaid.length} friends joined your table! +${unpaid.length * kReferralJoinChips} chips';
      _showToast(body);
      // A notification only makes sense once this is a live update rather
      // than the first snapshot after (re)subscribing — the same gate
      // `_notifyOvertaken` above uses, so a relaunch never spams a
      // notification for referrals that joined while the app was closed.
      if (wasWatchingBefore && state.notifSocial) {
        unawaited(_notifs.show('New friend at your table', body));
        _playSfx(GameSfx.win);
      }
    }
    state = state.copyWith(referralsCount: referralCount(members, me));
    // "Well Connected" is the one achievement nothing the player does at the
    // table can trigger — it lands when someone else accepts an invite.
    _awardAchievements();
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

  /// Called by [AppLifecycleBridge] whenever the app comes back to the
  /// foreground. Nothing here was previously handled at all — a resume used
  /// to wait for the next 60s heartbeat tick to roll a stale point bucket or
  /// notice a day has turned over.
  void onAppResumed() {
    if (!state.socialReady) return;
    _heartbeat();
    unawaited(_syncDailyBonusReminder());
    unawaited(_syncStreakReminder());
    if (state.pendingJoinCode != null) unawaited(_joinCode(state.pendingJoinCode!, viaLink: true));
  }

  /// Called by [AppLifecycleBridge] when the app is backgrounded — flushes
  /// any save still waiting out its debounce, the same way [dispose] does,
  /// so a swipe-away right after a hand never loses it.
  void onAppPaused() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      unawaited(_store.save(_snapshot()));
    }
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
        tableKey: state.screen == AppScreen.table ? (state.stake?.key ?? '') : '',
      ),
    );
  }

  /// Resolves the player's locale for invite text and toasts to the same
  /// precedence `MaterialApp.locale` uses in main.dart: an explicit Settings
  /// choice, else the device locale.
  AppLocalizations _appLocalizations() {
    final code = state.languageOverride ?? PlatformDispatcher.instance.locale.languageCode;
    final locale = AppLocalizations.supportedLocales.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => const Locale('en'),
    );
    return lookupAppLocalizations(locale);
  }

  String _inviteText(String code) => _appLocalizations().inviteMessage(inviteUri(code).toString());

  /// Creates the group on first use (idempotent otherwise) so every invite
  /// channel below shares the same code.
  Future<String?> _ensureGroupCode() async {
    if (!state.socialReady) {
      _showToast('No connection — try again in a moment');
      return null;
    }
    var code = state.groupCode;
    code ??= await _social.createGroup(_playerName, _rng);
    if (!mounted) return null;
    if (code == null) {
      _showToast('Could not create your group — try again');
      return null;
    }
    if (state.groupCode == null) _subscribeGroup(code);
    _reportScore();
    return code;
  }

  /// Opens WhatsApp with a ready-to-send invite — the single link every
  /// channel shares, so the recipient never has to navigate the app by hand.
  Future<void> shareInviteWhatsApp() async {
    final code = await _ensureGroupCode();
    if (code == null) return;
    final text = Uri.encodeComponent(_inviteText(code));
    final opened = await _openExternal(Uri.parse('https://wa.me/?text=$text'));
    if (!opened) _showToast('Could not open WhatsApp');
    // The invite is the app's only growth loop, so whether it was even opened
    // is worth knowing. The code itself is never logged.
    unawaited(_analytics.logEvent(AnalyticsEvent.inviteShared, {'channel': 'whatsapp', 'opened': opened ? 1 : 0}));
  }

  /// The system share sheet — for friends not reachable over WhatsApp.
  Future<void> shareInviteSheet() async {
    final code = await _ensureGroupCode();
    if (code == null) return;
    await SharePlus.instance.share(ShareParams(text: _inviteText(code)));
  }

  /// Copies the bare link, mainly useful on web where a share sheet may not
  /// exist.
  Future<void> copyInviteLink() async {
    final code = await _ensureGroupCode();
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: inviteUri(code).toString()));
    _showToast('Link copied');
  }

  Future<bool> _openExternal(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }

  /// Reads the join field, validates it, and joins. The typed-code entry
  /// point for [_joinCode] — see [handleIncomingLink] for the link entry
  /// point sharing the same join logic.
  Future<void> joinGroupByCode() async {
    final code = state.friendCodeInput.trim().toUpperCase();
    if (!isValidJoinCode(code)) {
      _showToast('Enter the ${SocialService.codeLength}-character group code');
      return;
    }
    await _joinCode(code, viaLink: false);
  }

  /// Parses an incoming deep link (a tapped invite, or `Uri.base` on web) and
  /// joins immediately if the social layer is already up, otherwise queues
  /// it as [GameState.pendingJoinCode] for `_initSocial`/[onAppResumed] to
  /// retry once it is.
  void handleIncomingLink(String route) {
    final code = joinCodeFromRoute(route);
    if (code == null) return;
    if (state.socialReady) {
      unawaited(_joinCode(code, viaLink: true));
    } else {
      state = state.copyWith(pendingJoinCode: code);
    }
  }

  /// Reads whatever text is on the clipboard — a pasted invite message, or a
  /// bare code — and pre-fills the join field. Skipped on web, where reading
  /// the clipboard needs a user gesture the Friends screen visit itself does
  /// not provide, and skipped once already tried this launch.
  Future<void> prefillJoinFromClipboard() async {
    if (kIsWeb || _clipboardChecked) return;
    _clipboardChecked = true;
    if (state.groupCode != null || state.friendCodeInput.isNotEmpty) return;
    try {
      final data = await Clipboard.getData('text/plain');
      final code = data?.text == null ? null : joinCodeFromText(data!.text!);
      if (code != null && mounted) state = state.copyWith(friendCodeInput: code);
    } on PlatformException {
      // No clipboard access — nothing to pre-fill, nothing to report.
    }
  }

  /// Shared by [joinGroupByCode] and [handleIncomingLink]/deep links.
  Future<void> _joinCode(String code, {required bool viaLink}) async {
    if (!state.socialReady) {
      state = state.copyWith(pendingJoinCode: code);
      return;
    }
    final result = await _social.joinGroup(code, _playerName);
    if (!mounted) return;
    switch (result) {
      case JoinResult.notFound:
        _showToast('Group $code not found');
        return;
      case JoinResult.failed:
        _showToast('No connection — try again in a moment');
        return;
      case JoinResult.alreadyMember:
        final ownTable = await _social.isGroupCreator(code);
        if (!mounted) return;
        state = state.copyWith(friendCodeInput: '', pendingJoinCode: null);
        _subscribeGroup(code);
        _reportScore();
        _showToast(ownTable ? _appLocalizations().joinOwnTableToast : _appLocalizations().joinAlreadyMemberToast);
        return;
      case JoinResult.joined:
        // Referral credit and the join bonus flow through `_onGroupUpdate`'s
        // `unrewardedReferrals` check once the group stream delivers this
        // row back — that path also covers a friend who joined while this
        // device was offline, which a one-shot bonus here would miss.
        state = state.copyWith(
          friendCodeInput: '',
          pendingJoinCode: null,
          joinedViaLink: viaLink || state.joinedViaLink,
          chips: state.chips + kReferralWelcomeChips,
        );
        _subscribeGroup(code);
        _reportScore();
        _scheduleSave();
        _showToast(_appLocalizations().joinedTableToast(kReferralWelcomeChips));
        _playSfx(GameSfx.win);
        _hapticMedium();
        return;
    }
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

  /// Mobile/desktop only — web's `authenticate()` throws `UnimplementedError`
  /// and instead delivers its result through [_handleAuthEvent].
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
    await _completeGoogleSignIn(account);
  }

  void _handleAuthEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      unawaited(_completeGoogleSignIn(event.user));
    }
  }

  Future<void> _completeGoogleSignIn(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      _showToast('Google sign-in failed. Please try again.');
      return;
    }

    try {
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final current = FirebaseAuth.instance.currentUser;
      UserCredential userCredential;
      // A guest who signs in should keep the group/leaderboard identity tied
      // to their anonymous uid, not lose it to a brand-new one — so link the
      // Google credential onto the existing anonymous user rather than
      // replacing the session outright.
      if (current != null && current.isAnonymous) {
        try {
          userCredential = await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          // This Google account already has its own uid elsewhere — fall
          // back to signing into that account, then re-adopt whatever group
          // it (or this device) already belongs to.
          if (e.code != 'credential-already-in-use' && e.code != 'email-already-in-use') rethrow;
          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          await _rebindSocialIdentity();
        }
      } else {
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        await _rebindSocialIdentity();
      }
      final user = userCredential.user;
      state = state.copyWith(
        signedIn: true,
        displayName: user?.displayName ?? account.displayName ?? 'Player',
        photoUrl: user?.photoURL ?? account.photoUrl,
        screen: _postOnboardingScreen,
        heroUid: _social.uid,
      );
      _reportScore();
    } on FirebaseAuthException {
      _showToast('Google sign-in failed. Please try again.');
    }
  }

  /// After the Firebase uid changes underneath an already-running session
  /// (the credential-already-in-use fallback above), the group subscription
  /// and `heroUid` would otherwise keep pointing at the old identity. Re-read
  /// membership for the new uid, and if it has none but this device was
  /// already in a group, rejoin that same group under the new uid.
  Future<void> _rebindSocialIdentity() async {
    if (!mounted) return;
    state = state.copyWith(heroUid: _social.uid);
    final code = await _social.fetchMyGroupCode();
    if (!mounted) return;
    if (code != null) {
      _subscribeGroup(code);
    } else if (state.groupCode != null) {
      await _social.joinGroup(state.groupCode!, _playerName);
      if (!mounted) return;
      _subscribeGroup(state.groupCode!);
    }
    _reportScore();
  }

  void playGuest() =>
      state = state.copyWith(signedIn: false, displayName: 'Guest', photoUrl: null, screen: _postOnboardingScreen);

  /// Where leaving onboarding lands: brand-new players get the one-time
  /// "Four things to know" primer first; anyone with hands on the clock (or
  /// who already saw it) goes straight to the lobby.
  AppScreen get _postOnboardingScreen =>
      !state.tipsSeen && state.stats.handsPlayed == 0 ? AppScreen.tips : AppScreen.lobby;

  /// The same rule, applied to a blob being restored — at hydrate time the
  /// live state has not been populated yet, so it cannot be asked.
  static AppScreen _postOnboardingScreenFor(SavedGame saved) =>
      !saved.tipsSeen && saved.stats.handsPlayed == 0 ? AppScreen.tips : AppScreen.lobby;

  /// Both exits of the tips screen. "I've played before — skip" also turns
  /// the three-hand tutorial off, since the player just said they know the
  /// game; "Deal me in" leaves it on.
  void finishTips({bool skipTutorial = false}) {
    state = state.copyWith(
      tipsSeen: true,
      screen: AppScreen.lobby,
      tutorialDismissed: skipTutorial ? true : state.tutorialDismissed,
    );
    _scheduleSave();
  }

  Future<void> signOutUser() async {
    await Future.wait([GoogleSignIn.instance.signOut(), FirebaseAuth.instance.signOut()]);
    state = state.copyWith(signedIn: false, displayName: 'Guest', photoUrl: null);
    _showToast('Signed out');
  }

  void goLobby() => state = state.copyWith(screen: AppScreen.lobby);
  void goStats() => state = state.copyWith(screen: AppScreen.stats);
  void goFriends() {
    state = state.copyWith(screen: AppScreen.friends);
    unawaited(prefillJoinFromClipboard());
  }
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
    // Publish table presence immediately rather than waiting up to 60s for
    // the heartbeat, so a friend's lobby card shows "here" right away.
    _reportScore();
    // Sitting at the VIP table is an achievement in its own right, and it can
    // happen without a hand being played.
    _awardAchievements();
    unawaited(_analytics.logEvent(AnalyticsEvent.tableEntered, {'stake': t.key}));
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
    _npcTimer = Timer(kNpcDecisionLead, () => _npcDecide(order, k));
  }

  /// How long a seat is shown as acting before it plays its card and speaks.
  /// The first seat's line therefore lands this long after the deal — while
  /// the hero's own "You have sixteen", cued [kHandTotalVoiceLead] in, is
  /// still being said. That overlap is why the seat lines belong on the
  /// queued voice channel; see [_playSpokenVoice].
  static const Duration kNpcDecisionLead = Duration(milliseconds: 520);

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
        _playSpokenVoice(GameVoice.npcBust);
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
      _playSpokenVoice(GameVoice.npcStand);
      _hapticSelection();
      _npcTimer = Timer(const Duration(milliseconds: 480), () => _stepNpc(order, k + 1));
    }
  }

  void exitTable() {
    _npcTimer?.cancel();
    state = state.copyWith(screen: AppScreen.lobby, actingSeat: null);
    _reportScore();
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

  /// A quick-reply chip in the table chat: posts a real "You" bubble into the
  /// chat log (capped like the NPC lines) and floats the reaction over the
  /// table. Canned-only on purpose — no free text, no moderation surface.
  void sendChatMessage(String text) {
    final appended = [
      ...state.chatMessages,
      ChatMessage(name: 'You', text: text, id: DateTime.now().millisecondsSinceEpoch),
    ];
    state = state.copyWith(
      chatMessages: appended.length > kChatLogLimit ? appended.sublist(appended.length - kChatLogLimit) : appended,
    );
    sendReaction(text);
    _hapticSelection();
  }

  // ---------------------------------------------------------------------
  // Daily bonus: once-per-24h chips claim + scheduled reminder
  // ---------------------------------------------------------------------

  /// Restores the persisted last-claim time on launch, then re-arms the
  /// reminder — the fixed notification id makes re-scheduling idempotent, so
  /// this also heals a reminder lost to a reinstall.
  Future<void> _restoreDailyBonus() async {
    final last = await _bonusStore.loadLastClaim();
    final streakDay = await _bonusStore.loadStreakDay();
    if (!mounted || last == null) return;
    state = state.copyWith(lastDailyBonusClaimAt: last, dailyBonusStreakDay: streakDay);
    await _syncDailyBonusReminder();
    await _syncStreakReminder();
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
    // Quote what a claim at the moment of unlock would actually pay — day 7
    // of a live streak is worth 1,000, not the flat 250, and a live play-day
    // streak still standing at unlock time adds its own bonus on top.
    final unlockAt = last.add(kDailyBonusCooldown);
    final dayAtUnlock = nextDailyBonusStreakDay(state.dailyBonusStreakDay, last, unlockAt);
    await _notifs.scheduleDailyBonusReminder(
      after: unlockAt.difference(now),
      chips: dailyBonusRewardForDay(dayAtUnlock) + _playStreakBonusNow(unlockAt),
    );
  }

  /// Keeps at most one pending "streak ends tonight" notification, matching
  /// the live play-day streak and the Settings "Daily reminder" toggle
  /// (there is no separate toggle for this one — it is the same promise:
  /// "remind me to come back today").
  Future<void> _syncStreakReminder() async {
    final now = DateTime.now();
    final liveStreak = livePlayStreak(streak: state.playDayStreak, lastDayKey: state.lastPlayDayKey, now: now);
    final at = state.notifDaily
        ? streakReminderAt(liveStreak: liveStreak, playedToday: playedToday(state.lastPlayDayKey, now), now: now)
        : null;
    if (at == null) {
      await _notifs.cancelStreakReminder();
      return;
    }
    await _notifs.scheduleStreakReminder(after: at.difference(now), streak: liveStreak);
  }

  /// Extra chips a live play-day streak adds on top of the claim-streak
  /// ladder — see utils/play_streak.dart. Kept as one place both
  /// `claimDailyBonus` and `_syncDailyBonusReminder` (which must quote the
  /// same total in the notification) read from.
  int _playStreakBonusNow(DateTime now) => playStreakBonusChips(
    livePlayStreak(streak: state.playDayStreak, lastDayKey: state.lastPlayDayKey, now: now),
  );

  void claimDailyBonus() {
    final now = DateTime.now();
    if (!isDailyBonusReady(state.lastDailyBonusClaimAt, now)) return;
    final day = nextDailyBonusStreakDay(state.dailyBonusStreakDay, state.lastDailyBonusClaimAt, now);
    final streakBonus = _playStreakBonusNow(now);
    final reward = dailyBonusRewardForDay(day) + streakBonus;
    state = state.copyWith(
      chips: state.chips + reward,
      lastDailyBonusClaimAt: now,
      dailyBonusStreakDay: day,
    );
    unawaited(_bonusStore.saveClaim(now, day));
    unawaited(_syncDailyBonusReminder());
    _scheduleSave();
    _showToast(
      streakBonus > 0
          ? '+$reward chips claimed — day $day of your streak, +$streakBonus for playing $_playStreakLabel!'
          : '+$reward chips claimed — day $day of your streak!',
    );
    _playSfx(GameSfx.win);
    _hapticMedium();
    unawaited(_analytics.logEvent(AnalyticsEvent.dailyBonusClaimed, {'day': day, 'reward': reward}));
  }

  String get _playStreakLabel {
    final n = livePlayStreak(streak: state.playDayStreak, lastDayKey: state.lastPlayDayKey, now: DateTime.now());
    return n == 1 ? '1 day in a row' : '$n days in a row';
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

  /// Bets the whole stack, capped at the table maximum.
  ///
  /// Reaching a $500 bet on the Bronze table otherwise costs a tap per chip;
  /// worse, the biggest moment the game has — riding the lot — was the one the
  /// interface made hardest to reach.
  void betAllIn() {
    if (state.phase != RoundPhase.betting) return;
    final stake = state.stake;
    final amount = stake?.max == null ? state.chips : min(state.chips, stake!.max);
    if (amount <= 0) return;
    if (stake != null && amount < stake.min) {
      _showToast('Table minimum is \$${formatChips(stake.min)}');
      return;
    }
    state = state.copyWith(bet: amount);
    _playSfx(GameSfx.chip);
    _hapticMedium();
  }

  /// Re-stakes [GameState.lastBet] and deals in one tap.
  ///
  /// A player who has settled on a stake was re-tapping the same chips every
  /// single hand; between hands the only thing standing between them and the
  /// next round was busywork.
  void rebetAndDeal() {
    final last = state.lastBet;
    if (state.phase != RoundPhase.betting || last <= 0) return;
    if (last > state.chips) {
      _showToast('Not enough chips');
      return;
    }
    final stake = state.stake;
    if (stake != null && (last < stake.min || last > stake.max)) return;
    state = state.copyWith(bet: last);
    _playSfx(GameSfx.chip);
    _hapticSelection();
    dealRound();
  }

  void dealRound() {
    final bet = state.bet;
    final chips = state.chips;
    final stake = state.stake;
    if (state.phase != RoundPhase.betting || bet <= 0 || bet > chips) return;
    // The table limits are a rule, not decoration: a bet outside them never deals.
    if (stake != null && (bet < stake.min || bet > stake.max)) return;

    // Recorded once here, before the three exits below: every later
    // `copyWith` carries it forward, so the betting panel can offer this
    // exact stake again next hand.
    state = state.copyWith(lastBet: bet);

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
      _announceDealerTotal();
      _settle(holeCardJustRevealed: true);
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
      _announceDealerTotal();
      _settle(holeCardJustRevealed: true);
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
    _announceHandTotal(newHand.cards);
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
    _announceHandTotal(newHand.cards);
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
    _announceHandTotal(handA.cards);
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
      final next = state.activeHandIndex + 1;
      state = state.copyWith(activeHandIndex: next);
      // The hand-total circle now belongs to the second split hand, so say its
      // number. Without this the last thing spoken was the first hand's total
      // while the circle on screen showed the second's.
      _announceHandTotal(state.hands[next].cards);
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

  // The dealer's turn is paced like an NPC's, and for the same reason: it is
  // another player acting at the table. The draw and settle beats mirror the
  // NPC timings above (600 / 480ms) so the table keeps one rhythm.
  //
  // These are floors, not fixed beats: the dealer also waits out its own
  // call-out before touching the next card — see [_dealerBeat].
  //
  // The reveal floor is deliberately longer than that rhythm. The hole card
  // turns over while the spoken call-out of the player's last card ("you have
  // twenty") may still be playing, and at the old 520ms the dealer was already
  // drawing over it. Two seconds outlasts that line, so the player hears the
  // hand they just finished, sees the dealer's cards, and only then watches
  // the dealer act.
  static const Duration kDealerRevealPause = Duration(seconds: 2);
  static const Duration _kDealerDrawPause = Duration(milliseconds: 600);
  static const Duration _kDealerSettlePause = Duration(milliseconds: 480);

  static bool _dealerShouldHit(List<PlayingCard> hand) {
    final v = BlackjackRules.handValue(hand);
    if (v < 17) return true;
    if (v == 17 && kDealerHitsSoft17 && BlackjackRules.isSoft(hand)) return true;
    return false;
  }

  /// Plays the dealer's hand out one card at a time.
  ///
  /// This used to draw the entire hand in a synchronous `while` loop and call
  /// [_settle] in the same frame, which set `RoundPhase.dealer` and left it
  /// again before a single frame was rendered. The consequences were all
  /// visible at the table: the hole-card flip and every dealer draw fired at
  /// once, the result panel landed on top of them, and the "Dealer is
  /// playing…" indicator was unreachable code. The player watched four NPCs
  /// take a considered turn each, then saw the hand they actually cared about
  /// resolve instantly.
  ///
  /// The cards are the same cards: [_drawCard] is pulled in the same order
  /// from the same shoe, and nothing else can draw while the dealer is acting.
  /// Only the timing changed.
  void _playDealer() {
    // Reveal the hole card and hand the stage over *before* drawing, so the
    // flip is its own beat rather than one frame of a pile-up.
    state = state.copyWith(holeRevealed: true, phase: RoundPhase.dealer);
    _dealerBeat(
      floor: kDealerRevealPause,
      lead: kDealerRevealVoiceLead,
      opening: true,
    );
  }

  /// The dealer says what it now holds, then plays on — after the line has
  /// been said, or after [floor], whichever is later.
  ///
  /// The wait is the longer of the two because the beats between the dealer's
  /// cards are shorter than the sentences describing them: on the floor alone
  /// it would be two cards ahead of what the player is being told it holds.
  /// The floor still sets the rhythm when there is nothing to say — the voice
  /// is off — and when the line is short enough to fit inside it.
  void _dealerBeat({
    required Duration floor,
    Duration lead = kDealerVoiceLead,
    bool opening = false,
  }) {
    _dealerTimer?.cancel();
    _dealerTotalTimer?.cancel();
    final floorEndsAt = DateTime.now().add(floor);
    _dealerTimer = Timer(floor, _dealerDrawStep);

    final words = _dealerTotalWords(opening: opening);
    if (words == null) return;

    _dealerTotalTimer = Timer(lead, () async {
      if (!_voiceOn) return;
      final endsAt = await _sound.playWords(words);
      if (endsAt == null) return;
      // Only ever pushes the next card back, never pulls it forward.
      final until = endsAt.add(kDealerVoiceTail);
      if (!until.isAfter(floorEndsAt)) return;
      if (state.phase != RoundPhase.dealer) return;
      _dealerTimer?.cancel();
      _dealerTimer = Timer(until.difference(DateTime.now()), _dealerDrawStep);
    });
  }

  void _dealerDrawStep() {
    // If the player walked away mid-turn, finish the hand at once rather than
    // leaving bets unsettled. The pacing is a presentation nicety; settling
    // is not optional, and abandoning it would strand the player's stake.
    if (state.screen != AppScreen.table) {
      _finishDealerWithoutPacing();
      return;
    }

    if (!_dealerShouldHit(state.dealerHand)) {
      _dealerTimer?.cancel();
      _dealerTimer = Timer(_kDealerSettlePause, () {
        if (state.phase != RoundPhase.dealer) return;
        _settle();
      });
      return;
    }

    state = state.copyWith(dealerHand: [...state.dealerHand, _drawCard()]);
    _playSfx(GameSfx.deal);
    _dealerBeat(floor: _kDealerDrawPause);
  }

  /// Resolves the rest of the dealer's hand immediately, for when there is
  /// nobody watching it.
  void _finishDealerWithoutPacing() {
    final hand = [...state.dealerHand];
    while (_dealerShouldHit(hand)) {
      hand.add(_drawCard());
    }
    state = state.copyWith(dealerHand: hand, holeRevealed: true);
    _settle();
  }

  // ---------------------------------------------------------------------
  // Settlement — "Closest to 21" sweep-pot logic ported from `settle()`
  // ---------------------------------------------------------------------

  void _settle({bool holeCardJustRevealed = false}) {
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

    // Tone first, then a spoken result — every outcome gets one, a push
    // included: "Push" is the answer to what happened to the bet, and silence
    // is not.
    if (outcomes.contains('blackjack')) {
      _playOutcomeTone(GameSfx.blackjack, afterFlip: holeCardJustRevealed);
      _playVoice(GameVoice.bigWin);
      _hapticCelebrate();
    } else if (messageType == MessageType.win) {
      _playOutcomeTone(GameSfx.win, afterFlip: holeCardJustRevealed);
      if (heroTakesPot) {
        _playVoice(GameVoice.playerPot, celebrate: true);
        _celebrateSweep();
        _hapticCelebrate();
      } else {
        _playVoice(GameVoice.playerWin);
        _hapticMedium();
      }
    } else if (messageType == MessageType.lose) {
      _playOutcomeTone(GameSfx.lose, afterFlip: holeCardJustRevealed);
      _playVoice(GameVoice.playerLose);
      _hapticLight();
    } else {
      _playOutcomeTone(GameSfx.push, afterFlip: holeCardJustRevealed);
      _playVoice(GameVoice.push);
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

    final advanced = advancePlayStreak(streak: state.playDayStreak, lastDayKey: state.lastPlayDayKey, now: now);
    final streakExtended = advanced.streak != state.playDayStreak;
    state = state.copyWith(playDayStreak: advanced.streak, lastPlayDayKey: advanced.dayKey);
    if (streakExtended && advanced.streak > 1) {
      _showToast('🔥 Day ${advanced.streak} play streak');
    }
    if (streakExtended) unawaited(_syncStreakReminder());

    // Progression is read from the hand that just settled, in this order:
    // missions first (their targets are about what happened), then experience,
    // then achievements — which can be triggered by any of the above, and by
    // the chips the first two just paid.
    _advanceMissions(
      won: winsDelta > 0 && lossesDelta == 0,
      blackjack: bjDelta > 0,
      sweptPot: heroTakesPot,
      winStreak: newStreak,
      dayKey: dayKey,
    );
    _awardXp(won: winsDelta > 0 && lossesDelta == 0, blackjack: bjDelta > 0, sweptPot: heroTakesPot);
    _awardAchievements();

    _reportScore();
    _scheduleSave();

    // Counts and outcomes only — never a name, a group code or a uid. This is
    // the event the whole funnel hangs off: without it there is no way to tell
    // how many hands a session actually runs to.
    unawaited(
      _analytics.logEvent(AnalyticsEvent.handPlayed, {
        'result': messageType.name,
        'stake': state.stake?.key ?? 'none',
        'net': sessionNetDelta,
        'swept': heroTakesPot ? 1 : 0,
        'blackjack': bjDelta > 0 ? 1 : 0,
      }),
    );
  }

  // ---------------------------------------------------------------------
  // Progression: achievements, experience, daily missions
  // ---------------------------------------------------------------------

  /// Pays and announces any achievement the current state has just satisfied.
  ///
  /// Called after every settled hand and after the two events that can unlock
  /// one without a hand being played — sitting at the VIP table, and a friend
  /// accepting an invite. Idempotent: an id in [GameState.unlockedAchievements]
  /// is never considered again, so nothing pays twice.
  void _awardAchievements() {
    final earned = newlyUnlocked(state, state.unlockedAchievements);
    if (earned.isEmpty) return;
    final reward = achievementReward(earned);
    state = state.copyWith(
      chips: state.chips + reward,
      unlockedAchievements: [...state.unlockedAchievements, ...earned.map((d) => d.id)],
      // One banner at a time, showing the first: two celebrations stacked on
      // one hand is noise, and the rest are on the Awards tab anyway.
      achievementBanner: earned.first.id,
    );
    _hapticMedium();
    _scheduleSave();
    for (final def in earned) {
      unawaited(_analytics.logEvent(AnalyticsEvent.achievementUnlocked, {'id': def.id}));
    }
  }

  /// Records that the player moved to [screen]. Called from the shell, which
  /// is the one place every navigation passes through.
  void logScreenView(AppScreen screen) => unawaited(_analytics.logScreen(screen.name));

  /// Turns anonymous usage and crash reporting on or off.
  ///
  /// The switch reaches the SDKs, not just this app's call sites, so "off"
  /// means nothing is collected rather than nothing being sent by us.
  void setAnalytics(bool on) {
    state = state.copyWith(analyticsOn: on);
    unawaited(_analytics.setEnabled(on));
    _scheduleSave();
  }

  /// Dismisses the achievement banner.
  void clearAchievementBanner() => state = state.copyWith(achievementBanner: null);

  /// Adds the hand's experience and, if it crossed a threshold, flags the
  /// level-up so the table can show it.
  void _awardXp({required bool won, required bool blackjack, required bool sweptPot}) {
    final before = Xp.levelFor(state.xp);
    final gained = Xp.forRound(
      won: won,
      blackjack: blackjack,
      sweptPot: sweptPot,
      stake: state.stake?.min ?? 25,
    );
    final xp = state.xp + gained;
    final after = Xp.levelFor(xp);
    state = state.copyWith(xp: xp, levelUpTo: after > before ? after : null);
    if (after > before) {
      unawaited(_analytics.logEvent(AnalyticsEvent.levelUp, {'level': after}));
    }
  }

  /// Dismisses the level-up sheet.
  void clearLevelUp() => state = state.copyWith(levelUpTo: null);

  /// Rolls the day's missions over if the date changed, then counts this hand
  /// against them.
  void _advanceMissions({
    required bool won,
    required bool blackjack,
    required bool sweptPot,
    required int winStreak,
    required String dayKey,
  }) {
    final rolled = state.missionDayKey != dayKey;
    final progress = rolled ? const <String, int>{} : state.missionProgress;
    final next = advanceMissions(
      missions: missionsForDay(dayKey),
      progress: progress,
      event: MissionEvent(
        won: won,
        blackjack: blackjack,
        sweptPot: sweptPot,
        stake: state.stake?.min ?? 25,
        winStreak: winStreak,
      ),
    );
    state = state.copyWith(
      missionDayKey: dayKey,
      missionProgress: next,
      missionsClaimed: rolled ? const [] : state.missionsClaimed,
    );
  }

  /// Pays a finished mission. Ignored unless it is actually finished and
  /// unclaimed, so a double tap cannot pay twice.
  void claimMission(String id) {
    final today = dayKeyOf(DateTime.now());
    final mission = missionsForDay(today).where((m) => m.id == id).firstOrNull;
    if (mission == null) return;
    if (!missionIsClaimable(mission, state.missionProgress, state.missionsClaimed)) return;
    state = state.copyWith(
      chips: state.chips + mission.reward,
      missionsClaimed: [...state.missionsClaimed, id],
    );
    unawaited(_analytics.logEvent(AnalyticsEvent.missionClaimed, {'id': mission.id, 'reward': mission.reward}));
    _showToast('Mission complete — ${mission.label}, +${formatChips(mission.reward)} chips');
    _playSfx(GameSfx.win);
    _hapticMedium();
    _scheduleSave();
    _awardAchievements();
  }

  void nextHand() {
    // The tutorial advances here rather than at settlement, so the last card
    // of a hand is still the recap of the hand the player just finished.
    final tutorialSeen = min(state.tutorialRoundsSeen + 1, kTutorialRounds);
    final tutorialAdvanced = tutorialSeen != state.tutorialRoundsSeen;

    // Table chat used to invent a message from a hardcoded name after every
    // hand, so a player with nobody in their group watched "Maya T." talk to
    // them all night. Fiction in a social surface teaches players the real
    // social features are fake too, so the filler only runs once there are
    // actual people in the group to talk to.
    final speakers = state.friendsAreLive ? state.friends.map((f) => f.name).toList() : const <String>[];
    final newMessages = speakers.isEmpty
        ? state.chatMessages
        : [
            ...state.chatMessages,
            ChatMessage(
              name: speakers[_rng.nextInt(speakers.length)],
              text: kChatPool[_rng.nextInt(kChatPool.length)],
              id: DateTime.now().millisecondsSinceEpoch,
            ),
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
      chatMessages: newMessages.length > kChatLogLimit
          ? newMessages.sublist(newMessages.length - kChatLogLimit)
          : newMessages,
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

  /// Tops the bankroll back up to [kRebuyChips] (never down — a rebuy while
  /// still holding more than that would be a free top-up, not a rescue),
  /// gated by a cooldown so there is a real reason to claim the daily bonus
  /// or invite someone to race you. Replaces the old free, unlimited
  /// "Reset bankroll".
  void rebuy() {
    final now = DateTime.now();
    if (!isRebuyReady(state.lastRebuyAt, now)) {
      _showToast('Rebuy available in ${rebuyCountdownLabel(state.lastRebuyAt!, now)}');
      return;
    }
    state = state.copyWith(chips: max(state.chips, kRebuyChips), lastRebuyAt: now);
    _scheduleSave();
    _showToast('+${formatChips(kRebuyChips)} rebuy chips');
    _playSfx(GameSfx.win);
    _hapticMedium();
    unawaited(_analytics.logEvent(AnalyticsEvent.rebuy));
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
    _scheduleSave();
    _showToast("You're in! Good luck in the Weekend Cup.");
  }

  /// Lobby Weekend Cup card → the tournament screen.
  void openCup() => state = state.copyWith(screen: AppScreen.cup);

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

  void selectAvatarColor(Color color) {
    state = state.copyWith(avatarColor: color);
    _scheduleSave();
  }
  /// The player's level, derived from lifetime experience.
  int get level => Xp.levelFor(state.xp);

  void selectCardBack(String id) {
    final def = kCardBackDefs.where((c) => c.id == id).firstOrNull;
    if (def == null) return;
    // Refused rather than silently ignored: a locked swatch that simply does
    // nothing on tap reads as a broken button.
    if (def.requiredLevel > level) {
      _showToast('${def.label} unlocks at level ${def.requiredLevel}');
      return;
    }
    state = state.copyWith(cardBackSkin: id);
    _scheduleSave();
  }

  void selectFelt(String id) {
    final def = kFeltDefs.where((f) => f.id == id).firstOrNull;
    if (def == null) return;
    if (def.requiredLevel > level) {
      _showToast('${def.label} unlocks at level ${def.requiredLevel}');
      return;
    }
    state = state.copyWith(themeChoice: id);
    _scheduleSave();
  }

  void setAvatarFrame(bool gold) {
    if (gold && level < kAvatarFrameLevel) {
      _showToast('The gold frame unlocks at level $kAvatarFrameLevel');
      return;
    }
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

  /// Muting takes the voice queue with it — a call-out already handed to the
  /// queue is waiting its turn there, not on a timer this class can cancel.
  void toggleSound() {
    final next = !state.soundOn;
    state = state.copyWith(soundOn: next);
    if (next) {
      unawaited(_sound.play(GameSfx.chip));
    } else {
      _voiceTimer?.cancel();
      _potTimer?.cancel();
      _handTotalTimer?.cancel();
      _celebrationTimer?.cancel();
      _sound.silenceVoice();
    }
    _scheduleSave();
  }

  /// Turning voice back on answers in the voice itself — "You have twenty
  /// one" — so the player hears exactly what they just switched on. Pending
  /// call-outs are dropped when it goes off: their timers re-check the toggle,
  /// but cancelling is what makes the table fall silent immediately.
  void toggleVoice() {
    final next = !state.voiceOn;
    state = state.copyWith(voiceOn: next);
    if (!next) {
      _voiceTimer?.cancel();
      _potTimer?.cancel();
      _handTotalTimer?.cancel();
      _sound.silenceVoice();
    } else if (state.soundOn) {
      unawaited(_sound.playWords(['you_have', ...spokenAmountWords(21)]));
    }
    _scheduleSave();
  }
  /// Sets the UI language override; null reverts to following the device
  /// locale. Voice call-outs follow this too (see `SoundPlayer.setLanguage`,
  /// wired once the voice pipeline gains per-language asset sets), so a
  /// single Settings picker controls both.
  void setLanguage(String? code) {
    state = state.copyWith(languageOverride: code);
    _scheduleSave();
  }

  void toggleTableMenu() => state = state.copyWith(tableMenuOpen: !state.tableMenuOpen);
  void toggleTableChat() => state = state.copyWith(tableChatOpen: !state.tableChatOpen, tableMenuOpen: false);
  /// Asks the OS for notification permission the first time the player turns
  /// one of these on, and reports back whether they can actually be notified.
  ///
  /// Turning a switch on *is* the consent moment: the player just said they
  /// want this specific kind of alert, which is the context the frame-1 prompt
  /// never had. If they decline at the OS level the switch goes back off
  /// rather than sitting there lit and lying — the previous behaviour left all
  /// three showing ON while nothing could ever be delivered.
  Future<bool> _ensureNotifPermission() async {
    if (_notifs.hasPermission) return true;
    final granted = await _notifs.requestPermission();
    if (!granted) {
      _showToast('Notifications are off for this app in system settings');
    }
    return granted;
  }

  Future<void> toggleNotifSocial() async {
    if (!state.notifSocial && !await _ensureNotifPermission()) return;
    state = state.copyWith(notifSocial: !state.notifSocial);
    _scheduleSave();
  }

  Future<void> toggleNotifLeaderboard() async {
    if (!state.notifLeaderboard && !await _ensureNotifPermission()) return;
    state = state.copyWith(notifLeaderboard: !state.notifLeaderboard);
    _scheduleSave();
  }

  Future<void> toggleNotifDaily() async {
    if (!state.notifDaily && !await _ensureNotifPermission()) return;
    state = state.copyWith(notifDaily: !state.notifDaily);
    // Off cancels both pending reminders; on re-arms whichever applies.
    unawaited(_syncDailyBonusReminder());
    unawaited(_syncStreakReminder());
    _scheduleSave();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());
