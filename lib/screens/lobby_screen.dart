import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/game_state.dart';
import '../models/social_models.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/daily_bonus.dart';
import '../utils/formatters.dart';
import '../utils/leaderboard.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/buttons.dart';
import '../widgets/panel_card.dart';

/// Home / lobby screen: welcome header, stories, daily bonus, tournament
/// promo, table picker, and a "Top players" leaderboard preview. Ported 1:1
/// from the `screen==='lobby'` block in `Blackjack 21 v2.dc.html`
/// (lines 45-128). The bottom nav bar and toast/reaction overlays live in the
/// app shell, not here.
class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final topPlayers = buildLeaderboard(state).take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(state: state),
          const SizedBox(height: 20),
          _StoriesRow(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _DailyBonusCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _TournamentCard(state: state, notifier: notifier),
          const SectionLabel('Choose your table'),
          for (final t in kTables) _TableCard(table: t, notifier: notifier),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOP PLAYERS', style: AppText.sectionLabel()),
                TextLinkButton(label: 'See all', onPressed: () => notifier.goFriends()),
              ],
            ),
          ),
          _LeaderboardCard(entries: topPlayers),
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
        AvatarCircle(
          initial: state.displayName.isEmpty ? '?' : state.displayName[0].toUpperCase(),
          color: state.avatarColor,
          size: 40,
          goldRing: state.avatarFrameGold,
          photoUrl: state.photoUrl,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: AppText.sora(14, weight: FontWeight.w600, color: AppColors.textMuted),
              ),
              Text(state.displayName, style: AppText.sora(18, weight: FontWeight.w800)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.navSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('●', style: AppText.mono(15, color: AppColors.gold, height: 1)),
              const SizedBox(width: 7),
              Text(formatChips(state.chips), style: AppText.mono(17, weight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoriesRow extends StatelessWidget {
  final GameState state;
  final GameNotifier notifier;

  const _StoriesRow({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kStoriesData.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final story = kStoriesData[i];
          final viewed = state.viewedStories.contains(story.id);
          return GestureDetector(
            onTap: () => notifier.openStory(story.id),
            child: SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: story.color,
                      border: Border.all(color: viewed ? const Color(0xFF3A4A42) : AppColors.gold, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      story.initial,
                      style: AppText.sora(20, weight: FontWeight.w800, color: AppColors.goldInk),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    story.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sora(12.5, weight: FontWeight.w700, color: const Color(0xFFD8D3C6)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.feltCardGradient,
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DAILY BONUS',
                style: AppText.mono(13, weight: FontWeight.w700, letterSpacing: 1.3, color: AppColors.gold),
              ),
              const SizedBox(height: 4),
              Text('+$kDailyBonusChips chips', style: AppText.mono(22, weight: FontWeight.w700)),
            ],
          ),
          if (ready)
            SizedBox(
              width: 110,
              child: GoldButton(
                label: 'Claim',
                onPressed: widget.notifier.claimDailyBonus,
                verticalPadding: 16,
                fontSize: 16,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.win, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Claimed',
                      style: AppText.sora(15, weight: FontWeight.w800, color: AppColors.win),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Next in ${dailyBonusCountdownLabel(lastClaim!, now)}',
                  style: AppText.sora(12.5, weight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final GameState state;
  final GameNotifier notifier;

  const _TournamentCard({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.feltCardGradient,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKEND CUP',
                style: AppText.mono(13, weight: FontWeight.w700, letterSpacing: 1.3, color: AppColors.gold),
              ),
              Text(
                'Ends in 2d 14h',
                style: AppText.sora(13, weight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '5,000 chip prize pool · 128 players joined',
              style: AppText.sora(16, color: const Color(0xFFD8D3C6)),
            ),
          ),
          state.tournamentJoined
              ? _DisabledFullButton(label: 'Joined')
              : GoldButton(label: 'Join tournament', onPressed: notifier.joinTournament),
        ],
      ),
    );
  }
}

/// Full-width grey disabled button, matching the design's
/// `background:#31403A;color:#9AA79E;` disabled-tournament-button style.
class _DisabledFullButton extends StatelessWidget {
  final String label;

  const _DisabledFullButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 17),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(14)),
      child: Text(
        label,
        style: AppText.sora(16, weight: FontWeight.w800, color: AppColors.textFaint),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableStake table;
  final GameNotifier notifier;

  const _TableCard({required this.table, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => notifier.enterTable(table),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: table.tintDim, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(color: table.tint, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(table.name, style: AppText.sora(17, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '\$${table.min} – \$${table.max} · ${tableFriendsHereLabel(table.key)}',
                        style: AppText.sora(14, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _LeaderboardCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: panelDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: i < entries.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: entries[i].medalColor),
                    alignment: Alignment.center,
                    child: Text(
                      '${entries[i].rank}',
                      style: AppText.sora(13, weight: FontWeight.w800, color: AppColors.goldInk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entries[i].name,
                      style: AppText.sora(16, weight: FontWeight.w700, color: entries[i].nameColor),
                    ),
                  ),
                  Text(
                    entries[i].scoreLabel,
                    style: AppText.sora(16, weight: FontWeight.w800, color: entries[i].nameColor),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
