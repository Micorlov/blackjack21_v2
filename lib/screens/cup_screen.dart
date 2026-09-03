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
import '../utils/cup.dart';
import '../utils/formatters.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/buttons.dart';
import '../widgets/panel_card.dart';
import 'shared/avatar_initial.dart';
import 'shared/empty_state.dart';

/// The Weekend Cup tournament screen ("proposed · new screen" 12 in the
/// design doc): prize pool with a live countdown to the end of the week,
/// the player's standing in their group's points race, the prize table,
/// the top of the table, and a single gold call to action.
///
/// The race itself is the existing daily-points leaderboard — the Cup gives
/// the group's week a finish line, it does not invent a separate score.
class CupScreen extends ConsumerStatefulWidget {
  const CupScreen({super.key});

  @override
  ConsumerState<CupScreen> createState() => _CupScreenState();
}

class _CupScreenState extends ConsumerState<CupScreen> {
  /// Re-renders the countdown boxes; 30s keeps the minutes box honest
  /// without a per-second rebuild.
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
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final now = DateTime.now();
    final countdown = cupCountdown(now);
    final standings = _cupStandings(state);
    final heroRank = standings.indexWhere((r) => r.isSelf) + 1;

    return SingleChildScrollView(
      // This screen hides the bottom nav, so nothing else keeps its last row
      // clear of the edge-to-edge system navigation bar. Growing the scroll
      // padding — instead of insetting the viewport — lets the list scroll
      // fully past the system bar rather than ending underneath it.
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _BackCircle(onTap: notifier.goLobby),
              const SizedBox(width: 10),
              // A 32pt serif title plus the back circle is wider than a small
              // phone at a large font scale; the title shrinks to fit instead
              // of running past the edge.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Weekend Cup', style: AppText.serifItalic(32)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PrizePoolCard(state: state, countdown: countdown),
          const SectionLabel('Your standing', margin: EdgeInsets.fromLTRB(2, 18, 2, 10)),
          _StandingCard(state: state, rank: heroRank, total: standings.length),
          const SectionLabel('Prizes', margin: EdgeInsets.fromLTRB(2, 18, 2, 10)),
          _PrizesCard(),
          const SectionLabel('Top of the table', margin: EdgeInsets.fromLTRB(2, 18, 2, 10)),
          // A one-name table is not a race. Rather than pad it with practice
          // bots, the card says what would make it one.
          if (standings.length > 1)
            _TopTableCard(rows: standings.take(3).toList())
          else
            EmptyState(
              icon: Icons.groups_outlined,
              title: 'Nobody to race yet',
              message:
                  'The Cup runs inside your friends group. Invite someone and the table fills '
                  'with their week.',
              actionLabel: 'Invite via WhatsApp',
              onAction: notifier.shareInviteWhatsApp,
            ),
          const SizedBox(height: 18),
          state.tournamentJoined
              ? GoldButton(label: 'Play a Cup hand', onPressed: () => notifier.enterTable(kTables.first))
              : GoldButton(label: 'Join the Cup', onPressed: notifier.joinTournament),
        ],
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  final VoidCallback onTap;

