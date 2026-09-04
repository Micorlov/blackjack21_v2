import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Shared button primitives.
///
/// ## Why every button here carries [Semantics]
///
/// Before the 2026-09-03 accessibility pass the codebase contained not one
/// `Semantics` widget, and [ChipButton] was a bare `GestureDetector` — so a
/// screen reader announced the chip tray as five pieces of loose text with no
/// hint that any of it could be tapped. Buttons declare their role, their
/// enabled state, and *why* they are disabled.
///
/// ## Why disabled buttons explain themselves
///
/// Disabled state used to be `Opacity(0.35)` and nothing else: a dimmed
/// SURRENDER told a player neither that it was unavailable nor what would make
/// it available. `DEAL` was the one exception, and only because someone had
/// hand-written a "min $25" hint beside it. [GoldButton.disabledReason]
/// generalises that: it is announced to screen readers and shown on
/// long-press.

/// Primary gold-gradient CTA (DEAL, CLAIM, sign-in, etc.). Disabled when
/// [onPressed] is null.
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double verticalPadding;
  final double fontSize;

  /// Announced instead of [label] when the visible text is not a full
  /// description on its own.
  final String? semanticLabel;

  /// Why this is unavailable, e.g. "Bet at least \$25 to deal".
  final String? disabledReason;

  /// Shows a spinner and blocks taps while an awaited action is in flight.
  ///
  /// The app previously had no loading affordance anywhere — sign-in stayed
  /// bright and idle through the whole round trip, which reads as broken.
  final bool busy;

  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.verticalPadding = 17,
    this.fontSize = 18,
    this.semanticLabel,
    this.disabledReason,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;
    return _ButtonSemantics(
      label: semanticLabel ?? label,
      enabled: !disabled,
      busy: busy,
      disabledReason: disabledReason,
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: busy ? null : onPressed,
            child: Container(
              constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: AppRadius.lgAll,
                boxShadow: disabled
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.goldDark.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: busy
                  ? SizedBox(
                      height: fontSize,
                      width: fontSize,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.goldInk),
                      ),
                    )
                  : _FittedLabel(
                      label: label,
                      style: AppText.sora(
                        fontSize,
                        weight: FontWeight.w800,
                        color: AppColors.goldInk,
                        letterSpacing: 0.9,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary call to action: a gold-outlined pill with a transparent fill.
///
/// The app had four near-identical copies of this — two in the friends screen,
/// one in the shop, one in the lobby — each with its own padding and font size.
/// It also fills a real hierarchy gap: before it, a screen's only two choices
/// were "gold gradient" or "plain text", so every secondary action reached for
/// the gradient and no screen had a single obvious primary any more.
class OutlinePillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double verticalPadding;
  final double fontSize;
  final Color color;
  final String? semanticLabel;
  final String? disabledReason;
  final bool busy;

  const OutlinePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.verticalPadding = 15,
    this.fontSize = 16,
    this.color = AppColors.gold,
    this.semanticLabel,
    this.disabledReason,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionPillButton(
      label: label,
      borderColor: color.withValues(alpha: 0.45),
      backgroundColor: color.withValues(alpha: 0.1),
      textColor: color,
      onPressed: busy ? null : onPressed,
      verticalPadding: verticalPadding,
      fontSize: fontSize,
      semanticLabel: semanticLabel,
      disabledReason: disabledReason,
    );
  }
}

/// Outlined pill button used for CLEAR / DOUBLE / SPLIT / SURRENDER / STAND /
/// NO THANKS actions — caller supplies the semantic colors.
class ActionPillButton extends StatelessWidget {
  final String label;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final double verticalPadding;
  final double fontSize;
  final String? semanticLabel;
  final String? disabledReason;

