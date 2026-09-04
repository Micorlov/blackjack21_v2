import '../data/game_data.dart';
import '../models/social_models.dart';

/// The table the lobby points the player at: the highest stake their bankroll
/// can actually sit down at with room for more than one hand.
///
/// The lobby listed three tables in identical grey cards and left the choice
/// entirely to the player, including the choice to walk into the VIP table
/// with $80 and be unable to place a legal bet. This picks the obvious one so
/// the screen can carry a single, honest primary action.
///
/// "Room for more than one hand" is the [_handsOfHeadroom] multiple: a stack
/// worth exactly one minimum bet at a table is not really a seat there.
TableStake recommendedTable(int chips) {
  const handsOfHeadroom = 4;
  TableStake best = kTables.first;
  for (final t in kTables) {
    if (chips >= t.min * handsOfHeadroom) best = t;
  }
  return best;
}
