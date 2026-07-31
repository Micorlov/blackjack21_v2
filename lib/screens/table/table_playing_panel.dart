import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons.dart';

/// Playing-phase bottom panel: DOUBLE/SPLIT/SURRENDER row (each disabled per
/// table rules) plus STAND/HIT row. Disabled logic mirrors the source
/// design's UI-only `canDouble`/`canSplit`/`canSurrender` helpers.
class TablePlayingPanel extends ConsumerWidget {
  const TablePlayingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    final isPlaying = state.phase == RoundPhase.playing;
    final activeHand = state.hands[state.activeHandIndex];
    final canDouble = isPlaying && activeHand.cards.length == 2 && state.chips >= activeHand.bet;
    final canSplit =
        isPlaying &&
        state.hands.length == 1 &&
        activeHand.cards.length == 2 &&
        activeHand.cards[0].rank == activeHand.cards[1].rank &&
        state.chips >= activeHand.bet;
    final canSurrender = isPlaying && state.hands.length == 1 && activeHand.cards.length == 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ActionPillButton(
                label: 'DOUBLE',
                borderColor: AppColors.gold.withValues(alpha: 0.32),
                backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                textColor: AppColors.gold,
                onPressed: canDouble ? notifier.playerDouble : null,
                verticalPadding: 15,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionPillButton(
                label: 'SPLIT',
                borderColor: AppColors.gold.withValues(alpha: 0.32),
                backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                textColor: AppColors.gold,
                onPressed: canSplit ? notifier.playerSplit : null,
                verticalPadding: 15,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ActionPillButton(
                label: 'SURRENDER',
                borderColor: AppColors.gold.withValues(alpha: 0.32),
                backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                textColor: AppColors.gold,
                onPressed: canSurrender ? notifier.playerSurrender : null,
                verticalPadding: 15,
                fontSize: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ActionPillButton(
                label: 'STAND',
                borderColor: AppColors.win.withValues(alpha: 0.6),
                backgroundColor: AppColors.win.withValues(alpha: 0.2),
                textColor: AppColors.winLight,
                onPressed: notifier.playerStand,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: GoldButton(label: 'HIT', onPressed: notifier.playerHit, verticalPadding: 20, fontSize: 20),
            ),
          ],
        ),
      ],
    );
  }
}
