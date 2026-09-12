// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSectionAccount => 'Conta';

  @override
  String get settingsSectionAvatarColor => 'Cor do avatar';

  @override
  String get settingsSectionAppearance => 'Aparência';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionSoundHaptics => 'Som e vibração';

  @override
  String get settingsSectionNotifications => 'Notificações';

  @override
  String get settingsSectionHelp => 'Ajuda';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get signingIn => 'Entrando…';

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get signOutConfirmTitle => 'Sair da conta?';

  @override
  String get signOutConfirmMessage =>
      'Suas fichas e estatísticas permanecem neste dispositivo, mas você sairá do seu grupo de amigos e da sua posição no ranking até entrar novamente.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Cor do avatar $index de $total';
  }

  @override
  String get themeDefault => 'Padrão';

  @override
  String get themeOcean => 'Oceano';

  @override
  String get themeEmber => 'Brasa';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'Mesa $label';
  }

  @override
  String get hapticsLabel => 'Vibração';

  @override
  String get soundEffectsLabel => 'Efeitos sonoros';

  @override
  String get voiceCalloutsLabel => 'Locução por voz';

  @override
  String get voiceCalloutsSublabel =>
      'Seu total na mão, os resultados e o pote são ditos em voz alta';

  @override
  String get voiceCalloutsDisabledReason =>
      'Ative os efeitos sonoros para usar a locução por voz';

  @override
  String get notifSocialLabel => 'Social';

  @override
  String get notifSocialSublabel =>
      'Quando um amigo entra no seu grupo, fica online ou te ultrapassa';

  @override
  String get notifLeaderboardLabel => 'Ranking';

  @override
  String get notifLeaderboardSublabel =>
      'Quando sua posição no ranking horário ou diário muda';

  @override
  String get notifDailyLabel => 'Lembrete diário';

  @override
  String get notifDailySublabel =>
      'Um aviso por dia, assim que seu bônus diário estiver pronto';

  @override
  String get howToPlayLabel => 'Como jogar';

  @override
  String get howToPlaySublabel => 'Regras, jogadas, pagamentos e o pote';

  @override
  String get replayTutorialLabel => 'Repetir o tutorial';

  @override
  String replayTutorialSublabel(int count) {
    return 'Cartões de dicas nas suas próximas $count mãos';
  }

  @override
  String get termsOfServiceLabel => 'Termos de Serviço';

  @override
  String get termsOfServiceSublabel => 'O que você aceita ao jogar';

  @override
  String get privacyPolicyLabel => 'Política de Privacidade';

  @override
  String get privacyPolicySublabel =>
      'O que fica neste dispositivo e o que não fica';

  @override
  String get moreGamesVideoPokerLabel => 'Mais jogos: Vídeo Pôquer';

  @override
  String get moreGamesVideoPokerSublabel => 'Vídeo pôquer grátis, sem anúncios';

  @override
  String get moreGamesOpenFailed => 'Não foi possível abrir o Google Play';

  @override
  String get versionLabel => 'Versão';

  @override
  String get languagePickerSublabel =>
      'Os menus e a voz do dealer seguem esta escolha';

  @override
  String get languageSystemDefault => 'Usar idioma do dispositivo';

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
  String get playNow => 'Jogar agora';

  @override
  String get welcomeBenefit =>
      'Cartas grandes e legíveis. Aprenda jogando, uma mão de cada vez.';

  @override
  String get continueGoogle => 'Continuar com Google';

  @override
  String get gameHit => 'PEDIR';

  @override
  String get gameStand => 'PARAR';

  @override
  String get gameDouble => 'DOBRAR';

  @override
  String get gameSplit => 'DIVIDIR';

  @override
  String get gameSurrender => 'DESISTIR';

  @override
  String get gameDeal => 'DISTRIBUIR';

  @override
  String get gameClear => 'LIMPAR';

  @override
  String get gameAllIn => 'TUDO';

  @override
  String get gameBet => 'Aposta';

  @override
  String gameMinimum(String amount) {
    return 'mín. $amount';
  }

  @override
  String gameRebet(String amount) {
    return 'REPETIR $amount';
  }

  @override
  String gameMinimumHint(String amount) {
    return 'Aposte pelo menos $amount para distribuir';
  }

  @override
  String get gamePracticeBots => 'Jogando com bots de treino';

  @override
  String get gameInvite => 'Convidar amigos';

  @override
  String get gameNextHand => 'PRÓXIMA MÃO';

  @override
  String get gameInsure => 'SEGURO';

  @override
  String get gameNoThanks => 'NÃO, OBRIGADO';

  @override
  String gameInsuranceOffer(String amount) {
    return 'O dealer mostra um ás. Seguro por $amount? Paga 2:1.';
  }

  @override
  String get gameYouBet => 'Sua aposta';

  @override
  String get gameAgainstDealer => 'Mão contra dealer';

  @override
  String get gameSweepPot => 'Pote da varredura';

  @override
  String get gameBalance => 'Saldo';

  @override
  String get gameWin => 'Você ganhou!';

  @override
  String get gameLose => 'O dealer ganhou';

  @override
  String get gamePush => 'Empate';

  @override
  String get gameDealerBlackjack => 'O dealer tem blackjack';

  @override
  String get gameBlackjackWin => 'Blackjack! Você ganhou';

  @override
  String get gameSweepWin => 'Você levou o pote';

  @override
  String get gameBlackjackSweep => 'Blackjack — você levou tudo';

  @override
  String gameShowdown(String you, String dealer) {
    return 'VOCÊ $you · DEALER $dealer';
  }

  @override
  String get gameNoPot => 'Sem pote de varredura';

  @override
  String get gameDealerPot => 'O dealer fica com o pote';

  @override
  String get gameYourPot => 'O pote é seu';

  @override
  String gameOtherPot(String name) {
    return 'Pote: $name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'APOSTA $bet + POTE $pot';
  }

  @override
  String get gameNoForfeit => 'Ninguém perdeu a aposta';

  @override
  String get gameNobodyBeat => 'Ninguém venceu o dealer';

  @override
  String coachStep(String hand) {
    return 'GUIA · MÃO $hand DE 3';
  }

  @override
  String get coachRules => 'Regras';

  @override
  String get coachSkip => 'Pular';

  @override
  String get gameChipOptions => 'Como obter fichas';

  @override
  String get shotBigCards => 'Cartas grandes e legíveis';

  @override
  String get shotLearn => 'Aprenda jogando';

  @override
  String get shotSweep => 'Leve o pote';

  @override
  String coachBetBody(String min) {
    return 'Toque numa ficha e depois DISTRIBUIR. A aposta mínima é $min por mão.';
  }

  @override
  String get coachNpcBody =>
      'Os bots jogam primeiro. Seu turno começa quando PEDIR e PARAR ficam disponíveis.';

  @override
  String get coachPlayBody =>
      'Chegue mais perto de 21 que o dealer sem ultrapassar. PEDIR adiciona uma carta; PARAR encerra seu turno. Passar de 21 perde.';

  @override
  String get coachSettleBody =>
      'O resultado separa sua aposta, o retorno da mão e o pote. Continue quando quiser.';

  @override
  String get coachDealerBody =>
      'O dealer pede abaixo de 17 e para em qualquer 17. Observe a carta visível dele antes de decidir.';

  @override
  String get coachPushBody =>
      'O mesmo total dá empate e devolve sua aposta. Passar de 21 perde mesmo se o dealer também passar.';

  @override
  String get coachPotBody =>
      'Apostas perdidas dos outros assentos formam o pote. Vença o dealer com o melhor total restante, mesmo empatado com outro assento, para levá-lo.';

  @override
  String get coachMovesBody =>
      'DOBRAR acrescenta uma aposta igual e uma carta. DIVIDIR separa um par com outra aposta. DESISTIR devolve metade da aposta inicial.';

  @override
  String get coachDoneBody =>
      'Você terminou as três mãos guiadas. Abra as regras ou repita o tutorial nas Configurações.';

  @override
  String get coachInsuranceBody =>
      'O seguro custa metade da aposta e paga 2:1 somente se o dealer tiver blackjack. Você pode recusar.';

  @override
  String get guideCardsBody =>
      'Cartas numéricas mantêm seu valor. J, Q e K valem 10. O ás vale 1 ou 11 para manter a mão em 21 ou menos.';

  @override
  String get guidePayoutsBody =>
      'Vitória paga 1:1 e blackjack natural 3:2. Empate devolve a aposta e desistência devolve metade. O blackjack do dealer vence um 21 não natural.';

  @override
  String get guideChipsBody =>
      'Os limites aparecem no lobby. Recargas e bônus diários têm tempo de espera; veja as opções de fichas quando o saldo estiver baixo.';

  @override
  String get gameDealer => 'DEALER';

  @override
  String get gameBusted => 'Estourou';

  @override
  String get gameWaiting => 'Aguardando';

  @override
  String get gameBlackjack => 'Blackjack!';

  @override
  String get gameSurrendered => 'Desistiu';

  @override
  String get gameSoft => 'Suave';

  @override
  String get gameHard => 'Dura';

  @override
  String get gameYouLead => 'VOCÊ LIDERA';

  @override
  String get gameTableSweep => 'VARREDURA';

  @override
  String get gameNoSweep => 'SEM VARREDURA';

  @override
  String get gameYouTake => 'VOCÊ LEVA';

  @override
  String get gameDealerTakes => 'DEALER LEVA';

  @override
  String gameOtherTakes(String name) {
    return '$name LEVA';
  }

  @override
  String get gamePlaceBet => 'Faça sua aposta';

  @override
  String get gameInsuranceOffered => 'Seguro disponível';

  @override
  String gameSeatPlaying(String name) {
    return '$name está jogando';
  }

  @override
  String get gameYourTurn => 'Sua vez';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'Sua vez · mão $hand de $total';
  }

  @override
  String get gameDealerPlaying => 'O dealer está jogando';

  @override
  String get gameRoundResult => 'Resultado';

  @override
  String get gameBronzeTable => 'Mesa de bronze';

  @override
  String get gameSilverTable => 'Mesa de prata';

  @override
  String get gameVipTable => 'Mesa VIP';

  @override
  String get gameLost => 'perdeu';
}
