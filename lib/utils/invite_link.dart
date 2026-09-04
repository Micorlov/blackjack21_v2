/// Pure invite-link construction and parsing.
///
/// No Firebase, no Flutter — join-by-link logic is fully unit-testable, the
/// same way `points.dart` and `daily_bonus.dart` are. `SocialService` and
/// `GameNotifier` both depend on this file rather than the other way around.
library;

/// Web host the join link points at — matches the `hosting.site` in
/// `firebase.json`. Hosting already rewrites every path (including
/// `/join/CODE`) to `index.html`, so no separate static join page exists.
const String kInviteHost = 'blackjack21-v2.web.app';

/// Where a browser without the app lands from the web install banner.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.micorlov.blackjack21_v2';

/// Code alphabet without lookalikes (0/O, 1/I/L) — friends retype these.
/// Lives here (not in `SocialService`) so pure code can validate a code
/// without importing Firebase.
const String kInviteCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const int kInviteCodeLength = 6;

/// The single link every invite shares: `https://<host>/join/<CODE>`.
Uri inviteUri(String code) => Uri.https(kInviteHost, '/join/$code');

bool isValidJoinCode(String code) =>
    code.length == kInviteCodeLength &&
    code.runes.every((r) => kInviteCodeAlphabet.contains(String.fromCharCode(r)));

/// Extracts a join code from a parsed [uri], accepting every shape the app
/// can receive one in: a path (`/join/CODE`), a query parameter
/// (`?code=CODE`), or a hash-routed path (`#/join/CODE`, as a web reload of
/// a hash-strategy link would present it). The host is checked only when
/// [uri] actually carries one — a bare route string like `/join/CODE` (what
/// `defaultRouteName` reports on a cold-started native app) has none and is
/// still trusted, since it never left the device.
String? joinCodeFromUri(Uri uri) {
  if (uri.host.isNotEmpty && uri.host != kInviteHost) return null;

  final fromQuery = uri.queryParameters['code'];
  if (fromQuery != null) {
    final code = fromQuery.toUpperCase();
    return isValidJoinCode(code) ? code : null;
  }

  final fragmentUri = uri.fragment.isEmpty ? null : Uri.tryParse(uri.fragment);
  final segments = [...uri.pathSegments, ...?fragmentUri?.pathSegments];
  final joinIndex = segments.indexOf('join');
  if (joinIndex == -1 || joinIndex + 1 >= segments.length) return null;
  final code = segments[joinIndex + 1].toUpperCase();
  return isValidJoinCode(code) ? code : null;
}

/// Same as [joinCodeFromUri], from a raw route string —
/// `PlatformDispatcher.defaultRouteName`, `RouteInformation.uri`, or
/// `Uri.base` on web.
String? joinCodeFromRoute(String route) {
  final uri = Uri.tryParse(route);
  return uri == null ? null : joinCodeFromUri(uri);
}

/// Finds a join code inside free text: a pasted invite message (clipboard
/// pre-fill) or a bare code someone typed or forwarded by hand.
String? joinCodeFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final urlMatch = RegExp(r'https?://\S+').firstMatch(trimmed);
  if (urlMatch != null) {
    final uri = Uri.tryParse(urlMatch.group(0)!);
    final fromUrl = uri == null ? null : joinCodeFromUri(uri);
    if (fromUrl != null) return fromUrl;
  }

  final bare = trimmed.toUpperCase();
  return isValidJoinCode(bare) ? bare : null;
}
