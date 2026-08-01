import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/social_models.dart';
import '../utils/points.dart';

/// Firestore-backed friends layer.
///
/// Layout:
/// - `players/{uid}`               → membership pointer: {groupCode, name}
/// - `groups/{code}`               → {createdBy, createdAt}
/// - `groups/{code}/players/{uid}` → live scoreboard row: {name, chips,
///     hourly, daily, hourKey, dayKey, updatedAt}
///
/// Every call is best-effort: with no Firebase app (unit tests), no network,
/// or no auth the service reports failure and the game keeps playing offline
/// against the built-in bots.
class SocialService {
  /// Code alphabet without lookalikes (0/O, 1/I/L) — friends retype these.
  static const String _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const int codeLength = 6;

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

  /// Creates a fresh group, joins it, and returns its code (null on failure).
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

  /// Joins an existing group by code. False when the code doesn't exist or
  /// the write fails.
  Future<bool> joinGroup(String code, String displayName) async {
    final u = uid;
    if (u == null) return false;
    try {
      if (!(await _db.collection('groups').doc(code).get()).exists) return false;
      await _writeMembership(code, displayName);
      return true;
    } on FirebaseException catch (e) {
      debugPrint('SocialService.joinGroup failed: ${e.code}');
      return false;
    }
  }

  Future<void> _writeMembership(String code, String displayName) async {
    final u = uid;
    if (u == null) return;
    await _db.collection('players').doc(u).set({'groupCode': code, 'name': displayName}, SetOptions(merge: true));
    await _db.collection('groups').doc(code).collection('players').doc(u).set({
      'name': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Publishes the player's current scoreboard row to the group.
  Future<void> reportScore({
    required String code,
    required String name,
    required int chips,
    required int hourly,
    required int daily,
    required String hourKey,
    required String dayKey,
  }) async {
    final u = uid;
    if (u == null) return;
    try {
      await _db.collection('groups').doc(code).collection('players').doc(u).set({
        'name': name,
        'chips': chips,
        'hourly': hourly,
        'daily': daily,
        'hourKey': hourKey,
        'dayKey': dayKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('SocialService.reportScore failed: ${e.code}');
    }
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
    return Friend(
      id: id,
      name: (d['name'] as String?) ?? 'Player',
      chips: (d['chips'] as num?)?.toInt() ?? 0,
      online: online,
      hourlyScore: rolledPoints((d['hourly'] as num?)?.toInt() ?? 0, (d['hourKey'] as String?) ?? '', hk),
      dailyScore: rolledPoints((d['daily'] as num?)?.toInt() ?? 0, (d['dayKey'] as String?) ?? '', dk),
    );
  }
}
