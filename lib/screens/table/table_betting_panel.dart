import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_data.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../utils/points.dart';
import '../../widgets/buttons.dart';

/// Betting-phase bottom panel: current bet readout, the denomination chips the
/// table allows, CLEAR/DEAL row, and (when broke) a complimentary-chips button.
class TableBettingPanel extends ConsumerWidget {
  const TableBettingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final stake = state.stake;
    final denoms = chipDenomsFor(stake);
    final tableMin = stake?.min ?? 0;
    final tableMax = stake?.max;
    final belowTableMin = state.bet < tableMin;
    final dealDisabled = !(state.bet > 0 && state.bet <= state.chips) || belowTableMin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FriendsMiniTable(state: state, notifier: notifier),
        const SizedBox(height: 8),
        // One compact line: the bet figure, with the table minimum folded in
        // as a hint until the bet clears it.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Bet ',
                style: AppText.mono(12, letterSpacing: 1.2, color: AppColors.textPrimary.withValues(alpha: 0.82)),
              ),
              TextSpan(
                text: '\$${state.bet}',
                style: AppText.mono(20, weight: FontWeight.w700, color: AppColors.gold),
              ),
              if (belowTableMin)
                TextSpan(
                  text: '  ·  min \$${formatChips(tableMin)}',
                  style: AppText.mono(12, letterSpacing: 0.8, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // The tray scales as a unit: capped height keeps the chips compact,
        // and the FittedBox still shrinks the row further on narrow phones.
        SizedBox(
          height: 46,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < denoms.length; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  ChipButton(
                    amount: denoms[i],
                    color: AppColors.chipColors[denoms[i]]!,
                    disabled:
                        (state.bet + denoms[i]) > state.chips ||
                        (tableMax != null && (state.bet + denoms[i]) > tableMax),
                    onPressed: () => notifier.placeBet(denoms[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ActionPillButton(
                label: 'CLEAR',
                borderColor: AppColors.lose.withValues(alpha: 0.6),
                backgroundColor: AppColors.lose.withValues(alpha: 0.2),
                textColor: AppColors.loseLight,
                onPressed: notifier.clearBet,
                verticalPadding: 12,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: GoldButton(
                label: 'DEAL',
                onPressed: dealDisabled ? null : notifier.dealRound,
                verticalPadding: 12,
                fontSize: 17,
              ),
            ),
          ],
        ),
        if (state.chips == 0) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ActionPillButton(
              label: 'Get 1,000 complimentary chips',
              borderColor: AppColors.gold.withValues(alpha: 0.32),
              backgroundColor: AppColors.gold.withValues(alpha: 0.08),
              textColor: AppColors.gold,
              onPressed: notifier.resetBankroll,
              verticalPadding: 12,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}

typedef _StandingsRow = ({String name, int points, bool isSelf});

/// Swipeable standings inside the betting panel, three pages:
/// 1. FRIENDS — only real people who joined via the WhatsApp invite code
///    (with an inline invite button when there is nobody yet),
/// 2. WORLD · THIS HOUR — live top players anywhere by hourly points,
/// 3. WORLD · TODAY — the same race over the whole day.
class _FriendsMiniTable extends StatefulWidget {
  final GameState state;
  final GameNotifier notifier;

  const _FriendsMiniTable({required this.state, required this.notifier});

  @override
  State<_FriendsMiniTable> createState() => _FriendsMiniTableState();
}

class _FriendsMiniTableState extends State<_FriendsMiniTable> {
  static const List<String> _titles = ['FRIENDS', 'WORLD · THIS HOUR', 'WORLD · TODAY'];
  static const int _kMaxRows = 5;

  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _titles[_page],
                style: AppText.sora(10, weight: FontWeight.w800, color: AppColors.textFaint, letterSpacing: 1),
              ),
              const Spacer(),
              for (var i = 0; i < _titles.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? AppColors.gold : AppColors.border,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            // The rows are text, so the page has to grow with the user's font
            // scale — a fixed height clips the last row at large type.
            height: 96 * (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 1.3),
            child: PageView(
              controller: _controller,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                _friendsPage(s),
                _worldPage(s, hourly: true),
                _worldPage(s, hourly: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _heroPoints(GameState s, {required bool hourly}) {
    final now = DateTime.now();
    return hourly
        ? rolledPoints(s.heroHourlyPoints, s.heroHourKey, hourKeyOf(now))
        : rolledPoints(s.heroDailyPoints, s.heroDayKey, dayKeyOf(now));
  }

  /// Real invited friends only — the practice bots never appear here. With no
  /// live friends yet, the page says so and offers the WhatsApp invite
  /// directly.
  Widget _friendsPage(GameState s) {
    if (!s.friendsAreLive) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No friends here yet — you play alone.',
            textAlign: TextAlign.center,
            style: AppText.sora(11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: widget.notifier.shareInviteWhatsApp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(999)),
              child: Text(
                'Invite friends on WhatsApp',
                style: AppText.sora(12, weight: FontWeight.w800, color: AppColors.goldInk),
              ),
            ),
          ),
        ],
      );
    }
    final hourly = s.badgeHourly;
    final rows = [
      for (final f in s.friends) (name: f.firstName, points: hourly ? f.hourlyScore : f.dailyScore, isSelf: false),
      (name: 'You', points: _heroPoints(s, hourly: hourly), isSelf: true),
    ]..sort((a, b) => b.points.compareTo(a.points));
    return _standings(rows);
  }

  /// Live world top list. The hero's row is highlighted when present; when
  /// outside the top, it is appended unranked so your own score stays visible.
  Widget _worldPage(GameState s, {required bool hourly}) {
    final source = hourly ? s.globalHourly : s.globalDaily;
    if (source.isEmpty) {
      return Center(
        child: Text(
          'Nobody on the world list ${hourly ? 'this hour' : 'today'} yet.\nDeal a hand and claim #1!',
          textAlign: TextAlign.center,
          style: AppText.sora(11, color: AppColors.textMuted),
        ),
      );
    }
    final rows = [
      for (final f in source)
        (
          name: f.id == s.heroUid ? 'You' : f.firstName,
          points: hourly ? f.hourlyScore : f.dailyScore,
          isSelf: f.id == s.heroUid,
        ),
    ];
    var selfAppended = false;
    if (!rows.any((r) => r.isSelf)) {
      rows.add((name: 'You', points: _heroPoints(s, hourly: hourly), isSelf: true));
      selfAppended = true;
    }
    return _standings(rows, selfUnranked: selfAppended);
  }

  /// Ranked rows capped at [_kMaxRows], always keeping the hero's row visible
  /// (it replaces the last visible row when it falls below the cut).
  Widget _standings(List<_StandingsRow> rows, {bool selfUnranked = false}) {
    var visible = [for (var i = 0; i < rows.length; i++) (rank: i + 1, row: rows[i])];
    final selfIdx = visible.indexWhere((e) => e.row.isSelf);
    if (visible.length > _kMaxRows) {
      visible = selfIdx >= _kMaxRows
          ? [...visible.take(_kMaxRows - 1), visible[selfIdx]]
          : visible.take(_kMaxRows).toList();
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final e in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    selfUnranked && e.row.isSelf ? '#–' : '#${e.rank}',
                    style: AppText.mono(11, weight: FontWeight.w700, color: e.rank == 1 ? AppColors.gold : AppColors.textFaint),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sora(
                      12,
                      weight: e.row.isSelf ? FontWeight.w800 : FontWeight.w600,
                      color: e.row.isSelf ? AppColors.gold : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${e.row.points >= 0 ? '+' : '-'}\$${formatChips(e.row.points.abs())}',
                  style: AppText.mono(
                    12,
                    weight: FontWeight.w700,
                    color: e.row.points >= 0 ? AppColors.winLight : AppColors.loseSoft,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
