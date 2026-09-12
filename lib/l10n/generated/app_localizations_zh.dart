// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionAccount => '账户';

  @override
  String get settingsSectionAvatarColor => '头像颜色';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsSectionSoundHaptics => '声音与震动';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionHelp => '帮助';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get signingIn => '正在登录…';

  @override
  String get signIn => '登录';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirmTitle => '要退出登录吗？';

  @override
  String get signOutConfirmMessage =>
      '你的筹码和统计数据会保留在此设备上，但在重新登录之前，你将离开好友群组并失去排行榜名次。';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return '头像颜色 $index／$total';
  }

  @override
  String get themeDefault => '默认';

  @override
  String get themeOcean => '海洋';

  @override
  String get themeEmber => '余烬';

  @override
  String themeFeltSemanticLabel(String label) {
    return '$label牌桌';
  }

  @override
  String get hapticsLabel => '震动';

  @override
  String get soundEffectsLabel => '音效';

  @override
  String get voiceCalloutsLabel => '语音播报';

  @override
  String get voiceCalloutsSublabel => '你的手牌点数、结果和彩池金额都会语音播报';

  @override
  String get voiceCalloutsDisabledReason => '开启音效后才能使用语音播报';

  @override
  String get notifSocialLabel => '社交';

  @override
  String get notifSocialSublabel => '好友加入群组、上线或超过你时提醒';

  @override
  String get notifLeaderboardLabel => '排行榜';

  @override
  String get notifLeaderboardSublabel => '你在每小时或每日榜单中的名次变化时提醒';

  @override
  String get notifDailyLabel => '每日提醒';

  @override
  String get notifDailySublabel => '每日奖励可领取时提醒一次';

  @override
  String get howToPlayLabel => '玩法说明';

  @override
  String get howToPlaySublabel => '规则、操作、赔付和彩池';

  @override
  String get replayTutorialLabel => '重新观看教程';

  @override
  String replayTutorialSublabel(int count) {
    return '接下来 $count 局会显示提示卡';
  }

  @override
  String get termsOfServiceLabel => '服务条款';

  @override
  String get termsOfServiceSublabel => '你在游戏中所同意的内容';

  @override
  String get privacyPolicyLabel => '隐私政策';

  @override
  String get privacyPolicySublabel => '哪些信息保留在本设备上，哪些不会';

  @override
  String get moreGamesVideoPokerLabel => '更多游戏：视频扑克';

  @override
  String get moreGamesVideoPokerSublabel => '免费视频扑克，无广告';

  @override
  String get moreGamesOpenFailed => '无法打开 Google Play';

  @override
  String get versionLabel => '版本';

  @override
  String get languagePickerSublabel => '菜单和荷官语音都会跟随此设置';

  @override
  String get languageSystemDefault => '跟随设备语言';

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
  String get playNow => '立即开始';

  @override
  String get welcomeBenefit => '大号清晰纸牌。边玩边学，逐手掌握。';

  @override
  String get continueGoogle => '使用 Google 继续';

  @override
  String get gameHit => '要牌';

  @override
  String get gameStand => '停牌';

  @override
  String get gameDouble => '加倍';

  @override
  String get gameSplit => '分牌';

  @override
  String get gameSurrender => '投降';

  @override
  String get gameDeal => '发牌';

  @override
  String get gameClear => '清除';

  @override
  String get gameAllIn => '全押';

  @override
  String get gameBet => '下注';

  @override
  String gameMinimum(String amount) {
    return '最低 $amount';
  }

  @override
  String gameRebet(String amount) {
    return '再次下注 $amount';
  }

  @override
  String gameMinimumHint(String amount) {
    return '至少下注 $amount 才能发牌';
  }

  @override
  String get gamePracticeBots => '正在与练习机器人对局';

  @override
  String get gameInvite => '邀请好友';

  @override
  String get gameNextHand => '下一手';

  @override
  String get gameInsure => '保险';

  @override
  String get gameNoThanks => '不用了';

  @override
  String gameInsuranceOffer(String amount) {
    return '庄家明牌为 A。花 $amount 买保险？赔率为 2:1。';
  }

  @override
  String get gameYouBet => '你的下注';

  @override
  String get gameAgainstDealer => '对庄家净收益';

  @override
  String get gameSweepPot => '横扫底池';

  @override
  String get gameBalance => '余额';

  @override
  String get gameWin => '你赢了！';

  @override
  String get gameLose => '庄家获胜';

  @override
  String get gamePush => '平局';

  @override
  String get gameDealerBlackjack => '庄家有黑杰克';

  @override
  String get gameBlackjackWin => '黑杰克！你赢了';

  @override
  String get gameSweepWin => '你横扫了全桌';

  @override
  String get gameBlackjackSweep => '黑杰克 — 底池归你';

  @override
  String gameShowdown(String you, String dealer) {
    return '你 $you · 庄家 $dealer';
  }

  @override
  String get gameNoPot => '没有横扫底池';

  @override
  String get gameDealerPot => '庄家保留底池';

  @override
  String get gameYourPot => '底池归你';

  @override
  String gameOtherPot(String name) {
    return '底池：$name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return '下注 $bet + 底池 $pot';
  }

  @override
  String get gameNoForfeit => '没有座位输掉下注';

  @override
  String get gameNobodyBeat => '无人击败庄家';

  @override
  String coachStep(String hand) {
    return '教学 · 第 $hand 手，共 3 手';
  }

  @override
  String get coachRules => '规则';

  @override
  String get coachSkip => '跳过';

  @override
  String get gameChipOptions => '获取筹码的方法';

  @override
  String get shotBigCards => '大号清晰纸牌';

  @override
  String get shotLearn => '边玩边学';

  @override
  String get shotSweep => '横扫全桌';

  @override
  String coachBetBody(String min) {
    return '点击筹码，再点发牌。本桌每手最低下注 $min。';
  }

  @override
  String get coachNpcBody => '练习机器人先行动。要牌和停牌按钮可用时，就轮到你了。';

  @override
  String get coachPlayBody => '比庄家更接近 21 点，但不要超过。要牌增加一张牌，停牌结束回合。超过 21 点即输。';

  @override
  String get coachSettleBody => '结果分别显示下注、对庄家收益和横扫底池。准备好后继续。';

  @override
  String get coachDealerBody => '庄家低于 17 点必须要牌，达到任意 17 点则停牌。行动前先看庄家的明牌。';

  @override
  String get coachPushBody => '点数相同为平局，退还下注。超过 21 点即输，即使庄家也爆牌。';

  @override
  String get coachPotBody => '其他座位输掉的下注组成底池。击败庄家且点数不低于其他未输座位，即可拿走底池。';

  @override
  String get coachMovesBody => '加倍需追加相同下注，只再发一张牌。分牌需追加下注，将一对拆成两手。投降退还开局下注的一半。';

  @override
  String get coachDoneBody => '三手教学已完成。随时可在设置中查看规则或重新开始教学。';

  @override
  String get coachInsuranceBody => '保险需支付下注的一半，仅当庄家有黑杰克时按 2:1 支付。你可以拒绝。';

  @override
  String get guideCardsBody =>
      '数字牌按牌面计点，J、Q、K 为 10 点。A 可算 1 或 11 点，以使手牌不超过 21 点。';

  @override
  String get guidePayoutsBody =>
      '获胜按 1:1 支付，天然黑杰克按 3:2 支付。平局退回下注，投降退回一半。庄家黑杰克胜过非天然的 21 点。';

  @override
  String get guideChipsBody => '大厅列出各桌下注限额。补充筹码和每日奖励有冷却时间；余额不足时查看筹码获取选项。';

  @override
  String get gameDealer => '庄家';

  @override
  String get gameBusted => '爆牌';

  @override
  String get gameWaiting => '等待中';

  @override
  String get gameBlackjack => '黑杰克！';

  @override
  String get gameSurrendered => '已投降';

  @override
  String get gameSoft => '软';

  @override
  String get gameHard => '硬';

  @override
  String get gameYouLead => '你领先';

  @override
  String get gameTableSweep => '横扫全桌';

  @override
  String get gameNoSweep => '无横扫';

  @override
  String get gameYouTake => '归你';

  @override
  String get gameDealerTakes => '庄家拿走';

  @override
  String gameOtherTakes(String name) {
    return '$name 拿走';
  }

  @override
  String get gamePlaceBet => '请下注';

  @override
  String get gameInsuranceOffered => '可购买保险';

  @override
  String gameSeatPlaying(String name) {
    return '$name 正在行动';
  }

  @override
  String get gameYourTurn => '轮到你了';

  @override
  String gameSplitTurn(String hand, String total) {
    return '轮到你了 · 第 $hand/$total 手';
  }

  @override
  String get gameDealerPlaying => '庄家行动中';

  @override
  String get gameRoundResult => '本轮结果';

  @override
  String get gameBronzeTable => '青铜桌';

  @override
  String get gameSilverTable => '白银桌';

  @override
  String get gameVipTable => 'VIP 桌';

  @override
  String get gameLost => '输掉';
}
