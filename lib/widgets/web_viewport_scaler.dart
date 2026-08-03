import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Scales the whole app up on wide web viewports so it reads at the same
/// comfortable size the native app fills a phone screen with, instead of
/// staying pinned at 1:1 CSS-pixel size in a small corner of a much bigger
/// browser window. Native platforms render at their true physical size
/// already, so this is a no-op there.
///
/// Uses the same design-canvas + `Transform.scale` technique as
/// `TableFelt` (`screens/table/table_felt.dart`): the child is told (via an
/// overridden `MediaQuery` size) that it has a canvas exactly
/// `available / scale`, then that canvas is blown up by `scale` so the
/// result exactly fills the real viewport with no cropping.
class WebViewportScaler extends StatelessWidget {
  const WebViewportScaler({super.key, required this.child});

  final Widget child;

  /// Reference width of the mobile design, matching `TableFelt`'s own
  /// `_designWidth` — the width every screen's fixed paddings/font sizes
  /// were built against. Scaling by `width / _designWidth` alone is what
  /// fills the screen instead of leaving a narrow column of dead space.
  static const double _designWidth = 393;

  /// Floor on the *derived* canvas height (`available.height / scale`).
  /// `OnboardingScreen` is the one screen that isn't scrollable-by-default
  /// (every other screen is a `SingleChildScrollView`, which tolerates any
  /// canvas height fine), so this is calibrated to its own content: icon +
  /// title + subtitle + button plus the 64px of vertical `Padding` around
  /// them is ~430px tall, plus headroom for font-metric/line-wrap variance
  /// across browsers. Bounding the scale by this (instead of only by width)
  /// keeps that content from being scaled into less room than it needs.
  static const double _minCanvasHeight = 560;

  /// Upper bound on the scale-up regardless of how much room is available.
  /// A desktop monitor's viewing distance is only roughly double a phone's,
  /// and an unbounded scale would blow a fixed 88px icon up past 700px on
  /// an ultra-wide display — legible isn't the same as sensible.
  static const double _maxScale = 2.5;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest;
        if (!available.isFinite || available.width <= 0 || available.height <= 0) {
          return child;
        }

        // Never shrink below native size — only grow into extra room, and
        // never past what the height floor above allows.
        final widthScale = available.width / _designWidth;
        final heightScale = available.height / _minCanvasHeight;
        final scale = math.min(math.max(1.0, math.min(widthScale, heightScale)), _maxScale);
        if (scale == 1.0) return child;

        final canvas = Size(available.width / scale, available.height / scale);
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(size: canvas),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: canvas.width,
            maxWidth: canvas.width,
            minHeight: canvas.height,
            maxHeight: canvas.height,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(width: canvas.width, height: canvas.height, child: child),
            ),
          ),
        );
      },
    );
  }
}
