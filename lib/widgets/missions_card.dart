import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../utils/missions.dart';
import '../utils/points.dart';
import 'buttons.dart';
import 'panel_card.dart';

/// Today's three missions.
///
/// The daily bonus rewards opening the app; nothing rewarded playing once you
/// were inside it. Someone with no friends online and no bonus ready had no
/// particular reason to sit down for a third hand. These give a session a
/// shape — three small goals, all reachable in one sitting, redrawn at
/// midnight, with nothing taken away for missing a day.
class MissionsCard extends ConsumerWidget {
  const MissionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final missions = missionsForDay(dayKeyOf(DateTime.now()));
    final done = missions.where((m) => state.missionsClaimed.contains(m.id)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: panelDecoration(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(child: Text('TODAY', style: AppText.sectionLabel(color: AppColors.gold))),
                const SizedBox(width: AppSpacing.sm),
                const Spacer(),
                Text(
                  '$done/${missions.length}',
                  style: AppText.mono(13, weight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < missions.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _MissionRow(
                mission: missions[i],
                progress: state.missionProgress[missions[i].id] ?? 0,
                claimed: state.missionsClaimed.contains(missions[i].id),
                onClaim: () => notifier.claimMission(missions[i].id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final MissionDef mission;
  final int progress;
  final bool claimed;
  final VoidCallback onClaim;

  const _MissionRow({
    required this.mission,
    required this.progress,
    required this.claimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (progress / mission.target).clamp(0.0, 1.0);
    final ready = !claimed && progress >= mission.target;

    return Semantics(
      label: claimed
          ? '${mission.label}. Claimed.'
          : '${mission.label}. $progress of ${mission.target}. '
                'Reward ${formatChips(mission.reward)} chips.',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mission.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sora(
                          15,
                          weight: FontWeight.w700,
                          color: claimed ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$progress/${mission.target}',
                      style: AppText.mono(12, color: AppColors.textFaint),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                // A bar rather than a bare count: "12 of 100 hands" is a
                // number to work out, a bar is a glance.
                ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(claimed ? AppColors.win : AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (claimed)
            const Icon(Icons.check_circle, color: AppColors.win, size: 22)
          else if (ready)
            OutlinePillButton(
              label: '+${formatChips(mission.reward)}',
              onPressed: onClaim,
              verticalPadding: 8,
              fontSize: 13,
            )
          else
            Text(
              '+${formatChips(mission.reward)}',
              style: AppText.mono(13, weight: FontWeight.w700, color: AppColors.textFaint),
            ),
        ],
      ),
    );
  }
}
