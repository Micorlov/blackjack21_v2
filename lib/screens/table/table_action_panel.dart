import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../utils/table_seats.dart';
import '../../widgets/tutorial_coach_card.dart';
import 'table_betting_panel.dart';
import 'table_insurance_panel.dart';
import 'table_layout.dart';
import 'table_playing_panel.dart';
import 'table_settlement_panel.dart';
import 'table_waiting_indicator.dart';

/// Auto-height action panel: whichever phase-specific content is active, under
/// the tutorial coach card.
///
/// The phase content used to be a raw `switch`, so panels replaced each other
/// between one frame and the next and the panel's height jumped tens of pixels
/// as it did — the buttons under the player's thumb moved without warning.
/// [AnimatedSwitcher] cross-fades the content and [AnimatedSize] carries the
/// height change, both on [AppMotion.base] and both collapsing to an instant
/// swap under reduced motion.
class TableActionPanel extends ConsumerWidget {
  /// True when the panel sits in the landscape side rail rather than under the
  /// felt. The rail already owns its own padding and scrolling, and it does not
  /// touch the bottom edge, so the bottom [SafeArea] belongs to the portrait
  /// layout only.
  final bool inSideRail;

  const TableActionPanel({super.key, this.inSideRail = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final gutter = TableLayout.gutterOf(MediaQuery.sizeOf(context).width);
    final duration = AppMotion.durationOf(context, AppMotion.base);

    final content = Padding(
      padding: inSideRail
          ? const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.sm)
          // The bottom inset sits *inside* the SafeArea, so it is breathing
          // room on top of the system bar's own clearance rather than the
          // clearance itself — [AppSpacing.md] is enough, and the 8px it gives
          // back is 8px of felt on a short screen.
          : EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sits directly above whichever phase panel is active, so the advice
          // and the buttons it talks about are read as one block. Collapses to
          // nothing once the tutorial is done.
          const TutorialCoachCard(),
          AnimatedSize(
            duration: duration,
            curve: AppMotion.emphasized,
            // The panel is anchored at the bottom of the screen, so growth has
            // to push upward — animating from the top would slide the buttons
            // down under the system navigation bar mid-transition.
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: duration,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              // Bottom-aligned for the same reason, and so the outgoing panel
              // fades out from where it stood instead of jumping to centre.
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.bottomCenter, children: [...previous, ?current]),
              child: KeyedSubtree(key: ValueKey(state.phase), child: _panelFor(state)),
            ),
          ),
        ],
      ),
    );

    // `top: false` because the panel only touches the bottom edge: the shell
    // draws edge-to-edge, so without this the system navigation bar sits on
    // top of the Hit/Stand/Deal buttons and swallows their taps.
    return inSideRail ? content : SafeArea(top: false, child: content);
  }

  Widget _panelFor(GameState state) {
    return switch (state.phase) {
      RoundPhase.betting => const TableBettingPanel(),
      RoundPhase.insurance => const TableInsurancePanel(),
      RoundPhase.playing => const TablePlayingPanel(),
      RoundPhase.npcs => TableWaitingIndicator(text: '${_actingName(state)} is playing…'),
      RoundPhase.dealer => const TableWaitingIndicator(text: 'Dealer is playing…', fontSize: 19),
      RoundPhase.settlement => const TableSettlementPanel(),
    };
  }

  String _actingName(GameState state) {
    final seat = state.actingSeat;
    final seats = tableSeats(state);
    if (seat == null || seat >= seats.length) return 'Table';
    return seats[seat].firstName;
  }
}
