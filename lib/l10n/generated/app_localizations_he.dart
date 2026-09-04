// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => '21 Sweet Pot';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get settingsSectionAccount => 'חשבון';

  @override
  String get settingsSectionAvatarColor => 'צבע האווטאר';

  @override
  String get settingsSectionAppearance => 'מראה';

  @override
  String get settingsSectionLanguage => 'שפה';

  @override
  String get settingsSectionSoundHaptics => 'צלילים ורטט';

  @override
  String get settingsSectionNotifications => 'התראות';

  @override
  String get settingsSectionHelp => 'עזרה';

  @override
  String get settingsSectionAbout => 'אודות';

  @override
  String get signingIn => 'מתחבר…';

  @override
  String get signIn => 'התחברות';

  @override
  String get signOut => 'התנתקות';

  @override
  String get signOutConfirmTitle => 'להתנתק?';

  @override
  String get signOutConfirmMessage =>
      'הצ\'יפים והסטטיסטיקות שלך יישארו במכשיר הזה, אך תעזוב את קבוצת החברים ואת מקומך בטבלת המובילים עד שתתחבר מחדש.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'צבע אווטאר $index מתוך $total';
  }

  @override
  String get themeDefault => 'ברירת מחדל';

  @override
  String get themeOcean => 'אוקיינוס';

  @override
  String get themeEmber => 'גחלת';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'מפת שולחן $label';
  }

  @override
  String get hapticsLabel => 'רטט';

  @override
  String get soundEffectsLabel => 'אפקטים קוליים';

  @override
  String get voiceCalloutsLabel => 'הכרזות קוליות';

  @override
  String get voiceCalloutsSublabel =>
      'סך הקלפים שלך, התוצאות והקופה המשותפת מוכרזים בקול';

  @override
  String get voiceCalloutsDisabledReason =>
      'הפעל אפקטים קוליים כדי להשתמש בהכרזות קוליות';

  @override
  String get notifSocialLabel => 'חברתי';

  @override
  String get notifSocialSublabel =>
      'כשחבר מצטרף לקבוצה שלך, מתחבר או עוקף אותך';

  @override
  String get notifLeaderboardLabel => 'טבלת מובילים';

  @override
  String get notifLeaderboardSublabel =>
      'כשהמקום שלך בטבלה השעתית או היומית משתנה';

  @override
  String get notifDailyLabel => 'תזכורת יומית';

  @override
  String get notifDailySublabel =>
      'תזכורת אחת ביום, כשהבונוס היומי שלך מוכן למימוש';

  @override
  String get howToPlayLabel => 'איך משחקים';

  @override
  String get howToPlaySublabel => 'חוקים, מהלכים, תשלומים והקופה המשותפת';

  @override
  String get replayTutorialLabel => 'לשחק שוב את המדריך';

  @override
  String replayTutorialSublabel(int count) {
    return 'כרטיסי הדרכה ב-$count היד הבאות שלך';
  }

  @override
  String get termsOfServiceLabel => 'תנאי השימוש';

  @override
  String get termsOfServiceSublabel => 'במה אתה מסכים כשאתה משחק';

  @override
  String get privacyPolicyLabel => 'מדיניות הפרטיות';

  @override
  String get privacyPolicySublabel => 'מה נשאר במכשיר הזה, ומה לא';

  @override
  String get versionLabel => 'גרסה';

  @override
  String get languagePickerSublabel =>
      'התפריטים וקול הדילר עוקבים אחרי הבחירה הזו';

  @override
  String get languageSystemDefault => 'כמו שפת המכשיר';

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
    return 'קנייה מחדש: $chips צ\'יפים';
  }

  @override
  String rebuyReadyInLabel(String time) {
    return 'קנייה מחדש בעוד $time';
  }

  @override
  String get rebuyHint => 'או קבלו את הבונוס היומי בלובי';

  @override
  String inviteMessage(String url) {
    return '🃏 בואו לשחק איתי 21 Sweet Pot — לחצו כדי להצטרף לשולחן שלי:\n$url';
  }

  @override
  String get inviteSubtitle =>
      'שלחו לחברים את הקישור שלכם — כל מי שלוחץ עליו מגיע ישר לטבלת השיאים החיה שלכם.';

  @override
  String get inviteButtonWhatsApp => 'הזמינו בוואטסאפ';

  @override
  String get inviteButtonShare => 'שתפו קישור';

  @override
  String get inviteCopyLink => 'העתיקו קישור';

  @override
  String joinedTableToast(int chips) {
    return 'הצטרפת לשולחן — קיבלת $chips צ\'יפים!';
  }

  @override
  String get joinAlreadyMemberToast => 'חזרתם לשולחן החברים שלכם';

  @override
  String get joinOwnTableToast => 'זה השולחן שלכם';

  @override
  String get webInstallBanner =>
      'משחקים בדפדפן — הורידו את האפליקציה לאנדרואיד';

  @override
  String get webInstallButton => 'הורידו מ-Google Play';
}
