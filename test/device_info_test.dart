import 'package:blackjack21_v2/utils/device_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currentPlatformName returns one of the known platform labels', () {
    const known = {'web', 'android', 'ios', 'macos', 'windows', 'linux', 'unknown'};
    expect(known, contains(currentPlatformName()));
  });
}