  const _BackCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Was a 46px `GestureDetector` around a bare chevron: under the 48dp
    // minimum, with no button role and no name at all in the semantics tree.
    return Semantics(
      button: true,
      label: 'Back to lobby',
      child: Material(
        color: Colors.black.withValues(alpha: 0.32),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: AppTouch.minTarget,
            height: AppTouch.minTarget,
            child: Icon(Icons.chevron_left, size: 28, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _CupRow {
  final String name;
  final int points;
  final bool isSelf;

  const _CupRow({required this.name, required this.points, required this.isSelf});
}

/// Daily-points standings for the Cup: the hero plus every friend, best
/// first. Ties keep the hero above a friend with the same score so "your
/// standing" never understates a level race.
///
/// Only real group members are rivals. When the group is empty `state.friends`
/// still holds the seeded practice bots, and counting them told a solo player
/// they were "#3 of 5" in a tournament nobody else had entered.
List<_CupRow> _cupStandings(GameState state) {
  final friends = state.friendsAreLive ? state.friends : const <Friend>[];
  final rows = [
    _CupRow(name: 'You', points: state.heroDailyPoints, isSelf: true),
    for (final f in friends) _CupRow(name: f.name, points: f.dailyScore, isSelf: false),
  ];
  rows.sort((a, b) {
    final byPoints = b.points.compareTo(a.points);
    if (byPoints != 0) return byPoints;
    return a.isSelf ? -1 : (b.isSelf ? 1 : 0);
  });
  return rows;
}

class _PrizePoolCard extends StatelessWidget {
  final GameState state;
  final ({int days, int hours, int minutes}) countdown;

  const _PrizePoolCard({required this.state, required this.countdown});

  @override
  Widget build(BuildContext context) {
    final players = state.friendsAreLive ? state.friends.length + 1 : 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: AppColors.feltCardGradient,
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text('PRIZE POOL', style: AppText.mono(13, letterSpacing: 1.6, color: AppColors.gold)),
          const SizedBox(height: 6),
          Text(formatChips(kCupPrizePool), style: AppText.mono(46, weight: FontWeight.w700, height: 1)),
          const SizedBox(height: 6),
          Text(
            players > 1 ? 'chips · $players players in your group' : 'chips · invite friends to race for it',
            style: AppText.sora(15, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountBox(value: countdown.days, unit: 'days'),
              const SizedBox(width: 8),
              _CountBox(value: countdown.hours, unit: 'hours'),
              const SizedBox(width: 8),
              _CountBox(value: countdown.minutes, unit: 'min'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBox extends StatelessWidget {
  final int value;
  final String unit;

  const _CountBox({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppText.mono(22, weight: FontWeight.w700, color: AppColors.gold, height: 1.1),
          ),
          // 12px is the app's floor; this label was 11 and unscalable-small.
          Text(unit, style: AppText.caption()),
        ],
      ),
    );
  }
}

class _StandingCard extends StatelessWidget {
  final GameState state;
  final int rank;
  final int total;

  const _StandingCard({required this.state, required this.rank, required this.total});

  @override
  Widget build(BuildContext context) {
    final points = state.heroDailyPoints;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(),
      child: Row(
        children: [
          ExcludeSemantics(
            child: AvatarCircle(
              initial: avatarInitialOf(state.displayName, fallback: '?'),
              color: AppColors.gold,
              size: 44,
              goldRing: state.avatarFrameGold,
              photoUrl: state.photoUrl,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#$rank of $total', style: AppText.sora(17, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    "${points >= 0 ? '+' : '−'}\$${formatChips(points.abs())} in today's race",
                    style: AppText.sora(14, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // The crown and triangle were typographic glyphs a screen reader
          // reads as punctuation or skips entirely; a real icon carries a
          // label with it.
          Semantics(
            label: rank == 1 ? 'Leading' : 'Chasing',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rank == 1 ? Icons.emoji_events : Icons.trending_up,
                  size: 16,
                  color: rank == 1 ? AppColors.gold : AppColors.winLight,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  rank == 1 ? 'leading' : 'chasing',
                  style: AppText.sora(
                    14,
                    weight: FontWeight.w700,
                    color: rank == 1 ? AppColors.gold : AppColors.winLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: panelDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < kCupPrizes.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: i < kCupPrizes.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    kCupPrizes[i].$1,
                    style: AppText.sora(
                      16,
                      weight: FontWeight.w600,
                      color: i == 0 ? AppColors.gold : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    formatChips(kCupPrizes[i].$2),
                    style: AppText.mono(
                      16,
                      weight: FontWeight.w700,
                      color: i == 0 ? AppColors.gold : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TopTableCard extends StatelessWidget {
  final List<_CupRow> rows;

  const _TopTableCard({required this.rows});

  static const List<Color> _medals = [AppColors.gold, Color(0xFFC7CCC9), Color(0xFFC98A4B)];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: panelDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _medals[i % _medals.length]),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: AppText.sora(13, weight: FontWeight.w800, color: AppColors.goldInk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].name,
                      style: AppText.sora(
                        16,
                        weight: FontWeight.w700,
                        color: rows[i].isSelf ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${rows[i].points >= 0 ? '+' : '−'}\$${formatChips(rows[i].points.abs())}',
                    style: AppText.mono(
                      16,
                      weight: FontWeight.w800,
                      color: rows[i].points >= 0 ? AppColors.winLight : AppColors.loseSoft,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
