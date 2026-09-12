// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

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
  String get moreGamesVideoPokerLabel => 'Plus de jeux : Vidéo Poker';

  @override
  String get moreGamesVideoPokerSublabel =>
      'Vidéo poker gratuit, sans publicité';

  @override
  String get moreGamesOpenFailed => 'Impossible d\'ouvrir Google Play';

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
  String get playNow => 'Jouer maintenant';

  @override
  String get welcomeBenefit =>
      'De grandes cartes lisibles. Apprenez en jouant, une main à la fois.';

  @override
  String get continueGoogle => 'Continuer avec Google';

  @override
  String get gameHit => 'TIRER';

  @override
  String get gameStand => 'RESTER';

  @override
  String get gameDouble => 'DOUBLER';

  @override
  String get gameSplit => 'SÉPARER';

  @override
  String get gameSurrender => 'ABANDON';

  @override
  String get gameDeal => 'DISTRIBUER';

  @override
  String get gameClear => 'EFFACER';

  @override
  String get gameAllIn => 'TOUT';

  @override
  String get gameBet => 'Mise';

  @override
  String gameMinimum(String amount) {
    return 'min. $amount';
  }

  @override
  String gameRebet(String amount) {
    return 'REJOUER $amount';
  }

  @override
  String gameMinimumHint(String amount) {
    return 'Misez au moins $amount pour distribuer';
  }

  @override
  String get gamePracticeBots => 'Partie avec des bots d’entraînement';

  @override
  String get gameInvite => 'Inviter des amis';

  @override
  String get gameNextHand => 'MAIN SUIVANTE';

  @override
  String get gameInsure => 'ASSURER';

  @override
  String get gameNoThanks => 'NON MERCI';

  @override
  String gameInsuranceOffer(String amount) {
    return 'Le croupier montre un as. Assurance pour $amount ? Gain de 2:1.';
  }

  @override
  String get gameYouBet => 'Votre mise';

  @override
  String get gameAgainstDealer => 'Main contre croupier';

  @override
  String get gameSweepPot => 'Pot de balayage';

  @override
  String get gameBalance => 'Solde';

  @override
  String get gameWin => 'Vous gagnez !';

  @override
  String get gameLose => 'Le croupier gagne';

  @override
  String get gamePush => 'Égalité';

  @override
  String get gameDealerBlackjack => 'Le croupier a un blackjack';

  @override
  String get gameBlackjackWin => 'Blackjack ! Vous gagnez';

  @override
  String get gameSweepWin => 'Vous raflez le pot';

  @override
  String get gameBlackjackSweep => 'Blackjack : vous raflez tout';

  @override
  String gameShowdown(String you, String dealer) {
    return 'VOUS $you · CROUPIER $dealer';
  }

  @override
  String get gameNoPot => 'Pas de pot à rafler';

  @override
  String get gameDealerPot => 'Le croupier garde le pot';

  @override
  String get gameYourPot => 'Le pot est à vous';

  @override
  String gameOtherPot(String name) {
    return 'Pot : $name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'MISE $bet + POT $pot';
  }

  @override
  String get gameNoForfeit => 'Aucun joueur n’a perdu sa mise';

  @override
  String get gameNobodyBeat => 'Personne n’a battu le croupier';

  @override
  String coachStep(String hand) {
    return 'GUIDE · MAIN $hand SUR 3';
  }

  @override
  String get coachRules => 'Règles';

  @override
  String get coachSkip => 'Passer';

  @override
  String get gameChipOptions => 'Obtenir des jetons';

  @override
  String get shotBigCards => 'De grandes cartes lisibles';

  @override
  String get shotLearn => 'Apprenez en jouant';

  @override
  String get shotSweep => 'Raflez le pot';

  @override
  String coachBetBody(String min) {
    return 'Touchez un jeton puis DISTRIBUER. La mise minimale est de $min par main.';
  }

  @override
  String get coachNpcBody =>
      'Les bots jouent d’abord. Votre tour commence quand TIRER et RESTER sont disponibles.';

  @override
  String get coachPlayBody =>
      'Approchez-vous plus de 21 que le croupier sans dépasser. TIRER ajoute une carte ; RESTER termine votre tour. Dépasser 21 fait perdre.';

  @override
  String get coachSettleBody =>
      'Le résultat distingue votre mise, le retour de la main et le pot. Continuez quand vous êtes prêt.';

  @override
  String get coachDealerBody =>
      'Le croupier tire sous 17 et reste sur tous les 17. Regardez sa carte visible avant de choisir.';

  @override
  String get coachPushBody =>
      'Un total égal donne une égalité et rend votre mise. Dépasser 21 fait perdre même si le croupier dépasse aussi.';

  @override
  String get coachPotBody =>
      'Les mises perdues des autres places forment le pot. Battez le croupier avec le meilleur total restant, même à égalité avec une autre place, pour le rafler.';

  @override
  String get coachMovesBody =>
      'DOUBLER ajoute une mise égale et une carte. SÉPARER divise une paire avec une autre mise. ABANDON rend la moitié de la mise initiale.';

  @override
  String get coachDoneBody =>
      'Vous avez terminé les trois mains guidées. Retrouvez les règles ou relancez le tutoriel dans les paramètres.';

  @override
  String get coachInsuranceBody =>
      'L’assurance coûte la moitié de votre mise et paie 2:1 seulement si le croupier a un blackjack. Vous pouvez refuser.';

  @override
  String get guideCardsBody =>
      'Les cartes numérotées gardent leur valeur. J, Q et K valent 10. L’as vaut 1 ou 11 pour garder la main à 21 ou moins.';

  @override
  String get guidePayoutsBody =>
      'Une victoire paie 1:1, un blackjack naturel 3:2. Une égalité rend la mise et l’abandon en rend la moitié. Le blackjack du croupier bat un 21 non naturel.';

  @override
  String get guideChipsBody =>
      'Les limites sont dans le salon. Les recharges et bonus quotidiens ont un délai ; consultez les options de jetons si votre solde est bas.';

  @override
  String get gameDealer => 'CROUPIER';

  @override
  String get gameBusted => 'Dépassé';

  @override
  String get gameWaiting => 'En attente';

  @override
  String get gameBlackjack => 'Blackjack !';

  @override
  String get gameSurrendered => 'Abandon';

  @override
  String get gameSoft => 'Souple';

  @override
  String get gameHard => 'Dure';

  @override
  String get gameYouLead => 'EN TÊTE';

  @override
  String get gameTableSweep => 'POT RAFLÉ';

  @override
  String get gameNoSweep => 'PAS DE BALAYAGE';

  @override
  String get gameYouTake => 'À VOUS';

  @override
  String get gameDealerTakes => 'AU CROUPIER';

  @override
  String gameOtherTakes(String name) {
    return 'À $name';
  }

  @override
  String get gamePlaceBet => 'Placez votre mise';

  @override
  String get gameInsuranceOffered => 'Assurance proposée';

  @override
  String gameSeatPlaying(String name) {
    return '$name joue';
  }

  @override
  String get gameYourTurn => 'À vous';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'À vous · main $hand sur $total';
  }

  @override
  String get gameDealerPlaying => 'Le croupier joue';

  @override
  String get gameRoundResult => 'Résultat';

  @override
  String get gameBronzeTable => 'Table bronze';

  @override
  String get gameSilverTable => 'Table argent';

  @override
  String get gameVipTable => 'Table VIP';

  @override
  String get gameLost => 'perdu';
}
