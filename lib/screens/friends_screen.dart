import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/social_models.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../utils/leaderboard.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/buttons.dart';
import '../widgets/panel_card.dart';
import 'shared/async_action.dart';
import 'shared/empty_state.dart';
import 'shared/tab_pill.dart';

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
                Semantics(
                  // The code is rendered letter-spaced mono, and the
                  // placeholder is six middle dots — both are gibberish read
                  // aloud, so the row states what it is instead.
                  label: state.groupCode == null
                      ? 'You do not have a group code yet'
                      : 'Your group code is ${state.groupCode!.split('').join(' ')}',
                  excludeSemantics: true,
                  child: Text(
                    inviteCode,
                    textAlign: TextAlign.center,
                    style: AppText.mono(
                      28,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 3.36,
                    ),
                  ),
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
                // Creating the group and opening WhatsApp are both awaited
                // network work; the button used to look idle throughout.
                AsyncActionBuilder(
                  action: notifier.shareInviteWhatsApp,
                  builder: (context, busy, run) => GoldButton(
                    label: busy ? 'Opening WhatsApp…' : 'Invite via WhatsApp',
                    onPressed: run,
                  ),
                ),
              ],
            ),
          ),

          const SectionLabel('Referral rewards'),
          _DividedPanel(
            rows: [
              for (final tier in kReferralTierDefs)
                _referralRow(state, notifier, tier),
            ],
          ),

          const SectionLabel('Join a friends group'),
          Container(
            decoration: panelDecoration(),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _GroupCodeField(
                    value: state.friendCodeInput,
                    onChanged: notifier.onFriendCodeInput,
                  ),
                ),
                const SizedBox(width: 8),
                // Joining hits Firestore. Kept enabled on a short code on
                // purpose: the notifier's "enter the 6-character code" toast
                // is more use than a dead button with no stated reason.
                AsyncActionBuilder(
                  action: notifier.joinGroupByCode,
                  builder: (context, busy, run) => _OutlinedPillButton(
                    label: busy ? 'Joining…' : 'Join',
                    onTap: run,
                  ),
                ),
              ],
            ),
          ),

          // `state.friends` is seeded with practice bots so the table is never
          // empty. They are opponents, not people: showing them here as real
          // friends — with working "Gift 100" buttons — was a lie the world
          // standings screen already knew not to tell. Same test, same answer.
          if (state.friendsAreLive) ...[
            const SectionLabel('Leaderboard'),
            TabPillRow(
              items: [
                TabPillItem(
                  label: 'Hourly',
                  active: state.leaderboardPeriod == LeaderboardPeriod.hourly,
                  onTap: notifier.setLeaderboardHourly,
                ),
                TabPillItem(
                  label: 'Daily',
                  active: state.leaderboardPeriod == LeaderboardPeriod.daily,
                  onTap: notifier.setLeaderboardDaily,
                ),
                TabPillItem(
                  label: 'All time',
                  active: state.leaderboardPeriod == LeaderboardPeriod.alltime,
                  onTap: notifier.setLeaderboardAlltime,
                ),
              ],
            ),
            const SizedBox(height: 2),
            _DividedPanel(
              rows: [
                for (final entry in buildLeaderboard(state))
                  _leaderboardRow(entry),
              ],
            ),
            const SectionLabel('Friends'),
            _DividedPanel(
              rows: [
                for (final f in state.friends) _friendRow(state, notifier, f),
              ],
            ),
          ] else ...[
            const SectionLabel('Friends'),
            EmptyState(
              icon: Icons.group_add_outlined,
              title: 'No friends in your group yet',
              message:
                  'The players at your table are practice opponents. Invite someone with your '
                  'code and this fills with their real scores.',
              actionLabel: 'Invite via WhatsApp',
              onAction: notifier.shareInviteWhatsApp,
            ),
          ],
        ],
      ),
    );
  }

  Widget _referralRow(
    GameState state,
    GameNotifier notifier,
    ReferralTierDef tier,
  ) {
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
              Text(
                tier.label,
                style: AppText.sora(16, weight: FontWeight.w700),
              ),
              Text(
                '+${tier.reward} chips · $progress',
                style: AppText.sora(14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RewardPillButton(
          label: label,
          enabled: claimable,
          onTap: claimable
              ? () => notifier.claimTier(tier.id, tier.need, tier.reward)
              : null,
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: entry.medalColor,
          ),
          alignment: Alignment.center,
          child: Text(
            '${entry.rank}',
            style: AppText.sora(
              13,
              weight: FontWeight.w800,
              color: AppColors.goldInk,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            entry.name,
            style: AppText.sora(
              16,
              weight: FontWeight.w700,
              color: entry.nameColor,
            ),
          ),
        ),
        Text(
          entry.scoreLabel,
          style: AppText.sora(
            16,
            weight: FontWeight.w800,
            color: entry.nameColor,
          ),
        ),
      ],
    );
  }

  Widget _friendRow(GameState state, GameNotifier notifier, Friend f) {
    final giftEnabled = state.chips >= 100;
    return Row(
      children: [
        Semantics(
          // The green dot is the only thing saying "online" — it needs words.
          label: f.online ? '${f.name}, online' : f.name,
          excludeSemantics: true,
          child: SizedBox(
            width: AppTouch.minTarget,
            height: AppTouch.minTarget,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarCircle(
                  initial: f.initial,
                  color: AppColors.gold.withValues(alpha: 0.15),
                  size: AppTouch.minTarget,
                ),
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
        Semantics(
          button: true,
          enabled: giftEnabled,
          // Every row's button says "Gift 100"; only its position says who it
          // gifts, which is invisible to a screen reader.
          label: 'Gift 100 chips to ${f.name}',
          hint: giftEnabled ? null : 'You need 100 chips to gift',
          excludeSemantics: true,
          child: _OutlinedPillButton(
            label: 'Gift 100',
            onTap: giftEnabled ? () => notifier.giftChips(f.id) : null,
          ),
        ),
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
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.border))
                    : null,
              ),
              child: rows[i],
            ),
        ],
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
            constraints: AppTouch.minTargetConstraints,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              // The outline is the whole control here, so it has to be visible:
              // AppColors.border is 1.71:1 and decorative only.
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Text(
              label,
              style: AppText.sora(
                15,
                weight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
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

  const _RewardPillButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          constraints: AppTouch.minTargetConstraints,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: enabled ? AppColors.goldGradient : null,
            border: enabled ? null : Border.all(color: AppColors.borderStrong),
          ),
          child: Text(
            label,
            style: AppText.sora(
              15,
              weight: FontWeight.w800,
              color: enabled ? AppColors.goldInk : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// The join-a-group code field.
///
/// Extracted into its own stateful widget because the controller has to
/// outlive a build. It used to be constructed inline —
/// `TextEditingController(text: state.friendCodeInput)` — which allocated a
/// fresh controller on every rebuild and leaked each one, and because the whole
/// screen rebuilds on any change to the ~90-field game state, that was most
/// frames. The selection was force-collapsed to the end each time to paper over
/// it, so the caret could never be placed mid-code to fix a typo.
class _GroupCodeField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _GroupCodeField({required this.value, required this.onChanged});

  @override
  State<_GroupCodeField> createState() => _GroupCodeFieldState();
}

class _GroupCodeFieldState extends State<_GroupCodeField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _GroupCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the state diverges from what is typed — e.g. the notifier
    // cleared the code after a successful join. Assigning unconditionally
    // would fight the player's own keystrokes.
    if (widget.value == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLength: 6,
      textCapitalization: TextCapitalization.characters,
      style: AppText.sora(17, weight: FontWeight.w700, letterSpacing: 1.36),
      decoration: InputDecoration(
        hintText: 'Group code',
        hintStyle: AppText.sora(
          17,
          weight: FontWeight.w700,
          color: AppColors.textFaint,
        ),
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
    );
  }
}
