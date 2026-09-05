import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../widgets/panel_card.dart';
import 'shared/tab_pill.dart';

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
          TabPillRow(
            items: [
              TabPillItem(label: 'Recent', active: state.statsTab == StatsTab.recent, onTap: notifier.setStatsRecent),
              TabPillItem(
                label: 'All time',
                active: state.statsTab == StatsTab.alltime,
                onTap: notifier.setStatsAlltime,
              ),
              TabPillItem(
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
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (var i = 0; i < recentHistory.length; i++)
                            _HistoryDot(result: recentHistory[i], handNumber: i + 1),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _HistoryLegend(),
                    ],
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

/// How one result is drawn: colour *and* a glyph.
///
/// The strip used to encode win/loss/push in hue alone, which is invisible to
/// a red-green colour-blind player — roughly one man in twelve — and says
/// nothing at all to a screen reader. The glyph carries the meaning; the colour
/// only reinforces it.
({Color color, IconData icon, Color ink, String label}) _historyStyle(RoundResult r) {
  switch (r) {
    case RoundResult.win:
      return (color: AppColors.win, icon: Icons.check_rounded, ink: AppColors.goldInk, label: 'Win');
    case RoundResult.loss:
      return (color: AppColors.lose, icon: Icons.close_rounded, ink: AppColors.textPrimary, label: 'Loss');
    case RoundResult.push:
      return (color: AppColors.push, icon: Icons.remove_rounded, ink: AppColors.goldInk, label: 'Push');
  }
}

class _HistoryDot extends StatelessWidget {
  final RoundResult result;
  final int handNumber;

  const _HistoryDot({required this.result, required this.handNumber});

  @override
  Widget build(BuildContext context) {
    final style = _historyStyle(result);
    return Semantics(
      label: 'Hand $handNumber: ${style.label.toLowerCase()}',
      excludeSemantics: true,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(shape: BoxShape.circle, color: style.color),
        alignment: Alignment.center,
        child: Icon(style.icon, size: 15, color: style.ink),
      ),
    );
  }
}

/// Names the three marks once, so the strip above needs no interpretation.
class _HistoryLegend extends StatelessWidget {
  const _HistoryLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (final result in RoundResult.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _historyStyle(result).color),
                  alignment: Alignment.center,
                  child: Icon(_historyStyle(result).icon, size: 11, color: _historyStyle(result).ink),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(_historyStyle(result).label, style: AppText.caption()),
            ],
          ),
      ],
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
          _AchievementRow(
            unlocked: state.unlockedAchievements.contains(def.id) || def.check(state),
            name: def.name,
            desc: def.desc,
            reward: def.reward,
            progress: def.progress?.call(state),
          ),
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

  /// One-time chips this pays. Shown so the list reads as something to earn
  /// rather than a set of badges.
  final int reward;

  /// Where the player currently stands, when the achievement counts toward
  /// something. "Play 100 hands" told nobody they were on 12.
  final (int, int)? progress;

  const _AchievementRow({
    required this.unlocked,
    required this.name,
    required this.desc,
    required this.reward,
    this.progress,
  });

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sora(16, weight: FontWeight.w800, color: nameColor),
                ),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sora(14, color: AppColors.textMuted),
                ),
                if (!unlocked && progress != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.smAll,
                          child: LinearProgressIndicator(
                            value: progress!.$2 == 0 ? 0 : (progress!.$1 / progress!.$2).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatChips(progress!.$1)}/${formatChips(progress!.$2)}',
                        style: AppText.mono(12, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            unlocked ? 'PAID' : '+${formatChips(reward)}',
            style: AppText.mono(
              12,
              weight: FontWeight.w700,
              color: unlocked ? AppColors.win : AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
