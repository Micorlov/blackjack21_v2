import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/social_models.dart';
import '../utils/invite_link.dart';
import '../utils/points.dart';

/// Result of [SocialService.joinGroup].
enum JoinResult {
  /// No group exists at that code.
  notFound,

  /// A brand-new membership row was created, with `invitedBy` set to the
  /// group's creator (unless the caller *is* the creator).
  joined,

  /// This player already had a row in that group — rejoining a link to your
  /// own table, or tapping the same invite twice.
  alreadyMember,

  /// The write failed (offline, rules rejection, etc).
  failed,
}

/// Firestore-backed friends layer.
///
/// Layout:
/// - `players/{uid}`               → membership pointer: {groupCode, name}
/// - `groups/{code}`               → {createdBy, createdAt}
/// - `groups/{code}/players/{uid}` → live scoreboard row: {name, chips,
///     hourly, daily, hourKey, dayKey, updatedAt, invitedBy?, tableKey}
///
/// Every call is best-effort: with no Firebase app (unit tests), no network,
/// or no auth the service reports failure and the game keeps playing offline
/// against the built-in bots.
class SocialService {
  /// Code alphabet and length live in utils/invite_link.dart so pure code
  /// (link parsing, tests) can validate a code without importing Firebase.
  static const String _codeAlphabet = kInviteCodeAlphabet;
  static const int codeLength = kInviteCodeLength;

  /// How recently a member must have written to count as online.
  static const Duration _onlineWindow = Duration(minutes: 5);

  bool get available => Firebase.apps.isNotEmpty;

