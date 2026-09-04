// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '21 Sweet Pot';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionAccount => '账户';

  @override
  String get settingsSectionAvatarColor => '头像颜色';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsSectionSoundHaptics => '声音与震动';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionHelp => '帮助';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get signingIn => '正在登录…';

  @override
  String get signIn => '登录';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirmTitle => '要退出登录吗？';

  @override
  String get signOutConfirmMessage =>
      '你的筹码和统计数据会保留在此设备上，但在重新登录之前，你将离开好友群组并失去排行榜名次。';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return '头像颜色 $index／$total';
  }

  @override
  String get themeDefault => '默认';

  @override
  String get themeOcean => '海洋';

  @override
  String get themeEmber => '余烬';

  @override
  String themeFeltSemanticLabel(String label) {
    return '$label牌桌';
  }

  @override
  String get hapticsLabel => '震动';

  @override
  String get soundEffectsLabel => '音效';

  @override
  String get voiceCalloutsLabel => '语音播报';

  @override
  String get voiceCalloutsSublabel => '你的手牌点数、结果和彩池金额都会语音播报';

  @override
  String get voiceCalloutsDisabledReason => '开启音效后才能使用语音播报';

  @override
  String get notifSocialLabel => '社交';

  @override
  String get notifSocialSublabel => '好友加入群组、上线或超过你时提醒';

  @override
  String get notifLeaderboardLabel => '排行榜';

  @override
  String get notifLeaderboardSublabel => '你在每小时或每日榜单中的名次变化时提醒';

  @override
  String get notifDailyLabel => '每日提醒';

  @override
  String get notifDailySublabel => '每日奖励可领取时提醒一次';

  @override
  String get howToPlayLabel => '玩法说明';

  @override
  String get howToPlaySublabel => '规则、操作、赔付和彩池';

  @override
  String get replayTutorialLabel => '重新观看教程';

  @override
  String replayTutorialSublabel(int count) {
    return '接下来 $count 局会显示提示卡';
  }

  @override
  String get termsOfServiceLabel => '服务条款';

  @override
  String get termsOfServiceSublabel => '你在游戏中所同意的内容';

  @override
  String get privacyPolicyLabel => '隐私政策';

  @override
  String get privacyPolicySublabel => '哪些信息保留在本设备上，哪些不会';

  @override
  String get versionLabel => '版本';

  @override
  String get resetBankrollConfirmTitle => '要重置筹码吗？';

  @override
  String get resetBankrollConfirmMessage =>
      '你的筹码将重置为 1,000。统计数据、奖励、好友和装扮不受影响，但当前的筹码将无法找回。';

  @override
  String get resetBankrollConfirmLabel => '重置筹码';

  @override
  String get resetBankrollButtonLabel => '将筹码重置为 1,000';

  @override
  String get languagePickerSublabel => '菜单和荷官语音都会跟随此设置';

  @override
  String get languageSystemDefault => '跟随设备语言';

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
}
