using System;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The lobby: who you are and your balance, the daily bonus, and the tables.</summary>
    public sealed class LobbyScreen : ScreenView
    {
        private TextMeshProUGUI _name;
        private CountUpText _balance;
        private RectTransform _avatarHost;
        private Dyn _avatar, _bonus, _reward, _tables;
        private AppState _state;
        private float _nextMinuteCheck;
        private string _bonusLabel = "";

        public LobbyScreen(GameController g, Overlays o) : base(g, o) { }

        public override void Build(RectTransform parent)
        {
            Root = Ui.Node("Lobby", parent).Fill();
            var scroll = W.Scroll(Root, Ui.Pad(20, 16, 20, 24), 0, true, false, out _);
            scroll.Fill();
            var content = scroll.GetComponentInChildren<ScrollRect>().content;

            var header = Ui.HStack(content, 12, null, TextAnchor.MiddleLeft, false, "Header");
            _avatarHost = Ui.Node("Avatar", header);
            _avatarHost.Size(40, 40);
            _avatar = new Dyn(_avatarHost);
            _name = Ui.Text(header, "", 17, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            _name.Shrink();
            _name.rectTransform.FlexW();
            var coin = Ui.Text(header, "●", 13, Theme.Gold, FontKind.Mono, TextAlignmentOptions.Center, false);
            var bal = Ui.Text(header, "0", 18, Theme.TextPrimary, FontKind.MonoBold, TextAlignmentOptions.Right, false);
            _balance = CountUpText.Make(bal, 0);

            Ui.Spacer(content, 24);
            _bonus = new Dyn(Ui.VStack(content, 0, null, TextAnchor.UpperLeft, true, "Bonus"));
            _reward = new Dyn(Ui.VStack(content, 0, null, TextAnchor.UpperLeft, true, "Reward"));
            Ui.Spacer(content, 24);
            W.SectionLabel(content, Loc.Or("sectionTables", "Tables"));
            _tables = new Dyn(Ui.VStack(content, 10, null, TextAnchor.UpperLeft, true, "Tables"));
        }

        public override void Refresh(AppState s)
        {
            _state = s;
            _name.text = s.DisplayName;
            _balance.SetValue(s.Round.Chips);
            var initial = s.DisplayName.Trim().Length == 0 ? "?" : s.DisplayName.Trim().Substring(0, 1).ToUpperInvariant();
            _avatar.Update($"{initial}|{s.AvatarColor}", host => W.Avatar(host, initial, Theme.AvatarColorOf(s.AvatarColor), 40));

            var now = DateTime.Now;
            var ready = DailyBonus.IsReady(s.LastDailyBonusClaimAt, now);
            _bonusLabel = ready ? "" : DailyBonus.CountdownLabel(s.LastDailyBonusClaimAt.Value, now);
            _bonus.Update($"{ready}|{s.DailyBonusStreakDay}|{_bonusLabel}|{Loc.Code}", host => BuildBonus(host, s, ready));

            // Rewarded video: player-initiated, off the table and away from every gameplay button.
            var rewardLeft = AdReward.LeftToday(s.AdRewardsToday, s.AdRewardsDayKey, now);
            var rewardReady = G.RewardedOfferAvailable;
            var rewardWait = s.LastAdRewardAt.HasValue && !AdReward.IsReady(s.LastAdRewardAt, now) ? AdReward.CountdownLabel(s.LastAdRewardAt.Value, now) : "";
            var showReward = rewardReady || (s.LastAdRewardAt.HasValue && (rewardLeft == 0 || rewardWait.Length > 0) && AdReward.PaidToday(s.AdRewardsToday, s.AdRewardsDayKey, now) > 0);
            _reward.Update($"{showReward}|{rewardReady}|{rewardLeft}|{rewardWait}|{Loc.Code}", host =>
            {
                if (showReward) BuildReward(host, rewardReady, rewardLeft, rewardWait);
            });

            var here = s.FriendsAreLive ? s.Friends : new Friend[0];
            var recommended = TableRecommendation.For(s.Round.Chips).Key;
            var sig = $"{recommended}|{Loc.Code}|" + string.Join(",", TableCatalog.Tables.Select(t => Roster.AtTable(here, t.Key).Count));
            _tables.Update(sig, host =>
            {
                foreach (var table in TableCatalog.Tables)
                    BuildTable(host, table, Roster.AtTable(here, table.Key), table.Key == recommended);
            });
        }

        public override void Tick()
        {
            if (_state == null || Time.unscaledTime < _nextMinuteCheck) return;
            _nextMinuteCheck = Time.unscaledTime + 5f; // short: a rewarded video can finish loading a few seconds after the lobby opens
            Refresh(_state);
        }

        private void BuildReward(RectTransform host, bool ready, int left, string wait)
        {
            Ui.Spacer(host, 12);
            var card = W.Panel(host, Ui.Pad(16, 14), 0);
            var row = Ui.HStack(card, 12, null, TextAnchor.MiddleLeft, false);
            var col = Ui.VStack(row, 2, null, TextAnchor.MiddleLeft, true);
            col.FlexW();
            Ui.Text(col, Loc.T("rewardCardTitle"), 17, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            var sub = ready ? Loc.T("rewardCardReady", ("chips", TableCatalog.FormatChips(AdReward.Chips)), ("left", left))
                : left == 0 ? Loc.T("rewardCardTomorrow") : Loc.T("routeReadyIn", ("time", wait));
            Ui.Text(col, sub, 13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true);
            if (ready) W.GoldButton(row, "+" + TableCatalog.FormatChips(AdReward.Chips), G.WatchAdForChips, 12, 18, 15);
        }

        private void BuildBonus(RectTransform host, AppState s, bool ready)
        {
            var now = DateTime.Now;
            var claimDay = DailyBonus.NextStreakDay(s.DailyBonusStreakDay, s.LastDailyBonusClaimAt, now);
            var reward = DailyBonus.RewardForDay(claimDay);
            string sub;
            if (ready)
                sub = s.DailyBonusStreakDay > 0
                    ? Loc.Or("bonusDayOf", "Day {day} of your streak", ("day", claimDay))
                    : Loc.Or("bonusEveryDay", "+{chips} chips, every day", ("chips", TableCatalog.FormatChips(reward)));
            else sub = Loc.Or("bonusNextIn", "Next in {time}", ("time", _bonusLabel));

            var card = W.Panel(host, Ui.Pad(16, 14), 0);
            var row = Ui.HStack(card, 12, null, TextAnchor.MiddleLeft, false);
            var col = Ui.VStack(row, 2, null, TextAnchor.MiddleLeft, true);
            col.FlexW();
            Ui.Text(col, Loc.Or("dailyBonus", "Daily bonus"), 17, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            Ui.Text(col, sub, 13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true);
            if (ready)
                W.GoldButton(row, "+" + TableCatalog.FormatChips(reward), () => DailyBonusDialog.Show(G, Overlays), 12, 18, 15);
            else
            {
                var done = Ui.HStack(row, 4, null, TextAnchor.MiddleCenter, false);
                W.Icon(done, "check", 18, Theme.Win);
                Ui.Text(done, Loc.Or("claimed", "Claimed"), 15, Theme.Win, FontKind.SoraSemiBold, TextAlignmentOptions.Left, false);
            }
        }

        private void BuildTable(RectTransform host, TableStake table, System.Collections.Generic.IReadOnlyList<Friend> here, bool recommended)
        {
            var label = Roster.PresenceLabel(here);
            var tint = table.Key switch { "bronze" => Theme.Win, "silver" => Theme.Silver, "trio" => Theme.Win, "headsup" => Theme.Silver, _ => Theme.Gold };
            var card = Ui.Card(host, Theme.Panel, Theme.RadiusLg, recommended ? Theme.BorderStrong : Theme.Border, 1, Ui.Pad(14), 0, true, "Table_" + table.Key);
            var shell = (RectTransform)card.parent;
            var row = Ui.HStack(card, 14, null, TextAnchor.MiddleLeft, false);
            W.Dot(row, 12, tint);
            var col = Ui.VStack(row, 2, null, TextAnchor.MiddleLeft, true);
            col.FlexW();
            var title = table.Key switch
            {
                "bronze" => Loc.T("gameBronzeTable"), "silver" => Loc.T("gameSilverTable"), "vip" => Loc.T("gameVipTable"),
                "trio" => Loc.T("gameTrioTable"), "headsup" => Loc.T("gameHeadsUpTable"), _ => table.Name,
            };
            Ui.Text(col, title, 17, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            var range = $"${table.Min} – ${table.Max}";
            // The smaller rooms say what is different about them; the classic ladder needs no note.
            var note = table.Key switch { "trio" => Loc.T("lobbyTrioNote"), "headsup" => Loc.T("lobbyHeadsUpNote"), _ => "" };
            if (note.Length > 0) range += " · " + note;
            Ui.Text(col, label.Length == 0 ? range : range + " · " + label, 13, label.Length == 0 ? Theme.TextMuted : Theme.Gold,
                FontKind.Sora, TextAlignmentOptions.TopLeft, true);

            if (here.Count > 0)
            {
                var faces = Ui.HStack(row, -12, null, TextAnchor.MiddleLeft, false);
                foreach (var f in here.Take(3)) W.Avatar(faces, f.Initial, Theme.Gold, 28);
            }
            var tap = (Action)(() => G.EnterTable(table));
            if (recommended) W.GoldButton(row, Loc.Or("play", "Play"), tap, 10, 20, 14);
            else W.Icon(row, "chevron_right", 24, Theme.TextFaint);
            shell.MakePressable(tap);
            shell.GetComponent<Image>().raycastTarget = true;
        }
    }
}
