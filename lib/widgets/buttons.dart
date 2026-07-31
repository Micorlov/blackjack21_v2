import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Primary gold-gradient CTA (DEAL, CLAIM, sign-in, etc.). Disabled when
/// [onPressed] is null.
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double verticalPadding;
  final double fontSize;

  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.verticalPadding = 17,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(16),
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
            child: _FittedLabel(
              label: label,
              style: AppText.sora(fontSize, weight: FontWeight.w800, color: AppColors.goldInk, letterSpacing: 0.9),
            ),
          ),
        ),
      ),
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

  const ActionPillButton({
    super.key,
    required this.label,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.verticalPadding = 20,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _FittedLabel(
              label: label,
              style: AppText.sora(fontSize, weight: FontWeight.w800, color: textColor, letterSpacing: 0.9),
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
class ChipButton extends StatelessWidget {
  final int amount;
  final Color color;
  final bool disabled;
  final VoidCallback onPressed;

  const ChipButton({
    super.key,
    required this.amount,
    required this.color,
    required this.disabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.24, -0.4),
              colors: [Color(0xFF1E2A26), Color(0xFF0C1110)],
            ),
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 5)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '\$$amount',
            style: AppText.mono(14, weight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Text-only link-style button (e.g. "Play as Guest", "See all").
class TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double fontSize;
  final bool underline;

  const TextLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.gold,
    this.fontSize = 15,
    this.underline = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14)),
      child: Text(
        label,
        style: AppText.sora(
          fontSize,
          weight: FontWeight.w700,
          color: color,
          height: 1,
        ).copyWith(decoration: underline ? TextDecoration.underline : TextDecoration.none),
      ),
    );
  }
}
