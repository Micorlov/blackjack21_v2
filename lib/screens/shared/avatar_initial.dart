/// The letter an avatar circle shows for a player.
///
/// Lived twice — once in `settings_screen.dart` and once in `shop_screen.dart`
/// — plus a third inline copy in `lobby_screen.dart` that used a different
/// fallback. One implementation with the fallback as a parameter keeps them
/// from drifting again.
String avatarInitialOf(String displayName, {String fallback = 'G'}) {
  final name = displayName.trim();
  if (name.isEmpty) return fallback;
  return name[0].toUpperCase();
}
