import 'dart:math' as math;

import 'package:blackjack21_v2/theme/app_colors.dart';
import 'package:blackjack21_v2/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrast is a gate, not a one-time audit.
///
/// The 2026-09-03 UI/UX pass found the loss red at **1.76:1** on the felt —
/// below even the 3:1 non-text floor — because nothing was watching. These
/// tests watch. A token change that regresses a pairing fails here rather than
/// shipping to players.
///
/// Thresholds are WCAG 2.2 AA: 4.5:1 for normal text, 3:1 for large text and
/// for non-text things that carry meaning (control boundaries, state icons).
void main() {
  group('WCAG AA contrast', () {
    group('dark theme — the primary theme', () {
      const p = AppPalette.dark;

      test('body and secondary text clear 4.5:1 on every surface', () {
        for (final surface in <(String, Color)>[
          ('background', p.background),
          ('card', p.card),
          ('panel', p.panel),
          ('navSurface', p.navSurface),
        ]) {
          expectContrast(p.foreground, surface.$2, 4.5,
              because: 'primary text on ${surface.$1}');
          expectContrast(p.mutedForeground, surface.$2, 4.5,
              because: 'secondary text on ${surface.$1}');
          expectContrast(p.faintForeground, surface.$2, 4.5,
              because: 'tertiary text on ${surface.$1}');
        }
      });

      test('gold reads as text on the app ground', () {
        expectContrast(p.accentText, p.background, 4.5,
            because: 'gold accent text on background');
      });

      test('ink on a gold fill is legible', () {
        expectContrast(p.onAccent, p.accent, 4.5,
            because: 'button label on the gold CTA');
      });

      test('control boundaries clear the 3:1 non-text floor', () {
        expectContrast(p.borderStrong, p.background, 3.0,
            because: 'control outline on background');
        expectContrast(p.borderStrong, p.card, 3.0,
            because: 'control outline on a card');
      });

      test('outcome colours are legible ON THE FELT, not just on panels', () {
        // The regression that started all this: the felt is far lighter than
        // the app's panels, so a colour that works on #0E1412 can be invisible
        // on #175943. Every outcome the player reads at the table is checked
        // against the felt it is actually drawn on.
        for (final felt in <(String, Color)>[
          ('felt', AppColors.felt),
          ('feltDark', AppColors.feltDark),
          ('feltTableMid', AppColors.feltTableMid),
        ]) {
          expectContrast(p.winOnFelt, felt.$2, 4.5, because: 'win on ${felt.$1}');
          expectContrast(p.loseOnFelt, felt.$2, 4.5, because: 'loss on ${felt.$1}');
          expectContrast(p.pushOnFelt, felt.$2, 4.5, because: 'push on ${felt.$1}');
          expectContrast(p.foreground, felt.$2, 4.5, because: 'text on ${felt.$1}');
          expectContrast(p.accent, felt.$2, 4.5, because: 'gold on ${felt.$1}');
        }
      });

      test('the raw loss red is still unfit for felt text', () {
        // Documents *why* loseOnFelt exists. If someone "simplifies" the
        // palette by pointing loseOnFelt back at lose, the test above breaks
        // and this one explains what they walked into.
        expect(
          contrastRatio(AppColors.lose, AppColors.felt),
          lessThan(3.0),
          reason: 'AppColors.lose is a fill colour; it must never be used as '
              'text on the felt. Use AppPalette.loseOnFelt.',
        );
      });
    });

    group('light theme', () {
      const p = AppPalette.light;

      test('body and secondary text clear 4.5:1 on every surface', () {
        for (final surface in <(String, Color)>[
          ('background', p.background),
          ('card', p.card),
          ('panel', p.panel),
        ]) {
          expectContrast(p.foreground, surface.$2, 4.5,
              because: 'primary text on ${surface.$1}');
          expectContrast(p.mutedForeground, surface.$2, 4.5,
              because: 'secondary text on ${surface.$1}');
          expectContrast(p.faintForeground, surface.$2, 4.5,
              because: 'tertiary text on ${surface.$1}');
        }
      });

      test('gold text is darkened for paper', () {
        expectContrast(p.accentText, p.background, 4.5,
            because: 'gold accent text on paper');
        expectContrast(p.accentText, p.card, 4.5,
            because: 'gold accent text on a card');
      });

      test('ink on a gold fill is legible', () {
        expectContrast(p.onAccent, p.accent, 4.5,
            because: 'button label on the gold CTA');
      });

      test('outcome colours are legible on paper', () {
        for (final surface in <(String, Color)>[
          ('background', p.background),
          ('card', p.card),
        ]) {
          expectContrast(p.win, surface.$2, 4.5, because: 'win on ${surface.$1}');
          expectContrast(p.lose, surface.$2, 4.5, because: 'loss on ${surface.$1}');
        }
      });

      test('control boundaries clear the 3:1 non-text floor', () {
        expectContrast(p.borderStrong, p.background, 3.0,
            because: 'control outline on background');
        expectContrast(p.borderStrong, p.card, 3.0,
            because: 'control outline on a card');
      });
    });
  });
}

/// Asserts [fg] on [bg] meets [minimum], reporting the actual ratio on failure
/// so the fix is obvious without re-deriving the maths.
void expectContrast(Color fg, Color bg, double minimum, {required String because}) {
  final ratio = contrastRatio(fg, bg);
  expect(
    ratio,
    greaterThanOrEqualTo(minimum),
    reason: '$because: ${_hex(fg)} on ${_hex(bg)} is '
        '${ratio.toStringAsFixed(2)}:1, needs $minimum:1',
  );
}

/// WCAG 2.x relative-luminance contrast ratio, `(L1 + 0.05) / (L2 + 0.05)`.
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _relativeLuminance(Color c) {
  double channel(double v) {
    return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

String _hex(Color c) {
  int byte(double v) => (v * 255).round();
  return '#${byte(c.r).toRadixString(16).padLeft(2, '0')}'
          '${byte(c.g).toRadixString(16).padLeft(2, '0')}'
          '${byte(c.b).toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}
