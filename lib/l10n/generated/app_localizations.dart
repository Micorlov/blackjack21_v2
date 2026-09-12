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
  /// **'Blackjack 21'**
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

  /// No description provided for @moreGamesVideoPokerLabel.
  ///
  /// In en, this message translates to:
  /// **'More games: Video Poker'**
  String get moreGamesVideoPokerLabel;

  /// No description provided for @moreGamesVideoPokerSublabel.
  ///
  /// In en, this message translates to:
  /// **'Free video poker, no ads'**
  String get moreGamesVideoPokerSublabel;

  /// No description provided for @moreGamesOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Play'**
  String get moreGamesOpenFailed;

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
  /// **'🃏 Play Blackjack 21 with me — tap to join my table:\n{url}'**
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

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get playNow;

  /// No description provided for @welcomeBenefit.
  ///
  /// In en, this message translates to:
  /// **'Big, readable cards. Learn as you play, one hand at a time.'**
  String get welcomeBenefit;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @gameHit.
  ///
  /// In en, this message translates to:
  /// **'HIT'**
  String get gameHit;

  /// No description provided for @gameStand.
  ///
  /// In en, this message translates to:
  /// **'STAND'**
  String get gameStand;

  /// No description provided for @gameDouble.
  ///
  /// In en, this message translates to:
  /// **'DOUBLE'**
  String get gameDouble;

  /// No description provided for @gameSplit.
  ///
  /// In en, this message translates to:
  /// **'SPLIT'**
  String get gameSplit;

  /// No description provided for @gameSurrender.
  ///
  /// In en, this message translates to:
  /// **'SURRENDER'**
  String get gameSurrender;

  /// No description provided for @gameDeal.
  ///
  /// In en, this message translates to:
  /// **'DEAL'**
  String get gameDeal;

  /// No description provided for @gameClear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get gameClear;

  /// No description provided for @gameAllIn.
  ///
  /// In en, this message translates to:
  /// **'ALL IN'**
  String get gameAllIn;

  /// No description provided for @gameBet.
  ///
  /// In en, this message translates to:
  /// **'Bet'**
  String get gameBet;

  /// No description provided for @gameMinimum.
  ///
  /// In en, this message translates to:
  /// **'min {amount}'**
  String gameMinimum(String amount);

  /// No description provided for @gameRebet.
  ///
  /// In en, this message translates to:
  /// **'DEAL {amount} AGAIN'**
  String gameRebet(String amount);

  /// No description provided for @gameMinimumHint.
  ///
  /// In en, this message translates to:
  /// **'Bet at least {amount} to deal'**
  String gameMinimumHint(String amount);

  /// No description provided for @gamePracticeBots.
  ///
  /// In en, this message translates to:
  /// **'Playing with practice bots'**
  String get gamePracticeBots;

  /// No description provided for @gameInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get gameInvite;

  /// No description provided for @gameNextHand.
  ///
  /// In en, this message translates to:
  /// **'READY FOR NEXT HAND'**
  String get gameNextHand;

  /// No description provided for @gameInsure.
  ///
  /// In en, this message translates to:
  /// **'INSURE'**
  String get gameInsure;

  /// No description provided for @gameNoThanks.
  ///
  /// In en, this message translates to:
  /// **'NO THANKS'**
  String get gameNoThanks;

  /// No description provided for @gameInsuranceOffer.
  ///
  /// In en, this message translates to:
  /// **'Dealer shows an Ace. Insure for {amount}? Pays 2:1.'**
  String gameInsuranceOffer(String amount);

  /// No description provided for @gameYouBet.
  ///
  /// In en, this message translates to:
  /// **'You bet'**
  String get gameYouBet;

  /// No description provided for @gameAgainstDealer.
  ///
  /// In en, this message translates to:
  /// **'Hand vs dealer'**
  String get gameAgainstDealer;

  /// No description provided for @gameSweepPot.
  ///
  /// In en, this message translates to:
  /// **'Sweep pot'**
  String get gameSweepPot;

  /// No description provided for @gameBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get gameBalance;

  /// No description provided for @gameWin.
  ///
  /// In en, this message translates to:
  /// **'You win!'**
  String get gameWin;

  /// No description provided for @gameLose.
  ///
  /// In en, this message translates to:
  /// **'Dealer wins'**
  String get gameLose;

  /// No description provided for @gamePush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get gamePush;

  /// No description provided for @gameDealerBlackjack.
  ///
  /// In en, this message translates to:
  /// **'Dealer has blackjack'**
  String get gameDealerBlackjack;

  /// No description provided for @gameBlackjackWin.
  ///
  /// In en, this message translates to:
  /// **'Blackjack! You win'**
  String get gameBlackjackWin;

  /// No description provided for @gameSweepWin.
  ///
  /// In en, this message translates to:
  /// **'You sweep the table'**
  String get gameSweepWin;

  /// No description provided for @gameBlackjackSweep.
  ///
  /// In en, this message translates to:
  /// **'Blackjack — you sweep'**
  String get gameBlackjackSweep;

  /// No description provided for @gameShowdown.
  ///
  /// In en, this message translates to:
  /// **'YOU {you} · DEALER {dealer}'**
  String gameShowdown(String you, String dealer);

  /// No description provided for @gameNoPot.
  ///
  /// In en, this message translates to:
  /// **'No sweep pot'**
  String get gameNoPot;

  /// No description provided for @gameDealerPot.
  ///
  /// In en, this message translates to:
  /// **'Dealer keeps the pot'**
  String get gameDealerPot;

  /// No description provided for @gameYourPot.
  ///
  /// In en, this message translates to:
  /// **'Sweep pot: yours'**
  String get gameYourPot;

  /// No description provided for @gameOtherPot.
  ///
  /// In en, this message translates to:
  /// **'Sweep pot: {name}'**
  String gameOtherPot(String name);

  /// No description provided for @gamePotBreakdown.
  ///
  /// In en, this message translates to:
  /// **'BET {bet} + POT {pot}'**
  String gamePotBreakdown(String bet, String pot);

  /// No description provided for @gameNoForfeit.
  ///
  /// In en, this message translates to:
  /// **'No seat forfeited a bet'**
  String get gameNoForfeit;

  /// No description provided for @gameNobodyBeat.
  ///
  /// In en, this message translates to:
  /// **'Nobody beat the dealer'**
  String get gameNobodyBeat;

  /// No description provided for @coachStep.
  ///
  /// In en, this message translates to:
  /// **'COACH · HAND {hand} OF 3'**
  String coachStep(String hand);

  /// No description provided for @coachRules.
  ///
  /// In en, this message translates to:
  /// **'Full rules'**
  String get coachRules;

  /// No description provided for @coachSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get coachSkip;

  /// No description provided for @gameChipOptions.
  ///
  /// In en, this message translates to:
  /// **'Ways to get chips'**
  String get gameChipOptions;

  /// No description provided for @shotBigCards.
  ///
  /// In en, this message translates to:
  /// **'Big, readable cards'**
  String get shotBigCards;

  /// No description provided for @shotLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn as you play'**
  String get shotLearn;

  /// No description provided for @shotSweep.
  ///
  /// In en, this message translates to:
  /// **'Sweep the table'**
  String get shotSweep;

  /// No description provided for @coachBetBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a chip, then DEAL. This table starts at {min} per hand.'**
  String coachBetBody(String min);

  /// No description provided for @coachNpcBody.
  ///
  /// In en, this message translates to:
  /// **'Practice bots play first. Your turn begins when HIT and STAND become available.'**
  String get coachNpcBody;

  /// No description provided for @coachPlayBody.
  ///
  /// In en, this message translates to:
  /// **'Get closer to 21 than the dealer without going over. HIT adds a card; STAND ends your turn. Over 21 loses.'**
  String get coachPlayBody;

  /// No description provided for @coachSettleBody.
  ///
  /// In en, this message translates to:
  /// **'Your result shows your bet, hand return and any sweep pot separately. Continue when ready.'**
  String get coachSettleBody;

  /// No description provided for @coachDealerBody.
  ///
  /// In en, this message translates to:
  /// **'The dealer draws below 17 and stands on all 17s. Look at the visible dealer card before choosing your move.'**
  String get coachDealerBody;

  /// No description provided for @coachPushBody.
  ///
  /// In en, this message translates to:
  /// **'An equal total is a push: your bet returns. Going over 21 loses, even if the dealer also busts.'**
  String get coachPushBody;

  /// No description provided for @coachPotBody.
  ///
  /// In en, this message translates to:
  /// **'Losing bets from other seats form the sweep pot. Beat the dealer with the best remaining total (ties count) to take it.'**
  String get coachPotBody;

  /// No description provided for @coachMovesBody.
  ///
  /// In en, this message translates to:
  /// **'DOUBLE adds an equal bet and one card. SPLIT separates a pair with another bet. SURRENDER returns half your opening bet.'**
  String get coachMovesBody;

  /// No description provided for @coachDoneBody.
  ///
  /// In en, this message translates to:
  /// **'You have finished the three coached hands. Reopen the rules or replay the tutorial from Settings anytime.'**
  String get coachDoneBody;

  /// No description provided for @coachInsuranceBody.
  ///
  /// In en, this message translates to:
  /// **'Insurance costs half your bet and pays 2:1 only if the dealer has blackjack. You can decline.'**
  String get coachInsuranceBody;

  /// No description provided for @guideCardsBody.
  ///
  /// In en, this message translates to:
  /// **'Number cards keep their value. J, Q and K count 10. An Ace counts 1 or 11, whichever keeps the hand at 21 or below.'**
  String get guideCardsBody;

  /// No description provided for @guidePayoutsBody.
  ///
  /// In en, this message translates to:
  /// **'A win pays 1:1, natural blackjack pays 3:2, a push returns your bet, and surrender returns half. A dealer blackjack beats any non-natural 21.'**
  String get guidePayoutsBody;

  /// No description provided for @guideChipsBody.
  ///
  /// In en, this message translates to:
  /// **'Table limits appear in the lobby. Rebuy and daily bonuses have cooldowns; check the chip options when your balance is low.'**
  String get guideChipsBody;

  /// No description provided for @gameDealer.
  ///
  /// In en, this message translates to:
  /// **'DEALER'**
  String get gameDealer;

  /// No description provided for @gameBusted.
  ///
  /// In en, this message translates to:
  /// **'Busted'**
  String get gameBusted;

  /// No description provided for @gameWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get gameWaiting;

  /// No description provided for @gameBlackjack.
  ///
  /// In en, this message translates to:
  /// **'Blackjack!'**
  String get gameBlackjack;

  /// No description provided for @gameSurrendered.
  ///
  /// In en, this message translates to:
  /// **'Surrendered'**
  String get gameSurrendered;

  /// No description provided for @gameSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get gameSoft;

  /// No description provided for @gameHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get gameHard;

  /// No description provided for @gameYouLead.
  ///
  /// In en, this message translates to:
  /// **'YOU LEAD'**
  String get gameYouLead;

  /// No description provided for @gameTableSweep.
  ///
  /// In en, this message translates to:
  /// **'TABLE SWEEP'**
  String get gameTableSweep;

  /// No description provided for @gameNoSweep.
  ///
  /// In en, this message translates to:
  /// **'NO SWEEP'**
  String get gameNoSweep;

  /// No description provided for @gameYouTake.
  ///
  /// In en, this message translates to:
  /// **'YOU TAKE'**
  String get gameYouTake;

  /// No description provided for @gameDealerTakes.
  ///
  /// In en, this message translates to:
  /// **'DEALER TAKES'**
  String get gameDealerTakes;

  /// No description provided for @gameOtherTakes.
  ///
  /// In en, this message translates to:
  /// **'{name} TAKES'**
  String gameOtherTakes(String name);

  /// No description provided for @gamePlaceBet.
  ///
  /// In en, this message translates to:
  /// **'Place your bet'**
  String get gamePlaceBet;

  /// No description provided for @gameInsuranceOffered.
  ///
  /// In en, this message translates to:
  /// **'Insurance offered'**
  String get gameInsuranceOffered;

  /// No description provided for @gameSeatPlaying.
  ///
  /// In en, this message translates to:
  /// **'{name} is playing'**
  String gameSeatPlaying(String name);

  /// No description provided for @gameYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get gameYourTurn;

  /// No description provided for @gameSplitTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn · hand {hand} of {total}'**
  String gameSplitTurn(String hand, String total);

  /// No description provided for @gameDealerPlaying.
  ///
  /// In en, this message translates to:
  /// **'Dealer is playing'**
  String get gameDealerPlaying;

  /// No description provided for @gameRoundResult.
  ///
  /// In en, this message translates to:
  /// **'Round result'**
  String get gameRoundResult;

  /// No description provided for @gameBronzeTable.
  ///
  /// In en, this message translates to:
  /// **'Bronze Table'**
  String get gameBronzeTable;

  /// No description provided for @gameSilverTable.
  ///
  /// In en, this message translates to:
  /// **'Silver Table'**
  String get gameSilverTable;

  /// No description provided for @gameVipTable.
  ///
  /// In en, this message translates to:
  /// **'VIP Table'**
  String get gameVipTable;

  /// No description provided for @gameLost.
  ///
  /// In en, this message translates to:
  /// **'lost'**
  String get gameLost;
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
