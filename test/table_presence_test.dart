import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/utils/table_presence.dart';
import 'package:flutter_test/flutter_test.dart';

Friend _friend(String name, {String? tableKey}) =>
    Friend(id: name, name: name, chips: 0, online: true, dailyScore: 0, hourlyScore: 0, tableKey: tableKey);

void main() {
  group('friendsAtTable', () {
    test('is empty when no friend carries a tableKey', () {
      final friends = [_friend('Maya'), _friend('Jordan')];
      expect(friendsAtTable(friends, 'bronze'), isEmpty);
    });

    test('filters to friends seated at the given table', () {
      final friends = [_friend('Maya', tableKey: 'bronze'), _friend('Jordan', tableKey: 'vip')];
      expect(friendsAtTable(friends, 'bronze').map((f) => f.name), ['Maya']);
    });

    test('a friend whose row is stale never counts (tableKey is already null)', () {
      // SocialService._friendFromDoc nulls out tableKey once a row goes
      // stale — this just confirms the pure function trusts that mapping.
      final friends = [_friend('Maya')];
      expect(friendsAtTable(friends, 'bronze'), isEmpty);
    });
  });

  group('tablePresenceLabel', () {
    test('is empty with nobody here', () {
      expect(tablePresenceLabel(const []), '');
    });

    test('names the one friend here', () {
      expect(tablePresenceLabel([_friend('Maya T.')]), 'Maya is here');
    });

    test('names both friends here', () {
      expect(tablePresenceLabel([_friend('Maya T.'), _friend('Jordan K.')]), 'Maya & Jordan are here');
    });

    test('names two and counts the rest', () {
      final here = [_friend('Maya T.'), _friend('Jordan K.'), _friend('Sam R.'), _friend('Priya N.')];
      expect(tablePresenceLabel(here), 'Maya, Jordan +2 here');
    });
  });

  group('tablePresenceCta', () {
    test('is empty with nobody here', () {
      expect(tablePresenceCta(const []), '');
    });

    test('names the one friend to join', () {
      expect(tablePresenceCta([_friend('Maya T.')]), 'Join Maya');
    });

    test('counts friends to join', () {
      expect(tablePresenceCta([_friend('Maya T.'), _friend('Jordan K.')]), 'Join 2 friends');
    });
  });
}
