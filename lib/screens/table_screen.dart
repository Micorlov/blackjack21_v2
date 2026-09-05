import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_data.dart';
import '../models/enums.dart';
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
    const felt = kFelt;

    // Android Back is handled once, app-wide, in `AppShell` — it peels the
    // chat sheet and menu before leaving the table, and reaches the same
    // `exitTable` this screen's chevron calls. A second PopScope here would
    // fire alongside it and pop two layers per press.
    return DecoratedBox(
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
    );
  }

  Widget _portrait(GameState state, Size available) {
    // The bottom panel is content-sized, but its tallest variants
    // (settlement recap, chat open) would otherwise eat the whole
    // screen on short devices. Cap it and let it scroll instead, so
    // the felt always keeps a usable share of the height.
    //
    // The result card gets a larger share. It is drawn for large type and
    // scrolls from the bottom so the CTA is always in reach, which at 0.62
    // left "Dealer wins" — the one line the card exists to say — scrolled
    // off the top on a 384x832 phone. During settlement the felt is a recap
    // the card repeats, so it is the felt that gives way.
    //
    // 0.72 is measured, not guessed: the tallest result card (a dealer sweep
    // with four losing seats, a wrapped pot headline) stands 573px on that
    // phone at the 130% text the app allows, against 566 at 0.68. The phone
    // this game is played on runs a 115% system font, so this is the case
    // the player actually sees, not a corner of the sweep.
    final panelShare = state.phase == RoundPhase.settlement ? 0.72 : 0.62;
    final panelMaxHeight = available.height * panelShare;

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
