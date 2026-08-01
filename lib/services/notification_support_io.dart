import 'dart:io';

/// True only on the two platforms this app wires notifications up for, and
/// never under `flutter test`.
///
/// The test runner registers no plugin implementations, so touching the
/// notification plugin there throws a `LateInitializationError` from deep
/// inside the package — an error no `on` clause in our own code can
/// meaningfully catch. Asking whether the plugin is usable *before* calling it
/// keeps that failure from ever happening.
bool get notificationsSupported =>
    !Platform.environment.containsKey('FLUTTER_TEST') && (Platform.isIOS || Platform.isAndroid);
