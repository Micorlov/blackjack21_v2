import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../utils/table_seats.dart';
import '../../widgets/tutorial_coach_card.dart';
import 'table_betting_panel.dart';
import 'table_insurance_panel.dart';
import 'table_playing_panel.dart';
import 'table_settlement_panel.dart';
import 'table_waiting_indicator.dart';

/// Fixed (auto-height, non-scrolling) bottom panel. The chat panel — when
/// open — stacks above whichever phase-specific content is active, mirroring
/// the source design where `tableChatOpen` is an independent overlay rather
/// than a phase of its own.
class TableActionPanel extends ConsumerWidget {
  const TableActionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);

    // `top: false` because the panel only touches the bottom edge: the shell
    // draws edge-to-edge, so without this the system navigation bar sits on
    // top of the Hit/Stand/Deal buttons and swallows their taps.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sits directly above whichever phase panel is active, so the advice
            // and the buttons it talks about are read as one block. Collapses to
            // nothing once the tutorial is done.
            const TutorialCoachCard(),
            switch (state.phase) {
              RoundPhase.betting => const TableBettingPanel(),
              RoundPhase.insurance => const TableInsurancePanel(),
              RoundPhase.playing => const TablePlayingPanel(),
              RoundPhase.npcs => TableWaitingIndicator(text: '${_actingName(state)} is playing…'),
              RoundPhase.dealer => const TableWaitingIndicator(text: 'Dealer is playing…', fontSize: 19),
              RoundPhase.settlement => const TableSettlementPanel(),
            },
          ],
        ),
      ),
    );
  }

  String _actingName(GameState state) {
    final seat = state.actingSeat;
    final seats = tableSeats(state);
    if (seat == null || seat >= seats.length) return 'Table';
    return seats[seat].firstName;
  }
}
