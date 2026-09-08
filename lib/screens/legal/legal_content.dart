/// The Terms of Service and Privacy Policy the app actually shows.
///
/// Onboarding asserted "By continuing you agree to the Terms & Privacy Policy"
/// as plain, untappable text, and no Terms or Privacy destination existed
/// anywhere in the app — a store-compliance problem as much as a trust one.
///
/// The copy lives in the binary rather than behind a URL on purpose: the
/// consent line is on the very first screen, before sign-in and before the
/// player has any connection guarantee, so the documents have to open offline.
///
/// Everything below describes what this build genuinely does. When behaviour
/// changes — a real payment provider, an ad network, an analytics SDK — this
/// file changes in the same commit.
library;

class LegalSection {
  final String heading;
  final String body;

  const LegalSection(this.heading, this.body);
}

class LegalDoc {
  final String title;

  /// Shown under the title so a player can see how current the document is.
  final String updated;
  final String intro;
  final List<LegalSection> sections;

  const LegalDoc({required this.title, required this.updated, required this.intro, required this.sections});
}

/// Keep in step with `version:` in `pubspec.yaml` — this is what the Settings
/// "About" row shows, and a stale number here makes a bug report unactionable.
const String kAppVersionLabel = '1.6.0 (7)';

const String kAppName = 'Blackjack 21';

/// How to reach the developer. Deliberately not an email address: the Play
/// listing is the contact channel that is guaranteed to exist for this app.
const String kContactLine =
    'Questions about these terms or your data go to the developer via the app\'s Google Play listing.';

const LegalDoc kTermsDoc = LegalDoc(
  title: 'Terms of Service',
  updated: 'Last updated 3 September 2026',
  intro:
      '$kAppName is a free social card game. Playing it means accepting the terms below. '
      'They are written plainly on purpose — there is nothing hidden in them.',
  sections: [
    LegalSection(
      'This is a game, not gambling',
      'Chips in $kAppName are play money. They have no cash value, they cannot be withdrawn, '
          'exchanged, transferred outside the game or redeemed for anything of real value, and no '
          'real-money wager is ever placed. Success here does not predict success at real gambling.',
    ),
    LegalSection(
      'Rewards',
      'The daily bonus, the table rebuy and referral rewards all grant play chips inside the game. '
          'There is nothing to buy: no money changes hands and no payment details are collected. If '
          'that ever changes, prices and terms will be shown before anything is charged.',
    ),
    LegalSection(
      'Your account',
      'You can play as a guest, in which case your progress stays on this device only. Signing in '
          'with Google creates an account so your score can appear on your friends group\'s '
          'leaderboard across devices. You are responsible for keeping access to your Google '
          'account secure.',
    ),
    LegalSection(
      'Friends groups',
      'A friends group is a six-character code you choose to share. Anyone who enters your code '
          'joins your group and can see the display name and scores you post to it. Share it only '
          'with people you want in your game.',
    ),
    LegalSection(
      'Fair play',
      'Do not modify the app, automate play, or tamper with saved data to manufacture chips or '
          'leaderboard positions. Accounts doing so may have their chips, scores or group '
          'membership reset.',
    ),
    LegalSection(
      'Availability',
      'The game is provided as it is, without a guarantee that it will be available, uninterrupted '
          'or free of faults. Features may change or be withdrawn, and online play depends on '
          'services outside our control.',
    ),
    LegalSection('Who can play', 'The game simulates casino play and is intended for adults aged 18 and over.'),
    LegalSection('Contact', kContactLine),
  ],
);

const LegalDoc kPrivacyDoc = LegalDoc(
  title: 'Privacy Policy',
  updated: 'Last updated 5 September 2026',
  intro:
      'The short version: $kAppName keeps your game on your device, and only sends anything to a '
      'server when you sign in, join a friends group, or — unless you turn it off — report an '
      'anonymous count of what happened in a hand. There are no ads and no third-party trackers.',
  sections: [
    LegalSection(
      'What stays on your device',
      'Your chips, statistics, hand history, unlocked cosmetics and every setting are stored in the '
          'app\'s own storage on this device. Playing as a guest sends none of it anywhere. '
          'Uninstalling the app removes it.',
    ),
    LegalSection(
      'What signing in shares',
      'Signing in with Google passes your Google display name, profile photo and account '
          'identifier to Firebase Authentication so the game can recognise you. No password ever '
          'reaches this app.',
    ),
    LegalSection(
      'What a friends group shares',
      'Joining or creating a group stores your display name, your group code and your current '
          'hourly, daily and all-time scores so the group\'s leaderboard can be assembled. Everyone '
          'holding the code can see those entries. Nothing else about your play is uploaded.',
    ),
    LegalSection(
      'Notifications',
      'Notifications are scheduled on your device — a daily-bonus reminder and friends-group '
          'activity. They are not sent from a server, and you can turn each type off in Settings or '
          'revoke the permission entirely in your system settings.',
    ),
    LegalSection(
      'Usage and crash reports',
      'The app reports anonymous counts of what happens in the game — hands played and their '
          'result, daily bonuses claimed, missions and achievements completed, levels reached, '
          'which screens are opened — and sends a report when it crashes, through Google Firebase '
          'Analytics and Crashlytics. These carry no display name, no group code, no account '
          'identifier and nothing you type. Turn the whole thing off under Privacy in Settings and '
          'nothing further is collected.',
    ),
    LegalSection(
      'No advertising',
      'This build contains no advertising SDK and no third-party trackers. No ad is ever loaded '
          'and no ad network sees you.',
    ),
    LegalSection(
      'Location',
      'The flags shown beside leaderboard names are decorative. They are derived from a player '
          'identifier, not from any location. The app never requests or stores location data.',
    ),
    LegalSection(
      'Removing your data',
      'Signing out clears your account details from this device. To have your leaderboard entries '
          'removed from a friends group, ask the group to drop your code or contact the developer.',
    ),
    LegalSection('Children', 'The game is intended for adults aged 18 and over and is not directed at children.'),
    LegalSection(
      'Changes',
      'If this policy changes, the updated date at the top of this page changes with it, and the '
          'new version ships inside the app.',
    ),
    LegalSection('Contact', kContactLine),
  ],
);
