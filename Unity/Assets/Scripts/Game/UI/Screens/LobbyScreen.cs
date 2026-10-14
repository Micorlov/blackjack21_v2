using System;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The lobby: who you are and your balance, the daily bonus, and the three tables.</summary>
    public sealed class LobbyScreen : ScreenView
    {
        private TextMeshProUGUI _name;
        private CountUpText _balance;
        private RectTransform _avatarHost;
        private Dyn _avatar, _bonus, _tables;
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
            _name = Ui.Text(header, "", 18, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            _name.Shrink();
            _name.rectTransform.FlexW();
            var coin = Ui.Text(header, "●", 13, Theme.Gold, FontKind.Mono, TextAlignmentOptions.Center, false);
            var bal = Ui.Text(header, "0", 18, Theme.TextPrimary, FontKind.MonoBold, TextAlignmentOptions.Right, false);
            _balance = CountUpText.Make(bal, 0);

            Ui.Spacer(content, 24);
            _bonus = new Dyn(Ui.VStack(content, 0, null, TextAnchor.UpperLeft, true, "Bonus"));
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
            _nextMinuteCheck = Time.unscaledTime + 30f;
            Refresh(_state);
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
            Ui.Text(col, Loc.Or("dailyBonus", "Daily bonus"), 16, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            Ui.Text(col, sub, 13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true);
            if (ready)
                W.GoldButton(row, "+" + TableCatalog.FormatChips(reward), () => DailyBonusDialog.Show(G, Overlays), 12, 18, 15);
            else
            {
                var done = Ui.HStack(row, 4, null, TextAnchor.MiddleCenter, false);
                W.Icon(done, "check", 18, Theme.Win);
                Ui.Text(done, Loc.Or("claimed", "Claimed"), 14, Theme.Win, FontKind.SoraSemiBold, TextAlignmentOptions.Left, false);
            }
        }

        private void BuildTable(RectTransform host, TableStake table, System.Collections.Generic.IReadOnlyList<Friend> here, bool recommended)
        {
            var label = Roster.PresenceLabel(here);
            var tint = table.Key switch { "bronze" => Theme.Win, "silver" => Theme.Hex(0xFF9FB8C9), _ => Theme.Gold };
            var card = Ui.Card(host, Theme.Panel, Theme.RadiusLg, recommended ? Theme.BorderStrong : Theme.Border, 1, Ui.Pad(14), 0, true, "Table_" + table.Key);
            var shell = (RectTransform)card.parent;
            var row = Ui.HStack(card, 14, null, TextAnchor.MiddleLeft, false);
            W.Dot(row, 12, tint);
            var col = Ui.VStack(row, 2, null, TextAnchor.MiddleLeft, true);
            col.FlexW();
            var title = table.Key switch
            {
                "bronze" => Loc.T("gameBronzeTable"), "silver" => Loc.T("gameSilverTable"), "vip" => Loc.T("gameVipTable"), _ => table.Name,
            };
            Ui.Text(col, title, 16, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            var range = $"${table.Min} – ${table.Max}";
            Ui.Text(col, label.Length == 0 ? range : range + " · " + label, 13, label.Length == 0 ? Theme.TextMuted : Theme.Gold,
                FontKind.Sora, TextAlignmentOptions.TopLeft, true);

            if (here.Count > 0)
            {
                var faces = Ui.HStack(row, -12, null, TextAnchor.MiddleLeft, false);
                foreach (var f in here.Take(3)) W.Avatar(faces, f.Initial, Theme.Gold.WithAlpha(0.22f), 28);
            }
            var tap = (Action)(() => G.EnterTable(table));
            if (recommended) W.GoldButton(row, Loc.Or("play", "Play"), tap, 10, 20, 14);
            else W.Icon(row, "chevron_right", 24, Theme.TextFaint);
            shell.MakePressable(tap);
            shell.GetComponent<Image>().raycastTarget = true;
        }
    }
}
