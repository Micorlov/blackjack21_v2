// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionAccount => 'Аккаунт';

  @override
  String get settingsSectionAvatarColor => 'Цвет аватара';

  @override
  String get settingsSectionAppearance => 'Оформление';

  @override
  String get settingsSectionLanguage => 'Язык';

  @override
  String get settingsSectionSoundHaptics => 'Звук и вибрация';

  @override
  String get settingsSectionNotifications => 'Уведомления';

  @override
  String get settingsSectionHelp => 'Помощь';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get signingIn => 'Вход…';

  @override
  String get signIn => 'Войти';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutConfirmTitle => 'Выйти из аккаунта?';

  @override
  String get signOutConfirmMessage =>
      'Ваши фишки и статистика останутся на этом устройстве, но вы покинете группу друзей и своё место в рейтинге до следующего входа.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Цвет аватара $index из $total';
  }

  @override
  String get themeDefault => 'Стандартный';

  @override
  String get themeOcean => 'Океан';

  @override
  String get themeEmber => 'Уголь';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'Сукно стола «$label»';
  }

  @override
  String get hapticsLabel => 'Вибрация';

  @override
  String get soundEffectsLabel => 'Звуковые эффекты';

  @override
  String get voiceCalloutsLabel => 'Голосовые объявления';

  @override
  String get voiceCalloutsSublabel =>
      'Сумма ваших карт, результаты и общий банк озвучиваются вслух';

  @override
  String get voiceCalloutsDisabledReason =>
      'Включите звуковые эффекты, чтобы использовать голосовые объявления';

  @override
  String get notifSocialLabel => 'Социальные';

  @override
  String get notifSocialSublabel =>
      'Когда друг присоединяется к группе, выходит в сеть или обгоняет вас';

  @override
  String get notifLeaderboardLabel => 'Рейтинг';

  @override
  String get notifLeaderboardSublabel =>
      'Когда меняется ваше место в почасовом или дневном рейтинге';

  @override
  String get notifDailyLabel => 'Ежедневное напоминание';

  @override
  String get notifDailySublabel =>
      'Одно напоминание в день, когда готов ежедневный бонус';

  @override
  String get howToPlayLabel => 'Как играть';

  @override
  String get howToPlaySublabel => 'Правила, ходы, выплаты и общий банк';

  @override
  String get replayTutorialLabel => 'Повторить обучение';

  @override
  String replayTutorialSublabel(int count) {
    return 'Подсказки на следующие $count раздачи';
  }

  @override
  String get termsOfServiceLabel => 'Условия использования';

  @override
  String get termsOfServiceSublabel => 'Что вы принимаете, играя в игру';

  @override
  String get privacyPolicyLabel => 'Политика конфиденциальности';

  @override
  String get privacyPolicySublabel =>
      'Что остаётся на этом устройстве, а что нет';

  @override
  String get moreGamesVideoPokerLabel => 'Другие игры: Видеопокер';

  @override
  String get moreGamesVideoPokerSublabel =>
      'Бесплатный видеопокер, без рекламы';

  @override
  String get moreGamesOpenFailed => 'Не удалось открыть Google Play';

  @override
  String get versionLabel => 'Версия';

  @override
  String get languagePickerSublabel =>
      'Меню и голос дилера следуют этому выбору';

  @override
  String get languageSystemDefault => 'Как в системе устройства';

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
  String get playNow => 'Играть';

  @override
  String get welcomeBenefit =>
      'Крупные, чёткие карты. Учитесь играя, раздача за раздачей.';

  @override
  String get continueGoogle => 'Продолжить с Google';

  @override
  String get gameHit => 'КАРТУ';

  @override
  String get gameStand => 'ХВАТИТ';

  @override
  String get gameDouble => 'УДВОИТЬ';

  @override
  String get gameSplit => 'РАЗДЕЛИТЬ';

  @override
  String get gameSurrender => 'СДАТЬСЯ';

  @override
  String get gameDeal => 'РАЗДАТЬ';

  @override
  String get gameClear => 'СБРОС';

  @override
  String get gameAllIn => 'ВСЁ';

  @override
  String get gameBet => 'Ставка';

  @override
  String gameMinimum(String amount) {
    return 'мин. $amount';
  }

  @override
  String gameRebet(String amount) {
    return 'ПОВТОРИТЬ $amount';
  }

  @override
  String gameMinimumHint(String amount) {
    return 'Для раздачи поставьте не менее $amount';
  }

  @override
  String get gamePracticeBots => 'Игра с тренировочными ботами';

  @override
  String get gameInvite => 'Пригласить друзей';

  @override
  String get gameNextHand => 'СЛЕДУЮЩАЯ РАЗДАЧА';

  @override
  String get gameInsure => 'СТРАХОВКА';

  @override
  String get gameNoThanks => 'НЕТ, СПАСИБО';

  @override
  String gameInsuranceOffer(String amount) {
    return 'У дилера туз. Страховка за $amount? Выплата 2:1.';
  }

  @override
  String get gameYouBet => 'Ваша ставка';

  @override
  String get gameAgainstDealer => 'Рука против дилера';

  @override
  String get gameSweepPot => 'Общий банк';

  @override
  String get gameBalance => 'Баланс';

  @override
  String get gameWin => 'Вы выиграли!';

  @override
  String get gameLose => 'Дилер выиграл';

  @override
  String get gamePush => 'Ничья';

  @override
  String get gameDealerBlackjack => 'У дилера блэкджек';

  @override
  String get gameBlackjackWin => 'Блэкджек! Вы выиграли';

  @override
  String get gameSweepWin => 'Вы забираете банк';

  @override
  String get gameBlackjackSweep => 'Блэкджек — банк ваш';

  @override
  String gameShowdown(String you, String dealer) {
    return 'ВЫ $you · ДИЛЕР $dealer';
  }

  @override
  String get gameNoPot => 'Общего банка нет';

  @override
  String get gameDealerPot => 'Банк остаётся у дилера';

  @override
  String get gameYourPot => 'Банк ваш';

  @override
  String gameOtherPot(String name) {
    return 'Банк: $name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'СТАВКА $bet + БАНК $pot';
  }

  @override
  String get gameNoForfeit => 'Никто не потерял ставку';

  @override
  String get gameNobodyBeat => 'Никто не победил дилера';

  @override
  String coachStep(String hand) {
    return 'УРОК · РАЗДАЧА $hand ИЗ 3';
  }

  @override
  String get coachRules => 'Правила';

  @override
  String get coachSkip => 'Пропустить';

  @override
  String get gameChipOptions => 'Как получить фишки';

  @override
  String get shotBigCards => 'Крупные, чёткие карты';

  @override
  String get shotLearn => 'Учитесь играя';

  @override
  String get shotSweep => 'Заберите весь банк';

  @override
  String coachBetBody(String min) {
    return 'Нажмите на фишку, затем РАЗДАТЬ. Минимальная ставка здесь — $min за руку.';
  }

  @override
  String get coachNpcBody =>
      'Боты играют первыми. Ваш ход начнётся, когда станут доступны КАРТУ и ХВАТИТ.';

  @override
  String get coachPlayBody =>
      'Наберите ближе к 21, чем дилер, не превышая 21. КАРТУ добавляет карту, ХВАТИТ завершает ход. Перебор проигрывает.';

  @override
  String get coachSettleBody =>
      'Результат отдельно показывает ставку, возврат по руке и общий банк. Продолжайте, когда готовы.';

  @override
  String get coachDealerBody =>
      'Дилер берёт карты до 17 и останавливается на любых 17. Перед решением посмотрите на его открытую карту.';

  @override
  String get coachPushBody =>
      'Равные суммы дают ничью и возврат ставки. Перебор проигрывает, даже если у дилера тоже перебор.';

  @override
  String get coachPotBody =>
      'Проигранные ставки других мест образуют банк. Победите дилера с лучшей оставшейся суммой, включая равенство с другим местом, чтобы забрать банк.';

  @override
  String get coachMovesBody =>
      'УДВОИТЬ добавляет равную ставку и одну карту. РАЗДЕЛИТЬ делит пару с новой ставкой. СДАТЬСЯ возвращает половину начальной ставки.';

  @override
  String get coachDoneBody =>
      'Вы завершили три учебные раздачи. Правила и повтор обучения доступны в настройках.';

  @override
  String get coachInsuranceBody =>
      'Страховка стоит половину ставки и платит 2:1 только при блэкджеке дилера. Можно отказаться.';

  @override
  String get guideCardsBody =>
      'Числовые карты равны номиналу. J, Q и K стоят 10. Туз даёт 1 или 11, чтобы сумма не превышала 21.';

  @override
  String get guidePayoutsBody =>
      'Победа платит 1:1, натуральный блэкджек — 3:2. Ничья возвращает ставку, сдача — половину. Блэкджек дилера побеждает ненатуральные 21.';

  @override
  String get guideChipsBody =>
      'Лимиты столов указаны в лобби. Пополнение и ежедневный бонус имеют период ожидания; при малом балансе смотрите способы получения фишек.';

  @override
  String get gameDealer => 'ДИЛЕР';

  @override
  String get gameBusted => 'Перебор';

  @override
  String get gameWaiting => 'Ожидание';

  @override
  String get gameBlackjack => 'Блэкджек!';

  @override
  String get gameSurrendered => 'Сдача';

  @override
  String get gameSoft => 'Мягкие';

  @override
  String get gameHard => 'Жёсткие';

  @override
  String get gameYouLead => 'ВЫ ЛИДИРУЕТЕ';

  @override
  String get gameTableSweep => 'ВЕСЬ БАНК';

  @override
  String get gameNoSweep => 'БЕЗ БАНКА';

  @override
  String get gameYouTake => 'БАНК ВАШ';

  @override
  String get gameDealerTakes => 'БЕРЁТ ДИЛЕР';

  @override
  String gameOtherTakes(String name) {
    return 'БЕРЁТ $name';
  }

  @override
  String get gamePlaceBet => 'Сделайте ставку';

  @override
  String get gameInsuranceOffered => 'Предложена страховка';

  @override
  String gameSeatPlaying(String name) {
    return 'Играет $name';
  }

  @override
  String get gameYourTurn => 'Ваш ход';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'Ваш ход · рука $hand из $total';
  }

  @override
  String get gameDealerPlaying => 'Дилер играет';

  @override
  String get gameRoundResult => 'Результат';

  @override
  String get gameBronzeTable => 'Бронзовый стол';

  @override
  String get gameSilverTable => 'Серебряный стол';

  @override
  String get gameVipTable => 'VIP-стол';

  @override
  String get gameLost => 'проигрыш';
}
