import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/widgets/web_viewport_scaler.dart';

/// The zoom exists so the web app reads comfortably for 60+ players, and the
/// canvas it hands the app must stay inside sizes `table_layout_test.dart`
/// already proves the layout survives (smallest device there: 320x568).
void main() {
  group('scaleFor', () {
    test('zooms a phone browser enough to be worth having', () {
      // iPhone 15 Pro Max in Safari, the case this was reported against.
      final scale = WebViewportScaler.scaleFor(const Size(430, 745));

      expect(scale, greaterThan(1.25));
    });

    test('never hands the app a canvas narrower or shorter than 320x560', () {
      const viewports = <Size>[
        Size(430, 745), // iPhone 15 Pro Max, Safari
        Size(390, 664), // iPhone 14, Safari
        Size(375, 812), // narrow phone
        Size(1280, 800), // laptop
        Size(1920, 1080), // desktop
        Size(2560, 900), // ultra-wide, short
      ];

      for (final viewport in viewports) {
        final scale = WebViewportScaler.scaleFor(viewport);
        final canvas = Size(viewport.width / scale, viewport.height / scale);

        expect(
          canvas.width,
          greaterThanOrEqualTo(320 - 0.01),
          reason: 'canvas too narrow at $viewport',
        );
        expect(
          canvas.height,
          greaterThanOrEqualTo(560 - 0.01),
          reason: 'canvas too short at $viewport',
        );
      }
    });

    test('never shrinks the app below native size', () {
      // Smaller than both floors — must clamp to 1, not scale down.
      expect(WebViewportScaler.scaleFor(const Size(320, 480)), 1.0);
      expect(WebViewportScaler.scaleFor(const Size(280, 500)), 1.0);
    });

    test('caps the zoom so an ultra-wide monitor does not balloon the UI', () {
      expect(WebViewportScaler.scaleFor(const Size(5120, 2880)), 2.5);
    });

    test('degrades to no zoom on a degenerate viewport', () {
      expect(WebViewportScaler.scaleFor(Size.zero), 1.0);
      expect(WebViewportScaler.scaleFor(const Size(double.infinity, 800)), 1.0);
    });
  });

  group('widget', () {
    testWidgets('leaves the child untouched off web', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 745));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: WebViewportScaler(isWeb: false, child: SizedBox.expand()),
        ),
      );

      expect(find.byType(Transform), findsNothing);
    });

    testWidgets(
      'gives the child the zoomed-out canvas as its MediaQuery size',
      (tester) async {
        const viewport = Size(430, 745);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        late Size seenByChild;
        await tester.pumpWidget(
          MaterialApp(
            home: WebViewportScaler(
              isWeb: true,
              child: Builder(
                builder: (context) {
                  seenByChild = MediaQuery.sizeOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );

        final scale = WebViewportScaler.scaleFor(viewport);
        expect(seenByChild.width, closeTo(viewport.width / scale, 0.01));
        expect(seenByChild.height, closeTo(viewport.height / scale, 0.01));
      },
    );
  });
}
