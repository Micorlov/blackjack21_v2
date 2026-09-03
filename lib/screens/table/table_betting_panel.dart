import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_data.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/flags.dart';
import '../../utils/formatters.dart';
import '../../utils/world_standings.dart';
import '../../widgets/buttons.dart';
import 'world_leaderboard_screen.dart';

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
        // The tray is 60px of chip either side of these gaps, so it reads as
        // its own band without needing a full step of space around it.
        const SizedBox(height: AppSpacing.xs),
        _ChipTray(state: state, notifier: notifier, denoms: denoms, tableMax: tableMax),
        const SizedBox(height: AppSpacing.xs),
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
        // Below the table minimum the player cannot legally bet, so the rebuy
        // has to appear before the stack literally hits zero — with a bankroll
        // that now survives relaunch, a stranded $10 would otherwise be a
        // permanent dead end.
        if (state.chips < (state.stake?.min ?? kStartingChips)) ...[
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

/// The row of denomination chips the player bets with.
///
/// This used to be `SizedBox(height: 46)` wrapping a `FittedBox(scaleDown)`.
/// Because 46/60 is a smaller ratio than any width ever produced, the height
/// always won: the 60px chips rendered at **46x46 on every device**, under the
/// 48dp minimum touch target, permanently — not just on narrow phones.
///
/// The chips now keep their real size. When they do not all fit, the row
/// scrolls horizontally rather than shrinking below the minimum, because a
/// target too small to hit reliably is worse than one that needs a swipe.
class _ChipTray extends StatelessWidget {
  final GameState state;
  final GameNotifier notifier;
  final List<int> denoms;
  final int? tableMax;

  const _ChipTray({required this.state, required this.notifier, required this.denoms, required this.tableMax});

  /// [ChipButton]'s painted diameter. Asserted against the platform minimum so
  /// this stays honest if either number ever moves.
  static const double _chipSize = 60;
  static const double _gap = 9;

  @override
  Widget build(BuildContext context) {
    assert(_chipSize >= AppTouch.minTarget, 'chips must clear the minimum touch target');

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < denoms.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          ChipButton(
            amount: denoms[i],
            color: AppColors.chipColors[denoms[i]]!,
            disabled:
                (state.bet + denoms[i]) > state.chips || (tableMax != null && (state.bet + denoms[i]) > tableMax!),
            onPressed: () => notifier.placeBet(denoms[i]),
          ),
        ],
      ],
    );

    return SizedBox(
      height: _chipSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needed = denoms.length * _chipSize + (denoms.length - 1) * _gap;
          if (needed <= constraints.maxWidth) {
            return Center(child: row);
          }
          return SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
        },
      ),
    );
  }
}

/// Swipeable standings inside the betting panel, three pages:
/// 1. FRIENDS — only real people who joined via the WhatsApp invite code
///    (with an inline invite button when there is nobody yet),
/// 2. WORLD · THIS HOUR — live top players anywhere by hourly points,
/// 3. WORLD · TODAY — the same race over the whole day.
/// Tapping the card opens [WorldLeaderboardScreen] with the full, uncapped
/// list for whichever page is currently showing.
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

  void _openFullList(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorldLeaderboardScreen(initialTab: _page)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openFullList(context),
        child: Container(
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
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_full, size: 11, color: AppColors.textFaint),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                // The rows are text, so the page has to grow with the user's
                // font scale — a fixed height clips the last row at large type.
                height: 96 * (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 1.3),
                child: PageView(
                  controller: _controller,
                  onPageChanged: (p) => setState(() => _page = p),
                  children: [
                    _fitPage(_friendsPage(s)),
                    _fitPage(_worldPage(s, hourly: true)),
                    _fitPage(_worldPage(s, hourly: false)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keeps a page inside the card's fixed height whatever the text scale or
  /// the card's width.
  ///
  /// The card is one fixed-height row of the betting panel, but its contents
  /// are wrapping text: narrow the card — the landscape side rail is ~26px
  /// tighter than the portrait panel — and the empty-state line takes a third
  /// line it has no room for. Re-imposing the real width inside the
  /// [FittedBox] is what keeps the wrapping honest: without it the child would
  /// be laid out unbounded, never wrap, and then be scaled to nothing.
  Widget _fitPage(Widget page) {
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: constraints.maxWidth, child: page),
      ),
    );
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
    return _standings(friendsStandingsRows(s));
  }

  /// Live world top list, always padded to [_kMaxRows] with filler bots so
  /// the card never looks sparse while the real player base is still small.
  Widget _worldPage(GameState s, {required bool hourly}) {
    final w = worldStandings(s, hourly: hourly, minCount: _kMaxRows);
    return _standings(w.rows, selfUnranked: w.selfUnranked);
  }

  /// Ranked rows capped at [_kMaxRows], always keeping the hero's row visible
  /// (it replaces the last visible row when it falls below the cut).
  Widget _standings(List<StandingsRow> rows, {bool selfUnranked = false}) {
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
                    style: AppText.mono(
                      11,
                      weight: FontWeight.w700,
                      color: e.rank == 1 ? AppColors.gold : AppColors.textFaint,
                    ),
                  ),
                ),
                Text(flagForId(e.row.id), style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
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
