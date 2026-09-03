import 'package:flutter/material.dart';

/// Spacing tokens on a 4/8dp rhythm.
///
/// Replaces the ad-hoc `SizedBox(height: N)` values scattered through the
/// screens. Pick the nearest step rather than inventing a new number — the
/// rhythm is what makes unrelated screens feel like one app.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// The standard page inset every list screen already uses.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(xl, xl, xl, xxl);

  /// Horizontal gutter by width class. Larger screens get more breathing room
  /// instead of a stretched phone layout.
  static double gutterFor(double width) {
    if (width >= 900) return 48;
    if (width >= 600) return 32;
    return xl;
  }
}

/// Corner radius tokens, replacing the ad-hoc 8/12/14/16/18/20/22 mix.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Fully rounded — pills, chips, circular controls.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Minimum interactive sizes.
///
/// Android's Material guidance is 48dp and iOS's is 44pt; we use the larger of
/// the two everywhere so one number is correct on both platforms.
class AppTouch {
  AppTouch._();

  static const double minTarget = 48;

  /// Guarantees the minimum on both axes. Use on icon buttons whose painted
  /// glyph is smaller than the target.
  static const BoxConstraints minTargetConstraints = BoxConstraints(
    minWidth: minTarget,
    minHeight: minTarget,
  );
}
