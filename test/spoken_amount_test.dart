// The pot call-out is assembled at runtime from one clip per word, so two
// things have to hold: the words must read the amount correctly, and every
// word the app can ask for must actually exist as a clip. A missing clip is
// silent at runtime — the announcement just stops — so it is checked here.

import 'dart:io';

import 'package:blackjack21_v2/services/spoken_amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('spokenAmountWords', () {
    test('reads a three-figure pot', () {
      expect(spokenAmountWords(375), ['three', 'hundred', 'seventy', 'five']);
    });

    test('reads round hundreds without a trailing zero', () {
      expect(spokenAmountWords(300), ['three', 'hundred']);
    });

    test('reads the teens as single words', () {
      expect(spokenAmountWords(15), ['fifteen']);
      expect(spokenAmountWords(115), ['one', 'hundred', 'fifteen']);
    });

    test('reads thousands, and skips empty places inside them', () {
      expect(spokenAmountWords(1000), ['one', 'thousand']);
      expect(spokenAmountWords(8250),
          ['eight', 'thousand', 'two', 'hundred', 'fifty']);
      expect(spokenAmountWords(13000), ['thirteen', 'thousand']);
      expect(spokenAmountWords(5005), ['five', 'thousand', 'five']);
    });

    test('says nothing for amounts it cannot read', () {
      expect(spokenAmountWords(0), isEmpty);
      expect(spokenAmountWords(-25), isEmpty);
      expect(spokenAmountWords(kMaxSpokenAmount + 1), isEmpty);
    });

    test('handles the largest amount it claims to support', () {
      expect(spokenAmountWords(kMaxSpokenAmount), [
        'nine', 'hundred', 'ninety', 'nine', 'thousand', //
        'nine', 'hundred', 'ninety', 'nine',
      ]);
    });
  });

  test('every word any pot amount can produce has a clip', () {
    final clips = Directory('assets/sfx/num')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.wav'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.wav', ''))
        .toSet();

    // Pot figures are always multiples of the $25 table minimum, but stepping
    // by 1 over the reachable range costs nothing and covers every word.
    final needed = <String>{'sweep_pot', 'dollars'};
    for (var amount = 1; amount <= 20000; amount++) {
      needed.addAll(spokenAmountWords(amount));
    }

    expect(clips, containsAll(needed),
        reason: 'missing clips: ${needed.difference(clips)}');
  });
}
