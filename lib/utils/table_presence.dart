/// Pure "who is actually at this table right now" logic, replacing the old
/// hardcoded `tableFriendsHereLabel` strings in `data/game_data.dart`.
///
/// A friend counts as present only once their row is both online (5-minute
/// freshness window, applied in `SocialService._friendFromDoc`) and seated
/// at this table — both folded into `Friend.tableKey` being non-null and
/// matching, so callers here never have to reason about staleness.
library;

import '../models/social_models.dart';

/// The members of [friends] currently seated at [tableKey] (`'bronze'`,
/// `'silver'`, `'vip'`). Always empty for the practice-bot roster, since
/// bots never carry a `tableKey`.
List<Friend> friendsAtTable(List<Friend> friends, String tableKey) =>
    friends.where((f) => f.tableKey == tableKey).toList();

/// Short label for a table card: `''`, `'Maya is here'`,
/// `'Maya & Jordan are here'`, `'Maya, Jordan +1 here'`.
String tablePresenceLabel(List<Friend> here) {
  if (here.isEmpty) return '';
  if (here.length == 1) return '${here.first.firstName} is here';
  if (here.length == 2) return '${here[0].firstName} & ${here[1].firstName} are here';
  return '${here[0].firstName}, ${here[1].firstName} +${here.length - 2} here';
}

/// Call-to-action pill for a table card: `''`, `'Join Maya'`,
/// `'Join 2 friends'`.
String tablePresenceCta(List<Friend> here) {
  if (here.isEmpty) return '';
  if (here.length == 1) return 'Join ${here.first.firstName}';
  return 'Join ${here.length} friends';
}
