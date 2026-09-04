import 'package:blackjack21_v2/utils/invite_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inviteUri', () {
    test('builds the single link every invite channel shares', () {
      expect(inviteUri('ABC234').toString(), 'https://blackjack21-v2.web.app/join/ABC234');
    });
  });

  group('isValidJoinCode', () {
    test('accepts a 6-character code from the alphabet', () {
      expect(isValidJoinCode('ABC234'), isTrue);
    });

    test('rejects the wrong length', () {
      expect(isValidJoinCode('ABC23'), isFalse);
      expect(isValidJoinCode('ABC2345'), isFalse);
    });

    test('rejects lookalike characters excluded from the alphabet', () {
      expect(isValidJoinCode('ABC10L'), isFalse); // 0, 1, L are excluded
      expect(isValidJoinCode('ABCIOO'), isFalse); // I, O are excluded
    });
  });

  group('joinCodeFromRoute', () {
    test('reads a path route, case-insensitively', () {
      expect(joinCodeFromRoute('/join/abc234'), 'ABC234');
    });

    test('reads a path route with a trailing query string', () {
      expect(joinCodeFromRoute('/join/ABC234?utm=whatsapp'), 'ABC234');
    });

    test('reads a bare query parameter', () {
      expect(joinCodeFromRoute('/?code=ABC234'), 'ABC234');
    });

    test('reads a full URL with a hash-routed path', () {
      expect(joinCodeFromRoute('https://blackjack21-v2.web.app/#/join/ABC234'), 'ABC234');
    });

    test('reads a full URL with a real path (path-strategy web routing)', () {
      expect(joinCodeFromRoute('https://blackjack21-v2.web.app/join/ABC234'), 'ABC234');
    });

    test('rejects a mismatched host', () {
      expect(joinCodeFromRoute('https://evil.example/join/ABC234'), isNull);
    });

    test('rejects a code of the wrong length', () {
      expect(joinCodeFromRoute('/join/ABC23'), isNull);
    });

    test('rejects a code with excluded characters', () {
      expect(joinCodeFromRoute('/join/ABC1O0'), isNull);
    });

    test('returns null for the root route', () {
      expect(joinCodeFromRoute('/'), isNull);
    });

    test('returns null for an unparsable route', () {
      expect(joinCodeFromRoute(''), isNull);
    });
  });

  group('joinCodeFromText', () {
    test('finds a code inside a link surrounded by other text', () {
      const text = '🃏 Play 21 Sweet Pot with me — tap to join my table:\n'
          'https://blackjack21-v2.web.app/join/ABC234';
      expect(joinCodeFromText(text), 'ABC234');
    });

    test('finds a code inside non-Latin surrounding text', () {
      const text = 'בואו לשחק: https://blackjack21-v2.web.app/join/ABC234 תודה!';
      expect(joinCodeFromText(text), 'ABC234');
    });

    test('accepts a bare code typed or pasted by hand', () {
      expect(joinCodeFromText('  abc234  '), 'ABC234');
    });

    test('returns null for text with no code', () {
      expect(joinCodeFromText('hello world'), isNull);
    });

    test('returns null for empty text', () {
      expect(joinCodeFromText(''), isNull);
    });
  });
}
