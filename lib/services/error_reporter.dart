import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

const int _kMaxMessageLength = 500;
const int _kMaxStackLength = 2000;

/// Truncates to at most [max] characters. Pure and separately testable — the
/// one piece of [ErrorReporter] that does not need a Firestore instance to
/// verify.
String truncateForReport(String value, int max) => value.length <= max ? value : value.substring(0, max);

/// Mirrors fatal errors — and one ping per cold start — into Firestore, so
/// the admin panel's Health tab can show what is breaking in the field and
/// which versions are actually installed, without opening the Crashlytics
/// console.
///
/// Best-effort only: nothing here may affect the crash report Crashlytics
/// already recorded, so every failure is swallowed.
class ErrorReporter {
  // The public param is intentionally unprefixed while the field stays
  // private; `this._firestore` would force the named argument at call sites
  // to carry the leading underscore too.
  ErrorReporter({FirebaseFirestore? firestore, required this.appVersion, required this.platform})
    : _firestore = firestore; // ignore: prefer_initializing_formals

  final FirebaseFirestore? _firestore;
  final String appVersion;
  final String platform;

  Future<void> reportFatal(Object error, StackTrace? stack) async {
    final db = _firestore;
    if (db == null) return;
    try {
      await db.collection('errors').add({
        'message': truncateForReport(error.toString(), _kMaxMessageLength),
        'stack': stack == null ? null : truncateForReport(stack.toString(), _kMaxStackLength),
        'appVersion': appVersion,
        'platform': platform,
        'at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('ErrorReporter.reportFatal failed: ${e.code}');
    }
  }

  Future<void> reportInstall() async {
    final db = _firestore;
    if (db == null) return;
    try {
      await db.collection('installs').add({
        'appVersion': appVersion,
        'platform': platform,
        'at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('ErrorReporter.reportInstall failed: ${e.code}');
    }
  }
}
