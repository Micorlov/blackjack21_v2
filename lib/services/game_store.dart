import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/tutorial_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';

/// How many past hands are kept on disk. Comeback dealing only ever reads the
/// last few, so a longer tail would grow the blob for nothing.
const int kSavedHistoryLimit = 50;

/// Bumped only when a change to [SavedGame.toJson] cannot be read by the
/// defensive defaults in [SavedGame.fromJson]; an unrecognised version is
/// discarded rather than guessed at.
const int _kSchemaVersion = 1;

/// The slice of [GameState] that has to outlive the app process: the bankroll
/// the whole game is scored on, all-time stats, the recent-hand history that
/// drives comeback dealing, the live point buckets, and the player's settings
/// and cosmetics.
///
/// Deliberately excludes everything belonging to one sitting — the shoe, the
/// current hand, toasts, the friends list — which is rebuilt on launch.
@immutable
class SavedGame {
  final int chips;
  final StatsSummary stats;
  final List<RoundResult> history;
  final int hourlyPoints;
  final int dailyPoints;
  final String hourKey;
  final String dayKey;
  final bool soundOn;
  final bool hapticsOn;
  final bool notifSocial;
  final bool notifLeaderboard;
  final bool notifDaily;
  final String themeChoice;
  final String cardBackSkin;
  final bool avatarFrameGold;
  final List<String> claimedTiers;
  final int tutorialRoundsSeen;
  final bool tutorialDismissed;

  const SavedGame({
    required this.chips,
    required this.stats,
    required this.history,
    required this.hourlyPoints,
    required this.dailyPoints,
    required this.hourKey,
    required this.dayKey,
    required this.soundOn,
    required this.hapticsOn,
    required this.notifSocial,
    required this.notifLeaderboard,
    required this.notifDaily,
    required this.themeChoice,
    required this.cardBackSkin,
    required this.avatarFrameGold,
    required this.claimedTiers,
    required this.tutorialRoundsSeen,
    required this.tutorialDismissed,
  });

  Map<String, Object?> toJson() => {
    'v': _kSchemaVersion,
    'chips': chips,
    'stats': {
      'handsPlayed': stats.handsPlayed,
      'wins': stats.wins,
      'losses': stats.losses,
      'pushes': stats.pushes,
      'blackjacks': stats.blackjacks,
      'currentStreak': stats.currentStreak,
      'bestStreak': stats.bestStreak,
    },
    'history': [
      for (final r in history.length > kSavedHistoryLimit
          ? history.sublist(history.length - kSavedHistoryLimit)
          : history)
        r.name,
    ],
    'hourlyPoints': hourlyPoints,
    'dailyPoints': dailyPoints,
    'hourKey': hourKey,
    'dayKey': dayKey,
    'soundOn': soundOn,
    'hapticsOn': hapticsOn,
    'notifSocial': notifSocial,
    'notifLeaderboard': notifLeaderboard,
    'notifDaily': notifDaily,
    'themeChoice': themeChoice,
    'cardBackSkin': cardBackSkin,
    'avatarFrameGold': avatarFrameGold,
    'claimedTiers': claimedTiers,
    'tutorialRoundsSeen': tutorialRoundsSeen,
    'tutorialDismissed': tutorialDismissed,
  };

  /// Every field falls back to the [GameState] default it mirrors, so a blob
  /// that lost a key still restores the fields it does carry instead of being
  /// thrown away wholesale.
  factory SavedGame.fromJson(Map<String, Object?> json) {
    const defaults = GameState();
    final stats = json['stats'];
    final statsMap = stats is Map ? stats : const {};
    final handsPlayed = _int(statsMap['handsPlayed'], 0);

    return SavedGame(
      chips: _int(json['chips'], defaults.chips),
      stats: StatsSummary(
        handsPlayed: handsPlayed,
        wins: _int(statsMap['wins'], 0),
        losses: _int(statsMap['losses'], 0),
        pushes: _int(statsMap['pushes'], 0),
        blackjacks: _int(statsMap['blackjacks'], 0),
        currentStreak: _int(statsMap['currentStreak'], 0),
        bestStreak: _int(statsMap['bestStreak'], 0),
      ),
      history: _history(json['history']),
      hourlyPoints: _int(json['hourlyPoints'], 0),
      dailyPoints: _int(json['dailyPoints'], 0),
      hourKey: _str(json['hourKey'], ''),
      dayKey: _str(json['dayKey'], ''),
      soundOn: _bool(json['soundOn'], defaults.soundOn),
      hapticsOn: _bool(json['hapticsOn'], defaults.hapticsOn),
      notifSocial: _bool(json['notifSocial'], defaults.notifSocial),
      notifLeaderboard: _bool(json['notifLeaderboard'], defaults.notifLeaderboard),
      notifDaily: _bool(json['notifDaily'], defaults.notifDaily),
      themeChoice: _str(json['themeChoice'], defaults.themeChoice),
      cardBackSkin: _str(json['cardBackSkin'], defaults.cardBackSkin),
      avatarFrameGold: _bool(json['avatarFrameGold'], defaults.avatarFrameGold),
      claimedTiers: _strings(json['claimedTiers']),
      // A blob written before the tutorial existed has no progress to restore,
      // and re-teaching a player who has already played hands would be worse
      // than skipping it — so hands played stands in for lessons seen.
      tutorialRoundsSeen: _int(json['tutorialRoundsSeen'], handsPlayed.clamp(0, kTutorialRounds)),
      tutorialDismissed: _bool(json['tutorialDismissed'], defaults.tutorialDismissed),
    );
  }

  static int _int(Object? v, int fallback) => v is int ? v : fallback;
  static bool _bool(Object? v, bool fallback) => v is bool ? v : fallback;
  static String _str(Object? v, String fallback) => v is String ? v : fallback;

  static List<String> _strings(Object? v) =>
      v is List ? [for (final e in v) if (e is String) e] : const [];

  /// Unreadable entries are dropped rather than defaulted: a wrong result in
  /// the tail would silently change whether comeback dealing kicks in.
  static List<RoundResult> _history(Object? v) {
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is String)
          for (final r in RoundResult.values)
            if (r.name == e) r,
    ];
  }
}

/// Persists [SavedGame] to `shared_preferences` as one JSON blob.
///
/// A load or save that fails (first run, corrupted store, no disk) degrades to
/// "nothing saved" rather than crashing — the same posture the daily-bonus
/// store takes. Losing a save costs the player some progress; taking the app
/// down with it costs them the session.
class GameStore {
  static const String _kKey = 'gameStateV1';

  Future<SavedGame?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      if (decoded['v'] != _kSchemaVersion) return null;
      return SavedGame.fromJson(decoded);
    } on Exception catch (e) {
      // Covers a corrupted blob too: jsonDecode throws FormatException.
      debugPrint('GameStore.load failed: $e');
      return null;
    }
  }

  Future<void> save(SavedGame game) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, jsonEncode(game.toJson()));
    } on Exception catch (e) {
      debugPrint('GameStore.save failed: $e');
    }
  }
}
