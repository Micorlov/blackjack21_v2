import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/buttons.dart';

/// Insurance-phase bottom panel: offer copy + NO THANKS / INSURE row.
class TableInsurancePanel extends ConsumerWidget {
  const TableInsurancePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: AppText.sora(17, color: AppColors.textPrimary.withValues(alpha: 0.85), height: 1.45),
            children: [
              const TextSpan(text: 'Dealer shows an Ace. Insure for '),
              TextSpan(
                text: '\$${formatChips(state.insuranceBet)}',
                style: AppText.mono(17, weight: FontWeight.w700, color: AppColors.gold),
              ),
              const TextSpan(text: '? Pays 2:1.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionPillButton(
                label: 'NO THANKS',
                borderColor: AppColors.lose.withValues(alpha: 0.6),
                backgroundColor: AppColors.lose.withValues(alpha: 0.2),
                textColor: AppColors.loseLight,
                onPressed: notifier.declineInsurance,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: GoldButton(label: 'INSURE', onPressed: notifier.takeInsurance, verticalPadding: 20, fontSize: 20),
            ),
          ],
        ),
      ],
    );
  }
}
