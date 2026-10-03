/// Counts how long the app has been in the foreground, for the admin panel's
/// "Time Played" column (`leaderboard/{uid}.playSeconds`).
///
/// Runs on a monotonic clock (a [Stopwatch] by default), not wall time, so a
/// device clock change can never add or subtract hours; and on Android/iOS
/// that clock stops while the device sleeps, so a missed pause callback with
/// the screen off still counts nothing.
///
/// [takeSeconds] hands out whole seconds and keeps the fraction, so a flush
/// every minute never rounds time away and each second is reported once.
class PlayTimeTracker {
  /// [clock] is a seam for tests; it must be monotonic. Counting starts at
  /// construction because the app is created in the foreground.
  PlayTimeTracker({Duration Function()? clock}) : _clock = clock ?? _stopwatchClock() {
    _since = _clock();
  }

  final Duration Function() _clock;

  /// When the current foreground stretch began; null while backgrounded.
  Duration? _since;

  /// Played time not yet handed out by [takeSeconds].
  Duration _banked = Duration.zero;

  static Duration Function() _stopwatchClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  void resume() => _since ??= _clock();

  void pause() {
    final since = _since;
    if (since == null) return;
    _banked += _clock() - since;
    _since = null;
  }

  /// Whole seconds played since the previous call, ready to add to the
  /// stored total.
  int takeSeconds() {
    final now = _clock();
    final since = _since;
    final total = _banked + (since == null ? Duration.zero : now - since);
    final whole = total.inSeconds;
    _banked = total - Duration(seconds: whole);
    if (since != null) _since = now;
    return whole;
  }
}
