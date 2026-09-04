// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => '21 Sweet Pot';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSectionAccount => 'Compte';

  @override
  String get settingsSectionAvatarColor => 'Couleur de l\'avatar';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionLanguage => 'Langue';

  @override
  String get settingsSectionSoundHaptics => 'Son et vibrations';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionHelp => 'Aide';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get signingIn => 'Connexion…';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirmTitle => 'Se déconnecter ?';

  @override
  String get signOutConfirmMessage =>
      'Vos jetons et statistiques restent sur cet appareil, mais vous quittez votre groupe d\'amis et votre place au classement jusqu\'à votre prochaine connexion.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Couleur d\'avatar $index sur $total';
  }

  @override
  String get themeDefault => 'Par défaut';

  @override
  String get themeOcean => 'Océan';

  @override
  String get themeEmber => 'Braise';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'Tapis $label';
  }

  @override
  String get hapticsLabel => 'Vibrations';

  @override
  String get soundEffectsLabel => 'Effets sonores';

  @override
  String get voiceCalloutsLabel => 'Annonces vocales';

  @override
  String get voiceCalloutsSublabel =>
      'Votre total en main, les résultats et le pot annoncés à voix haute';

  @override
  String get voiceCalloutsDisabledReason =>
      'Activez les effets sonores pour utiliser les annonces vocales';

  @override
  String get notifSocialLabel => 'Social';

  @override
  String get notifSocialSublabel =>
      'Quand un ami rejoint votre groupe, se connecte ou vous dépasse';

  @override
  String get notifLeaderboardLabel => 'Classement';

  @override
  String get notifLeaderboardSublabel =>
      'Quand votre place au classement horaire ou quotidien change';

  @override
  String get notifDailyLabel => 'Rappel quotidien';

  @override
  String get notifDailySublabel =>
      'Un rappel par jour, dès que votre bonus quotidien est prêt';

  @override
  String get howToPlayLabel => 'Comment jouer';

  @override
  String get howToPlaySublabel => 'Règles, actions, gains et le pot';

  @override
  String get replayTutorialLabel => 'Revoir le tutoriel';

  @override
  String replayTutorialSublabel(int count) {
    return 'Cartes de conseils sur vos $count prochaines mains';
  }

  @override
  String get termsOfServiceLabel => 'Conditions d\'utilisation';

  @override
  String get termsOfServiceSublabel => 'Ce que vous acceptez en jouant';

  @override
  String get privacyPolicyLabel => 'Politique de confidentialité';

  @override
  String get privacyPolicySublabel =>
      'Ce qui reste sur cet appareil, et ce qui n\'y reste pas';

  @override
  String get versionLabel => 'Version';

  @override
  String get languagePickerSublabel =>
      'Les menus et la voix du croupier suivent ce choix';

  @override
  String get languageSystemDefault => 'Suivre la langue de l\'appareil';

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
