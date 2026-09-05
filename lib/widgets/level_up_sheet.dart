import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/xp.dart';
import 'buttons.dart';
import 'confetti_burst.dart';

/// The moment a level lands.
///
/// Levels exist because a bankroll goes down as often as it goes up: a player
/// could play well for an hour, end the session $200 light, and have nothing
/// to show for it. Experience only accumulates, so time spent is never taken
/// away — and the level that experience buys is worth stopping for.
///
/// Shown over the felt when [GameState.levelUpTo] is set, listing whatever the
/// new level unlocked so the shop's cosmetics have somewhere to come from.
class LevelUpSheet extends ConsumerWidget {
  const LevelUpSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(gameProvider.select((s) => s.levelUpTo));
    if (level == null) return const SizedBox.shrink();
    final notifier = ref.read(gameProvider.notifier);
    final unlocks = unlocksAtLevel(level);

    return Positioned.fill(
      child: Stack(
        children: [
          ModalBarrier(color: AppColors.shellBlack.withValues(alpha: 0.82), onDismiss: notifier.clearLevelUp),
          const Positioned.fill(child: ConfettiBurst(origin: Alignment(0, -0.2))),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.gold),
                    borderRadius: AppRadius.xxlAll,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient),
                        alignment: Alignment.center,
                        child: Text('$level', style: AppText.serifItalic(34, color: AppColors.goldInk)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Level $level', style: AppText.serifItalic(30), textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        unlocks.isEmpty
                            ? 'Every hand you play counts toward the next one.'
                            : 'Unlocked: ${unlocks.join(', ')}',
                        textAlign: TextAlign.center,
                        style: AppText.bodySm(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GoldButton(label: 'Nice', onPressed: notifier.clearLevelUp),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
