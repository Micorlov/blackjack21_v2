import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colour roles, resolved per brightness.
///
/// [AppColors] holds raw values; this maps them to *roles* so a widget asks for
/// "the colour text sits in on a panel" rather than naming a specific green.
/// That indirection is what makes a light theme possible at all.
///
/// Read it with `AppPalette.of(context)`.
///
/// ## Why some roles come in pairs
///
/// The felt is much lighter than the app's panels, so one colour cannot serve
/// both. Measured against felt `#175943`, the shipped loss red `#C1503F` scores
/// **1.76:1** — it fails even the 3:1 non-text threshold, and a player reading
/// their losses on the table is reading the worst contrast in the app. The
/// `...OnFelt` variants are the accessible pairings for the table; the base
/// colours remain for fills, where white or ink text sits on top of them.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.shell,
    required this.card,
    required this.panel,
    required this.navSurface,
    required this.foreground,
    required this.mutedForeground,
    required this.faintForeground,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.win,
    required this.lose,
    required this.push,
    required this.winOnFelt,
    required this.loseOnFelt,
    required this.pushOnFelt,
  });

  final Brightness brightness;

  /// App ground.
  final Color background;

  /// Deepest surface — behind the ground, e.g. the nav bar scrim.
  final Color shell;

  /// Raised surfaces: dialogs, sheets, cards.
  final Color card;

  /// Recessed grouping surfaces inside a screen.
  final Color panel;

  /// The bottom navigation surface.
  final Color navSurface;

  /// Primary text.
  final Color foreground;

  /// Secondary text — still must clear 4.5:1.
  final Color mutedForeground;

  /// Tertiary text: timestamps, inactive nav labels.
  final Color faintForeground;

  /// Decorative hairlines only. Not for control boundaries — it is
  /// deliberately below 3:1 and carries no meaning.
  final Color border;

  /// Control boundaries and dividers that convey structure. Clears 3:1.
  final Color borderStrong;

  /// Gold — the brand accent, used as a fill.
  final Color accent;

  /// Text/icons drawn on top of [accent].
  final Color onAccent;

  /// Gold used *as text* on the app ground. In light mode this is much darker
  /// than [accent], because the brand gold on paper is only 3.25:1.
  final Color accentText;

  /// Outcome colours as fills.
  final Color win;
  final Color lose;
  final Color push;

  /// Outcome colours as text/icons on the felt.
  final Color winOnFelt;
  final Color loseOnFelt;
  final Color pushOnFelt;

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? dark;
  }

  /// The primary theme — a lamp-lit casino floor.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: AppColors.surface,
    shell: AppColors.shellBlack,
    card: AppColors.panel,
    panel: AppColors.panel,
    navSurface: AppColors.navSurface,
    foreground: AppColors.textPrimary,
    mutedForeground: AppColors.textMuted,
    faintForeground: AppColors.textFaint,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    accent: AppColors.gold,
    onAccent: AppColors.goldInk,
    accentText: AppColors.gold,
    win: AppColors.win,
    lose: AppColors.lose,
    push: AppColors.push,
    winOnFelt: AppColors.winLight,
    loseOnFelt: AppColors.loseLight,
    pushOnFelt: AppColors.pushOnFelt,
  );

  /// Warm paper, not clinical white — the gold identity needs a warm ground.
  /// The felt itself stays dark in both themes: a card table is green baize,
  /// not paper, so light mode changes the menus around it, not the table.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    shell: AppColors.lightPanel,
    card: AppColors.lightCard,
    panel: AppColors.lightPanel,
    navSurface: AppColors.lightCard,
    foreground: AppColors.lightForeground,
    mutedForeground: AppColors.lightMuted,
    faintForeground: AppColors.lightFaint,
    border: AppColors.lightBorder,
    borderStrong: AppColors.lightBorderStrong,
    accent: AppColors.gold,
    onAccent: AppColors.goldInk,
    accentText: AppColors.lightAccentText,
    win: AppColors.lightWin,
    lose: AppColors.lightLose,
    push: AppColors.lightFaint,
    winOnFelt: AppColors.winLight,
    loseOnFelt: AppColors.loseLight,
    pushOnFelt: AppColors.pushOnFelt,
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? shell,
    Color? card,
    Color? panel,
    Color? navSurface,
    Color? foreground,
    Color? mutedForeground,
    Color? faintForeground,
    Color? border,
    Color? borderStrong,
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? win,
    Color? lose,
    Color? push,
    Color? winOnFelt,
    Color? loseOnFelt,
    Color? pushOnFelt,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      shell: shell ?? this.shell,
      card: card ?? this.card,
      panel: panel ?? this.panel,
      navSurface: navSurface ?? this.navSurface,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      faintForeground: faintForeground ?? this.faintForeground,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentText: accentText ?? this.accentText,
      win: win ?? this.win,
      lose: lose ?? this.lose,
      push: push ?? this.push,
      winOnFelt: winOnFelt ?? this.winOnFelt,
      loseOnFelt: loseOnFelt ?? this.loseOnFelt,
      pushOnFelt: pushOnFelt ?? this.pushOnFelt,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      shell: mix(shell, other.shell),
      card: mix(card, other.card),
      panel: mix(panel, other.panel),
      navSurface: mix(navSurface, other.navSurface),
      foreground: mix(foreground, other.foreground),
      mutedForeground: mix(mutedForeground, other.mutedForeground),
      faintForeground: mix(faintForeground, other.faintForeground),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentText: mix(accentText, other.accentText),
      win: mix(win, other.win),
      lose: mix(lose, other.lose),
      push: mix(push, other.push),
      winOnFelt: mix(winOnFelt, other.winOnFelt),
      loseOnFelt: mix(loseOnFelt, other.loseOnFelt),
      pushOnFelt: mix(pushOnFelt, other.pushOnFelt),
    );
  }
}
