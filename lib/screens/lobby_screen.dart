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
import '../utils/cup.dart';
import '../utils/daily_bonus.dart';
import '../utils/formatters.dart';
import '../utils/leaderboard.dart';
import '../utils/table_presence.dart';
import '../utils/table_recommendation.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/buttons.dart';
import '../widgets/count_up_text.dart';
import '../widgets/daily_bonus_dialog.dart';
import '../widgets/panel_card.dart';
import 'shared/avatar_initial.dart';
import 'shared/empty_state.dart';

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
          // The stories rail is still seeded fiction (four invented players
          // with invented highlights). Shown to someone with an empty group it
          // sat directly above a leaderboard reading "your leaderboard is
          // waiting — invite a friend", so the lobby contradicted itself on
          // one screen. It stays hidden until there are real people in it.
          if (state.friendsAreLive) ...[
            _StoriesRow(state: state, notifier: notifier),
            const SizedBox(height: 16),
          ],
          _DailyBonusCard(state: state, notifier: notifier),
          const SizedBox(height: 16),
          _TournamentCard(state: state, notifier: notifier),
          const SectionLabel('Choose your table'),
          for (final t in kTables)
            _TableCard(
              table: t,
              notifier: notifier,
              // Bots never carry a `tableKey`, so this is real friends only.
              here: friendsAtTable(state.friendsAreLive ? state.friends : const [], t.key),
              recommended: t.key == recommendedTable(state.chips).key,
            ),
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
          // Same rule as the friends screen and the world standings: the
          // seeded practice bots are not people, so they do not get to stand
          // on a leaderboard next to the player's real score.
          if (state.friendsAreLive)
            _LeaderboardCard(entries: topPlayers)
          else
            EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Your leaderboard is waiting',
              message:
                  'Invite a friend with your group code and their scores race yours here, '
                  'hour by hour.',
              actionLabel: 'Invite via WhatsApp',
              onAction: notifier.shareInviteWhatsApp,
              actionStyle: EmptyStateAction.link,
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
            goldRing: state.avatarFrameGold,
            photoUrl: state.photoUrl,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MergeSemantics(
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
        ),
        Semantics(
          // "● 1,150" is a chip glyph and a bare number to a screen reader.
          label: 'Balance: ${formatChips(state.chips)} chips',
          excludeSemantics: true,
          child: Container(
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
                CountUpText(value: state.chips, style: AppText.mono(17, weight: FontWeight.w700)),
              ],
            ),
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
          return Semantics(
            button: true,
            // Without this the whole row is a strip of unnamed circles that
            // each read as a single capital letter.
            label: viewed ? '${story.name}, story seen' : '${story.name}, new story',
            excludeSemantics: true,
            child: GestureDetector(
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
    final claimDay = nextDailyBonusStreakDay(widget.state.dailyBonusStreakDay, lastClaim, now);
    final reward = dailyBonusRewardForDay(claimDay);

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
          // The reward figure and the streak line are both wider at a large
          // font scale than the card has room for beside the claim button, so
          // the label block takes the leftover width and scales into it
          // rather than pushing the button off the card.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY BONUS',
                    style: AppText.mono(13, weight: FontWeight.w700, letterSpacing: 1.3, color: AppColors.gold),
                  ),
                  const SizedBox(height: 4),
                  Text('+$reward chips', style: AppText.mono(22, weight: FontWeight.w700)),
                  if (widget.state.dailyBonusStreakDay > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        ready
                            ? 'Day $claimDay of your streak'
                            : 'Streak day ${widget.state.dailyBonusStreakDay} banked',
                        style: AppText.sora(12.5, weight: FontWeight.w700, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (ready)
            SizedBox(
              width: 110,
              child: GoldButton(
                label: 'Claim',
                onPressed: () => showDailyBonusDialog(context),
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
    // Only real group members are counted. Adding the practice bots made a
    // solo player's card claim a five-player race that does not exist.
    final players = state.friendsAreLive ? state.friends.length + 1 : 1;
    return GestureDetector(
      onTap: notifier.openCup,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.feltCardGradient,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Both halves flex. A fixed pair of labels overflowed this row by
            // ~7px on a 320-wide phone at 1.3x text: the title is a constant
            // but the countdown beside it grows from "Ends in 3h" to "Ends in
            // 2d 22h" as the week turns over.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'WEEKEND CUP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mono(13, weight: FontWeight.w700, letterSpacing: 1.3, color: AppColors.gold),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    cupEndsLabel(DateTime.now()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppText.sora(13, weight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${formatChips(kCupPrizePool)} chip prize pool · '
                '${players > 1 ? '$players players in your group' : 'your friends group race'}',
                style: AppText.sora(16, color: const Color(0xFFD8D3C6)),
              ),
            ),
            // Secondary on purpose: playing a hand is the lobby's job, and
            // this card used to fire the same gold gradient as the daily-bonus
            // claim above it and the invite button below it. Three primaries
            // on one screen is none.
            OutlinePillButton(
              label: state.tournamentJoined ? 'Play a Cup hand' : 'Join tournament',
              onPressed: notifier.openCup,
              verticalPadding: 16,
              fontSize: 17,
            ),
          ],
        ),
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
  /// lobby's one gold call to action.
  ///
  /// Playing a hand is what the lobby is for, and it was the only thing on the
  /// screen without a button: three promo cards shouted in gold above a quiet
  /// grey list, and the game itself was a chevron.
  final bool recommended;

  const _TableCard({
    required this.table,
    required this.notifier,
    required this.here,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = tablePresenceLabel(here);
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
              border: Border.all(
                color: recommended
                    ? AppColors.gold.withValues(alpha: 0.55)
                    : (here.isEmpty ? AppColors.border : AppColors.gold.withValues(alpha: 0.4)),
              ),
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
                        label.isEmpty ? '\$${table.min} – \$${table.max}' : '\$${table.min} – \$${table.max} · $label',
                        style: AppText.sora(14, color: label.isEmpty ? AppColors.textMuted : AppColors.gold),
                      ),
                    ],
                  ),
                ),
                if (here.isNotEmpty) ...[
                  SizedBox(
                    width: 20.0 * math.min(here.length, 3) + 8,
                    height: 28,
                    child: Stack(
                      children: [
                        for (var i = 0; i < math.min(here.length, 3); i++)
                          Positioned(
                            left: i * 16.0,
                            child: AvatarCircle(
                              initial: here[i].initial,
                              color: AppColors.gold.withValues(alpha: 0.22),
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'PLAY',
                      style: AppText.sora(14, weight: FontWeight.w800, letterSpacing: 0.9, color: AppColors.goldInk),
                    ),
                  )
                else
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
