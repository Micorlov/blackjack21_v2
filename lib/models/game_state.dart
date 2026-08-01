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

  const GameState({
    this.screen = AppScreen.onboarding,
    this.signedIn = false,
    this.displayName = 'Guest',
    this.photoUrl,
    this.chips = 1000,
    this.stake,
    this.bet = 0,
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
  });

  GameState copyWith({
    AppScreen? screen,
    bool? signedIn,
    String? displayName,
    Object? photoUrl = _unset,
    int? chips,
    Object? stake = _unset,
    int? bet,
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
  }) {
    return GameState(
      screen: screen ?? this.screen,
      signedIn: signedIn ?? this.signedIn,
      displayName: displayName ?? this.displayName,
      photoUrl: identical(photoUrl, _unset) ? this.photoUrl : photoUrl as String?,
      chips: chips ?? this.chips,
      stake: identical(stake, _unset) ? this.stake : stake as TableStake?,
      bet: bet ?? this.bet,
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
    );
  }
}
