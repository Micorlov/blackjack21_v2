import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons.dart';
import '../../widgets/panel_card.dart';
import 'async_action.dart';

/// A designed "nothing here yet" panel with a way out of the emptiness.
///
/// Several lists simply rendered an empty bordered box when they had no rows —
/// the friends list, the lobby's top-players preview — which reads as a
/// loading failure rather than an invitation. Every empty state in the app now
/// says what would fill it and offers the one action that does.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// Optional call to action. Awaited, so a network-backed action (the
  /// WhatsApp invite creates the group first) shows a pending label instead of
  /// looking inert.
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final action = onAction;

    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
      child: Column(
        children: [
          // Decorative: the title below already says what this panel is, and a
          // screen reader announcing "people icon" first adds nothing.
          ExcludeSemantics(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.12)),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.gold, size: 26),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, textAlign: TextAlign.center, style: AppText.title()),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center, style: AppText.bodySm()),
          if (label != null && action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: AsyncActionBuilder(
                action: action,
                builder: (context, busy, run) => GoldButton(
                  label: busy ? 'Opening…' : label,
                  onPressed: run,
                  verticalPadding: AppSpacing.lg,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
