import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/daily_bonus.dart';
import 'buttons.dart';
import 'chip_disc.dart';
import 'count_up_text.dart';

/// The daily-bonus claim overlay ("proposed · new screen" 15 in the design
/// doc): gold coin, today's reward, the D1..D7 streak ladder, and a single
/// claim button. Claiming happens inside the dialog; "Later" just closes it
/// and the lobby card keeps offering the claim.
Future<void> showDailyBonusDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99040806),
    builder: (_) => const _DailyBonusDialog(),
  );
}

class _DailyBonusDialog extends ConsumerWidget {
  const _DailyBonusDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final now = DateTime.now();
    final ready = isDailyBonusReady(state.lastDailyBonusClaimAt, now);
    final day = nextDailyBonusStreakDay(state.dailyBonusStreakDay, state.lastDailyBonusClaimAt, now);
    final reward = dailyBonusRewardForDay(day);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 70, offset: const Offset(0, 30))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A chip, not a flat gold disc with an oval punched out of it. The
            // reward is chips, and the app now has a chip it can draw.
            const ChipDisc(color: AppColors.gold, size: 78),
            const SizedBox(height: 14),
            Text('Daily bonus', style: AppText.serifItalic(32)),
            const SizedBox(height: 4),
            CountUpText(
              value: reward,
              signed: true,
              haptic: true,
              style: AppText.mono(40, weight: FontWeight.w700, color: AppColors.gold, height: 1.1),
            ),
            Text(
              day > 1 ? 'Day $day of your streak — keep it going' : 'Come back tomorrow to start a streak',
              style: AppText.sora(15, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var d = 1; d <= kDailyBonusStreakDays; d++) ...[
                  if (d > 1) const SizedBox(width: 6),
                  Expanded(child: _DayCell(day: d, claimDay: day)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Day 7 pays ', style: AppText.sora(13, color: AppColors.textFaint)),
                  TextSpan(
                    text: '+$kDailyBonusDay7Chips',
                    style: AppText.sora(13, weight: FontWeight.w700, color: AppColors.gold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GoldButton(
              label: 'Claim $reward chips',
              onPressed: ready
                  ? () {
                      notifier.claimDailyBonus();
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
            const SizedBox(height: 4),
            TextLinkButton(
              label: 'Later',
              onPressed: () => Navigator.of(context).pop(),
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// One D1..D7 cell: days already banked this streak get a gold check, the
/// day about to be claimed is highlighted, later days sit dim.
class _DayCell extends StatelessWidget {
  final int day;
  final int claimDay;

  const _DayCell({required this.day, required this.claimDay});

  @override
  Widget build(BuildContext context) {
    final banked = day < claimDay;
    final current = day == claimDay;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: current ? AppColors.gold.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: current
              ? AppColors.gold
              : banked
              ? AppColors.gold.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text('D$day', style: AppText.mono(12, color: AppColors.textFaint)),
          const SizedBox(height: 4),
          banked
              ? Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, size: 10, color: AppColors.goldInk),
                )
              : Container(
                  width: 13,
                  height: 10,
                  decoration: BoxDecoration(
                    color: current ? AppColors.gold : AppColors.border,
                    borderRadius: const BorderRadius.all(Radius.elliptical(6.5, 5)),
                  ),
                ),
        ],
      ),
    );
  }
}
