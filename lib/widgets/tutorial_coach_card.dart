import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/tutorial.dart';
import 'how_to_play_sheet.dart';

/// The first-run coach: one gold card above the action panel telling the
/// player what this phase of their first three hands is for.
///
/// Renders nothing at all once the tutorial is finished or skipped, so the
/// table goes back to its normal layout without any caller having to ask.
class TutorialCoachCard extends ConsumerWidget {
  const TutorialCoachCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tip = tutorialTipFor(ref.watch(gameProvider));
    if (tip == null) return const SizedBox.shrink();

    final notifier = ref.read(gameProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tip.stepLabel,
                  style: AppText.mono(10, weight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.gold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _CardLink(label: 'Full rules', onTap: () => showHowToPlaySheet(context)),
              const SizedBox(width: 12),
              _CardLink(label: 'Skip', onTap: notifier.skipTutorial, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 2),
          Text(tip.title, style: AppText.sora(15, weight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            tip.body,
            style: AppText.sora(13, color: const Color(0xFFD8D3C6), height: 1.42),
          ),
        ],
      ),
    );
  }
}

/// Small tap target for the card's two links. Deliberately not
/// [TextLinkButton]: that one carries 14px of vertical padding, which would
/// push the coach card into the felt's space on short phones.
class _CardLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _CardLink({required this.label, required this.onTap, this.color = AppColors.gold});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(label, style: AppText.sora(12, weight: FontWeight.w700, color: color)),
      ),
    );
  }
}
