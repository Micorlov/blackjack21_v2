import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/game_state.dart';
import '../state/game_notifier.dart';
import 'table/table_action_panel.dart';
import 'table/table_chat_panel.dart';
import 'table/table_felt.dart';
import 'table/table_header.dart';
import 'table/table_layout.dart';
import 'table/table_phase_banner.dart';

/// The blackjack table screen: header, phase banner, the felt (dealer +
/// friend seats + hero hand), and an action panel that switches by
/// `state.phase`.
///
/// Two arrangements, chosen from the box we are actually given rather than
/// from the device's reported orientation:
///
/// * **Portrait** — a fixed-height column, deliberately not scrollable, with
///   the felt as the only flexible section and the action panel across the
///   bottom.
/// * **Landscape** — the felt keeps the full height and the action panel moves
///   into a side rail. Stacking them the portrait way in a 412pt-tall window
///   leaves the felt about 150pt to draw a table in.
///
/// Consumes the existing [gameProvider] notifier/state; the app shell (bottom
/// nav, toasts, reaction overlay) is hidden on this screen and handled
/// elsewhere.
class TableScreen extends ConsumerWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    // The Appearance/Table-felt choice restyles the whole table, not just
    // the swatch: this background plus the felt ellipse in TableFelt.
    final felt = feltById(state.themeChoice);

    return PopScope(
      // Navigation here is an enum on the state, not a `Navigator` stack, so
      // there is nothing for the framework to pop: without this, Android Back
      // from the table quit the app outright. Back now peels off one layer at
      // a time — chat sheet, then menu, then the table itself — and reaches
      // the same `exitTable` the header's chevron calls, so the round's timers
      // are cancelled either way.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.tableChatOpen) {
          notifier.toggleTableChat();
          return;
        }
        if (state.tableMenuOpen) {
          notifier.toggleTableMenu();
          return;
        }
        notifier.exitTable();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: felt.tableGradient),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.biggest;
            final landscape = TableLayout.isLandscape(available);

            return Stack(
              children: [
                landscape ? _landscape(state, available) : _portrait(state, available),
                if (state.tableMenuOpen) const TableMenuDropdown(),
                if (state.tableChatOpen) const TableChatSheet(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _portrait(GameState state, Size available) {
    // The bottom panel is content-sized, but its tallest variants
    // (settlement recap, chat open) would otherwise eat the whole
    // screen on short devices. Cap it and let it scroll instead, so
    // the felt always keeps a usable share of the height.
    final panelMaxHeight = available.height * 0.62;

    return Column(
      children: [
        const TableHeader(),
        TablePhaseBanner.fromState(state),
        const Expanded(child: TableFelt()),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: panelMaxHeight),
          child: const SingleChildScrollView(reverse: true, child: TableActionPanel()),
        ),
      ],
    );
  }

  /// Felt on the left at full height, controls in a rail on the right.
  ///
  /// The rail scrolls on its own because the settlement recap is much taller
  /// than a landscape phone, and it carries a bottom [SafeArea] of its own so
  /// the last button clears the system navigation bar.
  Widget _landscape(GameState state, Size available) {
    final rail = TableLayout.railWidthOf(available.width);
    final gutter = TableLayout.gutterOf(available.width);

    return Column(
      children: [
        const TableHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TablePhaseBanner.fromState(state),
                    const Expanded(child: TableFelt()),
                  ],
                ),
              ),
              SizedBox(
                width: rail,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, gutter, 0),
                    child: SingleChildScrollView(child: TableActionPanel(inSideRail: true)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
