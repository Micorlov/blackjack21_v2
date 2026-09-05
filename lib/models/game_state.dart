import 'package:flutter/material.dart';

import 'enums.dart';
import 'hand.dart';
import 'playing_card.dart';
import 'social_models.dart';

class StatsSummary {
  final int handsPlayed;
  final int wins;
  final int losses;
  final int pushes;
  final int blackjacks;
  final int currentStreak;
  final int bestStreak;

  const StatsSummary({
    this.handsPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.pushes = 0,
    this.blackjacks = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  StatsSummary copyWith({
    int? handsPlayed,
    int? wins,
    int? losses,
    int? pushes,
    int? blackjacks,
    int? currentStreak,
    int? bestStreak,
  }) {
    return StatsSummary(
      handsPlayed: handsPlayed ?? this.handsPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      pushes: pushes ?? this.pushes,
      blackjacks: blackjacks ?? this.blackjacks,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }
}

class SessionSummary {
  final int hands;
  final int wins;
  final int net;

  const SessionSummary({this.hands = 0, this.wins = 0, this.net = 0});

  SessionSummary copyWith({int? hands, int? wins, int? net}) {
    return SessionSummary(hands: hands ?? this.hands, wins: wins ?? this.wins, net: net ?? this.net);
  }
}

/// Sentinel used so `copyWith` can distinguish "leave unchanged" from
/// "explicitly set to null" for nullable fields.
const Object _unset = Object();

class GameState {
  final AppScreen screen;
  final bool signedIn;
  final String displayName;
  final String? photoUrl;
  final int chips;
  final TableStake? stake;
  final int bet;

  /// The stake the player last actually dealt with, so the betting panel can
  /// offer a one-tap "deal that again". Session-only: it belongs to the sitting,
  /// not to the bankroll, so it is deliberately outside [SavedGame].
  final int lastBet;

  final RoundPhase phase;
  final List<PlayingCard> dealerHand;
  final bool holeRevealed;
  final List<Hand> hands;
  final int activeHandIndex;
  final int insuranceBet;
  final String message;
  final MessageType messageType;
  final StatsSummary stats;
  final SessionSummary session;
  final List<RoundResult> history;
  /// Moment of the last daily-bonus claim (persisted across launches by
  /// DailyBonusStore); null means never claimed. Readiness is derived via
  /// `isDailyBonusReady` in utils/daily_bonus.dart.
  final DateTime? lastDailyBonusClaimAt;

  /// The streak day the last daily-bonus claim landed on (1..7); 0 means no
  /// claim yet. The *next* claim's day and reward are derived from this via
  /// `nextDailyBonusStreakDay` in utils/daily_bonus.dart.
  final int dailyBonusStreakDay;

  /// True once the "Four things to know" new-player tips screen has been
  /// dismissed, so it is only ever shown once.
  final bool tipsSeen;
  final String toast;
  final String reactionFloat;
  final int reactionId;
  final AdState adState;
  final List<Friend> friends;
  final LeaderboardPeriod leaderboardPeriod;
  final String friendCodeInput;
  final StatsTab statsTab;
  final String themeChoice;
  final bool hapticsOn;
  final bool soundOn;

  /// Spoken call-outs only — hand totals, settlement results, the sweep-pot
  /// figure, and the NPC "Stand"/"Bust" lines. Nested under [soundOn]: muting
  /// sound silences the voice too, so both must be on for a word to be said.
  final bool voiceOn;

  /// ISO 639-1 code (e.g. 'es') the player explicitly picked in Settings;
  /// null means "follow the device's locale" — the same null-means-unset
  /// convention [avatarColor] uses for a color the player never chose.
  final String? languageOverride;
  final bool notifSocial;
  final bool notifLeaderboard;
  final bool notifDaily;
  final Color avatarColor;
  final bool tournamentJoined;
  final int referralsCount;
  final List<String> claimedTiers;
  final bool visitedVIP;
  final List<ChatMessage> chatMessages;
  final bool tableMenuOpen;
  final bool tableChatOpen;
  final List<NpcSeat> npcSeats;
  final int? actingSeat;
  final int sweepAmount;
  final int roundNet;
  final int roundStake;
  final int roundHandNet;
  final SweepInfo? sweepInfo;
  final String cardBackSkin;
  final bool avatarFrameGold;
  final bool highlight1Liked;
  final int highlight1Count;
  final bool highlight2Liked;
  final int highlight2Count;
  final String? activeStoryId;
  final List<String> viewedStories;
  final bool socialReady;
  final String? groupCode;
  final int heroHourlyPoints;
  final int heroDailyPoints;
  final String heroHourKey;
  final String heroDayKey;
  final bool badgeHourly;
  final String? heroUid;
  final bool friendsAreLive;
  final List<Friend> globalHourly;
  final List<Friend> globalDaily;

  /// Hands the first-run tutorial has already coached, which doubles as the
  /// index of the lesson now showing. Advanced by `nextHand()` and capped at
  /// `kTutorialRounds`, after which the coach card stops appearing.
  final int tutorialRoundsSeen;

  /// True once the player pressed "Skip" — the tutorial then stays off until
  /// they replay it from Settings.
  final bool tutorialDismissed;

  /// A join code parsed from an incoming link (or clipboard) before the
  /// social layer is ready to act on it yet. In-memory only — never
  /// persisted, since a stale pending join should not resurrect itself days
  /// later after a completely unrelated relaunch.
  final String? pendingJoinCode;

  /// True once this launch joined a group by tapping a link rather than
  /// typing a code — drives the one-time "get the Android app" banner on
  /// web. In-memory only.
  final bool joinedViaLink;

  /// Ids of referred friends whose join bonus has already been paid to the
  /// inviter, so a later snapshot of the same member (including one seen
  /// again after a relaunch) is never paid twice. See utils/referrals.dart.
  final List<String> rewardedReferralIds;

  /// Consecutive calendar days with at least one settled hand. See
  /// utils/play_streak.dart.
  final int playDayStreak;

  /// Day-key [playDayStreak] was last extended on; `''` before the first
  /// hand is ever settled.
  final String lastPlayDayKey;

  /// Moment of the last table Rebuy; null means never taken. Readiness is
  /// derived via `isRebuyReady` in utils/rebuy.dart.
  final DateTime? lastRebuyAt;

  /// Ids of achievements already paid and announced — see utils/achievements.dart.
  final List<String> unlockedAchievements;

  /// Lifetime experience; the player's level is derived from it via utils/xp.dart.
  final int xp;

  /// Day the current three missions were drawn for, their progress, and which
  /// have been claimed — see utils/missions.dart.
  final String missionDayKey;
  final Map<String, int> missionProgress;
  final List<String> missionsClaimed;

  /// The achievement whose unlock banner is showing, if any. Session-only: a
  /// celebration is for the moment it happens, not something to restore two
  /// days later on a cold launch.
  final String? achievementBanner;

  /// Level the player just reached, driving the level-up sheet. Also
  /// session-only, for the same reason.
  final int? levelUpTo;

  const GameState({
    this.screen = AppScreen.onboarding,
    this.signedIn = false,
    this.displayName = 'Guest',
    this.photoUrl,
    this.chips = 1000,
    this.stake,
    this.bet = 0,
    this.lastBet = 0,
    this.phase = RoundPhase.betting,
    this.dealerHand = const [],
    this.holeRevealed = false,
    this.hands = const [Hand()],
    this.activeHandIndex = 0,
    this.insuranceBet = 0,
    this.message = '',
    this.messageType = MessageType.none,
    this.stats = const StatsSummary(),
    this.session = const SessionSummary(),
    this.history = const [],
    this.lastDailyBonusClaimAt,
    this.dailyBonusStreakDay = 0,
    this.tipsSeen = false,
    this.toast = '',
    this.reactionFloat = '',
    this.reactionId = 0,
    this.adState = AdState.ready,
    this.friends = const [],
    this.leaderboardPeriod = LeaderboardPeriod.alltime,
    this.friendCodeInput = '',
    this.statsTab = StatsTab.recent,
    this.themeChoice = 'default',
    this.hapticsOn = true,
    this.soundOn = true,
    this.voiceOn = true,
    this.languageOverride,
    this.notifSocial = true,
    this.notifLeaderboard = true,
    // On by default so the daily-chips reminder works out of the box; the
    // Settings "Daily reminder" toggle turns it off.
    this.notifDaily = true,
    this.avatarColor = const Color(0xFF1E7D5D),
    this.tournamentJoined = false,
    this.referralsCount = 0,
    this.claimedTiers = const [],
    this.visitedVIP = false,
    this.chatMessages = const [],
    this.tableMenuOpen = false,
    this.tableChatOpen = false,
    this.npcSeats = const [],
    this.actingSeat,
    this.sweepAmount = 0,
    this.roundNet = 0,
    this.roundStake = 0,
    this.roundHandNet = 0,
    this.sweepInfo,
    this.cardBackSkin = 'gold',
    this.avatarFrameGold = false,
    this.highlight1Liked = false,
    this.highlight1Count = 24,
    this.highlight2Liked = false,
    this.highlight2Count = 12,
    this.activeStoryId,
    this.viewedStories = const [],
    this.socialReady = false,
    this.groupCode,
    this.heroHourlyPoints = 0,
    this.heroDailyPoints = 0,
    this.heroHourKey = '',
    this.heroDayKey = '',
    this.badgeHourly = true,
    this.heroUid,
    this.friendsAreLive = false,
    this.globalHourly = const [],
    this.globalDaily = const [],
    this.tutorialRoundsSeen = 0,
    this.tutorialDismissed = false,
    this.pendingJoinCode,
    this.joinedViaLink = false,
    this.rewardedReferralIds = const [],
    this.playDayStreak = 0,
    this.lastPlayDayKey = '',
    this.lastRebuyAt,
    this.unlockedAchievements = const [],
    this.xp = 0,
    this.missionDayKey = '',
    this.missionProgress = const {},
    this.missionsClaimed = const [],
    this.achievementBanner,
    this.levelUpTo,
  });

  GameState copyWith({
    AppScreen? screen,
    bool? signedIn,
    String? displayName,
    Object? photoUrl = _unset,
    int? chips,
    Object? stake = _unset,
    int? bet,
    int? lastBet,
    RoundPhase? phase,
    List<PlayingCard>? dealerHand,
    bool? holeRevealed,
    List<Hand>? hands,
    int? activeHandIndex,
    int? insuranceBet,
    String? message,
    MessageType? messageType,
    StatsSummary? stats,
    SessionSummary? session,
    List<RoundResult>? history,
    Object? lastDailyBonusClaimAt = _unset,
    int? dailyBonusStreakDay,
    bool? tipsSeen,
    String? toast,
    String? reactionFloat,
    int? reactionId,
    AdState? adState,
    List<Friend>? friends,
    LeaderboardPeriod? leaderboardPeriod,
    String? friendCodeInput,
    StatsTab? statsTab,
    String? themeChoice,
    bool? hapticsOn,
    bool? soundOn,
    bool? voiceOn,
    Object? languageOverride = _unset,
    bool? notifSocial,
    bool? notifLeaderboard,
    bool? notifDaily,
    Color? avatarColor,
    bool? tournamentJoined,
    int? referralsCount,
    List<String>? claimedTiers,
    bool? visitedVIP,
    List<ChatMessage>? chatMessages,
    bool? tableMenuOpen,
    bool? tableChatOpen,
    List<NpcSeat>? npcSeats,
    Object? actingSeat = _unset,
    int? sweepAmount,
    int? roundNet,
    int? roundStake,
    int? roundHandNet,
    Object? sweepInfo = _unset,
    String? cardBackSkin,
    bool? avatarFrameGold,
    bool? highlight1Liked,
    int? highlight1Count,
    bool? highlight2Liked,
    int? highlight2Count,
    Object? activeStoryId = _unset,
    List<String>? viewedStories,
    bool? socialReady,
    Object? groupCode = _unset,
    int? heroHourlyPoints,
    int? heroDailyPoints,
    String? heroHourKey,
    String? heroDayKey,
    bool? badgeHourly,
    Object? heroUid = _unset,
    bool? friendsAreLive,
    List<Friend>? globalHourly,
    List<Friend>? globalDaily,
    int? tutorialRoundsSeen,
    bool? tutorialDismissed,
    Object? pendingJoinCode = _unset,
    bool? joinedViaLink,
    List<String>? rewardedReferralIds,
    int? playDayStreak,
    String? lastPlayDayKey,
    Object? lastRebuyAt = _unset,
    List<String>? unlockedAchievements,
    int? xp,
    String? missionDayKey,
    Map<String, int>? missionProgress,
    List<String>? missionsClaimed,
    Object? achievementBanner = _unset,
    Object? levelUpTo = _unset,
  }) {
    return GameState(
      screen: screen ?? this.screen,
      signedIn: signedIn ?? this.signedIn,
      displayName: displayName ?? this.displayName,
      photoUrl: identical(photoUrl, _unset) ? this.photoUrl : photoUrl as String?,
      chips: chips ?? this.chips,
      stake: identical(stake, _unset) ? this.stake : stake as TableStake?,
      bet: bet ?? this.bet,
      lastBet: lastBet ?? this.lastBet,
      phase: phase ?? this.phase,
      dealerHand: dealerHand ?? this.dealerHand,
      holeRevealed: holeRevealed ?? this.holeRevealed,
      hands: hands ?? this.hands,
      activeHandIndex: activeHandIndex ?? this.activeHandIndex,
      insuranceBet: insuranceBet ?? this.insuranceBet,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      stats: stats ?? this.stats,
      session: session ?? this.session,
      history: history ?? this.history,
      lastDailyBonusClaimAt: identical(lastDailyBonusClaimAt, _unset)
          ? this.lastDailyBonusClaimAt
          : lastDailyBonusClaimAt as DateTime?,
      dailyBonusStreakDay: dailyBonusStreakDay ?? this.dailyBonusStreakDay,
      tipsSeen: tipsSeen ?? this.tipsSeen,
      toast: toast ?? this.toast,
      reactionFloat: reactionFloat ?? this.reactionFloat,
      reactionId: reactionId ?? this.reactionId,
      adState: adState ?? this.adState,
      friends: friends ?? this.friends,
      leaderboardPeriod: leaderboardPeriod ?? this.leaderboardPeriod,
      friendCodeInput: friendCodeInput ?? this.friendCodeInput,
      statsTab: statsTab ?? this.statsTab,
      themeChoice: themeChoice ?? this.themeChoice,
      hapticsOn: hapticsOn ?? this.hapticsOn,
      soundOn: soundOn ?? this.soundOn,
      voiceOn: voiceOn ?? this.voiceOn,
      languageOverride: identical(languageOverride, _unset)
          ? this.languageOverride
          : languageOverride as String?,
      notifSocial: notifSocial ?? this.notifSocial,
      notifLeaderboard: notifLeaderboard ?? this.notifLeaderboard,
      notifDaily: notifDaily ?? this.notifDaily,
      avatarColor: avatarColor ?? this.avatarColor,
      tournamentJoined: tournamentJoined ?? this.tournamentJoined,
      referralsCount: referralsCount ?? this.referralsCount,
      claimedTiers: claimedTiers ?? this.claimedTiers,
      visitedVIP: visitedVIP ?? this.visitedVIP,
      chatMessages: chatMessages ?? this.chatMessages,
      tableMenuOpen: tableMenuOpen ?? this.tableMenuOpen,
      tableChatOpen: tableChatOpen ?? this.tableChatOpen,
      npcSeats: npcSeats ?? this.npcSeats,
      actingSeat: identical(actingSeat, _unset) ? this.actingSeat : actingSeat as int?,
      sweepAmount: sweepAmount ?? this.sweepAmount,
      roundNet: roundNet ?? this.roundNet,
      roundStake: roundStake ?? this.roundStake,
      roundHandNet: roundHandNet ?? this.roundHandNet,
      sweepInfo: identical(sweepInfo, _unset) ? this.sweepInfo : sweepInfo as SweepInfo?,
      cardBackSkin: cardBackSkin ?? this.cardBackSkin,
      avatarFrameGold: avatarFrameGold ?? this.avatarFrameGold,
      highlight1Liked: highlight1Liked ?? this.highlight1Liked,
      highlight1Count: highlight1Count ?? this.highlight1Count,
      highlight2Liked: highlight2Liked ?? this.highlight2Liked,
      highlight2Count: highlight2Count ?? this.highlight2Count,
      activeStoryId: identical(activeStoryId, _unset) ? this.activeStoryId : activeStoryId as String?,
      viewedStories: viewedStories ?? this.viewedStories,
      socialReady: socialReady ?? this.socialReady,
      groupCode: identical(groupCode, _unset) ? this.groupCode : groupCode as String?,
      heroHourlyPoints: heroHourlyPoints ?? this.heroHourlyPoints,
      heroDailyPoints: heroDailyPoints ?? this.heroDailyPoints,
      heroHourKey: heroHourKey ?? this.heroHourKey,
      heroDayKey: heroDayKey ?? this.heroDayKey,
      badgeHourly: badgeHourly ?? this.badgeHourly,
      heroUid: identical(heroUid, _unset) ? this.heroUid : heroUid as String?,
      friendsAreLive: friendsAreLive ?? this.friendsAreLive,
      globalHourly: globalHourly ?? this.globalHourly,
      globalDaily: globalDaily ?? this.globalDaily,
      tutorialRoundsSeen: tutorialRoundsSeen ?? this.tutorialRoundsSeen,
      tutorialDismissed: tutorialDismissed ?? this.tutorialDismissed,
      pendingJoinCode: identical(pendingJoinCode, _unset) ? this.pendingJoinCode : pendingJoinCode as String?,
      joinedViaLink: joinedViaLink ?? this.joinedViaLink,
      rewardedReferralIds: rewardedReferralIds ?? this.rewardedReferralIds,
      playDayStreak: playDayStreak ?? this.playDayStreak,
      lastPlayDayKey: lastPlayDayKey ?? this.lastPlayDayKey,
      lastRebuyAt: identical(lastRebuyAt, _unset) ? this.lastRebuyAt : lastRebuyAt as DateTime?,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      xp: xp ?? this.xp,
      missionDayKey: missionDayKey ?? this.missionDayKey,
      missionProgress: missionProgress ?? this.missionProgress,
      missionsClaimed: missionsClaimed ?? this.missionsClaimed,
      achievementBanner: identical(achievementBanner, _unset)
          ? this.achievementBanner
          : achievementBanner as String?,
      levelUpTo: identical(levelUpTo, _unset) ? this.levelUpTo : levelUpTo as int?,
    );
  }
}
