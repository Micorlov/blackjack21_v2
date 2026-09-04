// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '21 Sweet Pot';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionAccount => 'アカウント';

  @override
  String get settingsSectionAvatarColor => 'アバターの色';

  @override
  String get settingsSectionAppearance => '外観';

  @override
  String get settingsSectionLanguage => '言語';

  @override
  String get settingsSectionSoundHaptics => 'サウンドと触覚フィードバック';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionHelp => 'ヘルプ';

  @override
  String get settingsSectionAbout => 'アプリについて';

  @override
  String get signingIn => 'サインイン中…';

  @override
  String get signIn => 'サインイン';

  @override
  String get signOut => 'サインアウト';

  @override
  String get signOutConfirmTitle => 'サインアウトしますか？';

  @override
  String get signOutConfirmMessage =>
      'チップと統計はこの端末に残りますが、再度サインインするまでフレンドグループとランキングの順位から外れます。';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'アバターカラー $total 色中 $index 番目';
  }

  @override
  String get themeDefault => 'デフォルト';

  @override
  String get themeOcean => 'オーシャン';

  @override
  String get themeEmber => 'エンバー';

  @override
  String themeFeltSemanticLabel(String label) {
    return '$labelのテーブルフェルト';
  }

  @override
  String get hapticsLabel => '触覚フィードバック';

  @override
  String get soundEffectsLabel => '効果音';

  @override
  String get voiceCalloutsLabel => '音声コールアウト';

  @override
  String get voiceCalloutsSublabel => '手札の合計、結果、スイープポットを音声で読み上げます';

  @override
  String get voiceCalloutsDisabledReason => '音声コールアウトを使うには効果音をオンにしてください';

  @override
  String get notifSocialLabel => 'ソーシャル';

  @override
  String get notifSocialSublabel => 'フレンドがグループに参加、オンラインになる、またはあなたを追い抜いたとき';

  @override
  String get notifLeaderboardLabel => 'ランキング';

  @override
  String get notifLeaderboardSublabel => '1時間ごとまたは1日ごとのランキング順位が変わったとき';

  @override
  String get notifDailyLabel => 'デイリーリマインダー';

  @override
  String get notifDailySublabel => 'デイリーボーナスを受け取れるようになったら1日1回通知します';

  @override
  String get howToPlayLabel => '遊び方';

  @override
  String get howToPlaySublabel => 'ルール、操作、配当、スイープポットについて';

  @override
  String get replayTutorialLabel => 'チュートリアルをもう一度見る';

  @override
  String replayTutorialSublabel(int count) {
    return '次の$countハンドでコーチングカードを表示します';
  }

  @override
  String get termsOfServiceLabel => '利用規約';

  @override
  String get termsOfServiceSublabel => 'プレイすることで同意する内容';

  @override
  String get privacyPolicyLabel => 'プライバシーポリシー';

  @override
  String get privacyPolicySublabel => 'この端末に残るものと残らないもの';

  @override
  String get versionLabel => 'バージョン';

  @override
  String get languagePickerSublabel => 'メニューとディーラーの音声もこの設定に従います';

  @override
  String get languageSystemDefault => '端末の言語に合わせる';

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
