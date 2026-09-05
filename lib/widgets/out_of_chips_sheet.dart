import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/daily_bonus.dart';
import '../utils/formatters.dart';
import '../utils/rebuy.dart';
import 'buttons.dart';

/// Every way back to the table, in one place, when the stack runs out.
///
/// Running dry used to surface as a single "Rebuy in 3h 21m" pill inside the
/// betting panel with a line of grey text under it. A player who found it on
/// cooldown was, as far as the interface was concerned, finished — while a
/// daily bonus and a referral reward might both have been sitting there
/// unmentioned.
Future<void> showOutOfChipsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _OutOfChipsSheet(),
  );
}

class _OutOfChipsSheet extends ConsumerWidget {
  const _OutOfChipsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final now = DateTime.now();
    final routes = _routes(state, now);
    // Exactly one gold button, and only when something is actually available
    // right now: a primary button that opens a countdown is a promise the
    // screen cannot keep.
    final first = routes.where((r) => r.ready).firstOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadius.xxlAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Out of chips', style: AppText.serifItalic(28), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text('Here is every way to get back to the table.', textAlign: TextAlign.center, style: AppText.bodySm()),
              const SizedBox(height: AppSpacing.lg),
              for (final route in routes) ...[_RouteRow(route: route), const SizedBox(height: AppSpacing.sm)],
              const SizedBox(height: AppSpacing.xs),
              if (first != null)
                GoldButton(
                  label: first.action,
                  onPressed: () {
                    Navigator.of(context).pop();
                    first.onTap(notifier);
                  },
                )
              else
                OutlinePillButton(
                  label: 'Back to the lobby',
                  onPressed: () {
                    Navigator.of(context).pop();
                    notifier.exitTable();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_Route> _routes(GameState state, DateTime now) {
    final bonusReady = isDailyBonusReady(state.lastDailyBonusClaimAt, now);
    final rebuyReady = isRebuyReady(state.lastRebuyAt, now);

    return [
      _Route(
        icon: Icons.replay,
        title: 'Table rebuy',
        detail: rebuyReady
            ? 'Tops your stack back up to ${formatChips(kRebuyChips)}'
            : 'Ready in ${rebuyCountdownLabel(state.lastRebuyAt!, now)}',
        ready: rebuyReady,
        action: 'Rebuy ${formatChips(kRebuyChips)} chips',
        onTap: (n) => n.rebuy(),
      ),
      _Route(
        icon: Icons.card_giftcard,
        title: 'Daily bonus',
        detail: bonusReady
            ? 'Waiting for you in the lobby'
            : 'Next in ${dailyBonusCountdownLabel(state.lastDailyBonusClaimAt!, now)}',
        ready: bonusReady,
        action: 'Claim the daily bonus',
        onTap: (n) => n.goLobby(),
      ),
      _Route(
        icon: Icons.person_add_alt,
        title: 'Invite a friend',
        detail: 'They join your race, you both get chips',
        ready: true,
        action: 'Invite on WhatsApp',
        onTap: (n) => n.shareInviteWhatsApp(),
      ),
    ];
  }
}

class _Route {
  final IconData icon;
  final String title;
  final String detail;
  final bool ready;
  final String action;
  final void Function(GameNotifier) onTap;

  const _Route({
    required this.icon,
    required this.title,
    required this.detail,
    required this.ready,
    required this.action,
    required this.onTap,
  });
}

class _RouteRow extends StatelessWidget {
  final _Route route;

  const _RouteRow({required this.route});

  @override
  Widget build(BuildContext context) {
    final tint = route.ready ? AppColors.gold : AppColors.textFaint;
    return Semantics(
      label: '${route.title}. ${route.detail}',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: AppAlpha.subtle),
            ),
            alignment: Alignment.center,
            child: Icon(route.icon, size: 18, color: tint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  route.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sora(
                    15,
                    weight: FontWeight.w700,
                    color: route.ready ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                Text(route.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodySm()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