  String? get uid => available ? FirebaseAuth.instance.currentUser?.uid : null;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Signs in anonymously when nobody is signed in yet, so guests can join
  /// groups too. Returns whether a Firebase user is available afterwards.
  Future<bool> ensureSignedIn() async {
    if (!available) return false;
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      return FirebaseAuth.instance.currentUser != null;
    } on FirebaseException catch (e) {
      debugPrint('SocialService.ensureSignedIn failed: ${e.code}');
      return false;
    } on PlatformException catch (e) {
      debugPrint('SocialService.ensureSignedIn failed: ${e.code}');
      return false;
    }
  }

  /// The group this player already belongs to, from a previous launch.
  Future<String?> fetchMyGroupCode() async {
    final u = uid;
    if (u == null) return null;
    try {
      final doc = await _db.collection('players').doc(u).get();
      final code = doc.data()?['groupCode'];
      return (code is String && code.isNotEmpty) ? code : null;
    } on FirebaseException catch (e) {
      debugPrint('SocialService.fetchMyGroupCode failed: ${e.code}');
      return null;
    }
  }

  String _generateCode(Random rng) => String.fromCharCodes(
    List.generate(codeLength, (_) => _codeAlphabet.codeUnitAt(rng.nextInt(_codeAlphabet.length))),
  );

  /// True when this player created [code] themself — used only to tell a
  /// "you're already at this table" toast apart from a genuine "welcome
  /// back" one when a member re-taps an invite they already used.
  Future<bool> isGroupCreator(String code) async {
    final u = uid;
    if (u == null) return false;
    try {
      final doc = await _db.collection('groups').doc(code).get();
      return doc.data()?['createdBy'] == u;
    } on FirebaseException catch (e) {
      debugPrint('SocialService.isGroupCreator failed: ${e.code}');
      return false;
    }
  }

  /// Creates a fresh group, joins it, and returns its code (null on failure).
  /// The creator's own row never carries `invitedBy` — there is no one to
  /// credit for it.
  Future<String?> createGroup(String displayName, Random rng) async {
    final u = uid;
    if (u == null) return null;
    try {
      for (var attempt = 0; attempt < 5; attempt++) {
        final code = _generateCode(rng);
        final ref = _db.collection('groups').doc(code);
        if ((await ref.get()).exists) continue;
        await ref.set({'createdBy': u, 'createdAt': FieldValue.serverTimestamp()});
        await _writeMembership(code, displayName);
        return code;
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint('SocialService.createGroup failed: ${e.code}');
      return null;
    }
  }

  /// Joins an existing group by code, crediting the group's creator as
  /// `invitedBy` unless the caller *is* the creator (rejoining their own
  /// link) or already has a row there (rejoining the same invite twice —
  /// `invitedBy` is write-once, so re-writing it would violate the rules).
  Future<JoinResult> joinGroup(String code, String displayName) async {
    final u = uid;
    if (u == null) return JoinResult.failed;
    try {
      final group = await _db.collection('groups').doc(code).get();
      if (!group.exists) return JoinResult.notFound;
      final existing = await _db.collection('groups').doc(code).collection('players').doc(u).get();
      if (existing.exists) {
        await _writeMembership(code, displayName);
        return JoinResult.alreadyMember;
      }
      final createdBy = group.data()?['createdBy'];
      final invitedBy = (createdBy is String && createdBy != u) ? createdBy : null;
      await _writeMembership(code, displayName, invitedBy: invitedBy);
      return JoinResult.joined;
    } on FirebaseException catch (e) {
      debugPrint('SocialService.joinGroup failed: ${e.code}');
      return JoinResult.failed;
    }
  }

  Future<void> _writeMembership(String code, String displayName, {String? invitedBy}) async {
    final u = uid;
    if (u == null) return;
    await _db.collection('players').doc(u).set({'groupCode': code, 'name': displayName}, SetOptions(merge: true));
    await _db.collection('groups').doc(code).collection('players').doc(u).set({
      'name': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
      'tableKey': '',
      if (invitedBy != null) 'invitedBy': invitedBy,
    }, SetOptions(merge: true));
  }

  /// Publishes the player's current scoreboard row: always to the world
  /// `leaderboard`, and additionally to the friends group (with [tableKey]
  /// for real table presence) when [code] is set.
  Future<void> reportScore({
    String? code,
    required String name,
    required int chips,
    required int hourly,
    required int daily,
    required String hourKey,
    required String dayKey,
    required String tableKey,
  }) async {
    final u = uid;
    if (u == null) return;
    final row = {
      'name': name,
      'chips': chips,
      'hourly': hourly,
      'daily': daily,
      'hourKey': hourKey,
      'dayKey': dayKey,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await _db.collection('leaderboard').doc(u).set(row, SetOptions(merge: true));
      if (code != null) {
        await _db
            .collection('groups')
            .doc(code)
            .collection('players')
            .doc(u)
            .set({...row, 'tableKey': tableKey}, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      debugPrint('SocialService.reportScore failed: ${e.code}');
    }
  }

  /// Live top players worldwide for one period key (`2026-08-01T19` hourly /
  /// `2026-08-01` daily), best score first. Backed by the composite indexes
  /// in `firestore.indexes.json`.
  Stream<List<Friend>> watchTopPlayers({required bool hourly, required String periodKey, int limitTo = 10}) {
    return _db
        .collection('leaderboard')
        .where(hourly ? 'hourKey' : 'dayKey', isEqualTo: periodKey)
        .orderBy(hourly ? 'hourly' : 'daily', descending: true)
        .limit(limitTo)
        .snapshots()
        .map((snap) {
          final now = DateTime.now();
          final hk = hourKeyOf(now);
          final dk = dayKeyOf(now);
          return [for (final doc in snap.docs) _friendFromDoc(doc.id, doc.data(), now, hk, dk)];
        });
  }

  /// Live view of the *other* members of [code], mapped into the [Friend]
  /// model the whole UI already renders. Stale hourly/daily buckets read as 0.
  Stream<List<Friend>> watchMembers(String code) {
    return _db.collection('groups').doc(code).collection('players').snapshots().map((snap) {
      final now = DateTime.now();
      final hk = hourKeyOf(now);
      final dk = dayKeyOf(now);
      final me = uid;
      return [
        for (final doc in snap.docs)
          if (doc.id != me) _friendFromDoc(doc.id, doc.data(), now, hk, dk),
      ];
    });
  }

  Friend _friendFromDoc(String id, Map<String, dynamic> d, DateTime now, String hk, String dk) {
    final updatedAt = d['updatedAt'];
    final online = updatedAt is Timestamp && now.difference(updatedAt.toDate()) < _onlineWindow;
    // A stale or empty tableKey never counts as "here" — folding freshness
    // into the value itself means callers (utils/table_presence.dart) never
    // have to reason about `online` separately.
    final rawTableKey = d['tableKey'];
    final tableKey = (online && rawTableKey is String && rawTableKey.isNotEmpty) ? rawTableKey : null;
    return Friend(
      id: id,
      name: (d['name'] as String?) ?? 'Player',
      chips: (d['chips'] as num?)?.toInt() ?? 0,
      online: online,
      hourlyScore: rolledPoints((d['hourly'] as num?)?.toInt() ?? 0, (d['hourKey'] as String?) ?? '', hk),
      dailyScore: rolledPoints((d['daily'] as num?)?.toInt() ?? 0, (d['dayKey'] as String?) ?? '', dk),
      invitedBy: d['invitedBy'] as String?,
      tableKey: tableKey,
    );
  }
}
