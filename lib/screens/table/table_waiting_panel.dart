import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_spacing.dart';
import 'standings_mini_table.dart';
import 'table_waiting_indicator.dart';

/// What the action panel shows while the other seats, and then the dealer,
/// play their hands.
///
/// This stretch of the round used to be a single pulsing line of text over a
/// third of an empty screen — the player's only job was to wait, and the app
/// gave them nothing to look at while they did. The friends standings live
/// here instead: the hourly race is the one thing a player genuinely wants to
/// check between decisions, and this is the only part of the hand where
/// checking it costs nothing.
class TableWaitingPanel extends StatelessWidget {
  final GameState state;
  final GameNotifier notifier;
  final String text;

  /// Larger for the dealer's turn, matching the previous indicator sizing.
  final double fontSize;

  const TableWaitingPanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.text,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TableWaitingIndicator(text: text, fontSize: fontSize),
        // Only once there are real people to race. With bots-only seats the
        // card used to fill this space with invented world standings.
        if (state.friendsAreLive) ...[
          const SizedBox(height: AppSpacing.sm),
          StandingsMiniTable(state: state, notifier: notifier),
        ],
      ],
    );
  }
}
