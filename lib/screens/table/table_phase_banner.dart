import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/table_seats.dart';
import 'table_layout.dart';

const List<RoundPhase> _kPhaseOrder = [
  RoundPhase.betting,
  RoundPhase.npcs,
  RoundPhase.playing,
  RoundPhase.dealer,
  RoundPhase.settlement,
];

const Map<RoundPhase, String> _kPhaseLabels = {
  RoundPhase.betting: 'Bet',
  RoundPhase.npcs: 'Table',
  RoundPhase.playing: 'You',
  RoundPhase.dealer: 'Dealer',
  RoundPhase.settlement: 'Result',
};

/// Who the table is waiting for, and how far through the round we are.
///
/// This used to be five small monospaced pills and nothing else, which asked
/// the player to decode "which pill is slightly more gold" to answer the only
/// question that matters mid-hand: *is it my turn?* The headline states that
/// outright, in a sentence, and during a split says which of the two hands is
/// live.
///
/// The five pills are gone; a five-segment track carries the same sequence in
/// 4px instead of 40. That trade is what pays for the headline: the pills'
/// labels only ever repeated the phase the headline now names, and on a
/// 320x568 screen at 130% text every pixel this row takes is a pixel the felt
/// does not get.
class TablePhaseBanner extends StatelessWidget {
  final RoundPhase phase;

  /// The sentence on the headline — "Your turn", "Maya is playing", …
  final String turnLabel;

  /// True while the player is the one being waited on. Drives the gold fill:
  /// the one state the player has to notice from across the room.
  final bool isHeroTurn;

  const TablePhaseBanner({
    super.key,
    required this.phase,
    required this.turnLabel,
    required this.isHeroTurn,
  });

  /// Builds the banner's copy from the round state, so the felt, the action
  /// panel and this line can never disagree about whose turn it is.
  factory TablePhaseBanner.fromState(GameState state) {
    final split = state.hands.length > 1;
    final label = switch (state.phase) {
      RoundPhase.betting => 'Place your bet',
      RoundPhase.insurance => 'Insurance offered',
      RoundPhase.npcs => '${_actingName(state)} is playing',
      RoundPhase.playing => split
          ? 'Your turn · hand ${state.activeHandIndex + 1} of ${state.hands.length}'
          : 'Your turn',
      RoundPhase.dealer => 'Dealer is playing',
      RoundPhase.settlement => 'Round result',
    };
    return TablePhaseBanner(
      phase: state.phase,
      turnLabel: label,
      // Betting and insurance are the player's move as much as `playing` is —
      // the gold means "the table is waiting for you", not "you may hit".
      isHeroTurn:
          state.phase == RoundPhase.playing ||
          state.phase == RoundPhase.betting ||
          state.phase == RoundPhase.insurance,
    );
  }

  static String _actingName(GameState state) {
    final seat = state.actingSeat;
    final seats = tableSeats(state);
    if (seat == null || seat >= seats.length) return 'The table';
    return seats[seat].firstName;
  }

  @override
  Widget build(BuildContext context) {
    final gutter = TableLayout.gutterOf(MediaQuery.sizeOf(context).width);
    // `insurance` visually counts as the "Table" step (same index as `npcs`),
    // matching the source design.
    final curPhase = phase == RoundPhase.insurance ? RoundPhase.npcs : phase;
    final curIdx = _kPhaseOrder.indexOf(curPhase).clamp(0, _kPhaseOrder.length - 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A live region: the turn changing is the most important
          // announcement on this screen and it happens without the player
          // touching anything.
          Semantics(
            liveRegion: true,
            label: turnLabel,
            excludeSemantics: true,
            child: _headline(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          _StepTrack(currentIndex: curIdx, stepName: _kPhaseLabels[_kPhaseOrder[curIdx]]!),
        ],
      ),
    );
  }

  Widget _headline(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.durationOf(context, AppMotion.base),
      curve: AppMotion.emphasized,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: isHeroTurn ? AppColors.goldGradient : null,
        color: isHeroTurn ? null : Colors.black.withValues(alpha: 0.42),
        border: Border.all(color: isHeroTurn ? Colors.transparent : AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: AppRadius.pillAll,
      ),
      // The line names a player, so it has to survive a long name on a narrow
      // screen rather than pushing the row off the edge.
      child: Text(
        turnLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppText.sora(
          15,
          weight: FontWeight.w800,
          letterSpacing: 0.4,
          color: isHeroTurn ? AppColors.goldInk : AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Five segments — bet, table, you, dealer, result — filling left to right.
///
/// Purely a progress read: the step's *name* is in the headline above, so
/// nothing here is carried by colour alone, and the whole track carries one
/// spoken label rather than five.
class _StepTrack extends StatelessWidget {
  final int currentIndex;
  final String stepName;

  const _StepTrack({required this.currentIndex, required this.stepName});

  static const double _height = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${currentIndex + 1} of ${_kPhaseOrder.length}, $stepName',
      excludeSemantics: true,
      child: SizedBox(
        height: _height,
        child: Row(
          children: [
            for (var i = 0; i < _kPhaseOrder.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.durationOf(context, AppMotion.base),
                  curve: AppMotion.emphasized,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.pillAll,
                    color: i == currentIndex
                        ? AppColors.gold
                        : (i < currentIndex
                              ? AppColors.gold.withValues(alpha: 0.45)
                              : AppColors.textPrimary.withValues(alpha: 0.18)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
