import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../state/game_notifier.dart';
import 'table/table_action_panel.dart';
import 'table/table_chat_panel.dart';
import 'table/table_felt.dart';
import 'table/table_header.dart';
import 'table/table_phase_steps.dart';

/// The blackjack table screen: header, phase-step pills, the felt (dealer +
/// friend seats + hero hand), and a bottom action panel that switches by
/// `state.phase`. A fixed-height `Column` — deliberately not scrollable —
/// with the felt as the only flexible section. Consumes the existing
/// [gameProvider] notifier/state; the app shell (bottom nav, toasts,
/// reaction overlay) is hidden on this screen and handled elsewhere.
class TableScreen extends ConsumerWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    // The Appearance/Table-felt choice restyles the whole table, not just
    // the swatch: this background plus the felt ellipse in TableFelt.
    final felt = feltById(state.themeChoice);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: felt.tableGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The bottom panel is content-sized, but its tallest variants
          // (settlement recap, chat open) would otherwise eat the whole
          // screen on short devices. Cap it and let it scroll instead, so
          // the felt always keeps a usable share of the height.
          final panelMaxHeight = constraints.maxHeight * 0.62;

          return Stack(
            children: [
              Column(
                children: [
                  const TableHeader(),
                  TablePhaseSteps(phase: state.phase),
                  const Expanded(child: TableFelt()),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: panelMaxHeight),
                    child: const SingleChildScrollView(reverse: true, child: TableActionPanel()),
                  ),
                ],
              ),
              if (state.tableMenuOpen) const TableMenuDropdown(),
              if (state.tableChatOpen) const TableChatSheet(),
            ],
          );
        },
      ),
    );
  }
}
