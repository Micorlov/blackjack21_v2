// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionAvatarColor => 'Avatar color';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionSoundHaptics => 'Sound & haptics';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionHelp => 'Help';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmMessage =>
      'Your chips and stats stay on this device, but you leave your friends group and your leaderboard entry until you sign back in.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Avatar colour $index of $total';
  }

  @override
  String get themeDefault => 'Default';

  @override
  String get themeOcean => 'Ocean';

  @override
  String get themeEmber => 'Ember';

  @override
  String themeFeltSemanticLabel(String label) {
    return '$label table felt';
  }

  @override
  String get hapticsLabel => 'Haptics';

  @override
  String get soundEffectsLabel => 'Sound effects';

  @override
  String get voiceCalloutsLabel => 'Voice call-outs';

  @override
  String get voiceCalloutsSublabel =>
      'Your hand total, results and the sweep pot, spoken aloud';

  @override
  String get voiceCalloutsDisabledReason =>
      'Turn sound effects on to use voice call-outs';

  @override
  String get notifSocialLabel => 'Social';

  @override
  String get notifSocialSublabel =>
      'When a friend joins your group, comes online or passes you';

  @override
  String get notifLeaderboardLabel => 'Leaderboard';

  @override
  String get notifLeaderboardSublabel =>
      'When your place on the hourly or daily board changes';

  @override
  String get notifDailyLabel => 'Daily reminder';

  @override
  String get notifDailySublabel =>
      'One nudge a day, once your daily bonus is ready to claim';

  @override
  String get howToPlayLabel => 'How to play';

  @override
  String get howToPlaySublabel => 'Rules, moves, payouts and the sweep pot';

  @override
  String get replayTutorialLabel => 'Replay the tutorial';

  @override
  String replayTutorialSublabel(int count) {
    return 'Coaching cards on your next $count hands';
  }

  @override
  String get termsOfServiceLabel => 'Terms of Service';

  @override
  String get termsOfServiceSublabel => 'What you agree to by playing';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get privacyPolicySublabel =>
      'What stays on this device, and what does not';

  @override
  String get versionLabel => 'Version';

  @override
  String get languagePickerSublabel =>
      'Menus and the dealer\'s voice both follow this';

  @override
  String get languageSystemDefault => 'Match device language';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameEs => 'Español';

  @override
  String get languageNameFr => 'Français';

  @override
  String get languageNameDe => 'Deutsch';

  @override
  String get languageNamePt => 'Português';

  @override
  String get languageNameRu => 'Русский';

  @override
  String get languageNameZh => '中文';

  @override
  String get languageNameJa => '日本語';

  @override
  String get languageNameHe => 'עברית';

  @override
  String get languageNameAr => 'العربية';

  @override
  String rebuyButtonLabel(int chips) {
    return 'Rebuy $chips chips';
  }

  @override
  String rebuyReadyInLabel(String time) {
    return 'Rebuy in $time';
  }

  @override
  String get rebuyHint => 'Or claim your daily bonus in the lobby';

  @override
  String inviteMessage(String url) {
    return '🃏 Play Blackjack 21 with me — tap to join my table:\n$url';
  }

  @override
  String get inviteSubtitle =>
      'Send friends your link — anyone who taps it lands on your live leaderboard.';

  @override
  String get inviteButtonWhatsApp => 'Invite via WhatsApp';

  @override
  String get inviteButtonShare => 'Share link';

  @override
  String get inviteCopyLink => 'Copy link';

  @override
  String joinedTableToast(int chips) {
    return 'Joined the table — +$chips welcome chips!';
  }

  @override
  String get joinAlreadyMemberToast => 'Back at your friends\' table';

  @override
  String get joinOwnTableToast => 'This is your own table';

  @override
  String get webInstallBanner => 'Playing in the browser — get the Android app';

  @override
  String get webInstallButton => 'Get it on Google Play';
}
