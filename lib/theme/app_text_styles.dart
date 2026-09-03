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

  // ── Type ramp ──────────────────────────────────────────────────────────
  //
  // Before this existed, every call site passed a raw pixel size and the app
  // accumulated 14 of them between 10 and 48. Reach for a step here first;
  // the raw helpers above remain for the felt, where sizes are computed from
  // the card geometry rather than chosen from a ramp.
  //
  // Serif italic carries display and headings, Sora carries everything the
  // player reads as prose, and mono carries numbers — money should line up in
  // columns and never reflow as digits change.

  /// Hero moments only: the onboarding wordmark, a jackpot figure.
  static TextStyle display({Color color = AppColors.textPrimary}) {
    return serifItalic(40, color: color, height: 1.1);
  }

  /// Screen titles.
  static TextStyle h1({Color color = AppColors.textPrimary}) {
    return serifItalic(32, color: color, height: 1.15);
  }

  /// Section and card headings.
  static TextStyle h2({Color color = AppColors.textPrimary}) {
    return serifItalic(24, color: color, height: 1.2);
  }

  /// Emphasised UI text: list row titles, button labels.
  static TextStyle title({Color color = AppColors.textPrimary}) {
    return sora(17, weight: FontWeight.w700, color: color, height: 1.3);
  }

  /// Default body copy.
  static TextStyle body({Color color = AppColors.textPrimary}) {
    return sora(15, color: color, height: 1.5);
  }

  /// Supporting copy: sublabels, helper text.
  static TextStyle bodySm({Color color = AppColors.textMuted}) {
    return sora(13, color: color, height: 1.45);
  }

  /// The smallest text the app is allowed to use.
  ///
  /// 12px is the floor deliberately: the audit found 10–11px labels on the
  /// felt that also had text scaling disabled, which is unreadable for anyone
  /// who needs larger type. If something does not fit at 12, the layout is
  /// wrong, not the type size.
  static TextStyle caption({Color color = AppColors.textMuted}) {
    return sora(12, color: color, height: 1.35);
  }

  /// Money and counts.
  static TextStyle numeral(
    double size, {
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w700,
  }) {
    return mono(size, weight: weight, color: color);
  }
}
