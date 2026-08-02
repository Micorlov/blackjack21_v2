/// Small pool of flag emoji used purely for cosmetic variety on leaderboard
/// rows — no real location data is collected, requested, or stored anywhere.
const List<String> _kFlagPool = [
  '🇺🇸',
  '🇬🇧',
  '🇨🇦',
  '🇦🇺',
  '🇩🇪',
  '🇫🇷',
  '🇮🇹',
  '🇪🇸',
  '🇧🇷',
  '🇯🇵',
  '🇰🇷',
  '🇮🇳',
  '🇲🇽',
  '🇳🇱',
  '🇸🇪',
  '🇮🇱',
  '🇿🇦',
  '🇦🇷',
  '🇹🇷',
  '🇵🇱',
];

/// A deterministic decorative flag for a player id — the same id always maps
/// to the same flag, but it carries no real geographic meaning. Uses a
/// hand-rolled hash rather than [String.hashCode], which Dart does not
/// guarantee to be stable across platforms.
String flagForId(String id) {
  if (id.isEmpty) return _kFlagPool.first;
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _kFlagPool[hash % _kFlagPool.length];
}
