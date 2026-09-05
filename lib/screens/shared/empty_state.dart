import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons.dart';
import '../../widgets/panel_card.dart';
import 'async_action.dart';

/// Weight an [EmptyState]'s call to action carries.
enum EmptyStateAction {
  /// Gold gradient. For the one empty state that *is* the screen's main job.
  primary,

  /// Underlined text link. For everywhere else.
  link,
}

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

  /// How much weight the action carries.
  ///
  /// Empty states are, by definition, not what the player came to the screen
  /// to do — and there was one on the lobby, one on the shop and one on the
  /// friends screen, each firing a full gold gradient button. Three of them
  /// competing with the screen's real primary is why the lobby had no obvious
  /// place to tap. [EmptyStateAction.link] keeps the way out without the
  /// shouting.
  final EmptyStateAction actionStyle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionStyle = EmptyStateAction.primary,
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: AppAlpha.subtle)),
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
                builder: (context, busy, run) => switch (actionStyle) {
                  EmptyStateAction.primary => GoldButton(
                    label: busy ? 'Opening…' : label,
                    onPressed: run,
                    verticalPadding: AppSpacing.lg,
                    fontSize: 16,
                  ),
                  EmptyStateAction.link => TextLinkButton(
                    label: busy ? 'Opening…' : label,
                    onPressed: run,
                    underline: true,
                  ),
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
