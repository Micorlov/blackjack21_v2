import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/buttons.dart';

/// Playing-phase bottom panel: DOUBLE/SPLIT/SURRENDER row (each disabled per
/// table rules) plus STAND/HIT row. Disabled logic mirrors the source
/// design's UI-only `canDouble`/`canSplit`/`canSurrender` helpers.
///
/// Stateful only to hold the tap debounce — the notifier is untouched.
class TablePlayingPanel extends ConsumerStatefulWidget {
  const TablePlayingPanel({super.key});

  @override
  ConsumerState<TablePlayingPanel> createState() => _TablePlayingPanelState();
}

class _TablePlayingPanelState extends ConsumerState<TablePlayingPanel> {
  /// When the last action on this panel was accepted.
  ///
  /// HIT and STAND are never disabled and the notifier acts synchronously, so
  /// a fast double-tap used to draw two cards with no visual separation — the
  /// second card landing before the player had seen the first. One
  /// [AppMotion.base] window between actions is long enough to swallow the
  /// stray second tap of a double-tap and short enough that deliberate
  /// hit-hit-hit still feels immediate.
  ///
  /// Local to the widget on purpose: the round's rules are the notifier's
  /// business, and how fast a thumb can travel is not.
  DateTime? _lastActionAt;

  /// Wraps an action so it is ignored inside the debounce window. A null
  /// [action] (the rules forbid it) stays null, so the button still reads as
  /// disabled rather than as an enabled control that does nothing.
  VoidCallback? _debounced(VoidCallback? action) {
    if (action == null) return null;
    return () {
      final now = DateTime.now();
      final last = _lastActionAt;
      if (last != null && now.difference(last) < AppMotion.base) return;
      _lastActionAt = now;
      action();
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final palette = AppPalette.of(context);

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
              flex: 3,
              child: ActionPillButton(
                label: 'DOUBLE',
                borderColor: AppColors.gold.withValues(alpha: 0.32),
                backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                textColor: AppColors.gold,
                onPressed: _debounced(canDouble ? notifier.playerDouble : null),
                verticalPadding: 15,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: ActionPillButton(
                label: 'SPLIT',
                borderColor: AppColors.gold.withValues(alpha: 0.32),
                backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                textColor: AppColors.gold,
                onPressed: _debounced(canSplit ? notifier.playerSplit : null),
                verticalPadding: 15,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Surrender forfeits half the bet and cannot be undone, yet it used
            // to be the *widest* button in this row (`flex: 2` against 1 and 1)
            // and was painted in the same gold as the two constructive plays —
            // the most dangerous control on the table dressed as the most
            // inviting one. It now takes the smallest share of the row and a
            // destructive outline, so weight and colour both say "not this one
            // by accident".
            Expanded(
              flex: 2,
              child: ActionPillButton(
                label: 'SURRENDER',
                borderColor: palette.lose,
                backgroundColor: Colors.transparent,
                textColor: palette.loseOnFelt,
                onPressed: _debounced(canSurrender ? notifier.playerSurrender : null),
                verticalPadding: 15,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xxs),
        // Equal halves, deliberately. HIT used to be twice as wide as STAND
        // and the only gold button on the felt, so on a hard 19 — where
        // standing is the only sane play — the interface still pointed at the
        // card that busts. Neither action is right for every hand, so neither
        // gets the extra weight; colour alone keeps them apart.
        Row(
          children: [
            Expanded(
              child: ActionPillButton(
                label: 'STAND',
                borderColor: AppColors.win.withValues(alpha: 0.6),
                backgroundColor: AppColors.win.withValues(alpha: 0.2),
                textColor: AppColors.winLight,
                onPressed: _debounced(notifier.playerStand),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GoldButton(
                label: 'HIT',
                onPressed: _debounced(notifier.playerHit),
                verticalPadding: 20,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
