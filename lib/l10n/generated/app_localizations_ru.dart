// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionAccount => 'Аккаунт';

  @override
  String get settingsSectionAvatarColor => 'Цвет аватара';

  @override
  String get settingsSectionAppearance => 'Оформление';

  @override
  String get settingsSectionLanguage => 'Язык';

  @override
  String get settingsSectionSoundHaptics => 'Звук и вибрация';

  @override
  String get settingsSectionNotifications => 'Уведомления';

  @override
  String get settingsSectionHelp => 'Помощь';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get signingIn => 'Вход…';

  @override
  String get signIn => 'Войти';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutConfirmTitle => 'Выйти из аккаунта?';

  @override
  String get signOutConfirmMessage =>
      'Ваши фишки и статистика останутся на этом устройстве, но вы покинете группу друзей и своё место в рейтинге до следующего входа.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Цвет аватара $index из $total';
  }

  @override
  String get themeDefault => 'Стандартный';

  @override
  String get themeOcean => 'Океан';

  @override
  String get themeEmber => 'Уголь';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'Сукно стола «$label»';
  }

  @override
  String get hapticsLabel => 'Вибрация';

  @override
  String get soundEffectsLabel => 'Звуковые эффекты';

  @override
  String get voiceCalloutsLabel => 'Голосовые объявления';

  @override
  String get voiceCalloutsSublabel =>
      'Сумма ваших карт, результаты и общий банк озвучиваются вслух';

  @override
  String get voiceCalloutsDisabledReason =>
      'Включите звуковые эффекты, чтобы использовать голосовые объявления';

  @override
  String get notifSocialLabel => 'Социальные';

  @override
  String get notifSocialSublabel =>
      'Когда друг присоединяется к группе, выходит в сеть или обгоняет вас';

  @override
  String get notifLeaderboardLabel => 'Рейтинг';

  @override
  String get notifLeaderboardSublabel =>
      'Когда меняется ваше место в почасовом или дневном рейтинге';

  @override
  String get notifDailyLabel => 'Ежедневное напоминание';

  @override
  String get notifDailySublabel =>
      'Одно напоминание в день, когда готов ежедневный бонус';

  @override
  String get howToPlayLabel => 'Как играть';

  @override
  String get howToPlaySublabel => 'Правила, ходы, выплаты и общий банк';

  @override
  String get replayTutorialLabel => 'Повторить обучение';

  @override
  String replayTutorialSublabel(int count) {
    return 'Подсказки на следующие $count раздачи';
  }

  @override
  String get termsOfServiceLabel => 'Условия использования';

  @override
  String get termsOfServiceSublabel => 'Что вы принимаете, играя в игру';

  @override
  String get privacyPolicyLabel => 'Политика конфиденциальности';

  @override
  String get privacyPolicySublabel =>
      'Что остаётся на этом устройстве, а что нет';

  @override
  String get versionLabel => 'Версия';

  @override
  String get languagePickerSublabel =>
      'Меню и голос дилера следуют этому выбору';

  @override
  String get languageSystemDefault => 'Как в системе устройства';

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
