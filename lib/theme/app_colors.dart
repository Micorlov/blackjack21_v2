import 'package:flutter/material.dart';

/// Design tokens ported from `Blackjack 21 v2.dc.html` (Omaha poker-app system).
class AppColors {
  AppColors._();

  // Shell / backgrounds
  static const Color shellBlack = Color(0xFF05100C);
  static const Color surface = Color(0xFF0E1412);
  static const Color panel = Color(0xFF1A2320);
  static const Color navSurface = Color(0xFF182420);
  static const Color border = Color(0xFF31403A);

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
  static const Color borderStrong = Color(0xFF577167);

  // Gold accent
  static const Color goldLight = Color(0xFFF3E0A3);
  static const Color gold = Color(0xFFE8C77A);
  static const Color goldDark = Color(0xFFD9AD5C);
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

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient feltCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [felt, feltDark],
    stops: [0.0, 0.7],
  );

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
}
