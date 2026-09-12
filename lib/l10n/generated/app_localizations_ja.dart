// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Blackjack 21';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionAccount => 'アカウント';

  @override
  String get settingsSectionAvatarColor => 'アバターの色';

  @override
  String get settingsSectionAppearance => '外観';

  @override
  String get settingsSectionLanguage => '言語';

  @override
  String get settingsSectionSoundHaptics => 'サウンドと触覚フィードバック';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionHelp => 'ヘルプ';

  @override
  String get settingsSectionAbout => 'アプリについて';

  @override
  String get signingIn => 'サインイン中…';

  @override
  String get signIn => 'サインイン';

  @override
  String get signOut => 'サインアウト';

  @override
  String get signOutConfirmTitle => 'サインアウトしますか？';

  @override
  String get signOutConfirmMessage =>
      'チップと統計はこの端末に残りますが、再度サインインするまでフレンドグループとランキングの順位から外れます。';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'アバターカラー $total 色中 $index 番目';
  }

  @override
  String get themeDefault => 'デフォルト';

  @override
  String get themeOcean => 'オーシャン';

  @override
  String get themeEmber => 'エンバー';

  @override
  String themeFeltSemanticLabel(String label) {
    return '$labelのテーブルフェルト';
  }

  @override
  String get hapticsLabel => '触覚フィードバック';

  @override
  String get soundEffectsLabel => '効果音';

  @override
  String get voiceCalloutsLabel => '音声コールアウト';

  @override
  String get voiceCalloutsSublabel => '手札の合計、結果、スイープポットを音声で読み上げます';

  @override
  String get voiceCalloutsDisabledReason => '音声コールアウトを使うには効果音をオンにしてください';

  @override
  String get notifSocialLabel => 'ソーシャル';

  @override
  String get notifSocialSublabel => 'フレンドがグループに参加、オンラインになる、またはあなたを追い抜いたとき';

  @override
  String get notifLeaderboardLabel => 'ランキング';

  @override
  String get notifLeaderboardSublabel => '1時間ごとまたは1日ごとのランキング順位が変わったとき';

  @override
  String get notifDailyLabel => 'デイリーリマインダー';

  @override
  String get notifDailySublabel => 'デイリーボーナスを受け取れるようになったら1日1回通知します';

  @override
  String get howToPlayLabel => '遊び方';

  @override
  String get howToPlaySublabel => 'ルール、操作、配当、スイープポットについて';

  @override
  String get replayTutorialLabel => 'チュートリアルをもう一度見る';

  @override
  String replayTutorialSublabel(int count) {
    return '次の$countハンドでコーチングカードを表示します';
  }

  @override
  String get termsOfServiceLabel => '利用規約';

  @override
  String get termsOfServiceSublabel => 'プレイすることで同意する内容';

  @override
  String get privacyPolicyLabel => 'プライバシーポリシー';

  @override
  String get privacyPolicySublabel => 'この端末に残るものと残らないもの';

  @override
  String get moreGamesVideoPokerLabel => '他のゲーム：ビデオポーカー';

  @override
  String get moreGamesVideoPokerSublabel => '無料のビデオポーカー、広告なし';

  @override
  String get moreGamesOpenFailed => 'Google Play を開けませんでした';

  @override
  String get versionLabel => 'バージョン';

  @override
  String get languagePickerSublabel => 'メニューとディーラーの音声もこの設定に従います';

  @override
  String get languageSystemDefault => '端末の言語に合わせる';

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
  String get playNow => '今すぐプレイ';

  @override
  String get welcomeBenefit => '大きく見やすいカード。プレイしながら一手ずつ学べます。';

  @override
  String get continueGoogle => 'Google で続ける';

  @override
  String get gameHit => 'ヒット';

  @override
  String get gameStand => 'スタンド';

  @override
  String get gameDouble => 'ダブル';

  @override
  String get gameSplit => 'スプリット';

  @override
  String get gameSurrender => 'サレンダー';

  @override
  String get gameDeal => 'ディール';

  @override
  String get gameClear => 'クリア';

  @override
  String get gameAllIn => '全額';

  @override
  String get gameBet => 'ベット';

  @override
  String gameMinimum(String amount) {
    return '最低 $amount';
  }

  @override
  String gameRebet(String amount) {
    return '$amount でもう一度';
  }

  @override
  String gameMinimumHint(String amount) {
    return '$amount 以上をベットしてください';
  }

  @override
  String get gamePracticeBots => '練習用ボットとプレイ中';

  @override
  String get gameInvite => '友達を招待';

  @override
  String get gameNextHand => '次のハンドへ';

  @override
  String get gameInsure => '保険をかける';

  @override
  String get gameNoThanks => 'いいえ';

  @override
  String gameInsuranceOffer(String amount) {
    return 'ディーラーの表札は A。$amount で保険をかけますか？配当は 2:1。';
  }

  @override
  String get gameYouBet => 'ベット額';

  @override
  String get gameAgainstDealer => '対ディーラー収支';

  @override
  String get gameSweepPot => 'スイープポット';

  @override
  String get gameBalance => '残高';

  @override
  String get gameWin => 'あなたの勝ち！';

  @override
  String get gameLose => 'ディーラーの勝ち';

  @override
  String get gamePush => '引き分け';

  @override
  String get gameDealerBlackjack => 'ディーラーがブラックジャック';

  @override
  String get gameBlackjackWin => 'ブラックジャック！あなたの勝ち';

  @override
  String get gameSweepWin => 'ポットを総取り';

  @override
  String get gameBlackjackSweep => 'ブラックジャック — 総取り';

  @override
  String gameShowdown(String you, String dealer) {
    return 'あなた $you · ディーラー $dealer';
  }

  @override
  String get gameNoPot => 'スイープポットなし';

  @override
  String get gameDealerPot => 'ディーラーがポットを保持';

  @override
  String get gameYourPot => 'ポットはあなたのもの';

  @override
  String gameOtherPot(String name) {
    return 'ポット：$name';
  }

  @override
  String gamePotBreakdown(String bet, String pot) {
    return 'ベット $bet + ポット $pot';
  }

  @override
  String get gameNoForfeit => 'ベットを失った席はありません';

  @override
  String get gameNobodyBeat => '誰もディーラーに勝てませんでした';

  @override
  String coachStep(String hand) {
    return 'ガイド · $hand/3 ハンド';
  }

  @override
  String get coachRules => 'ルール';

  @override
  String get coachSkip => 'スキップ';

  @override
  String get gameChipOptions => 'チップの獲得方法';

  @override
  String get shotBigCards => '大きく見やすいカード';

  @override
  String get shotLearn => 'プレイしながら学ぶ';

  @override
  String get shotSweep => 'ポットを総取り';

  @override
  String coachBetBody(String min) {
    return 'チップをタップし、ディールを押します。このテーブルの最低ベットは $min です。';
  }

  @override
  String get coachNpcBody => '練習用ボットが先にプレイします。ヒットとスタンドが使えるようになったら、あなたの番です。';

  @override
  String get coachPlayBody =>
      '21 を超えずにディーラーより 21 に近づけます。ヒットはカードを追加し、スタンドはターンを終了します。21 を超えると負けです。';

  @override
  String get coachSettleBody =>
      '結果にはベット、対ディーラー収支、スイープポットが別々に表示されます。準備ができたら続けましょう。';

  @override
  String get coachDealerBody =>
      'ディーラーは 17 未満で引き、すべての 17 で止まります。行動を選ぶ前にディーラーの表札を見ましょう。';

  @override
  String get coachPushBody => '同じ合計は引き分けでベットが戻ります。21 を超えると、ディーラーもバストしていても負けです。';

  @override
  String get coachPotBody =>
      '他の席が負けたベットがポットになります。ディーラーに勝ち、残る席以上の合計なら、同点でもポットを獲得します。';

  @override
  String get coachMovesBody =>
      'ダブルは同額を追加し、あと 1 枚だけ引きます。スプリットは追加ベットでペアを分けます。サレンダーは最初のベットの半分を戻します。';

  @override
  String get coachDoneBody =>
      '3 ハンドのガイドが終わりました。設定からいつでもルールを開いたり、ガイドをやり直したりできます。';

  @override
  String get coachInsuranceBody =>
      '保険はベットの半額で、ディーラーがブラックジャックのときだけ 2:1 を支払います。断ることもできます。';

  @override
  String get guideCardsBody =>
      '数字のカードはその数字、J・Q・K は 10 です。A は合計が 21 以下になるよう 1 または 11 と数えます。';

  @override
  String get guidePayoutsBody =>
      '勝利は 1:1、ナチュラルブラックジャックは 3:2 の配当です。引き分けはベット返却、サレンダーは半額返却。ディーラーのブラックジャックは通常の 21 に勝ちます。';

  @override
  String get guideChipsBody =>
      '各テーブルの上限・下限はロビーに表示されます。補充とデイリーボーナスには待ち時間があります。残高が少ないときはチップの獲得方法を確認してください。';

  @override
  String get gameDealer => 'ディーラー';

  @override
  String get gameBusted => 'バスト';

  @override
  String get gameWaiting => '待機中';

  @override
  String get gameBlackjack => 'ブラックジャック！';

  @override
  String get gameSurrendered => 'サレンダー';

  @override
  String get gameSoft => 'ソフト';

  @override
  String get gameHard => 'ハード';

  @override
  String get gameYouLead => 'リード中';

  @override
  String get gameTableSweep => '総取り';

  @override
  String get gameNoSweep => 'スイープなし';

  @override
  String get gameYouTake => 'あなたが獲得';

  @override
  String get gameDealerTakes => 'ディーラーが獲得';

  @override
  String gameOtherTakes(String name) {
    return '$name が獲得';
  }

  @override
  String get gamePlaceBet => 'ベットしてください';

  @override
  String get gameInsuranceOffered => '保険の選択';

  @override
  String gameSeatPlaying(String name) {
    return '$name がプレイ中';
  }

  @override
  String get gameYourTurn => 'あなたの番';

  @override
  String gameSplitTurn(String hand, String total) {
    return 'あなたの番 · $hand/$total ハンド';
  }

  @override
  String get gameDealerPlaying => 'ディーラーの番';

  @override
  String get gameRoundResult => 'ラウンド結果';

  @override
  String get gameBronzeTable => 'ブロンズテーブル';

  @override
  String get gameSilverTable => 'シルバーテーブル';

  @override
  String get gameVipTable => 'VIP テーブル';

  @override
  String get gameLost => '負け';
}
