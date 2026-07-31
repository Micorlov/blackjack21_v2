import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons.dart';

const List<int> _kChipDenoms = [25, 50, 100, 500, 1000];

/// Betting-phase bottom panel: current bet readout, the 5 denomination
/// chips, CLEAR/DEAL row, and (when broke) a complimentary-chips button.
class TableBettingPanel extends ConsumerWidget {
  const TableBettingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final dealDisabled = !(state.bet > 0 && state.bet <= state.chips);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Bet ',
                style: AppText.mono(13, letterSpacing: 1.4, color: AppColors.textPrimary.withValues(alpha: 0.82)),
              ),
              TextSpan(
                text: '\$${state.bet}',
                style: AppText.mono(26, weight: FontWeight.w700, color: AppColors.gold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Five 60px chips plus gaps need 336px; a 360px phone leaves 332px of
        // content width, so the tray shrinks as a unit and stays centered.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _kChipDenoms.length; i++) ...[
                if (i > 0) const SizedBox(width: 9),
                ChipButton(
                  amount: _kChipDenoms[i],
                  color: AppColors.chipColors[_kChipDenoms[i]]!,
                  disabled: (state.bet + _kChipDenoms[i]) > state.chips,
                  onPressed: () => notifier.placeBet(_kChipDenoms[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionPillButton(
                label: 'CLEAR',
                borderColor: AppColors.lose.withValues(alpha: 0.6),
                backgroundColor: AppColors.lose.withValues(alpha: 0.2),
                textColor: AppColors.loseLight,
                onPressed: notifier.clearBet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: GoldButton(
                label: 'DEAL',
                onPressed: dealDisabled ? null : notifier.dealRound,
                verticalPadding: 20,
                fontSize: 20,
              ),
            ),
          ],
        ),
        if (state.chips == 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ActionPillButton(
              label: 'Get 1,000 complimentary chips',
              borderColor: AppColors.gold.withValues(alpha: 0.32),
              backgroundColor: AppColors.gold.withValues(alpha: 0.08),
              textColor: AppColors.gold,
              onPressed: notifier.resetBankroll,
              verticalPadding: 15,
              fontSize: 17,
            ),
          ),
        ],
      ],
    );
  }
}
