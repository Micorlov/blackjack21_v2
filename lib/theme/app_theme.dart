import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// The app's [ThemeData], built from the tokens.
///
/// Previously the theme styled only `bodyMedium` and the Switch, so every
/// widget hand-styled itself and light mode was impossible. Wiring the real
/// component themes here means a widget that simply uses `ElevatedButton` or
/// `Dialog` inherits the casino look instead of re-deriving it — and gets the
/// light variant for free.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData get light => _build(AppPalette.light);

  static ThemeData _build(AppPalette palette) {
    final isDark = palette.brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: palette.brightness,
      // Gold is the brand and the thing players tap, so it is the primary
      // role rather than the felt green — the felt is scenery, not an action.
      primary: palette.accent,
      onPrimary: palette.onAccent,
      secondary: AppColors.felt,
      onSecondary: AppColors.textPrimary,
      error: palette.lose,
      onError: Colors.white,
      surface: palette.card,
      onSurface: palette.foreground,
      surfaceContainerHighest: palette.panel,
      onSurfaceVariant: palette.mutedForeground,
      outline: palette.borderStrong,
      outlineVariant: palette.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      dividerColor: palette.border,
      extensions: <ThemeExtension<dynamic>>[palette],

      textTheme: _textTheme(palette),

      // Every interactive surface gets the same minimum, so a control can
      // never be smaller than a finger regardless of how it is built.
      materialTapTargetSize: MaterialTapTargetSize.padded,

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.faintForeground;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.border;
          }
          return states.contains(WidgetState.selected)
              ? palette.accent
              : palette.borderStrong;
        }),
        trackOutlineColor: WidgetStateProperty.all(palette.borderStrong),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.border,
          disabledForegroundColor: palette.faintForeground,
          minimumSize: const Size(0, AppTouch.minTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          textStyle: AppText.sora(17, weight: FontWeight.w800, letterSpacing: 0.9),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.foreground,
          disabledForegroundColor: palette.faintForeground,
          side: BorderSide(color: palette.borderStrong, width: 2),
          minimumSize: const Size(0, AppTouch.minTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          textStyle: AppText.sora(15, weight: FontWeight.w700, letterSpacing: 0.6),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accentText,
          disabledForegroundColor: palette.faintForeground,
          minimumSize: const Size(0, AppTouch.minTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppText.sora(15, weight: FontWeight.w600),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.foreground,
          minimumSize: const Size(AppTouch.minTarget, AppTouch.minTarget),
        ),
      ),

      iconTheme: IconThemeData(color: palette.foreground, size: 24),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        // Measured against the real background rather than reusing one
        // opacity: the app ground is nearly black, so a light scrim would be
        // invisible and the dialog would not read as separated.
        barrierColor: isDark ? const Color(0xCC040806) : const Color(0x99141A17),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xxlAll),
        titleTextStyle: AppText.h2(color: palette.foreground),
        contentTextStyle: AppText.body(color: palette.mutedForeground),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor:
            isDark ? const Color(0x99040806) : const Color(0x66141A17),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.card,
        contentTextStyle: AppText.body(color: palette.foreground),
        actionTextColor: palette.accentText,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.panel,
        hintStyle: AppText.body(color: palette.faintForeground),
        labelStyle: AppText.bodySm(color: palette.mutedForeground),
        errorStyle: AppText.bodySm(color: palette.lose),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.lose, width: 2),
        ),
      ),

      // A focus ring the player can actually see — required for keyboard use
      // on the web build, and for switch-access users on mobile.
      focusColor: palette.accent.withValues(alpha: 0.24),
      splashColor: palette.accent.withValues(alpha: 0.12),
      highlightColor: palette.accent.withValues(alpha: 0.08),
    );
  }

  /// Deliberately only `bodyMedium`, and deliberately without a line height.
  ///
  /// `bodyMedium` is the inherited default for every bare [Text] in the app,
  /// so widening it widens hundreds of existing layouts at once. Giving it the
  /// ramp's `height: 1.5` grew each line by ~3.5px and overflowed the betting
  /// panel's standings pager by exactly 4px on a 360x640 screen — caught by
  /// `test/screen_overflow_test.dart`.
  ///
  /// The ramp in [AppText] is therefore opt-in: screens adopt `AppText.body()`
  /// and friends as they are reworked, when their layout is being re-measured
  /// anyway. Wiring the full [TextTheme] is Phase 4 work, not a token change
  /// that silently reflows screens nobody is looking at.
  static TextTheme _textTheme(AppPalette palette) {
    return TextTheme(
      bodyMedium: AppText.sora(15, color: palette.foreground),
    );
  }
}
