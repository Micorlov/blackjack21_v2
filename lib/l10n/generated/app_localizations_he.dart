// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

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
  String get moreGamesVideoPokerLabel => 'משחקים נוספים: וידאו פוקר';

  @override
  String get moreGamesVideoPokerSublabel => 'וידאו פוקר חינם, בלי פרסומות';

  @override
  String get moreGamesOpenFailed => 'לא ניתן לפתוח את Google Play';

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
    return '🃏 בואו לשחק איתי Blackjack 21 — לחצו כדי להצטרף לשולחן שלי:\n$url';
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

  @override
  String get playNow => 'לשחק עכשיו';

  @override
  String get welcomeBenefit =>
      'קלפים גדולים וברורים. לומדים תוך כדי משחק, יד אחר יד.';

  @override
  String get continueGoogle => 'המשך עם Google';

  @override
  String get gameHit => 'קלף';

  @override
  String get gameStand => 'עמידה';

  @override
  String get gameDouble => 'הכפלה';

  @override
  String get gameSplit => 'פיצול';

  @override
  String get gameSurrender => 'כניעה';

  @override
  String get gameDeal => 'חלוקה';

  @override
  String get gameClear => 'ניקוי';

  @override
  String get gameAllIn => 'הכול';

  @override
  String get gameBet => 'הימור';

  @override
  String gameMinimum(String amount) {
    return 'מינ׳ $amount';
  }

  @override
  String gameRebet(String amount) {
    return 'שוב חלוקה ב־$amount';
  }

  @override
  String gameMinimumHint(String amount) {
    return 'יש להמר לפחות $amount לחלוקה';
  }

  @override
  String get gamePracticeBots => 'משחקים עם בוטים לתרגול';

  @override
  String get gameInvite => 'הזמנת חברים';

  @override
  String get gameNextHand => 'ליד הבאה';

  @override
  String get gameInsure => 'ביטוח';

  @override
  String get gameNoThanks => 'לא תודה';

  @override
  String gameInsuranceOffer(String amount) {
    return 'לדילר יש אס. ביטוח ב־$amount? משלם 2:1.';
  }

  @override
  String get gameYouBet => 'ההימור שלך';

  @override
  String get gameAgainstDealer => 'היד מול הדילר';

  @override
  String get gameSweepPot => 'קופת הסוויפ';

  @override
  String get gameBalance => 'יתרה';

  @override
  String get gameWin => 'ניצחת!';

  @override
  String get gameLose => 'הדילר ניצח';

  @override
  String get gamePush => 'תיקו';

  @override
  String get gameDealerBlackjack => 'לדילר יש בלאקג׳ק';

  @override
  String get gameBlackjackWin => 'בלאקג׳ק! ניצחת';

  @override
  String get gameSweepWin => 'לקחת את הקופה';

  @override
  String get gameBlackjackSweep => 'בלאקג׳ק — הקופה שלך';

  @override
  String gameShowdown(String you, String dealer) {
    return 'אתה $you · דילר $dealer';
  }

  @override
  String get gameNoPot => 'אין קופת סוויפ';

  @override
  String get gameDealerPot => 'הקופה נשארת אצל הדילר';

  @override
  String get gameYourPot => 'הקופה שלך';

  @override
  String gameOtherPot(String name) {
    return 'הקופה: $name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'הימור $bet + קופה $pot';
  }

  @override
  String get gameNoForfeit => 'אף שחקן לא הפסיד הימור';

  @override
  String get gameNobodyBeat => 'אף אחד לא ניצח את הדילר';

  @override
  String coachStep(String hand) {
    return 'הדרכה · יד $hand מתוך 3';
  }

  @override
  String get coachRules => 'כל הכללים';

  @override
  String get coachSkip => 'דילוג';

  @override
  String get gameChipOptions => 'דרכים להשיג צ׳יפים';

  @override
  String get shotBigCards => 'קלפים גדולים וברורים';

  @override
  String get shotLearn => 'לומדים תוך כדי משחק';

  @override
  String get shotSweep => 'לוקחים את הקופה';

  @override
  String coachBetBody(String min) {
    return 'נוגעים בצ׳יפ ואז בחלוקה. ההימור המינימלי בשולחן הוא $min ליד.';
  }

  @override
  String get coachNpcBody =>
      'בוטים לתרגול משחקים קודם. תורך מתחיל כשהכפתורים קלף ועמידה זמינים.';

  @override
  String get coachPlayBody =>
      'יש להתקרב ל־21 יותר מהדילר בלי לעבור אותו. קלף מוסיף קלף; עמידה מסיימת את התור. מעל 21 מפסידים.';

  @override
  String get coachSettleBody =>
      'התוצאה מציגה בנפרד את ההימור, הרווח מהיד וקופת הסוויפ. ממשיכים כשמוכנים.';

  @override
  String get coachDealerBody =>
      'הדילר מושך מתחת ל־17 ועומד על כל 17. לפני הפעולה כדאי להביט בקלף הגלוי שלו.';

  @override
  String get coachPushBody =>
      'סכום זהה הוא תיקו וההימור מוחזר. מעל 21 מפסידים גם אם הדילר עובר 21.';

  @override
  String get coachPotBody =>
      'הימורים ששחקנים אחרים הפסידו יוצרים את הקופה. ניצחון על הדילר עם הסכום הגבוה שנותר, גם בתיקו עם שחקן, מזכה בקופה.';

  @override
  String get coachMovesBody =>
      'הכפלה מוסיפה הימור זהה וקלף אחד. פיצול מפריד זוג עם הימור נוסף. כניעה מחזירה חצי מההימור הפותח.';

  @override
  String get coachDoneBody =>
      'סיימת שלוש ידיים מודרכות. אפשר לפתוח את הכללים או לחזור להדרכה בהגדרות בכל עת.';

  @override
  String get coachInsuranceBody =>
      'ביטוח עולה חצי מההימור ומשלם 2:1 רק אם לדילר יש בלאקג׳ק. אפשר לסרב.';

  @override
  String get guideCardsBody =>
      'קלפי מספר שווים לערכם. J, Q ו־K שווים 10. אס שווה 1 או 11, כך שהיד לא תעבור 21.';

  @override
  String get guidePayoutsBody =>
      'ניצחון משלם 1:1, בלאקג׳ק טבעי 3:2, תיקו מחזיר את ההימור וכניעה מחזירה חצי. בלאקג׳ק של הדילר מנצח 21 שאינו טבעי.';

  @override
  String get guideChipsBody =>
      'גבולות ההימור מופיעים בלובי. לחידוש צ׳יפים ולבונוס היומי יש זמני המתנה; כשהיתרה נמוכה, בדקו את האפשרויות לקבלת צ׳יפים.';

  @override
  String get gameDealer => 'דילר';

  @override
  String get gameBusted => 'נשרף';

  @override
  String get gameWaiting => 'בהמתנה';

  @override
  String get gameBlackjack => 'בלאקג׳ק!';

  @override
  String get gameSurrendered => 'כניעה';

  @override
  String get gameSoft => 'רך';

  @override
  String get gameHard => 'קשה';

  @override
  String get gameYouLead => 'אתה מוביל';

  @override
  String get gameTableSweep => 'לקיחת הקופה';

  @override
  String get gameNoSweep => 'אין סוויפ';

  @override
  String get gameYouTake => 'הקופה שלך';

  @override
  String get gameDealerTakes => 'הדילר לוקח';

  @override
  String gameOtherTakes(String name) {
    return '$name לוקח';
  }

  @override
  String get gamePlaceBet => 'זמן להמר';

  @override
  String get gameInsuranceOffered => 'הצעת ביטוח';

  @override
  String gameSeatPlaying(String name) {
    return '$name משחק';
  }

  @override
  String get gameYourTurn => 'תורך';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'תורך · יד $hand מתוך $total';
  }

  @override
  String get gameDealerPlaying => 'הדילר משחק';

  @override
  String get gameRoundResult => 'תוצאת הסיבוב';

  @override
  String get gameBronzeTable => 'שולחן ארד';

  @override
  String get gameSilverTable => 'שולחן כסף';

  @override
  String get gameVipTable => 'שולחן VIP';

  @override
  String get gameLost => 'הפסיד';
}
