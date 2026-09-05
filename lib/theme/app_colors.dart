import 'package:flutter/material.dart';

/// Design tokens.
///
/// Calmed on 2026-09-05: the surfaces lost most of their green cast and sit a
/// step lighter, so the app reads as a quiet dark room rather than a lit
/// casino floor. The felt keeps its greens — a card table is baize — and gold
/// stays the single accent, but it is now a flat fill: the gradients and glows
/// are gone.
class AppColors {
  AppColors._();

  // Shell / backgrounds
  static const Color shellBlack = Color(0xFF0B0E0D);
  static const Color surface = Color(0xFF131716);
  static const Color panel = Color(0xFF1C2120);
  static const Color navSurface = Color(0xFF171B1A);
  static const Color border = Color(0xFF2B3230);

  // Felt greens
  static const Color felt = Color(0xFF175943);
  static const Color feltDark = Color(0xFF0E3B2E);
  static const Color feltDarkest = Color(0xFF0A2018);
  static const Color feltTableMid = Color(0xFF123A2C);
  static const Color feltTableDark = Color(0xFF0A1F18);

  // Text
  static const Color textPrimary = Color(0xFFF5F1E8);
  static const Color textMuted = Color(0xFFC7C3B7);
  static const Color textLabel = Color(0xFFC2BEB2);
  static const Color textFaint = Color(0xFF9AA79E);

  /// Control boundaries and structural dividers.
  ///
  /// [border] is 1.71:1 against [surface] — fine for a decorative hairline,
  /// but below the 3:1 that a control outline needs to be perceivable. Use
  /// this where the edge is the only thing defining a tappable thing.
  static const Color borderStrong = Color(0xFF6B7572);

  // Gold accent
  static const Color goldLight = Color(0xFFEBD7A0);
  static const Color gold = Color(0xFFDCBF7A);
  static const Color goldDark = Color(0xFFC9A75C);
  static const Color goldInk = Color(0xFF1A1408);

  // Win / lose / push
  //
  // Contrast measured against felt #175943. The base colours are fills — text
  // goes on top of them, not in them. On the felt itself, use the `*Light` /
  // `pushOnFelt` variants: `lose` scores 1.76:1 there and `win` 3.05:1, so
  // neither is legible as table text.
  static const Color win = Color(0xFF4FAE8E);

  /// Win text on felt — 5.75:1.
  static const Color winLight = Color(0xFF9FE6C9);
  static const Color lose = Color(0xFFC1503F);

  /// Loss text on felt — 4.53:1. Nudged up from #F0A79B, which sat at 4.20.
  static const Color loseLight = Color(0xFFF2B0A5);
  static const Color loseSoft = Color(0xFFE39084);
  static const Color push = Color(0xFFC2BEB2);

  /// Push text on felt — 4.53:1. [push] itself lands at 4.44.
  static const Color pushOnFelt = Color(0xFFC4C0B4);

  // Card faces
  static const Color cardFaceTop = Color(0xFFFFFDF8);
  static const Color cardFaceBottom = Color(0xFFF0E9D9);
  static const Color cardRed = Color(0xFFB23A2E);
  static const Color cardBlack = Color(0xFF16130E);

  // ── Light theme ──
  //
  // Warm paper rather than clinical white: the brand is warm gold, and a cool
  // grey ground makes it look dirty. The felt greens above are shared by both
  // themes — a card table is baize in any light, so light mode restyles the
  // menus around the table, not the table itself.

  static const Color lightBackground = Color(0xFFF4F1EA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPanel = Color(0xFFEAE4D8);
  static const Color lightForeground = Color(0xFF141A17);
  static const Color lightMuted = Color(0xFF4C5A52);
  static const Color lightFaint = Color(0xFF4F5C54);
  static const Color lightBorder = Color(0xFFC3BCAC);
  static const Color lightBorderStrong = Color(0xFF7E7666);

  /// Gold as *text* on paper. The brand gold manages only 3.25:1 on
  /// [lightBackground], so light mode darkens it rather than shipping an
  /// accent nobody can read. Gold *fills* still use [gold] with [goldInk] on
  /// top, which is 11.23:1 and needs no change.
  static const Color lightAccentText = Color(0xFF6B5114);
  static const Color lightWin = Color(0xFF1F7A5C);
  static const Color lightLose = Color(0xFFA3352A);

  // Chip denomination colors
  static const Map<int, Color> chipColors = {25: win, 50: lose, 100: textPrimary, 500: gold, 1000: Color(0xFF9B7FD4)};

  // Seat plate accent colors (friends at table)
  static const List<Color> seatColors = [Color(0xFFC86A9E), Color(0xFF4FAE8E), Color(0xFF8A9BB8), Color(0xFFE0A050)];

  // Avatar swatch colors
  static const List<Color> avatarSwatchColors = [
    Color(0xFF1E7D5D),
    gold,
    Color(0xFFB23A2E),
    Color(0xFF3E7FA8),
    Color(0xFF8A6BB8),
    win,
  ];

  static Color medalColor(int rank) {
    switch (rank) {
      case 1:
        return gold;
      case 2:
        return const Color(0xFFC7CCC9);
      case 3:
        return const Color(0xFFC98A4B);
      default:
        return border;
    }
  }

  // ── Colours that were repeated as literals across the screens ──
  //
  // Each appeared as a bare hex in several files, close to but not equal to an
  // existing token, which is how a palette drifts: the next person copies
  // whichever literal is nearest.

  /// Body copy on a panel. Sat as a raw `#D8D3C6` in five places, a shade off
  /// [textMuted] for no stated reason.
  static const Color textBody = Color(0xFFD8D3C6);

  /// The true black behind a modal, and under the felt's vignette. Written as
  /// a raw `#040806` in eight places, the theme itself included.
  static const Color scrim = Color(0xFF040806);
}
