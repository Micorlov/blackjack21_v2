/// Whether local notifications can actually be driven on this host.
///
/// The implementation is chosen at compile time: the `dart:io` variant on
/// mobile/desktop, the always-false variant on web (where `dart:io` does not
/// exist and no notification plugin is wired up).
library;

export 'notification_support_web.dart' if (dart.library.io) 'notification_support_io.dart';
