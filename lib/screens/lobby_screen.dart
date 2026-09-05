import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/game_state.dart';
import '../models/social_models.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/daily_bonus.dart';
import '../utils/formatters.dart';
import '../utils/table_presence.dart';
import '../utils/table_recommendation.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/buttons.dart';
import '../widgets/count_up_text.dart';
import '../widgets/daily_bonus_dialog.dart';
import '../widgets/panel_card.dart';
import 'shared/avatar_initial.dart';

/// Home screen: who you are and what you have, today's bonus, and the three
/// tables. That is the whole list.
///
/// It used to stack seven things — a rank ticker, an XP level, the bonus,
/// three missions, a tournament promo, the tables and a leaderboard preview —
/// and the game itself was the one item without a button. Everything that was
/// not "sit down and play" is gone; the friends race lives on its own tab.
class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(state: state),
          const SizedBox(height: 24),
          _DailyBonusCard(state: state, notifier: notifier),
          const SizedBox(height: 24),
          const SectionLabel('Tables'),
          for (final t in kTables)
            _TableCard(
              table: t,
              notifier: notifier,
              // Bots never carry a `tableKey`, so this is real friends only.
              here: friendsAtTable(state.friendsAreLive ? state.friends : const [], t.key),
              recommended: t.key == recommendedTable(state.chips).key,
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final GameState state;

  const _HeaderRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(
          // The name is spoken by the row beside it; the avatar would only
          // repeat its first letter.
          child: AvatarCircle(
            initial: avatarInitialOf(state.displayName, fallback: '?'),
            color: state.avatarColor,
            size: 40,
            photoUrl: state.photoUrl,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            state.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sora(18, weight: FontWeight.w700),
          ),
        ),
        Semantics(
          // "● 1,150" is a chip glyph and a bare number to a screen reader.
          label: 'Balance: ${formatChips(state.chips)} chips',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('●', style: AppText.mono(13, color: AppColors.gold, height: 1)),
              const SizedBox(width: 7),
              CountUpText(
                value: state.chips,
                style: AppText.mono(18, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyBonusCard extends StatefulWidget {
  final GameState state;
  final GameNotifier notifier;

  const _DailyBonusCard({required this.state, required this.notifier});

  @override
  State<_DailyBonusCard> createState() => _DailyBonusCardState();
}

class _DailyBonusCardState extends State<_DailyBonusCard> {
  /// Ticks the countdown label and flips the card back to "Claim" the moment
  /// the 24-hour cooldown runs out, without any state change elsewhere.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastClaim = widget.state.lastDailyBonusClaimAt;
    final ready = isDailyBonusReady(lastClaim, now);
    final claimDay = nextDailyBonusStreakDay(widget.state.dailyBonusStreakDay, lastClaim, now);
    final reward = dailyBonusRewardForDay(claimDay);
    final streakDay = widget.state.dailyBonusStreakDay;

    final String sub;
    if (ready) {
      sub = streakDay > 0 ? 'Day $claimDay of your streak' : '+${formatChips(reward)} chips, every day';
    } else {
      sub = 'Next in ${dailyBonusCountdownLabel(lastClaim!, now)}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: panelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Daily bonus', style: AppText.sora(16, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub, style: AppText.sora(13, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (ready)
            GoldButton(
              label: '+${formatChips(reward)}',
              semanticLabel: 'Claim ${formatChips(reward)} chips',
              onPressed: () => showDailyBonusDialog(context),
              verticalPadding: 12,
              horizontalPadding: 18,
              fontSize: 15,
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, color: AppColors.win, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Claimed',
                  style: AppText.sora(14, weight: FontWeight.w600, color: AppColors.win),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableStake table;
  final GameNotifier notifier;

  /// Real friends currently seated at this table — always empty for the
  /// practice-bot roster (see [friendsAtTable]).
  final List<Friend> here;

  /// The highest table this bankroll can actually sit at. It carries the
  /// screen's one gold call to action, because playing a hand is what the
  /// screen is for.
  final bool recommended;

  const _TableCard({required this.table, required this.notifier, required this.here, this.recommended = false});

  @override
  Widget build(BuildContext context) {
    final label = tablePresenceLabel(here);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => notifier.enterTable(table),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              border: Border.all(color: recommended ? AppColors.borderStrong : AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: table.tint),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(table.name, style: AppText.sora(16, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        label.isEmpty ? '\$${table.min} – \$${table.max}' : '\$${table.min} – \$${table.max} · $label',
                        style: AppText.sora(13, color: label.isEmpty ? AppColors.textMuted : AppColors.gold),
                      ),
                    ],
                  ),
                ),
                if (here.isNotEmpty) ...[
                  SizedBox(
                    width: 20.0 * (here.length > 3 ? 3 : here.length) + 8,
                    height: 28,
                    child: Stack(
                      children: [
                        for (var i = 0; i < (here.length > 3 ? 3 : here.length); i++)
                          Positioned(
                            left: i * 16.0,
                            child: AvatarCircle(
                              initial: here[i].initial,
                              color: AppColors.gold.withValues(alpha: AppAlpha.tint),
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (recommended)
                  GoldButton(
                    label: 'Play',
                    semanticLabel: 'Play at the ${table.name}',
                    onPressed: () => notifier.enterTable(table),
                    verticalPadding: 10,
                    horizontalPadding: 20,
                    fontSize: 14,
                  )
                else
                  const Icon(Icons.chevron_right, color: AppColors.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
