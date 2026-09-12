// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsSectionAvatarColor => 'Color del avatar';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionSoundHaptics => 'Sonido y vibración';

  @override
  String get settingsSectionNotifications => 'Notificaciones';

  @override
  String get settingsSectionHelp => 'Ayuda';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get signingIn => 'Iniciando sesión…';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get signOutConfirmMessage =>
      'Tus fichas y estadísticas permanecen en este dispositivo, pero abandonarás tu grupo de amigos y tu posición en la clasificación hasta que vuelvas a iniciar sesión.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Color de avatar $index de $total';
  }

  @override
  String get themeDefault => 'Predeterminado';

  @override
  String get themeOcean => 'Océano';

  @override
  String get themeEmber => 'Ascua';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'Tapete $label';
  }

  @override
  String get hapticsLabel => 'Vibración';

  @override
  String get soundEffectsLabel => 'Efectos de sonido';

  @override
  String get voiceCalloutsLabel => 'Locución de voz';

  @override
  String get voiceCalloutsSublabel =>
      'Tu total de mano, los resultados y el bote se dicen en voz alta';

  @override
  String get voiceCalloutsDisabledReason =>
      'Activa los efectos de sonido para usar la locución de voz';

  @override
  String get notifSocialLabel => 'Social';

  @override
  String get notifSocialSublabel =>
      'Cuando un amigo se une a tu grupo, se conecta o te supera';

  @override
  String get notifLeaderboardLabel => 'Clasificación';

  @override
  String get notifLeaderboardSublabel =>
      'Cuando cambia tu posición en la tabla por hora o diaria';

  @override
  String get notifDailyLabel => 'Recordatorio diario';

  @override
  String get notifDailySublabel =>
      'Un aviso al día, cuando tu bono diario esté listo para reclamar';

  @override
  String get howToPlayLabel => 'Cómo jugar';

  @override
  String get howToPlaySublabel => 'Reglas, jugadas, pagos y el bote';

  @override
  String get replayTutorialLabel => 'Repetir el tutorial';

  @override
  String replayTutorialSublabel(int count) {
    return 'Tarjetas de ayuda en tus próximas $count manos';
  }

  @override
  String get termsOfServiceLabel => 'Términos del servicio';

  @override
  String get termsOfServiceSublabel => 'Lo que aceptas al jugar';

  @override
  String get privacyPolicyLabel => 'Política de privacidad';

  @override
  String get privacyPolicySublabel =>
      'Qué permanece en este dispositivo y qué no';

  @override
  String get moreGamesVideoPokerLabel => 'Más juegos: Video Póker';

  @override
  String get moreGamesVideoPokerSublabel => 'Video póker gratis, sin anuncios';

  @override
  String get moreGamesOpenFailed => 'No se pudo abrir Google Play';

  @override
  String get versionLabel => 'Versión';

  @override
  String get languagePickerSublabel =>
      'Los menús y la voz del crupier siguen esta opción';

  @override
  String get languageSystemDefault => 'Igual que el idioma del dispositivo';

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
  String get playNow => 'Jugar ahora';

  @override
  String get welcomeBenefit =>
      'Cartas grandes y legibles. Aprende jugando, mano a mano.';

  @override
  String get continueGoogle => 'Continuar con Google';

  @override
  String get gameHit => 'PEDIR';

  @override
  String get gameStand => 'PLANTARSE';

  @override
  String get gameDouble => 'DOBLAR';

  @override
  String get gameSplit => 'DIVIDIR';

  @override
  String get gameSurrender => 'RENDIRSE';

  @override
  String get gameDeal => 'REPARTIR';

  @override
  String get gameClear => 'BORRAR';

  @override
  String get gameAllIn => 'TODO';

  @override
  String get gameBet => 'Apuesta';

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
    return 'Apuesta al menos $amount para repartir';
  }

  @override
  String get gamePracticeBots => 'Jugando con bots de práctica';

  @override
  String get gameInvite => 'Invitar amigos';

  @override
  String get gameNextHand => 'SIGUIENTE MANO';

  @override
  String get gameInsure => 'ASEGURAR';

  @override
  String get gameNoThanks => 'NO, GRACIAS';

  @override
  String gameInsuranceOffer(String amount) {
    return 'El crupier muestra un as. ¿Seguro por $amount? Paga 2:1.';
  }

  @override
  String get gameYouBet => 'Tu apuesta';

  @override
  String get gameAgainstDealer => 'Mano contra crupier';

  @override
  String get gameSweepPot => 'Bote de barrido';

  @override
  String get gameBalance => 'Saldo';

  @override
  String get gameWin => '¡Ganaste!';

  @override
  String get gameLose => 'Gana el crupier';

  @override
  String get gamePush => 'Empate';

  @override
  String get gameDealerBlackjack => 'El crupier tiene blackjack';

  @override
  String get gameBlackjackWin => '¡Blackjack! Ganaste';

  @override
  String get gameSweepWin => 'Te llevas el bote';

  @override
  String get gameBlackjackSweep => 'Blackjack: barres la mesa';

  @override
  String gameShowdown(String you, String dealer) {
    return 'TÚ $you · CRUPIER $dealer';
  }

  @override
  String get gameNoPot => 'Sin bote de barrido';

  @override
  String get gameDealerPot => 'El crupier conserva el bote';

  @override
  String get gameYourPot => 'El bote es tuyo';

  @override
  String gameOtherPot(String name) {
    return 'Bote: $name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'APUESTA $bet + BOTE $pot';
  }

  @override
  String get gameNoForfeit => 'Nadie perdió su apuesta';

  @override
  String get gameNobodyBeat => 'Nadie venció al crupier';

  @override
  String coachStep(String hand) {
    return 'GUÍA · MANO $hand DE 3';
  }

  @override
  String get coachRules => 'Reglas';

  @override
  String get coachSkip => 'Omitir';

  @override
  String get gameChipOptions => 'Cómo conseguir fichas';

  @override
  String get shotBigCards => 'Cartas grandes y legibles';

  @override
  String get shotLearn => 'Aprende jugando';

  @override
  String get shotSweep => 'Barre la mesa';

  @override
  String coachBetBody(String min) {
    return 'Toca una ficha y luego REPARTIR. La apuesta mínima aquí es $min por mano.';
  }

  @override
  String get coachNpcBody =>
      'Los bots juegan primero. Tu turno comienza cuando PEDIR y PLANTARSE están disponibles.';

  @override
  String get coachPlayBody =>
      'Acércate más a 21 que el crupier sin pasarte. PEDIR añade una carta; PLANTARSE termina tu turno. Pasarte de 21 pierde.';

  @override
  String get coachSettleBody =>
      'El resultado separa tu apuesta, el retorno de la mano y el bote. Continúa cuando quieras.';

  @override
  String get coachDealerBody =>
      'El crupier pide con menos de 17 y se planta en cualquier 17. Mira su carta visible antes de decidir.';

  @override
  String get coachPushBody =>
      'El mismo total es empate y devuelve tu apuesta. Pasarte de 21 pierde aunque el crupier también se pase.';

  @override
  String get coachPotBody =>
      'Las apuestas perdidas de otros asientos forman el bote. Vence al crupier con el mejor total restante, incluidos empates con otro asiento, para llevártelo.';

  @override
  String get coachMovesBody =>
      'DOBLAR añade una apuesta igual y una carta. DIVIDIR separa una pareja con otra apuesta. RENDIRSE devuelve la mitad de la apuesta inicial.';

  @override
  String get coachDoneBody =>
      'Terminaste las tres manos guiadas. Puedes abrir las reglas o repetir el tutorial desde Ajustes.';

  @override
  String get coachInsuranceBody =>
      'El seguro cuesta la mitad de tu apuesta y paga 2:1 solo si el crupier tiene blackjack. Puedes rechazarlo.';

  @override
  String get guideCardsBody =>
      'Las cartas numéricas conservan su valor. J, Q y K valen 10. El as vale 1 u 11, manteniendo la mano en 21 o menos.';

  @override
  String get guidePayoutsBody =>
      'Una victoria paga 1:1 y blackjack natural 3:2. El empate devuelve la apuesta; rendirse devuelve la mitad. El blackjack del crupier vence a un 21 no natural.';

  @override
  String get guideChipsBody =>
      'Los límites aparecen en el vestíbulo. Las recargas y bonos diarios tienen tiempos de espera; consulta las opciones de fichas si te quedan pocas.';

  @override
  String get gameDealer => 'CRUPIER';

  @override
  String get gameBusted => 'Pasado';

  @override
  String get gameWaiting => 'Esperando';

  @override
  String get gameBlackjack => '¡Blackjack!';

  @override
  String get gameSurrendered => 'Rendido';

  @override
  String get gameSoft => 'Suave';

  @override
  String get gameHard => 'Dura';

  @override
  String get gameYouLead => 'VAS PRIMERO';

  @override
  String get gameTableSweep => 'BARRIDO';

  @override
  String get gameNoSweep => 'SIN BARRIDO';

  @override
  String get gameYouTake => 'TE LO LLEVAS';

  @override
  String get gameDealerTakes => 'GANA EL CRUPIER';

  @override
  String gameOtherTakes(String name) {
    return 'GANA $name';
  }

  @override
  String get gamePlaceBet => 'Haz tu apuesta';

  @override
  String get gameInsuranceOffered => 'Seguro disponible';

  @override
  String gameSeatPlaying(String name) {
    return '$name está jugando';
  }

  @override
  String get gameYourTurn => 'Tu turno';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'Tu turno · mano $hand de $total';
  }

  @override
  String get gameDealerPlaying => 'Juega el crupier';

  @override
  String get gameRoundResult => 'Resultado';

  @override
  String get gameBronzeTable => 'Mesa de bronce';

  @override
  String get gameSilverTable => 'Mesa de plata';

  @override
  String get gameVipTable => 'Mesa VIP';

  @override
  String get gameLost => 'perdió';
}
