import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/social_models.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../utils/leaderboard.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/buttons.dart';
import '../widgets/panel_card.dart';

/// Friends screen: invite code, referral rewards, add-a-friend, leaderboard,
/// and friends list. Ported from `Blackjack 21 v2.dc.html` lines 545-611.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    final inviteCode = state.groupCode ?? '· · · · · ·';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTitle('Friends'),

          const SectionLabel('Your friends group'),
          Container(
            decoration: panelDecoration(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  inviteCode,
                  textAlign: TextAlign.center,
                  style: AppText.mono(28, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3.36),
                ),
                const SizedBox(height: 8),
                Text(
                  state.groupCode == null
                      ? 'Invite friends on WhatsApp — everyone who joins with your code plays on your live leaderboard.'
                      : 'Friends who enter this code appear live below.',
                  textAlign: TextAlign.center,
                  style: AppText.sora(13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                GoldButton(label: 'Invite via WhatsApp', onPressed: notifier.shareInviteWhatsApp),
              ],
            ),
          ),

          const SectionLabel('Referral rewards'),
          _DividedPanel(rows: [for (final tier in kReferralTierDefs) _referralRow(state, notifier, tier)]),

          const SectionLabel('Join a friends group'),
          Container(
            decoration: panelDecoration(),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: state.friendCodeInput)
                      ..selection = TextSelection.collapsed(offset: state.friendCodeInput.length),
                    onChanged: notifier.onFriendCodeInput,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    style: AppText.sora(17, weight: FontWeight.w700, letterSpacing: 1.36),
                    decoration: InputDecoration(
                      hintText: 'Group code',
                      hintStyle: AppText.sora(17, weight: FontWeight.w700, color: AppColors.textFaint),
                      filled: true,
                      fillColor: AppColors.surface,
                      counterText: '',
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.gold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _OutlinedPillButton(label: 'Join', onTap: notifier.joinGroupByCode),
              ],
            ),
          ),

          const SectionLabel('Leaderboard'),
          Row(
            children: [
              _TabPill(
                label: 'Hourly',
                fontSize: 14,
                active: state.leaderboardPeriod == LeaderboardPeriod.hourly,
                onTap: notifier.setLeaderboardHourly,
              ),
              const SizedBox(width: 8),
              _TabPill(
                label: 'Daily',
                fontSize: 14,
                active: state.leaderboardPeriod == LeaderboardPeriod.daily,
                onTap: notifier.setLeaderboardDaily,
              ),
              const SizedBox(width: 8),
              _TabPill(
                label: 'All time',
                fontSize: 14,
                active: state.leaderboardPeriod == LeaderboardPeriod.alltime,
                onTap: notifier.setLeaderboardAlltime,
              ),
            ],
          ),
          const SizedBox(height: 2),
          _DividedPanel(rows: [for (final entry in buildLeaderboard(state)) _leaderboardRow(entry)]),

          const SectionLabel('Friends'),
          _DividedPanel(rows: [for (final f in state.friends) _friendRow(state, notifier, f)]),
        ],
      ),
    );
  }

  Widget _referralRow(GameState state, GameNotifier notifier, ReferralTierDef tier) {
    final progress = '${min(state.referralsCount, tier.need)}/${tier.need}';
    final claimed = state.claimedTiers.contains(tier.id);
    final met = state.referralsCount >= tier.need;
    final label = claimed ? 'Claimed' : (met ? 'Claim' : 'Locked');
    final claimable = met && !claimed;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tier.label, style: AppText.sora(16, weight: FontWeight.w700)),
              Text('+${tier.reward} chips · $progress', style: AppText.sora(14, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RewardPillButton(
          label: label,
          enabled: claimable,
          onTap: claimable ? () => notifier.claimTier(tier.id, tier.need, tier.reward) : null,
        ),
      ],
    );
  }

  Widget _leaderboardRow(LeaderboardEntry entry) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, color: entry.medalColor),
          alignment: Alignment.center,
          child: Text(
            '${entry.rank}',
            style: AppText.sora(13, weight: FontWeight.w800, color: AppColors.goldInk),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            entry.name,
            style: AppText.sora(16, weight: FontWeight.w700, color: entry.nameColor),
          ),
        ),
        Text(
          entry.scoreLabel,
          style: AppText.sora(16, weight: FontWeight.w800, color: entry.nameColor),
        ),
      ],
    );
  }

  Widget _friendRow(GameState state, GameNotifier notifier, Friend f) {
    final giftEnabled = state.chips >= 100;
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarCircle(initial: f.initial, color: AppColors.gold.withValues(alpha: 0.15), size: 46),
              if (f.online)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.win,
                      border: Border.all(color: AppColors.panel, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(f.name, style: AppText.sora(16, weight: FontWeight.w700)),
              Text(
                '\$${formatChips(f.chips)} · ${f.dailyScore >= 0 ? '+' : '-'}\$${formatChips(f.dailyScore.abs())} today',
                style: AppText.sora(14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _OutlinedPillButton(label: 'Gift 100', onTap: giftEnabled ? () => notifier.giftChips(f.id) : null),
      ],
    );
  }
}

/// Panel container with rows separated by a bottom divider (all but the last).
class _DividedPanel extends StatelessWidget {
  final List<Widget> rows;

  const _DividedPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
              ),
              child: rows[i],
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final double fontSize;

  const _TabPill({required this.label, required this.active, required this.onTap, this.fontSize = 15});

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
              style: AppText.sora(
                fontSize,
                weight: FontWeight.w700,
                color: active ? AppColors.gold : AppColors.textFaint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined pill (used for "Add" and "Gift 100"); dims and disables when
/// [onTap] is null.
class _OutlinedPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OutlinedPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              label,
              style: AppText.sora(15, weight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Referral-tier pill: gold-filled when claimable, muted outline otherwise
/// (covers both "Claimed" and "Locked" states).
class _RewardPillButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _RewardPillButton({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: enabled ? AppColors.goldGradient : null,
            border: enabled ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: AppText.sora(15, weight: FontWeight.w800, color: enabled ? AppColors.goldInk : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
