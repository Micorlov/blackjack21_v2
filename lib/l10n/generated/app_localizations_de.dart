// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

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
  String get moreGamesVideoPokerLabel => 'Mehr Spiele: Video Poker';

  @override
  String get moreGamesVideoPokerSublabel =>
      'Kostenloses Video Poker, ohne Werbung';

  @override
  String get moreGamesOpenFailed => 'Google Play konnte nicht geöffnet werden';

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
  String get playNow => 'Jetzt spielen';

  @override
  String get welcomeBenefit =>
      'Große, gut lesbare Karten. Lerne beim Spielen, Hand für Hand.';

  @override
  String get continueGoogle => 'Weiter mit Google';

  @override
  String get gameHit => 'KARTE';

  @override
  String get gameStand => 'HALTEN';

  @override
  String get gameDouble => 'DOPPELN';

  @override
  String get gameSplit => 'TEILEN';

  @override
  String get gameSurrender => 'AUFGEBEN';

  @override
  String get gameDeal => 'GEBEN';

  @override
  String get gameClear => 'LÖSCHEN';

  @override
  String get gameAllIn => 'ALLES';

  @override
  String get gameBet => 'Einsatz';

  @override
  String gameMinimum(String amount) {
    return 'min. $amount';
  }

  @override
  String gameRebet(String amount) {
    return 'NOCHMAL $amount';
  }

  @override
  String gameMinimumHint(String amount) {
    return 'Setze mindestens $amount zum Geben';
  }

  @override
  String get gamePracticeBots => 'Du spielst mit Übungsbots';

  @override
  String get gameInvite => 'Freunde einladen';

  @override
  String get gameNextHand => 'NÄCHSTE HAND';

  @override
  String get gameInsure => 'VERSICHERN';

  @override
  String get gameNoThanks => 'NEIN DANKE';

  @override
  String gameInsuranceOffer(String amount) {
    return 'Der Dealer zeigt ein Ass. Versicherung für $amount? Zahlt 2:1.';
  }

  @override
  String get gameYouBet => 'Dein Einsatz';

  @override
  String get gameAgainstDealer => 'Hand gegen Dealer';

  @override
  String get gameSweepPot => 'Sweep-Pot';

  @override
  String get gameBalance => 'Guthaben';

  @override
  String get gameWin => 'Du gewinnst!';

  @override
  String get gameLose => 'Dealer gewinnt';

  @override
  String get gamePush => 'Unentschieden';

  @override
  String get gameDealerBlackjack => 'Dealer hat Blackjack';

  @override
  String get gameBlackjackWin => 'Blackjack! Du gewinnst';

  @override
  String get gameSweepWin => 'Du holst den Pot';

  @override
  String get gameBlackjackSweep => 'Blackjack — der Pot gehört dir';

  @override
  String gameShowdown(String you, String dealer) {
    return 'DU $you · DEALER $dealer';
  }

  @override
  String get gameNoPot => 'Kein Sweep-Pot';

  @override
  String get gameDealerPot => 'Dealer behält den Pot';

  @override
  String get gameYourPot => 'Der Pot gehört dir';

  @override
  String gameOtherPot(String name) {
    return 'Pot: $name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'EINSATZ $bet + POT $pot';
  }

  @override
  String get gameNoForfeit => 'Niemand hat einen Einsatz verloren';

  @override
  String get gameNobodyBeat => 'Niemand schlug den Dealer';

  @override
  String coachStep(String hand) {
    return 'HILFE · HAND $hand VON 3';
  }

  @override
  String get coachRules => 'Regeln';

  @override
  String get coachSkip => 'Überspringen';

  @override
  String get gameChipOptions => 'Chips erhalten';

  @override
  String get shotBigCards => 'Große, gut lesbare Karten';

  @override
  String get shotLearn => 'Lerne beim Spielen';

  @override
  String get shotSweep => 'Hol dir den Pot';

  @override
  String coachBetBody(String min) {
    return 'Tippe auf einen Chip und dann GEBEN. Der Mindesteinsatz beträgt $min pro Hand.';
  }

  @override
  String get coachNpcBody =>
      'Übungsbots spielen zuerst. Du bist dran, sobald KARTE und HALTEN verfügbar sind.';

  @override
  String get coachPlayBody =>
      'Komm näher an 21 als der Dealer, ohne darüber zu liegen. KARTE zieht eine Karte; HALTEN beendet deinen Zug. Über 21 verliert.';

  @override
  String get coachSettleBody =>
      'Das Ergebnis zeigt Einsatz, Handertrag und Sweep-Pot getrennt. Spiele weiter, wenn du bereit bist.';

  @override
  String get coachDealerBody =>
      'Der Dealer zieht unter 17 und hält bei jeder 17. Sieh dir vor deiner Entscheidung seine offene Karte an.';

  @override
  String get coachPushBody =>
      'Gleicher Wert bedeutet Unentschieden: Dein Einsatz kommt zurück. Über 21 verlierst du, auch wenn der Dealer sich ebenfalls überkauft.';

  @override
  String get coachPotBody =>
      'Verlorene Einsätze anderer Plätze bilden den Pot. Schlage den Dealer mit dem besten verbleibenden Wert, auch bei Gleichstand mit einem anderen Platz, um ihn zu holen.';

  @override
  String get coachMovesBody =>
      'DOPPELN setzt denselben Betrag dazu und zieht eine Karte. TEILEN trennt ein Paar mit weiterem Einsatz. AUFGEBEN gibt die Hälfte des Starteinsatzes zurück.';

  @override
  String get coachDoneBody =>
      'Du hast drei begleitete Hände gespielt. Regeln und Neustart des Tutorials findest du in den Einstellungen.';

  @override
  String get coachInsuranceBody =>
      'Die Versicherung kostet den halben Einsatz und zahlt 2:1 nur bei Blackjack des Dealers. Du kannst ablehnen.';

  @override
  String get guideCardsBody =>
      'Zahlenkarten zählen ihren Wert. J, Q und K zählen 10. Ein Ass zählt 1 oder 11, sodass die Hand höchstens 21 hat.';

  @override
  String get guidePayoutsBody =>
      'Ein Gewinn zahlt 1:1, natürlicher Blackjack 3:2. Gleichstand gibt den Einsatz zurück, Aufgeben die Hälfte. Dealer-Blackjack schlägt jede nicht natürliche 21.';

  @override
  String get guideChipsBody =>
      'Tischlimits stehen in der Lobby. Nachkauf und Tagesbonus haben Wartezeiten; bei wenig Guthaben helfen die Chip-Optionen.';

  @override
  String get gameDealer => 'DEALER';

  @override
  String get gameBusted => 'Überkauft';

  @override
  String get gameWaiting => 'Warten';

  @override
  String get gameBlackjack => 'Blackjack!';

  @override
  String get gameSurrendered => 'Aufgegeben';

  @override
  String get gameSoft => 'Weich';

  @override
  String get gameHard => 'Hart';

  @override
  String get gameYouLead => 'DU FÜHRST';

  @override
  String get gameTableSweep => 'POT GEHOLT';

  @override
  String get gameNoSweep => 'KEIN SWEEP';

  @override
  String get gameYouTake => 'DEIN POT';

  @override
  String get gameDealerTakes => 'DEALER NIMMT';

  @override
  String gameOtherTakes(String name) {
    return '$name NIMMT';
  }

  @override
  String get gamePlaceBet => 'Setze deinen Einsatz';

  @override
  String get gameInsuranceOffered => 'Versicherung angeboten';

  @override
  String gameSeatPlaying(String name) {
    return '$name spielt';
  }

  @override
  String get gameYourTurn => 'Du bist dran';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'Du bist dran · Hand $hand von $total';
  }

  @override
  String get gameDealerPlaying => 'Dealer spielt';

  @override
  String get gameRoundResult => 'Rundenergebnis';

  @override
  String get gameBronzeTable => 'Bronzetisch';

  @override
  String get gameSilverTable => 'Silbertisch';

  @override
  String get gameVipTable => 'VIP-Tisch';

  @override
  String get gameLost => 'verloren';
}
