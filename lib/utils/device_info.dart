import 'dart:io' as io;

import 'package:flutter/foundation.dart' show kIsWeb;

/// The platform label every telemetry write uses (`leaderboard.platform`,
/// `errors.platform`, `installs.platform`), so the admin panel's breakdowns
/// group consistently instead of drifting per call site.
///
/// `dart:io.Platform` has no web implementation — accessing it there throws
/// — so [kIsWeb] is checked first rather than caught.
String currentPlatformName() {
  if (kIsWeb) return 'web';
  if (io.Platform.isAndroid) return 'android';
  if (io.Platform.isIOS) return 'ios';
  if (io.Platform.isMacOS) return 'macos';
  if (io.Platform.isWindows) return 'windows';
  if (io.Platform.isLinux) return 'linux';
  return 'unknown';
}
