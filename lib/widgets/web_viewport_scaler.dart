import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Zooms the whole app on web so it reads comfortably for this app's
/// players, who are largely 60+. Native platforms are left at their true
/// physical size, so this is a no-op there.
///
/// Uses the same design-canvas + `Transform.scale` technique as
/// `TableFelt` (`screens/table/table_felt.dart`): the child is told (via an
/// overridden `MediaQuery` size) that it has a canvas exactly
/// `available / scale`, then that canvas is blown up by `scale` so the
/// result exactly fills the real viewport with no cropping.
///
/// The zoom is bounded by *canvas* floors rather than a target scale, which
/// is what keeps it safe: shrinking the canvas is how the zoom is bought,
/// so a canvas the app is known to handle is a zoom the app is known to
/// survive. Both floors below sit at sizes `test/table_layout_test.dart`
/// already exercises.
class WebViewportScaler extends StatelessWidget {
  const WebViewportScaler({
    super.key,
    required this.child,
    this.isWeb = kIsWeb,
  });

  final Widget child;

  /// Overridable for tests; defaults to the real platform.
  final bool isWeb;

  /// The zoom this widget would apply in [available]. Exposed so tests can
  /// assert the calibration directly instead of inferring it from a render
  /// tree, and so the doc comments above stay checkable.
  static double scaleFor(Size available) {
    if (!available.isFinite || available.width <= 0 || available.height <= 0) {
      return 1;
    }
    final widthScale = available.width / _minCanvasWidth;
    final heightScale = available.height / _minCanvasHeight;
    return math.min(
      math.max(1.0, math.min(widthScale, heightScale)),
      _maxScale,
    );
  }

  /// Floor on the *derived* canvas width (`available.width / scale`), set to
  /// the narrowest device the layout tests cover (`small-320x568`). Zooming
  /// hands the app a canvas narrower than the real viewport, so this says:
  /// never make it narrower than a phone the app already supports.
  ///
  /// This is deliberately *not* the 393 design width. Pinning the canvas to
  /// 393 meant a 430-wide phone browser zoomed by only 1.09 — invisible —
  /// which is exactly why the first pass at this fixed desktop but left
  /// phones just as small as before.
  static const double _minCanvasWidth = 320;

  /// Floor on the *derived* canvas height (`available.height / scale`), just
  /// under the 568 of that same smallest tested device. Without it a short,
  /// wide window would zoom on width alone and leave the two non-scrolling
  /// screens (onboarding, the table) with too little height to lay out in.
  static const double _minCanvasHeight = 560;

  /// Upper bound on the scale-up regardless of how much room is available.
  /// A desktop monitor's viewing distance is only roughly double a phone's,
  /// and an unbounded scale would blow a fixed 88px icon up past 700px on
  /// an ultra-wide display — legible isn't the same as sensible.
  static const double _maxScale = 2.5;

  @override
  Widget build(BuildContext context) {
    if (!isWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest;
        // Never shrink below native size — only grow into extra room, and
        // never past what the canvas floors above allow.
        final scale = scaleFor(available);
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
              child: SizedBox(
                width: canvas.width,
                height: canvas.height,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
