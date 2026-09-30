import 'package:blackjack21_v2/services/error_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('truncateForReport', () {
    test('returns the original string when under the limit', () {
      expect(truncateForReport('short', 10), 'short');
    });

    test('cuts to exactly max characters when over the limit', () {
      expect(truncateForReport('0123456789', 5), '01234');
    });

    test('returns an empty string unchanged', () {
      expect(truncateForReport('', 10), '');
    });
  });

  group('ErrorReporter', () {
    test('reportFatal is a no-op with no Firestore instance', () async {
      final reporter = ErrorReporter(appVersion: '1.0.0+1', platform: 'android');
      await expectLater(reporter.reportFatal(Exception('boom'), StackTrace.current), completes);
    });

    test('reportInstall is a no-op with no Firestore instance', () async {
      final reporter = ErrorReporter(appVersion: '1.0.0+1', platform: 'android');
      await expectLater(reporter.reportInstall(), completes);
    });
  });
}
