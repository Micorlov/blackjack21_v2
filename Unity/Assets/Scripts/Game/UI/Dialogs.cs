using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The modal surfaces: daily bonus, out of chips, how to play, confirm, and the coach card.</summary>
    public static class DailyBonusDialog
    {
        public static void Show(GameController g, Overlays overlays)
        {
            var s = g.State;
            var now = DateTime.Now;
            var ready = DailyBonus.IsReady(s.LastDailyBonusClaimAt, now);
            var day = DailyBonus.NextStreakDay(s.DailyBonusStreakDay, s.LastDailyBonusClaimAt, now);
            var reward = DailyBonus.RewardForDay(day);

            overlays.Dialog((card, close) =>
            {
                var col = Ui.VStack(card, 0, null, TextAnchor.UpperCenter, true, "Bonus");
                var chipRow = Ui.HStack(col, 0, null, TextAnchor.MiddleCenter, false);
                W.ChipDisc(chipRow, Theme.Gold, 78);
                Ui.Spacer(col, 14);
                Ui.Text(col, Loc.Or("dailyBonus", "Daily bonus"), 32, Theme.TextPrimary, FontKind.SerifItalic, TextAlignmentOptions.Center, false);
                Ui.Spacer(col, 4);
                var amount = Ui.Text(col, "", 40, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Center, false);
                CountUpText.Make(amount, 0, "", true).SetValue(reward);
                Ui.Text(col, day > 1
                        ? Loc.Or("bonusKeepGoing", "Day {day} of your streak — keep it going", ("day", day))
                        : Loc.Or("bonusStartStreak", "Come back tomorrow to start a streak"),
                    15, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.Center, true);
                Ui.Spacer(col, 18);

                var cells = Ui.HStack(col, 6, null, TextAnchor.MiddleCenter, true);
                for (var d = 1; d <= DailyBonus.StreakDays; d++) DayCell(cells, d, day);
                Ui.Spacer(col, 8);
                var day7 = Ui.HStack(col, 4, null, TextAnchor.MiddleCenter, false);
                Ui.Text(day7, Loc.Or("bonusDay7", "Day 7 pays"), 13, Theme.TextFaint, FontKind.Sora, TextAlignmentOptions.Center, false);
                Ui.Text(day7, "+" + DailyBonus.Day7Chips, 13, Theme.Gold, FontKind.SoraBold, TextAlignmentOptions.Center, false);
                Ui.Spacer(col, 18);
                W.GoldButton(col, Loc.Or("bonusClaim", "Claim {chips} chips", ("chips", reward)), () => { g.ClaimDailyBonus(); close(); },
                    16, 0, 17, ready);
                Ui.Spacer(col, 4);
                W.TextLink(col, Loc.Or("bonusLater", "Later"), close, Theme.TextMuted, 15);
            }, Theme.Gold, 0.6f);
        }

        private static void DayCell(RectTransform row, int day, int claimDay)
        {
            var banked = day < claimDay;
            var current = day == claimDay;
            var border = current ? Theme.Gold : banked ? Theme.Gold.WithAlpha(0.35f) : Theme.Border;
            var cell = Ui.Card(row, current ? Theme.Gold.WithAlpha(0.16f) : Color.black.WithAlpha(0.3f), Theme.RadiusMd, border, 1,
                Ui.Pad(0, 9), 4, true, "Day" + day);
            ((RectTransform)cell.parent).FlexW();
            cell.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.UpperCenter;
            Ui.Text(cell, "D" + day, 12, Theme.TextFaint, FontKind.Mono, TextAlignmentOptions.Center, false);
            if (banked)
            {
                var disc = W.Dot(cell, 16, Theme.Gold);
                var tick = W.Icon(disc.transform, "check", 12, Theme.GoldInk);
                tick.rectTransform.PinCentre(Vector2.zero, new Vector2(12, 12));
                tick.rectTransform.IgnoreLayout();
            }
            else
            {
                var coin = W.Dot(cell, 13, current ? Theme.Gold : Theme.Border);
                coin.rectTransform.Size(13, 10);
            }
        }
    }

    public static class OutOfChipsSheet
    {
        private sealed record Route(string Icon, string Title, string Detail, bool Ready, string Action, Action OnTap);

        public static void Show(GameController g, Overlays overlays)
        {
            var s = g.State;
            var now = DateTime.Now;
            var bonusReady = DailyBonus.IsReady(s.LastDailyBonusClaimAt, now);
            var rebuyReady = Core.Rebuy.IsReady(s.LastRebuyAt, now);
            g.Services.Analytics.LogEvent(Services.AnalyticsEvent.OutOfChips);

            var routes = new List<Route>
            {
                new Route("replay", Loc.Or("routeRebuy", "Table rebuy"),
                    rebuyReady ? Loc.Or("routeRebuyReady", "Tops your stack back up to {chips}", ("chips", TableCatalog.FormatChips(Core.Rebuy.Chips)))
                               : Loc.Or("routeReadyIn", "Ready in {time}", ("time", Core.Rebuy.CountdownLabel(s.LastRebuyAt.Value, now))),
                    rebuyReady, Loc.T("rebuyButtonLabel", ("chips", TableCatalog.FormatChips(Core.Rebuy.Chips))), g.Rebuy),
                new Route("gift", Loc.Or("dailyBonus", "Daily bonus"),
                    bonusReady ? Loc.Or("routeBonusReady", "Waiting for you in the lobby")
                               : Loc.Or("routeNextIn", "Next in {time}", ("time", DailyBonus.CountdownLabel(s.LastDailyBonusClaimAt.Value, now))),
                    bonusReady, Loc.Or("routeClaimBonus", "Claim the daily bonus"), g.GoLobby),
                new Route("person_add", Loc.Or("routeInvite", "Invite a friend"),
                    Loc.Or("routeInviteDetail", "They join your race, you both get chips"), true,
                    Loc.Or("routeInviteAction", "Invite on WhatsApp"), g.ShareInviteWhatsApp),
            };
            // Exactly one gold button, and only when something is available right now.
            var first = routes.FirstOrDefault(r => r.Ready);

            overlays.Sheet((sheet, close) =>
            {
                var col = Ui.VStack(sheet, 0, Ui.Pad(0, 6, 0, 0), TextAnchor.UpperCenter, true, "OutOfChips");
                Ui.Text(col, Loc.Or("outOfChips", "Out of chips"), 32, Theme.TextPrimary, FontKind.SerifItalic, TextAlignmentOptions.Center, false);
                Ui.Spacer(col, 4);
                Ui.Text(col, Loc.Or("outOfChipsHint", "Here is every way to get back to the table."), 13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.Center, true);
                Ui.Spacer(col, Theme.Lg);
                foreach (var route in routes)
                {
                    var row = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleLeft, false);
                    var tint = route.Ready ? Theme.Gold : Theme.TextFaint;
                    var disc = W.Dot(row, 36, tint.WithAlpha(0.12f));
                    var icon = W.Icon(disc.transform, route.Icon, 18, tint);
                    icon.rectTransform.PinCentre(Vector2.zero, new Vector2(18, 18));
                    icon.rectTransform.IgnoreLayout();
                    var text = Ui.VStack(row, 0, null, TextAnchor.MiddleLeft, true);
                    text.FlexW();
                    Ui.Text(text, route.Title, 15, route.Ready ? Theme.TextPrimary : Theme.TextMuted, FontKind.SoraBold, TextAlignmentOptions.Left, false);
                    Ui.Text(text, route.Detail, 13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true);
                    Ui.Spacer(col, Theme.Sm);
                }
                Ui.Spacer(col, Theme.Xs);
                if (first != null) W.GoldButton(col, first.Action, () => { close(); first.OnTap(); }, 16, 0, 17);
                else W.OutlinePill(col, Loc.Or("backToLobby", "Back to the lobby"), () => { close(); g.ExitTable(); });
            });
        }
    }

    public static class HowToPlaySheet
    {
        public static void Show(Overlays overlays)
        {
            overlays.Sheet((sheet, close) =>
            {
                var head = Ui.HStack(sheet, 0, Ui.Pad(4, 2, 0, 6), TextAnchor.MiddleLeft, false);
                var title = Ui.Text(head, Loc.T("howToPlayLabel"), 32, Theme.TextPrimary, FontKind.SerifItalic, TextAlignmentOptions.Left, false, 0, -10);
                title.rectTransform.FlexW();
                var x = W.CircleIconButton(head, "close", close, 22);
                x.GetComponent<Image>().color = Color.clear;

                var scrollRoot = W.Scroll(sheet, Ui.Pad(4, 4, 4, 28), 18, true, false, out var scrollRect);
                scrollRoot.Size(null, 560);
                var content = scrollRect.content;
                foreach (var section in Guide.Sections)
                {
                    var block = Ui.VStack(content, 7, null, TextAnchor.UpperLeft, true);
                    Ui.Text(block, Loc.Joined(section.TitleKeys).ToUpperInvariant(), 12, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Left, true, 1.2f);
                    foreach (var key in section.BodyKeys)
                        Ui.Text(block, Loc.T(key), 15, Theme.TextBody, FontKind.Sora, TextAlignmentOptions.TopLeft, true, 0, 14);
                }
            }, 0.9f);
        }
    }

    public static class ConfirmDialog
    {
        public static void Show(Overlays overlays, string title, string message, string confirmLabel, Action onConfirm,
            string cancelLabel = null, bool destructive = false)
        {
            overlays.Dialog((card, close) =>
            {
                var col = Ui.VStack(card, Theme.Md, null, TextAnchor.UpperLeft, true, "Confirm");
                Ui.Text(col, title, 24, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.TopLeft, true);
                Ui.Text(col, message, 15, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true, 0, 14);
                var row = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleRight, false);
                W.TextLink(row, cancelLabel ?? Loc.Or("cancel", "Cancel"), close, Theme.TextMuted, 16);
                W.TextLink(row, confirmLabel, () => { close(); onConfirm(); }, destructive ? Theme.LoseSoft : Theme.Gold, 16);
            }, null, 0.6f);
        }
    }

    /// <summary>The coached first hands' card, shown above the active panel until the tutorial is done or skipped.</summary>
    public static class CoachCard
    {
        public static void Build(RectTransform host, AppState s, GameController g, Overlays overlays)
        {
            var r = s.Round;
            var tip = Tutorial.Active(s.TutorialDismissed, s.Screen == AppScreen.Table, s.TutorialRoundsSeen, r.Phase);
            if (tip == null) return;

            var minimum = "$" + TableCatalog.FormatChips(r.Stake?.Min ?? TableCatalog.ChipDenoms[0]);
            var body = tip.UsesMinimum ? Loc.T(tip.BodyKey, ("min", minimum)) : Loc.T(tip.BodyKey);
            var lesson = s.TutorialRoundsSeen;

            var card = Ui.Card(host, Color.black.WithAlpha(0.72f), Theme.RadiusMd, Theme.Gold.WithAlpha(0.55f), 1, Ui.Pad(Theme.Md, Theme.Sm), 0, true, "Coach");
            var head = Ui.HStack(card, 8, null, TextAnchor.MiddleLeft, false);
            var left = Ui.HStack(head, 8, null, TextAnchor.MiddleLeft, false);
            left.FlexW();
            Ui.Text(left, Loc.T("coachStep", ("hand", lesson + 1)), 12, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Left, false, 1.2f);
            for (var i = 0; i < Tutorial.Rounds; i++) W.Dot(left, 6, i <= lesson ? Theme.Gold : Theme.Border);
            Link(head, Loc.T("coachRules"), () => HowToPlaySheet.Show(overlays), Theme.Gold);
            Ui.Spacer(head, 4);
            Link(head, Loc.T("coachSkip"), g.SkipTutorial, Theme.TextMuted);
            Ui.Spacer(card, 2);
            Ui.Text(card, Loc.Joined(tip.TitleKeys), 15, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.TopLeft, true);
            Ui.Spacer(card, 3);
            Ui.Text(card, body, 13, Theme.TextBody, FontKind.Sora, TextAlignmentOptions.TopLeft, true, 0, 6);
            Ui.Spacer(host, 8);
        }

        /// <summary>A small text link with a full 48x48 hit area around it.</summary>
        private static void Link(RectTransform parent, string label, Action onTap, Color color)
        {
            var box = Ui.VStack(parent, 0, Ui.Pad(Theme.Sm, 0), TextAnchor.MiddleCenter, false, "Link");
            box.MinSize(Theme.MinTarget, Theme.MinTarget);
            Ui.Text(box, label, Type.Caption.WithFont(FontKind.SoraBold), color, TextAlignmentOptions.Center, false);
            box.MakePressable(onTap);
        }
    }

    public static class TabPills
    {
        public static void Row(Transform parent, params (string label, bool active, Action onTap)[] items)
        {
            var row = Ui.HStack(parent, Theme.Sm, null, TextAnchor.MiddleCenter, true, "Tabs");
            foreach (var item in items)
            {
                var pill = Ui.Card(row, item.active ? Theme.Gold.WithAlpha(0.12f) : Color.clear, Theme.RadiusPill,
                    item.active ? Theme.Gold : Theme.BorderStrong, 1.5f, Ui.Pad(Theme.Sm, Theme.Md), 0, true, "Pill");
                var shell = (RectTransform)pill.parent;
                shell.FlexW();
                shell.MinSize(null, Theme.MinTarget);
                pill.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
                Ui.Text(pill, item.label, 15, item.active ? Theme.Gold : Theme.TextMuted, FontKind.SoraBold, TextAlignmentOptions.Center, false);
                shell.MakePressable(item.onTap);
                shell.GetComponent<Image>().raycastTarget = true;
            }
        }
    }

    public static class EmptyState
    {
        public static void Build(Transform parent, string icon, string title, string message, string actionLabel = null,
            Action onAction = null, bool linkStyle = false)
        {
            var card = W.Panel(parent, Ui.Pad(Theme.Lg, Theme.Xxl), Theme.Md);
            card.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.UpperCenter;
            var discRow = Ui.HStack(card, 0, null, TextAnchor.MiddleCenter, false);
            var disc = W.Dot(discRow, 52, Theme.Gold.WithAlpha(0.12f));
            var ic = W.Icon(disc.transform, icon, 26, Theme.Gold);
            ic.rectTransform.PinCentre(Vector2.zero, new Vector2(26, 26));
            ic.rectTransform.IgnoreLayout();
            Ui.Text(card, title, 17, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Center, true);
            Ui.Text(card, message, 13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.Center, true, 0, 6);
            if (actionLabel != null && onAction != null)
            {
                if (linkStyle) W.TextLink(card, actionLabel, onAction, Theme.Gold, 15);
                else W.GoldButton(card, actionLabel, onAction, Theme.Lg, 0, 16);
            }
        }
    }
}
