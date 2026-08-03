/// Wraps a Google sign-in button with the platform-correct trigger.
///
/// `GoogleSignIn.authenticate()` throws `UnimplementedError` on web — Google
/// Identity Services requires its own rendered button there instead, so on
/// web [child] is ignored in favor of Google's button, and the result
/// arrives via `GoogleSignIn.instance.authenticationEvents` (see
/// `GameNotifier`'s constructor). On mobile/desktop, [child] is rendered
/// unchanged — it already wires its own `onTap` to `signInGoogle()`.
library;

export 'google_signin_button_web.dart' if (dart.library.io) 'google_signin_button_io.dart';
