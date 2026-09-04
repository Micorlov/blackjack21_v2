import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('he'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The app's title, used for the OS task switcher / window title.
  ///
  /// In en, this message translates to:
  /// **'21 Sweet Pot'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionAvatarColor.
  ///
  /// In en, this message translates to:
  /// **'Avatar color'**
  String get settingsSectionAvatarColor;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionSoundHaptics.
  ///
  /// In en, this message translates to:
  /// **'Sound & haptics'**
  String get settingsSectionSoundHaptics;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsSectionHelp;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your chips and stats stay on this device, but you leave your friends group and your leaderboard entry until you sign back in.'**
  String get signOutConfirmMessage;

  /// No description provided for @avatarColorSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar colour {index} of {total}'**
  String avatarColorSemanticLabel(int index, int total);

  /// No description provided for @themeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get themeDefault;

  /// No description provided for @themeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themeOcean;

  /// No description provided for @themeEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get themeEmber;

  /// No description provided for @themeFeltSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} table felt'**
  String themeFeltSemanticLabel(String label);

  /// No description provided for @hapticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get hapticsLabel;

  /// No description provided for @soundEffectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffectsLabel;

  /// No description provided for @voiceCalloutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice call-outs'**
  String get voiceCalloutsLabel;

  /// No description provided for @voiceCalloutsSublabel.
  ///
  /// In en, this message translates to:
  /// **'Your hand total, results and the sweep pot, spoken aloud'**
  String get voiceCalloutsSublabel;

  /// No description provided for @voiceCalloutsDisabledReason.
  ///
  /// In en, this message translates to:
  /// **'Turn sound effects on to use voice call-outs'**
  String get voiceCalloutsDisabledReason;

  /// No description provided for @notifSocialLabel.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get notifSocialLabel;

  /// No description provided for @notifSocialSublabel.
  ///
  /// In en, this message translates to:
  /// **'When a friend joins your group, comes online or passes you'**
  String get notifSocialSublabel;

  /// No description provided for @notifLeaderboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get notifLeaderboardLabel;

  /// No description provided for @notifLeaderboardSublabel.
  ///
  /// In en, this message translates to:
  /// **'When your place on the hourly or daily board changes'**
  String get notifLeaderboardSublabel;

  /// No description provided for @notifDailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get notifDailyLabel;

  /// No description provided for @notifDailySublabel.
  ///
  /// In en, this message translates to:
  /// **'One nudge a day, once your daily bonus is ready to claim'**
  String get notifDailySublabel;

  /// No description provided for @howToPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlayLabel;

  /// No description provided for @howToPlaySublabel.
  ///
  /// In en, this message translates to:
  /// **'Rules, moves, payouts and the sweep pot'**
  String get howToPlaySublabel;

  /// No description provided for @replayTutorialLabel.
  ///
  /// In en, this message translates to:
  /// **'Replay the tutorial'**
  String get replayTutorialLabel;

  /// No description provided for @replayTutorialSublabel.
  ///
  /// In en, this message translates to:
  /// **'Coaching cards on your next {count} hands'**
  String replayTutorialSublabel(int count);

  /// No description provided for @termsOfServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceLabel;

  /// No description provided for @termsOfServiceSublabel.
  ///
  /// In en, this message translates to:
  /// **'What you agree to by playing'**
  String get termsOfServiceSublabel;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

  /// No description provided for @privacyPolicySublabel.
  ///
  /// In en, this message translates to:
  /// **'What stays on this device, and what does not'**
  String get privacyPolicySublabel;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @languagePickerSublabel.
  ///
  /// In en, this message translates to:
  /// **'Menus and the dealer\'s voice both follow this'**
  String get languagePickerSublabel;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'Match device language'**
  String get languageSystemDefault;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNameEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageNameEs;

  /// No description provided for @languageNameFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageNameFr;

  /// No description provided for @languageNameDe.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageNameDe;

  /// No description provided for @languageNamePt.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languageNamePt;

  /// No description provided for @languageNameRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageNameRu;

  /// No description provided for @languageNameZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageNameZh;

  /// No description provided for @languageNameJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageNameJa;

  /// No description provided for @languageNameHe.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get languageNameHe;

  /// No description provided for @languageNameAr.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageNameAr;

  /// No description provided for @rebuyButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rebuy {chips} chips'**
  String rebuyButtonLabel(int chips);

  /// No description provided for @rebuyReadyInLabel.
  ///
  /// In en, this message translates to:
  /// **'Rebuy in {time}'**
  String rebuyReadyInLabel(String time);

  /// No description provided for @rebuyHint.
  ///
  /// In en, this message translates to:
  /// **'Or claim your daily bonus in the lobby'**
  String get rebuyHint;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'🃏 Play 21 Sweet Pot with me — tap to join my table:\n{url}'**
  String inviteMessage(String url);

  /// No description provided for @inviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send friends your link — anyone who taps it lands on your live leaderboard.'**
  String get inviteSubtitle;

  /// No description provided for @inviteButtonWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Invite via WhatsApp'**
  String get inviteButtonWhatsApp;

  /// No description provided for @inviteButtonShare.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get inviteButtonShare;

  /// No description provided for @inviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get inviteCopyLink;

  /// No description provided for @joinedTableToast.
  ///
  /// In en, this message translates to:
  /// **'Joined the table — +{chips} welcome chips!'**
  String joinedTableToast(int chips);

  /// No description provided for @joinAlreadyMemberToast.
  ///
  /// In en, this message translates to:
  /// **'Back at your friends\' table'**
  String get joinAlreadyMemberToast;

  /// No description provided for @joinOwnTableToast.
  ///
  /// In en, this message translates to:
  /// **'This is your own table'**
  String get joinOwnTableToast;

  /// No description provided for @webInstallBanner.
  ///
  /// In en, this message translates to:
  /// **'Playing in the browser — get the Android app'**
  String get webInstallBanner;

  /// No description provided for @webInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Get it on Google Play'**
  String get webInstallButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'he',
    'ja',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
