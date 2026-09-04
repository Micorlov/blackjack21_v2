import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/utils/table_seats.dart';

const _alice = Friend(id: 'real-1', name: 'Alice', chips: 500, online: true, dailyScore: 10, hourlyScore: 5);
const _bob = Friend(id: 'real-2', name: 'Bob', chips: 700, online: true, dailyScore: 20, hourlyScore: 8);

void main() {
  group('tableSeats', () {
    test('pads a lone real friend with 3 practice bots to reach 5 players total', () {
      final seats = tableSeats(const GameState(friends: [_alice]));

      expect(seats.length, 4, reason: 'hero + these 4 seats = 5 players in the room');
      expect(seats.first, _alice);
      expect(seats.skip(1), everyElement(isIn(kInitialFriends)));
    });

    test('pads two real friends with 2 practice bots', () {
      final seats = tableSeats(const GameState(friends: [_alice, _bob]));

      expect(seats.length, 4);
      expect(seats.take(2), [_alice, _bob]);
      expect(seats.skip(2), everyElement(isIn(kInitialFriends)));
    });

    test('never seats the same bot twice when padding', () {
      final seats = tableSeats(const GameState(friends: [_alice, _bob]));

      expect(seats.map((f) => f.id).toSet().length, seats.length);
    });

    test('four or more real friends fill every seat with no padding', () {
      final fourReal = [
        _alice,
        _bob,
        const Friend(id: 'real-3', name: 'Cara', chips: 100, online: true, dailyScore: 0, hourlyScore: 0),
        const Friend(id: 'real-4', name: 'Dev', chips: 200, online: false, dailyScore: 0, hourlyScore: 0),
      ];

      final seats = tableSeats(GameState(friends: fourReal));

      expect(seats, fourReal);
    });

    test('caps at 4 seats even with more real friends than seats', () {
      final fiveReal = [
        _alice,
        _bob,
        const Friend(id: 'real-3', name: 'Cara', chips: 100, online: true, dailyScore: 0, hourlyScore: 0),
        const Friend(id: 'real-4', name: 'Dev', chips: 200, online: false, dailyScore: 0, hourlyScore: 0),
        const Friend(id: 'real-5', name: 'Eve', chips: 300, online: false, dailyScore: 0, hourlyScore: 0),
      ];

      final seats = tableSeats(GameState(friends: fiveReal));

      expect(seats.length, 4);
      expect(seats, fiveReal.take(4).toList());
    });

    test('solo play (no real friends) still fills all 4 seats with the default bots', () {
      final seats = tableSeats(const GameState(friends: kInitialFriends));

      expect(seats, kInitialFriends);
    });

    test('a friend actually seated at this stake goes first', () {
      final stake = kTables.firstWhere((t) => t.key == 'bronze');
      final friends = [
        // Bob comes first in the roster, but Alice is the one really at this
        // table (real table presence) — she should seat before Bob.
        Friend(
          id: _bob.id,
          name: _bob.name,
          chips: _bob.chips,
          online: _bob.online,
          dailyScore: _bob.dailyScore,
          hourlyScore: _bob.hourlyScore,
          tableKey: 'vip',
        ),
        Friend(
          id: _alice.id,
          name: _alice.name,
          chips: _alice.chips,
          online: _alice.online,
          dailyScore: _alice.dailyScore,
          hourlyScore: _alice.hourlyScore,
          tableKey: 'bronze',
        ),
      ];

      final seats = tableSeats(GameState(friends: friends, stake: stake));

      expect(seats.first.id, _alice.id);
    });
  });
}
