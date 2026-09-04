// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => '21 Sweet Pot';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionAccount => 'Konto';

  @override
  String get settingsSectionAvatarColor => 'Avatarfarbe';

  @override
  String get settingsSectionAppearance => 'Erscheinungsbild';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsSectionSoundHaptics => 'Ton & Vibration';

  @override
  String get settingsSectionNotifications => 'Benachrichtigungen';

  @override
  String get settingsSectionHelp => 'Hilfe';

  @override
  String get settingsSectionAbout => 'Über';

  @override
  String get signingIn => 'Anmelden…';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutConfirmTitle => 'Abmelden?';

  @override
  String get signOutConfirmMessage =>
      'Deine Chips und Statistiken bleiben auf diesem Gerät, aber du verlässt deine Freundesgruppe und deinen Platz in der Bestenliste, bis du dich wieder anmeldest.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Avatarfarbe $index von $total';
  }

  @override
  String get themeDefault => 'Standard';

  @override
  String get themeOcean => 'Ozean';

  @override
  String get themeEmber => 'Glut';

  @override
  String themeFeltSemanticLabel(String label) {
    return '$label-Tischfilz';
  }

  @override
  String get hapticsLabel => 'Vibration';

  @override
  String get soundEffectsLabel => 'Soundeffekte';

  @override
  String get voiceCalloutsLabel => 'Sprachansagen';

  @override
  String get voiceCalloutsSublabel =>
      'Deine Handsumme, Ergebnisse und der Sweep-Pot werden laut angesagt';

  @override
  String get voiceCalloutsDisabledReason =>
      'Aktiviere Soundeffekte, um Sprachansagen zu nutzen';

  @override
  String get notifSocialLabel => 'Sozial';

  @override
  String get notifSocialSublabel =>
      'Wenn ein Freund deiner Gruppe beitritt, online geht oder dich überholt';

  @override
  String get notifLeaderboardLabel => 'Bestenliste';

  @override
  String get notifLeaderboardSublabel =>
      'Wenn sich dein Platz in der Stunden- oder Tagesliste ändert';

  @override
  String get notifDailyLabel => 'Tägliche Erinnerung';

  @override
  String get notifDailySublabel =>
      'Ein Hinweis pro Tag, sobald dein täglicher Bonus bereit ist';

  @override
  String get howToPlayLabel => 'Spielanleitung';

  @override
  String get howToPlaySublabel =>
      'Regeln, Aktionen, Auszahlungen und der Sweep-Pot';

  @override
  String get replayTutorialLabel => 'Tutorial wiederholen';

  @override
  String replayTutorialSublabel(int count) {
    return 'Hinweiskarten für deine nächsten $count Hände';
  }

  @override
  String get termsOfServiceLabel => 'Nutzungsbedingungen';

  @override
  String get termsOfServiceSublabel => 'Was du beim Spielen akzeptierst';

  @override
  String get privacyPolicyLabel => 'Datenschutzrichtlinie';

  @override
  String get privacyPolicySublabel =>
      'Was auf diesem Gerät bleibt und was nicht';

  @override
  String get versionLabel => 'Version';

  @override
  String get languagePickerSublabel =>
      'Menüs und die Stimme des Dealers folgen dieser Auswahl';

  @override
  String get languageSystemDefault => 'Gerätesprache verwenden';

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
    return '🃏 Play 21 Sweet Pot with me — tap to join my table:\n$url';
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
