import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/utils/comeback.dart';
import 'package:flutter_test/flutter_test.dart';

PlayingCard c(String rank) => PlayingCard(rank: rank, suit: '♠');

void main() {
  group('startingHandScore', () {
    test('a natural blackjack beats any other total', () {
      expect(startingHandScore([c('A'), c('K')]), greaterThan(startingHandScore([c('10'), c('10')])));
    });

    test('higher totals score higher', () {
      expect(startingHandScore([c('10'), c('9')]), greaterThan(startingHandScore([c('10'), c('6')])));
    });
  });

  group('drawStartingPair', () {
    test('tries: 1 deals the top two cards exactly like a fair deal', () {
      // Shoe top is the END of the list (removeLast draws).
      final shoe = [c('2'), c('3'), c('9'), c('K')];
      final pair = drawStartingPair(shoe, tries: 1);
      expect(pair, [c('K'), c('9')]);
      expect(shoe, [c('2'), c('3')]);
    });

    test('a comeback deal picks the best of the candidate pairs', () {
      // Bottom→top: 4,5 | 10,9 | 2,7 → candidate pairs from the top are
      // (7,2)=9, (9,10)=19, (5,4)=9; tries: 3 picks the 19.
      final shoe = [c('4'), c('5'), c('10'), c('9'), c('2'), c('7')];
      final pair = drawStartingPair(shoe, tries: 3);
      expect(BlackjackRules.handValue(pair), 19);
      // The skipped candidates stay in the shoe, order preserved.
      expect(shoe, [c('4'), c('5'), c('2'), c('7')]);
    });

    test('a natural blackjack wins over a higher-count pair further down', () {
      final shoe = [c('A'), c('K'), c('10'), c('9')];
      final pair = drawStartingPair(shoe, tries: 2);
      expect(BlackjackRules.handValue(pair), 21);
      expect(shoe, [c('10'), c('9')]);
    });

    test('never asks for more pairs than the shoe holds', () {
      final shoe = [c('5'), c('9')];
      final pair = drawStartingPair(shoe, tries: 3);
      expect(pair.length, 2);
      expect(shoe, isEmpty);
    });
  });
}
