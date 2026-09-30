import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Names of the remote kill switches this app checks, in one place — the same
/// reason [AnalyticsEvent] collects event names — so a typo cannot quietly
/// create a flag the admin panel's toggle has no effect on.
class FeatureFlag {
  FeatureFlag._();

  static const String reviewPrompt = 'reviewPromptEnabled';
  static const String referralRewards = 'referralRewardsEnabled';
}

/// Remote feature toggles read from `config/features`, so a feature can be
/// switched off for every player from the admin panel without shipping a
/// release.
///
/// Fails open: a flag missing from the document, a document that does not
/// exist yet, or a read that fails (offline, rules, no Firebase) all read as
/// enabled. The admin panel can only turn things *off* — a missing or slow
/// read can never silently disable a feature for everyone.
class FeatureFlags {
  // The public param is intentionally unprefixed while the field stays
  // private; `this._firestore` would force the named argument at call sites
  // to carry the leading underscore too.
  FeatureFlags({FirebaseFirestore? firestore}) : _firestore = firestore; // ignore: prefer_initializing_formals

  final FirebaseFirestore? _firestore;
  Map<String, bool> _values = const {};

  /// Fetches `config/features` once. Safe to call on every app start — a
  /// failure here leaves every flag at its fail-open default rather than
  /// throwing.
  Future<void> load() async {
    final db = _firestore;
    if (db == null) return;
    try {
      final doc = await db.collection('config').doc('features').get();
      applyRemoteConfig(doc.data());
    } on FirebaseException catch (e) {
      debugPrint('FeatureFlags.load failed: ${e.code}');
    }
  }

  /// Parses a raw Firestore document into flag values. Split out from [load]
  /// so the parsing itself — the part actually worth testing — does not need
  /// a Firestore instance to verify.
  @visibleForTesting
  void applyRemoteConfig(Map<String, dynamic>? data) {
    if (data == null) return;
    _values = data.map((key, value) => MapEntry(key, value == true));
  }

  bool isEnabled(String flag) => _values[flag] ?? true;
}
