import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/utils/referrals.dart';
import 'package:flutter_test/flutter_test.dart';

Friend _friend(String id, {String? invitedBy}) => Friend(
  id: id,
  name: id,
  chips: 0,
  online: true,
  dailyScore: 0,
  hourlyScore: 0,
  invitedBy: invitedBy,
);

void main() {
  const heroUid = 'hero';

  group('referredBy / referralCount', () {
    test('ignores members with no invitedBy', () {
      final group = [_friend('a'), _friend('b')];
      expect(referredBy(group, heroUid), isEmpty);
      expect(referralCount(group, heroUid), 0);
    });

    test('ignores members invited by someone else', () {
      final group = [_friend('a', invitedBy: 'other')];
      expect(referredBy(group, heroUid), isEmpty);
    });

    test('counts members invited by the hero', () {
      final group = [
        _friend('a', invitedBy: heroUid),
        _friend('b', invitedBy: 'other'),
        _friend('c', invitedBy: heroUid),
      ];
      expect(referredBy(group, heroUid).map((f) => f.id), ['a', 'c']);
      expect(referralCount(group, heroUid), 2);
    });
  });

  group('unrewardedReferrals', () {
    test('returns every referral when nothing has been paid yet', () {
      final group = [_friend('a', invitedBy: heroUid), _friend('b', invitedBy: heroUid)];
      expect(unrewardedReferrals(group, heroUid, const []).map((f) => f.id), ['a', 'b']);
    });

    test('excludes referrals already in the rewarded list', () {
      final group = [_friend('a', invitedBy: heroUid), _friend('b', invitedBy: heroUid)];
      expect(unrewardedReferrals(group, heroUid, const ['a']).map((f) => f.id), ['b']);
    });

    test('is empty once every referral has been paid', () {
      final group = [_friend('a', invitedBy: heroUid)];
      expect(unrewardedReferrals(group, heroUid, const ['a']), isEmpty);
    });

    test('never pays a referral credited to someone else', () {
      final group = [_friend('a', invitedBy: 'other')];
      expect(unrewardedReferrals(group, heroUid, const []), isEmpty);
    });
  });
}
