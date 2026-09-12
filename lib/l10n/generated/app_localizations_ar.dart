// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsSectionAvatarColor => 'لون الصورة الرمزية';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionLanguage => 'اللغة';

  @override
  String get settingsSectionSoundHaptics => 'الصوت والاهتزاز';

  @override
  String get settingsSectionNotifications => 'الإشعارات';

  @override
  String get settingsSectionHelp => 'المساعدة';

  @override
  String get settingsSectionAbout => 'حول التطبيق';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول…';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get signOutConfirmMessage =>
      'ستبقى رقائقك وإحصائياتك على هذا الجهاز، لكنك ستغادر مجموعة أصدقائك ومكانك في لوحة المتصدرين حتى تسجّل الدخول مرة أخرى.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'لون الصورة الرمزية $index من $total';
  }

  @override
  String get themeDefault => 'افتراضي';

  @override
  String get themeOcean => 'المحيط';

  @override
  String get themeEmber => 'الجمر';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'طاولة $label';
  }

  @override
  String get hapticsLabel => 'الاهتزاز';

  @override
  String get soundEffectsLabel => 'المؤثرات الصوتية';

  @override
  String get voiceCalloutsLabel => 'التعليقات الصوتية';

  @override
  String get voiceCalloutsSublabel =>
      'يُعلَن مجموع أوراقك والنتائج ومبلغ القدر بصوت مسموع';

  @override
  String get voiceCalloutsDisabledReason =>
      'فعّل المؤثرات الصوتية لاستخدام التعليقات الصوتية';

  @override
  String get notifSocialLabel => 'اجتماعي';

  @override
  String get notifSocialSublabel =>
      'عندما ينضم صديق إلى مجموعتك أو يتصل بالإنترنت أو يتخطاك';

  @override
  String get notifLeaderboardLabel => 'لوحة المتصدرين';

  @override
  String get notifLeaderboardSublabel =>
      'عندما يتغيّر ترتيبك في اللوحة الساعية أو اليومية';

  @override
  String get notifDailyLabel => 'تذكير يومي';

  @override
  String get notifDailySublabel =>
      'تنبيه واحد يوميًا عندما تصبح مكافأتك اليومية جاهزة';

  @override
  String get howToPlayLabel => 'كيفية اللعب';

  @override
  String get howToPlaySublabel => 'القواعد والحركات والمدفوعات ومبلغ القدر';

  @override
  String get replayTutorialLabel => 'إعادة عرض الشرح';

  @override
  String replayTutorialSublabel(int count) {
    return 'بطاقات إرشادية خلال $count أيدٍ القادمة';
  }

  @override
  String get termsOfServiceLabel => 'شروط الخدمة';

  @override
  String get termsOfServiceSublabel => 'ما توافق عليه عند اللعب';

  @override
  String get privacyPolicyLabel => 'سياسة الخصوصية';

  @override
  String get privacyPolicySublabel => 'ما يبقى على هذا الجهاز وما لا يبقى';

  @override
  String get moreGamesVideoPokerLabel => 'ألعاب أخرى: فيديو بوكر';

  @override
  String get moreGamesVideoPokerSublabel => 'فيديو بوكر مجاني، بدون إعلانات';

  @override
  String get moreGamesOpenFailed => 'تعذّر فتح Google Play';

  @override
  String get versionLabel => 'الإصدار';

  @override
  String get languagePickerSublabel => 'تتبع القوائم وصوت الموزّع هذا الاختيار';

  @override
  String get languageSystemDefault => 'مطابقة لغة الجهاز';

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
  String get playNow => 'العب الآن';

  @override
  String get welcomeBenefit =>
      'أوراق كبيرة وواضحة. تعلّم أثناء اللعب، جولة بعد جولة.';

  @override
  String get continueGoogle => 'المتابعة باستخدام Google';

  @override
  String get gameHit => 'سحب';

  @override
  String get gameStand => 'وقوف';

  @override
  String get gameDouble => 'مضاعفة';

  @override
  String get gameSplit => 'تقسيم';

  @override
  String get gameSurrender => 'استسلام';

  @override
  String get gameDeal => 'توزيع';

  @override
  String get gameClear => 'مسح';

  @override
  String get gameAllIn => 'الكل';

  @override
  String get gameBet => 'الرهان';

  @override
  String gameMinimum(String amount) {
    return 'الأدنى $amount';
  }

  @override
  String gameRebet(String amount) {
    return 'توزيع مجدداً بـ $amount';
  }

  @override
  String gameMinimumHint(String amount) {
    return 'راهن بما لا يقل عن $amount للتوزيع';
  }

  @override
  String get gamePracticeBots => 'تلعب مع روبوتات للتدريب';

  @override
  String get gameInvite => 'دعوة الأصدقاء';

  @override
  String get gameNextHand => 'الجولة التالية';

  @override
  String get gameInsure => 'تأمين';

  @override
  String get gameNoThanks => 'لا شكراً';

  @override
  String gameInsuranceOffer(String amount) {
    return 'لدى الموزع آس. تأمين مقابل $amount؟ يدفع 2:1.';
  }

  @override
  String get gameYouBet => 'رهانك';

  @override
  String get gameAgainstDealer => 'اليد مقابل الموزع';

  @override
  String get gameSweepPot => 'وعاء الاكتساح';

  @override
  String get gameBalance => 'الرصيد';

  @override
  String get gameWin => 'فزت!';

  @override
  String get gameLose => 'فاز الموزع';

  @override
  String get gamePush => 'تعادل';

  @override
  String get gameDealerBlackjack => 'لدى الموزع بلاك جاك';

  @override
  String get gameBlackjackWin => 'بلاك جاك! فزت';

  @override
  String get gameSweepWin => 'اكتسحت الطاولة';

  @override
  String get gameBlackjackSweep => 'بلاك جاك — الوعاء لك';

  @override
  String gameShowdown(String you, String dealer) {
    return 'أنت $you · الموزع $dealer';
  }

  @override
  String get gameNoPot => 'لا يوجد وعاء اكتساح';

  @override
  String get gameDealerPot => 'الموزع يحتفظ بالوعاء';

  @override
  String get gameYourPot => 'الوعاء لك';

  @override
  String gameOtherPot(String name) {
    return 'الوعاء: $name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'رهان $bet + وعاء $pot';
  }

  @override
  String get gameNoForfeit => 'لم يخسر أي مقعد رهانه';

  @override
  String get gameNobodyBeat => 'لم يهزم أحد الموزع';

  @override
  String coachStep(String hand) {
    return 'تدريب · الجولة $hand من 3';
  }

  @override
  String get coachRules => 'القواعد';

  @override
  String get coachSkip => 'تخطّي';

  @override
  String get gameChipOptions => 'طرق الحصول على الرقائق';

  @override
  String get shotBigCards => 'أوراق كبيرة وواضحة';

  @override
  String get shotLearn => 'تعلّم أثناء اللعب';

  @override
  String get shotSweep => 'اكتسح الطاولة';

  @override
  String coachBetBody(String min) {
    return 'اضغط على رقاقة ثم توزيع. الحد الأدنى هنا $min لكل يد.';
  }

  @override
  String get coachNpcBody =>
      'تلعب روبوتات التدريب أولاً. يبدأ دورك عندما يتاح زرا السحب والوقوف.';

  @override
  String get coachPlayBody =>
      'اقترب من 21 أكثر من الموزع دون تجاوزها. السحب يضيف ورقة والوقوف ينهي دورك. تجاوز 21 يعني الخسارة.';

  @override
  String get coachSettleBody =>
      'تعرض النتيجة رهانك وعائد اليد ووعاء الاكتساح بشكل منفصل. تابع عندما تكون مستعداً.';

  @override
  String get coachDealerBody =>
      'يسحب الموزع تحت 17 ويقف عند أي 17. انظر إلى ورقته المكشوفة قبل اختيار حركتك.';

  @override
  String get coachPushBody =>
      'المجموع المتساوي تعادل ويعيد رهانك. تجاوز 21 يخسرك حتى لو تجاوزها الموزع أيضاً.';

  @override
  String get coachPotBody =>
      'رهانات المقاعد الأخرى الخاسرة تشكل الوعاء. اهزم الموزع بأفضل مجموع متبقٍ، ويُقبل التعادل مع مقعد آخر، لتأخذ الوعاء.';

  @override
  String get coachMovesBody =>
      'المضاعفة تضيف رهاناً مساوياً وورقة واحدة. التقسيم يفصل الزوج مع رهان إضافي. الاستسلام يعيد نصف رهان البداية.';

  @override
  String get coachDoneBody =>
      'أنهيت ثلاث جولات تدريبية. افتح القواعد أو أعد التدريب من الإعدادات متى شئت.';

  @override
  String get coachInsuranceBody =>
      'التأمين يكلف نصف رهانك ويدفع 2:1 فقط إذا كان لدى الموزع بلاك جاك. يمكنك رفضه.';

  @override
  String get guideCardsBody =>
      'الأوراق الرقمية بقيمتها. J وQ وK تساوي 10. الآس يساوي 1 أو 11 بما يُبقي اليد عند 21 أو أقل.';

  @override
  String get guidePayoutsBody =>
      'الفوز يدفع 1:1 والبلاك جاك الطبيعي 3:2. التعادل يعيد الرهان والاستسلام يعيد نصفه. بلاك جاك الموزع يهزم أي 21 غير طبيعي.';

  @override
  String get guideChipsBody =>
      'حدود الطاولة تظهر في الردهة. لإعادة التعبئة والمكافآت اليومية فترات انتظار؛ تحقق من خيارات الرقائق عند انخفاض رصيدك.';

  @override
  String get gameDealer => 'الموزع';

  @override
  String get gameBusted => 'تجاوز 21';

  @override
  String get gameWaiting => 'انتظار';

  @override
  String get gameBlackjack => 'بلاك جاك!';

  @override
  String get gameSurrendered => 'استسلام';

  @override
  String get gameSoft => 'مرن';

  @override
  String get gameHard => 'صلب';

  @override
  String get gameYouLead => 'أنت متصدر';

  @override
  String get gameTableSweep => 'اكتساح الطاولة';

  @override
  String get gameNoSweep => 'لا اكتساح';

  @override
  String get gameYouTake => 'الوعاء لك';

  @override
  String get gameDealerTakes => 'الموزع يأخذ';

  @override
  String gameOtherTakes(String name) {
    return '$name يأخذ';
  }

  @override
  String get gamePlaceBet => 'ضع رهانك';

  @override
  String get gameInsuranceOffered => 'التأمين متاح';

  @override
  String gameSeatPlaying(String name) {
    return '$name يلعب';
  }

  @override
  String get gameYourTurn => 'دورك';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'دورك · اليد $hand من $total';
  }

  @override
  String get gameDealerPlaying => 'الموزع يلعب';

  @override
  String get gameRoundResult => 'نتيجة الجولة';

  @override
  String get gameBronzeTable => 'طاولة برونزية';

  @override
  String get gameSilverTable => 'طاولة فضية';

  @override
  String get gameVipTable => 'طاولة VIP';

  @override
  String get gameLost => 'خسر';
}
