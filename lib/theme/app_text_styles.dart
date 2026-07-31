import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography helpers ported from `Blackjack 21 v2.dc.html`:
/// Sora (body), Instrument Serif italic (headings), Space Mono (numbers/labels).
class AppText {
  AppText._();

  static TextStyle sora(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle serifItalic(
    double size, {
    Color color = AppColors.textPrimary,
    double? height,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.instrumentSerif(
      fontSize: size,
      fontStyle: FontStyle.italic,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Uppercase mono section label, e.g. "CHOOSE YOUR TABLE".
  static TextStyle sectionLabel({Color color = AppColors.textLabel}) {
    return mono(13, letterSpacing: 1.3, color: color);
  }
}
