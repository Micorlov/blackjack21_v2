using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>Your group code and invite buttons, joining a group, and the live leaderboard once real friends are in.</summary>
    public sealed class FriendsScreen : ScreenView
    {
        private Dyn _body;
        private TMP_InputField _codeField;
        private string _lastSignature;

        public FriendsScreen(GameController g, Overlays o) : base(g, o) { }

        public override void Build(RectTransform parent)
        {
            Root = Ui.Node("Friends", parent).Fill();
            var scroll = W.Scroll(Root, Ui.Pad(20, 20, 20, 24), 0, true, false, out var sr);
            scroll.Fill();
            _body = new Dyn(Ui.VStack(sr.content, 0, null, TextAnchor.UpperLeft, true, "Body"));
        }

        public override void Refresh(AppState s)
        {
            // The code field keeps its own text while typing: only rebuild when something else changes.
            var sig = $"{s.GroupCode}|{s.FriendsAreLive}|{s.LeaderboardPeriod}|{s.Round.Chips}|{s.HeroDailyPoints}|{s.HeroHourlyPoints}|{s.JoinedViaLink}|{Loc.Code}|"
                      + string.Join(",", s.Friends.Select(f => $"{f.Id}{f.Chips}{f.HourlyScore}{f.DailyScore}{f.Online}"));
            if (sig != _lastSignature)
            {
                _lastSignature = sig;
                _body.Invalidate();
            }
            _body.Update(sig, host => Build(host, s));
            // An external change (cleared after a join, pasted from the clipboard) is pushed into the field.
            if (_codeField != null && _codeField.text != s.FriendCodeInput) _codeField.SetTextWithoutNotify(s.FriendCodeInput);
        }

        private void Build(RectTransform host, AppState s)
        {
            W.ScreenTitle(host, Loc.Or("navFriends", "Friends"));

            W.SectionLabel(host, Loc.Or("friendsYourGroup", "Your friends group"));
            var panel = W.Panel(host, Ui.Pad(16), 0);
            panel.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.UpperCenter;
            var code = s.GroupCode ?? "· · · · · ·";
            Ui.Text(panel, code, 28, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Center, false, 3.36f);
            Ui.Spacer(panel, 8);
            Ui.Text(panel, s.GroupCode == null ? Loc.T("inviteSubtitle")
                    : Loc.Or("friendsLiveHint", "Friends who tap this link (or enter the code) appear live below."),
                13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.Top, true);
            Ui.Spacer(panel, 14);
            W.GoldButton(panel, Loc.T("inviteButtonWhatsApp"), G.ShareInviteWhatsApp);
            Ui.Spacer(panel, 8);
            var row = Ui.HStack(panel, 8, null, TextAnchor.MiddleCenter, true);
            W.ActionPill(row, Loc.T("inviteButtonShare"), Theme.Gold.WithAlpha(0.4f), Color.clear, Theme.Gold, G.ShareInviteSheet, 12, 0, 14).FlexW();
            W.ActionPill(row, Loc.T("inviteCopyLink"), Theme.Gold.WithAlpha(0.4f), Color.clear, Theme.Gold, G.CopyInviteLink, 12, 0, 14).FlexW();

            Ui.Spacer(host, 14);
            W.SectionLabel(host, Loc.Or("friendsJoinGroup", "Join a friends group"));
            var join = W.Panel(host, Ui.Pad(16), 0);
            var jrow = Ui.HStack(join, 8, null, TextAnchor.MiddleLeft, false);
            _codeField = W.Input(jrow, Loc.Or("groupCode", "Group code"), s.FriendCodeInput, 17, G.OnFriendCodeInput, InviteLink.CodeLength);
            ((RectTransform)_codeField.transform).FlexW();
            W.OutlinePill(jrow, Loc.Or("join", "Join"), G.JoinGroupByCode, 15, 16, null, true);

            // The seeded practice bots are opponents, not people, so they are never listed as friends.
            if (s.FriendsAreLive)
            {
                Ui.Spacer(host, 14);
                W.SectionLabel(host, Loc.Or("leaderboard", "Leaderboard"));
                TabPills.Row(host,
                    (Loc.Or("lbHourly", "Hourly"), s.LeaderboardPeriod == LeaderboardPeriod.Hourly, () => G.SetLeaderboardPeriod(LeaderboardPeriod.Hourly)),
                    (Loc.Or("lbDaily", "Daily"), s.LeaderboardPeriod == LeaderboardPeriod.Daily, () => G.SetLeaderboardPeriod(LeaderboardPeriod.Daily)),
                    (Loc.Or("statsAllTime", "All time"), s.LeaderboardPeriod == LeaderboardPeriod.AllTime, () => G.SetLeaderboardPeriod(LeaderboardPeriod.AllTime)));
                Ui.Spacer(host, 2);
                var board = DividedPanel(host);
                foreach (var e in Leaderboard.Build(s)) LeaderboardRow(board, e);
                Ui.Spacer(host, 14);
                W.SectionLabel(host, Loc.Or("navFriends", "Friends"));
                var friends = DividedPanel(host);
                foreach (var f in s.Friends) FriendRow(friends, f);
            }
            else
            {
                Ui.Spacer(host, 14);
                W.SectionLabel(host, Loc.Or("navFriends", "Friends"));
                EmptyState.Build(host, "group_add", Loc.Or("friendsEmptyTitle", "No friends in your group yet"),
                    Loc.Or("friendsEmptyBody", "The players at your table are practice opponents. Invite someone with your code and this fills with their real scores."),
                    Loc.T("inviteButtonWhatsApp"), G.ShareInviteWhatsApp);
            }

            if (s.JoinedViaLink && Application.platform != RuntimePlatform.Android)
            {
                Ui.Spacer(host, 12);
                var banner = Ui.Card(host, Theme.Gold.WithAlpha(0.08f), Theme.RadiusMd, Theme.Gold.WithAlpha(0.3f), 1, Ui.Pad(14, 10), 0, true, "Install");
                var brow = Ui.HStack(banner, 8, null, TextAnchor.MiddleLeft, false);
                Ui.Text(brow, Loc.T("webInstallBanner"), 13, Theme.Gold, FontKind.Sora, TextAlignmentOptions.TopLeft, true).rectTransform.FlexW();
                W.TextLink(brow, Loc.T("webInstallButton"), () => G.Services.Platform.OpenUrl(InviteLink.PlayStoreUrl));
            }
        }

        private static RectTransform DividedPanel(RectTransform host)
        {
            var panel = W.Panel(host, Ui.Pad(16, 0), 0);
            return panel;
        }

        private static RectTransform Row(RectTransform panel, bool last)
        {
            var row = Ui.HStack(panel, 12, Ui.Pad(0, 15), TextAnchor.MiddleLeft, false);
            if (!last) { }
            return row;
        }

        private void LeaderboardRow(RectTransform panel, LeaderboardEntry e)
        {
            var row = Ui.HStack(panel, 12, Ui.Pad(0, 15), TextAnchor.MiddleLeft, false);
            var medal = W.Dot(row, 22, e.MedalColor);
            Ui.Text(medal.transform, e.Rank.ToString(), 13, Theme.GoldInk, FontKind.SoraBold, TextAlignmentOptions.Center, false).rectTransform.Fill();
            var name = Ui.Text(row, e.Name, 16, e.NameColor, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            name.rectTransform.FlexW();
            Ui.Text(row, e.ScoreLabel, 16, e.NameColor, FontKind.SoraBold, TextAlignmentOptions.Right, false);
            W.Divider(panel);
        }

        private void FriendRow(RectTransform panel, Friend f)
        {
            var row = Ui.HStack(panel, 12, Ui.Pad(0, 15), TextAnchor.MiddleLeft, false);
            var face = Ui.Node("Face", row);
            face.Size(Theme.MinTarget, Theme.MinTarget);
            W.Avatar(face, f.Initial, Theme.Gold.WithAlpha(0.15f), Theme.MinTarget, false, Theme.TextPrimary).Fill();
            if (f.Online)
            {
                var dot = W.Dot(face, 13, Theme.Panel);
                dot.rectTransform.IgnoreLayout();
                dot.rectTransform.Pin(new Vector2(1, 0), new Vector2(1, 0), new Vector2(2, -2), new Vector2(13, 13));
                var inner = W.Dot(dot.transform, 9, Theme.Win);
                inner.rectTransform.IgnoreLayout();
                inner.rectTransform.PinCentre(Vector2.zero, new Vector2(9, 9));
            }
            var col = Ui.VStack(row, 0, null, TextAnchor.MiddleLeft, true);
            col.FlexW();
            Ui.Text(col, f.Name, 16, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            var today = (f.DailyScore >= 0 ? "+" : "-") + "$" + TableCatalog.FormatChips(System.Math.Abs(f.DailyScore));
            Ui.Text(col, $"${TableCatalog.FormatChips(f.Chips)} · {today} {Loc.Or("today", "today")}", 14, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.Left, false);
            W.Divider(panel);
        }
    }

    public sealed record LeaderboardEntry(int Rank, string Name, string ScoreLabel, Color MedalColor, Color NameColor, bool IsSelf);

    /// <summary>The ranked list for the chosen period, with the hero's own row inserted by score.</summary>
    public static class Leaderboard
    {
        public static List<LeaderboardEntry> Build(AppState s)
        {
            int ScoreFor(int chips, int daily, int hourly) => s.LeaderboardPeriod switch
            {
                LeaderboardPeriod.Hourly => hourly, LeaderboardPeriod.Daily => daily, _ => chips,
            };
            string Fmt(int n) => s.LeaderboardPeriod == LeaderboardPeriod.AllTime
                ? "$" + TableCatalog.FormatChips(n)
                : (n >= 0 ? "+$" : "-$") + TableCatalog.FormatChips(System.Math.Abs(n));

            var now = System.DateTime.Now;
            var self = ScoreFor(s.Round.Chips,
                Points.Rolled(s.HeroDailyPoints, s.HeroDayKey, Points.DayKeyOf(now)),
                Points.Rolled(s.HeroHourlyPoints, s.HeroHourKey, Points.HourKeyOf(now)));

            var sources = s.Friends.Select(f => (name: f.Name, score: ScoreFor(f.Chips, f.DailyScore, f.HourlyScore), isSelf: false)).ToList();
            sources.Add((s.SignedIn ? s.DisplayName : "You", self, true));
            // A stable sort keeps ties in roster order, like the Flutter list sort.
            var ordered = sources.Select((x, i) => (x, i)).OrderByDescending(t => t.x.score).ThenBy(t => t.i).Select(t => t.x).ToList();
            return ordered.Select((e, i) => new LeaderboardEntry(i + 1, e.isSelf ? "You" : e.name, Fmt(e.score),
                i < 3 ? Theme.Medal(i + 1) : Theme.Border, e.isSelf ? Theme.Gold : Theme.TextPrimary, e.isSelf)).ToList();
        }
    }
}
