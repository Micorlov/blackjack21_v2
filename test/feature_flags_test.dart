import 'package:blackjack21_v2/services/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureFlags', () {
    test('defaults every flag to enabled before load', () {
      final flags = FeatureFlags();
      expect(flags.isEnabled(FeatureFlag.reviewPrompt), isTrue);
      expect(flags.isEnabled(FeatureFlag.referralRewards), isTrue);
      expect(flags.isEnabled('somethingNobodyDefined'), isTrue);
    });

    test('applyRemoteConfig turns an explicit false into disabled', () {
      final flags = FeatureFlags();
      flags.applyRemoteConfig({FeatureFlag.reviewPrompt: false});
      expect(flags.isEnabled(FeatureFlag.reviewPrompt), isFalse);
      // Untouched flags stay enabled — this is a kill switch, not a whitelist.
      expect(flags.isEnabled(FeatureFlag.referralRewards), isTrue);
    });

    test('applyRemoteConfig treats any non-true value as disabled', () {
      final flags = FeatureFlags();
      flags.applyRemoteConfig({FeatureFlag.reviewPrompt: 'nope'});
      expect(flags.isEnabled(FeatureFlag.reviewPrompt), isFalse);
    });

    test('applyRemoteConfig with null data leaves defaults untouched', () {
      final flags = FeatureFlags();
      flags.applyRemoteConfig(null);
      expect(flags.isEnabled(FeatureFlag.reviewPrompt), isTrue);
    });

    test('load is a no-op with no Firestore instance', () async {
      final flags = FeatureFlags();
      await flags.load();
      expect(flags.isEnabled(FeatureFlag.reviewPrompt), isTrue);
    });
  });
}
