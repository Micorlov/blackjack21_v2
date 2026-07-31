/// Reads a whole-dollar amount out as the words that say it.
///
/// Pot figures are arbitrary multiples of the table minimum, so there is no
/// fixed set of amounts to pre-record. Instead each number word is its own
/// clip under `assets/sfx/num/` and the app joins them — this decides which
/// clips, in what order.
library;

/// Words for 0-19, indexed by the number itself. Index 0 is unused: a zero
/// never reaches this list, since [spokenAmountWords] drops empty places.
const List<String> _ones = [
  '',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];

/// Words for 20, 30, … 90, indexed by the tens digit.
const List<String> _tens = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

/// The largest amount that can be spoken. There is no "million" clip, and the
/// biggest pot the game can build is far below this: the VIP table's $5000 max
/// hero bet plus four seats betting 4× a $500 minimum comes to $13,000.
const int kMaxSpokenAmount = 999999;

/// The words that read [amount] aloud, e.g. 375 -> three, hundred, seventy,
/// five. Each entry is the basename of a clip in `assets/sfx/num/`.
///
/// Returns an empty list for amounts that cannot be spoken — zero, negatives,
/// and anything above [kMaxSpokenAmount] — so callers can skip the call-out
/// rather than announce a wrong figure.
List<String> spokenAmountWords(int amount) {
  if (amount <= 0 || amount > kMaxSpokenAmount) return const [];

  final words = <String>[];
  final thousands = amount ~/ 1000;
  if (thousands > 0) {
    words
      ..addAll(_underThousand(thousands))
      ..add('thousand');
  }
  words.addAll(_underThousand(amount % 1000));
  return words;
}

/// The words for 0-999. An empty list for 0, so $3000 reads as "three
/// thousand" rather than trailing into a spoken zero.
List<String> _underThousand(int n) {
  final words = <String>[];
  var rest = n;

  if (rest >= 100) {
    words
      ..add(_ones[rest ~/ 100])
      ..add('hundred');
    rest %= 100;
  }

  if (rest >= 20) {
    words.add(_tens[rest ~/ 10]);
    rest %= 10;
    if (rest > 0) words.add(_ones[rest]);
  } else if (rest > 0) {
    words.add(_ones[rest]);
  }

  return words;
}
