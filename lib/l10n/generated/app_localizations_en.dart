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
  String get moreGamesVideoPokerLabel => 'More games: Video Poker';

  @override
  String get moreGamesVideoPokerSublabel => 'Free video poker, no ads';

  @override
  String get moreGamesOpenFailed => 'Could not open Google Play';

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

  @override
  String get playNow => 'Play now';

  @override
  String get welcomeBenefit =>
      'Big, readable cards. Learn as you play, one hand at a time.';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get gameHit => 'HIT';

  @override
  String get gameStand => 'STAND';

  @override
  String get gameDouble => 'DOUBLE';

  @override
  String get gameSplit => 'SPLIT';

  @override
  String get gameSurrender => 'SURRENDER';

  @override
  String get gameDeal => 'DEAL';

  @override
  String get gameClear => 'CLEAR';

  @override
  String get gameAllIn => 'ALL IN';

  @override
  String get gameBet => 'Bet';

  @override
  String gameMinimum(String amount) {
    return 'min $amount';
  }

  @override
  String gameRebet(String amount) {
    return 'DEAL $amount AGAIN';
  }

  @override
  String gameMinimumHint(String amount) {
    return 'Bet at least $amount to deal';
  }

  @override
  String get gamePracticeBots => 'Playing with practice bots';

  @override
  String get gameInvite => 'Invite friends';

  @override
  String get gameNextHand => 'READY FOR NEXT HAND';

  @override
  String get gameInsure => 'INSURE';

  @override
  String get gameNoThanks => 'NO THANKS';

  @override
  String gameInsuranceOffer(String amount) {
    return 'Dealer shows an Ace. Insure for $amount? Pays 2:1.';
  }

  @override
  String get gameYouBet => 'You bet';

  @override
  String get gameAgainstDealer => 'Hand vs dealer';

  @override
  String get gameSweepPot => 'Sweep pot';

  @override
  String get gameBalance => 'Balance';

  @override
  String get gameWin => 'You win!';

  @override
  String get gameLose => 'Dealer wins';

  @override
  String get gamePush => 'Push';

  @override
  String get gameDealerBlackjack => 'Dealer has blackjack';

  @override
  String get gameBlackjackWin => 'Blackjack! You win';

  @override
  String get gameSweepWin => 'You sweep the table';

  @override
  String get gameBlackjackSweep => 'Blackjack — you sweep';

  @override
  String gameShowdown(String you, String dealer) {
    return 'YOU $you · DEALER $dealer';
  }

  @override
  String get gameNoPot => 'No sweep pot';

  @override
  String get gameDealerPot => 'Dealer keeps the pot';

  @override
  String get gameYourPot => 'Sweep pot: yours';

  @override
  String gameOtherPot(String name) {
    return 'Sweep pot: $name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'BET $bet + POT $pot';
  }

  @override
  String get gameNoForfeit => 'No seat forfeited a bet';

  @override
  String get gameNobodyBeat => 'Nobody beat the dealer';

  @override
  String coachStep(String hand) {
    return 'COACH · HAND $hand OF 3';
  }

  @override
  String get coachRules => 'Full rules';

  @override
  String get coachSkip => 'Skip';

  @override
  String get gameChipOptions => 'Ways to get chips';

  @override
  String get shotBigCards => 'Big, readable cards';

  @override
  String get shotLearn => 'Learn as you play';

  @override
  String get shotSweep => 'Sweep the table';

  @override
  String coachBetBody(String min) {
    return 'Tap a chip, then DEAL. This table starts at $min per hand.';
  }

  @override
  String get coachNpcBody =>
      'Practice bots play first. Your turn begins when HIT and STAND become available.';

  @override
  String get coachPlayBody =>
      'Get closer to 21 than the dealer without going over. HIT adds a card; STAND ends your turn. Over 21 loses.';

  @override
  String get coachSettleBody =>
      'Your result shows your bet, hand return and any sweep pot separately. Continue when ready.';

  @override
  String get coachDealerBody =>
      'The dealer draws below 17 and stands on all 17s. Look at the visible dealer card before choosing your move.';

  @override
  String get coachPushBody =>
      'An equal total is a push: your bet returns. Going over 21 loses, even if the dealer also busts.';

  @override
  String get coachPotBody =>
      'Losing bets from other seats form the sweep pot. Beat the dealer with the best remaining total (ties count) to take it.';

  @override
  String get coachMovesBody =>
      'DOUBLE adds an equal bet and one card. SPLIT separates a pair with another bet. SURRENDER returns half your opening bet.';

  @override
  String get coachDoneBody =>
      'You have finished the three coached hands. Reopen the rules or replay the tutorial from Settings anytime.';

  @override
  String get coachInsuranceBody =>
      'Insurance costs half your bet and pays 2:1 only if the dealer has blackjack. You can decline.';

  @override
  String get guideCardsBody =>
      'Number cards keep their value. J, Q and K count 10. An Ace counts 1 or 11, whichever keeps the hand at 21 or below.';

  @override
  String get guidePayoutsBody =>
      'A win pays 1:1, natural blackjack pays 3:2, a push returns your bet, and surrender returns half. A dealer blackjack beats any non-natural 21.';

  @override
  String get guideChipsBody =>
      'Table limits appear in the lobby. Rebuy and daily bonuses have cooldowns; check the chip options when your balance is low.';

  @override
  String get gameDealer => 'DEALER';

  @override
  String get gameBusted => 'Busted';

  @override
  String get gameWaiting => 'Waiting';

  @override
  String get gameBlackjack => 'Blackjack!';

  @override
  String get gameSurrendered => 'Surrendered';

  @override
  String get gameSoft => 'Soft';

  @override
  String get gameHard => 'Hard';

  @override
  String get gameYouLead => 'YOU LEAD';

  @override
  String get gameTableSweep => 'TABLE SWEEP';

  @override
  String get gameNoSweep => 'NO SWEEP';

  @override
  String get gameYouTake => 'YOU TAKE';

  @override
  String get gameDealerTakes => 'DEALER TAKES';

  @override
  String gameOtherTakes(String name) {
    return '$name TAKES';
  }

  @override
  String get gamePlaceBet => 'Place your bet';

  @override
  String get gameInsuranceOffered => 'Insurance offered';

  @override
  String gameSeatPlaying(String name) {
    return '$name is playing';
  }

  @override
  String get gameYourTurn => 'Your turn';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'Your turn · hand $hand of $total';
  }

  @override
  String get gameDealerPlaying => 'Dealer is playing';

  @override
  String get gameRoundResult => 'Round result';

  @override
  String get gameBronzeTable => 'Bronze Table';

  @override
  String get gameSilverTable => 'Silver Table';

  @override
  String get gameVipTable => 'VIP Table';

  @override
  String get gameLost => 'lost';
}
