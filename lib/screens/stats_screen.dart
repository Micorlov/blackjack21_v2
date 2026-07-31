import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../widgets/panel_card.dart';

/// Stats screen: Recent / All time / Awards tabs plus a "last 10 hands"
/// history strip. Ported from `Blackjack 21 v2.dc.html` lines 490-543.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    final recentHistory = state.history.length > 10 ? state.history.sublist(state.history.length - 10) : state.history;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTitle('Stats'),
          Row(
            children: [
              _TabPill(label: 'Recent', active: state.statsTab == StatsTab.recent, onTap: notifier.setStatsRecent),
              const SizedBox(width: 8),
              _TabPill(label: 'All time', active: state.statsTab == StatsTab.alltime, onTap: notifier.setStatsAlltime),
              const SizedBox(width: 8),
              _TabPill(
                label: 'Awards',
                active: state.statsTab == StatsTab.achievements,
                onTap: notifier.setStatsAchievements,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.statsTab == StatsTab.achievements) _AchievementsList(state: state),
          if (state.statsTab == StatsTab.recent) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatTile(value: '${state.session.hands}', label: 'Hands this session'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(value: '${state.session.wins}', label: 'Wins this session'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StatTile(
              value: formatSignedChips(state.session.net),
              label: 'Net chips this session',
              valueColor: state.session.net >= 0 ? AppColors.win : AppColors.lose,
            ),
            const SizedBox(height: 20),
          ],
          if (state.statsTab == StatsTab.alltime) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatTile(value: '${state.stats.handsPlayed}', label: 'Hands played'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(value: _winRateDisplay(state.stats), label: 'Win rate'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatTile(value: '${state.stats.blackjacks}', label: 'Blackjacks'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(value: '${state.stats.currentStreak}', label: 'Current streak'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StatTile(value: '${state.stats.bestStreak}', label: 'Best streak'),
            const SizedBox(height: 20),
          ],
          const SectionLabel('Last 10 hands'),
          Container(
            decoration: panelDecoration(),
            padding: const EdgeInsets.all(16),
            child: recentHistory.isEmpty
                ? Text('Play a hand to see your streak here.', style: AppText.sora(15, color: AppColors.textMuted))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recentHistory
                        .map(
                          (r) => Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _historyDotColor(r)),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

String _winRateDisplay(StatsSummary stats) {
  if (stats.handsPlayed <= 0) return '0%';
  return '${(stats.wins / stats.handsPlayed * 100).round()}%';
}

Color _historyDotColor(RoundResult r) {
  switch (r) {
    case RoundResult.win:
      return AppColors.win;
    case RoundResult.loss:
      return AppColors.lose;
    case RoundResult.push:
      return AppColors.push;
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? AppColors.gold : AppColors.border),
              color: active ? AppColors.gold.withValues(alpha: 0.12) : Colors.transparent,
            ),
            child: Text(
              label,
              style: AppText.sora(15, weight: FontWeight.w700, color: active ? AppColors.gold : AppColors.textFaint),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatTile({required this.value, required this.label, this.valueColor = AppColors.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(radius: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppText.mono(30, weight: FontWeight.w700, color: valueColor),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.sora(14, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  final GameState state;

  const _AchievementsList({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final def in kAchievementDefs) ...[
          _AchievementRow(unlocked: def.check(state), name: def.name, desc: def.desc),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final bool unlocked;
  final String name;
  final String desc;

  const _AchievementRow({required this.unlocked, required this.name, required this.desc});

  @override
  Widget build(BuildContext context) {
    final ringColor = unlocked ? AppColors.gold : AppColors.border;
    final iconColor = unlocked ? AppColors.goldInk : AppColors.textFaint;
    final nameColor = unlocked ? AppColors.gold : AppColors.textFaint;

    return Container(
      decoration: panelDecoration(borderColor: ringColor, radius: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
            alignment: Alignment.center,
            child: Icon(Icons.check_rounded, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppText.sora(16, weight: FontWeight.w800, color: nameColor),
                ),
                Text(desc, style: AppText.sora(14, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
