// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => '21 Sweet Pot';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsSectionAvatarColor => 'لون الصورة الرمزية';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionLanguage => 'اللغة';

  @override
  String get settingsSectionSoundHaptics => 'الصوت والاهتزاز';

  @override
  String get settingsSectionNotifications => 'الإشعارات';

  @override
  String get settingsSectionHelp => 'المساعدة';

  @override
  String get settingsSectionAbout => 'حول التطبيق';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول…';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get signOutConfirmMessage =>
      'ستبقى رقائقك وإحصائياتك على هذا الجهاز، لكنك ستغادر مجموعة أصدقائك ومكانك في لوحة المتصدرين حتى تسجّل الدخول مرة أخرى.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'لون الصورة الرمزية $index من $total';
  }

  @override
  String get themeDefault => 'افتراضي';

  @override
  String get themeOcean => 'المحيط';

  @override
  String get themeEmber => 'الجمر';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'طاولة $label';
  }

  @override
  String get hapticsLabel => 'الاهتزاز';

  @override
  String get soundEffectsLabel => 'المؤثرات الصوتية';

  @override
  String get voiceCalloutsLabel => 'التعليقات الصوتية';

  @override
  String get voiceCalloutsSublabel =>
      'يُعلَن مجموع أوراقك والنتائج ومبلغ القدر بصوت مسموع';

  @override
  String get voiceCalloutsDisabledReason =>
      'فعّل المؤثرات الصوتية لاستخدام التعليقات الصوتية';

  @override
  String get notifSocialLabel => 'اجتماعي';

  @override
  String get notifSocialSublabel =>
      'عندما ينضم صديق إلى مجموعتك أو يتصل بالإنترنت أو يتخطاك';

  @override
  String get notifLeaderboardLabel => 'لوحة المتصدرين';

  @override
  String get notifLeaderboardSublabel =>
      'عندما يتغيّر ترتيبك في اللوحة الساعية أو اليومية';

  @override
  String get notifDailyLabel => 'تذكير يومي';

  @override
  String get notifDailySublabel =>
      'تنبيه واحد يوميًا عندما تصبح مكافأتك اليومية جاهزة';

  @override
  String get howToPlayLabel => 'كيفية اللعب';

  @override
  String get howToPlaySublabel => 'القواعد والحركات والمدفوعات ومبلغ القدر';

  @override
  String get replayTutorialLabel => 'إعادة عرض الشرح';

  @override
  String replayTutorialSublabel(int count) {
    return 'بطاقات إرشادية خلال $count أيدٍ القادمة';
  }

  @override
  String get termsOfServiceLabel => 'شروط الخدمة';

  @override
  String get termsOfServiceSublabel => 'ما توافق عليه عند اللعب';

  @override
  String get privacyPolicyLabel => 'سياسة الخصوصية';

  @override
  String get privacyPolicySublabel => 'ما يبقى على هذا الجهاز وما لا يبقى';

  @override
  String get versionLabel => 'الإصدار';

  @override
  String get resetBankrollConfirmTitle => 'إعادة تعيين رصيدك؟';

  @override
  String get resetBankrollConfirmMessage =>
      'ستعود رقائقك إلى 1000. لن تتأثر الإحصائيات والجوائز والأصدقاء والمظاهر، لكن لا يمكن استرجاع الرقائق الحالية.';

  @override
  String get resetBankrollConfirmLabel => 'إعادة تعيين الرقائق';

  @override
  String get resetBankrollButtonLabel => 'إعادة تعيين الرصيد إلى 1000 رقاقة';

  @override
  String get languagePickerSublabel => 'تتبع القوائم وصوت الموزّع هذا الاختيار';

  @override
  String get languageSystemDefault => 'مطابقة لغة الجهاز';

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
