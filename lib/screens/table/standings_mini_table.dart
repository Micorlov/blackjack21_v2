import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/flags.dart';
import '../../utils/formatters.dart';
import '../../utils/world_standings.dart';
import 'world_leaderboard_screen.dart';

/// Swipeable standings card, three pages:
/// 1. FRIENDS — only real people who joined via the WhatsApp invite code
///    (with an inline invite button when there is nobody yet),
/// 2. WORLD · THIS HOUR — live top players anywhere by hourly points,
/// 3. WORLD · TODAY — the same race over the whole day.
/// Tapping the card opens [WorldLeaderboardScreen] with the full, uncapped
/// list for whichever page is currently showing.
///
/// It used to live inside the betting panel, where it ate roughly a quarter of
/// the screen at the one moment the player is trying to pick a chip — and, with
/// nobody in the group yet, spent that space saying "you play alone". It now
/// shows while the other seats and the dealer play, which is the stretch of the
/// hand where the player has nothing to do and the standings are what they
/// actually want to look at.
class StandingsMiniTable extends StatefulWidget {
  final GameState state;
  final GameNotifier notifier;

  const StandingsMiniTable({super.key, required this.state, required this.notifier});

  @override
  State<StandingsMiniTable> createState() => _StandingsMiniTableState();
}

class _StandingsMiniTableState extends State<StandingsMiniTable> {
  static const List<String> _titles = ['FRIENDS', 'WORLD · THIS HOUR', 'WORLD · TODAY'];
  static const int _kMaxRows = 5;

  /// With nobody in the group, the FRIENDS page is dropped rather than shown
  /// empty.
  ///
  /// It used to open on a page reading "No friends here yet — you play alone"
  /// under a full gold invite button: the one page in the card with nothing on
  /// it, handed to the player mid-hand, when the invite already sits on the
  /// betting panel, the lobby, the shop and the friends screen. The world race
  /// is real whether or not you have invited anyone, so that shows instead.
  bool get _hasFriendsPage => widget.state.friendsAreLive;

  int get _firstPage => _hasFriendsPage ? 0 : 1;

  late final PageController _controller = PageController(initialPage: _firstPage);
  late int _page = _firstPage;

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
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _openFullList(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: AppColors.gold.withValues(alpha: AppAlpha.border)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Flexible because the card is narrower in the landscape
                  // side rail than in the portrait panel, and the world titles
                  // are twice the length of "FRIENDS".
                  Flexible(
                    child: Text(
                      _titles[_page],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sora(12, weight: FontWeight.w800, color: AppColors.textFaint, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Spacer(),
                  for (var i = _firstPage; i < _titles.length; i++) ...[
                    if (i > _firstPage) const SizedBox(width: 4),
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
                    // An empty slot rather than a removed child, so page
                    // indices stay aligned with [_titles] and with the tab the
                    // full standings screen opens on.
                    if (_hasFriendsPage) _fitPage(_friendsPage(s)) else const SizedBox.shrink(),
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

  /// Real invited friends only — the practice bots never appear here. Not
  /// built at all until there are some (see [_hasFriendsPage]).
  Widget _friendsPage(GameState s) => _standings(friendsStandingsRows(s));

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
