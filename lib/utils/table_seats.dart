import '../data/game_data.dart';
import '../models/game_state.dart';
import '../models/social_models.dart';

/// The 4 opponents seated at the table for the current round.
///
/// [GameState.friends] is the *real* friends-group roster and must stay
/// exactly that for the friends screen, rank strip, and leaderboards — this
/// function never feeds those. It only answers "who is sitting in the 4
/// opponent seats right now": real friends fill seats first, and if fewer
/// than 4 are in the group, practice bots (skipping any already seated) pad
/// the rest so the room never looks sparse with just one or two friends
/// online. More than 4 real friends still only occupy the 4 physical seats.
List<Friend> tableSeats(GameState state) {
  final real = state.friends;
  if (real.length >= 4) return real.take(4).toList();
  final seatedIds = real.map((f) => f.id).toSet();
  final filler = kInitialFriends.where((f) => !seatedIds.contains(f.id));
  return [...real, ...filler].take(4).toList();
}