  const ActionPillButton({
    super.key,
    required this.label,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.verticalPadding = 20,
    this.fontSize = 20,
    this.semanticLabel,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return _ButtonSemantics(
      label: semanticLabel ?? label,
      enabled: !disabled,
      disabledReason: disabledReason,
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: onPressed,
            child: Container(
              constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: AppRadius.lgAll,
              ),
              child: _FittedLabel(
                label: label,
                style: AppText.sora(
                  fontSize,
                  weight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A one-line button label that shrinks to fit its button instead of wrapping.
/// Side-by-side action buttons ("DOUBLE" next to "SURRENDER") get narrow on
/// small phones, and wrapping mid-word — "DOUBL / E" — is never the right
/// answer for a CTA.
class _FittedLabel extends StatelessWidget {
  final String label;
  final TextStyle style;

  const _FittedLabel({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: style, maxLines: 1, softWrap: false),
    );
  }
}

/// Round chip-denomination button used on the betting panel.
///
/// Rendered as a real casino chip — edge spots, an inner ring and a rim
/// highlight — rather than the flat bordered circle it used to be. The weight
/// is the point: a chip should look like an object you could pick up.
class ChipButton extends StatelessWidget {
  final int amount;
  final Color color;
  final bool disabled;
  final VoidCallback onPressed;

  /// Why this denomination is unavailable, e.g. "Not enough chips".
  final String? disabledReason;

  /// The painted diameter. Never rendered below [AppTouch.minTarget].
  final double size;

  const ChipButton({
    super.key,
    required this.amount,
    required this.color,
    required this.disabled,
    required this.onPressed,
    this.disabledReason,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    // The betting panel used to wrap the tray in `SizedBox(height: 46)` and a
    // scaling FittedBox, which shrank every chip to 46x46 on every device —
    // permanently under the 48dp minimum. Guarding here means the floor holds
    // no matter what a caller wraps this in.
    final diameter = math.max(size, AppTouch.minTarget);

    return _ButtonSemantics(
      label: '\$$amount chip',
      enabled: !disabled,
      disabledReason: disabledReason,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: disabled ? null : onPressed,
            child: Ink(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.24, -0.4),
                  colors: [Color(0xFF1E2A26), Color(0xFF0C1110)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _ChipEdgePainter(color: color),
                child: Center(
                  child: Text(
                    '\$$amount',
                    style: AppText.mono(
                      14,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the denomination ring, the evenly spaced edge spots and the rim
/// highlight that make a chip read as a moulded object rather than a circle.
class _ChipEdgePainter extends CustomPainter {
  final Color color;

  /// Six spots is what most real casino chips use; it also stays legible at
  /// 48dp, where eight would smear into a dashed line.
  static const int _spotCount = 6;

  const _ChipEdgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // The denomination band around the rim.
    canvas.drawCircle(
      centre,
      radius - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );

    // Edge spots, drawn as short thick arcs straddling the band.
    final spotPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.butt
      ..color = color;
    const sweep = math.pi / 14;
    for (var i = 0; i < _spotCount; i++) {
      final start = (2 * math.pi / _spotCount) * i - sweep / 2;
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius - 2.5),
        start,
        sweep,
        false,
        spotPaint,
      );
    }

    // Inner ring separating the face from the rim.
    canvas.drawCircle(
      centre,
      radius * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.55),
    );

    // A single top-left highlight for moulded plastic. One light source only —
    // stacking more shading on top of the radial gradient reads as mud.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius - 2),
      math.pi * 1.05,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(_ChipEdgePainter oldDelegate) => oldDelegate.color != color;
}

/// Text-only link-style button (e.g. "Play as Guest", "See all").
class TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double fontSize;
  final bool underline;
  final String? semanticLabel;

  const TextLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.gold,
    this.fontSize = 15,
    this.underline = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _ButtonSemantics(
      label: semanticLabel ?? label,
      enabled: onPressed != null,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 14,
          ),
          minimumSize: const Size(0, AppTouch.minTarget),
        ),
        child: Text(
          label,
          style: AppText.sora(
            fontSize,
            weight: FontWeight.w700,
            color: color,
            height: 1,
          ).copyWith(
            decoration: underline ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// An icon-only control with the accessible name it cannot show on screen, and
/// a hit area that meets the platform minimum even when the glyph is smaller.
///
/// The table header's back, chat and kebab buttons were 46x46 and unlabelled;
/// a screen reader announced three anonymous "button"s.
class AppIconButton extends StatelessWidget {
  final IconData icon;

  /// Required, not optional: an icon-only control with no name is unusable
  /// with a screen reader, and there is no sensible default to fall back to.
  final String label;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final String? disabledReason;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconSize = 22,
    this.color,
    this.backgroundColor,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    return _ButtonSemantics(
      label: label,
      enabled: onPressed != null,
      disabledReason: disabledReason,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            constraints: AppTouch.minTargetConstraints,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: iconSize,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a control in the semantics a button needs, and surfaces
/// [disabledReason] to both screen readers and long-press.
///
/// [excludeSemantics] is on because these buttons paint their own label as
/// text: without it a screen reader reads the name twice.
class _ButtonSemantics extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool busy;
  final String? disabledReason;
  final Widget child;

  const _ButtonSemantics({
    required this.label,
    required this.enabled,
    required this.child,
    this.busy = false,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final hint = !enabled ? disabledReason : null;
    final semantics = Semantics(
      button: true,
      enabled: enabled,
      label: busy ? '$label, working' : label,
      hint: hint,
      excludeSemantics: true,
      child: child,
    );
    if (hint == null) return semantics;
    return Tooltip(
      message: hint,
      waitDuration: AppMotion.celebratory,
      child: semantics,
    );
  }
}
