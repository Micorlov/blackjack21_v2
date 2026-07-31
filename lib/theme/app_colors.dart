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

  // Gold accent
  static const Color goldLight = Color(0xFFF3E0A3);
  static const Color gold = Color(0xFFE8C77A);
  static const Color goldDark = Color(0xFFD9AD5C);
  static const Color goldInk = Color(0xFF1A1408);

  // Win / lose / push
  static const Color win = Color(0xFF4FAE8E);
  static const Color winLight = Color(0xFF9FE6C9);
  static const Color lose = Color(0xFFC1503F);
  static const Color loseLight = Color(0xFFF0A79B);
  static const Color loseSoft = Color(0xFFE39084);
  static const Color push = Color(0xFFC2BEB2);

  // Card faces
  static const Color cardFaceTop = Color(0xFFFFFDF8);
  static const Color cardFaceBottom = Color(0xFFF0E9D9);
  static const Color cardRed = Color(0xFFB23A2E);
  static const Color cardBlack = Color(0xFF16130E);

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
