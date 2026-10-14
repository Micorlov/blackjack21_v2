using System.Linq;
using Blackjack.Core;
using UnityEngine;

namespace Blackjack.Game.UI
{
    public sealed record MidRoundPot(bool HasSweepPot, bool HeroLeads, string PotLabelText, string PotValueLabel, int HeroLiveTotal);

    public sealed record PotWinnerInfo(string Initial, Color AvatarBg, Color TextColor, Color RowBg, Color RowBorder, string Headline, string Sub);

    /// <summary>What the felt and result card say, derived from the round — ported from the Flutter <c>TableCalc</c>.</summary>
    public static class TableCalc
    {
        private static string Chips(int n) => TableCatalog.FormatChips(n);

        public static string DealerTotalLabel(RoundState r)
        {
            if (r.DealerHand.Count == 0) return "—";
            if (r.HoleRevealed) return BlackjackRules.HandValue(r.DealerHand).ToString();
            return BlackjackRules.HandValue(new[] { r.DealerHand[0] }) + " + ?";
        }

        public static bool DealerBusted(RoundState r) =>
            r.HoleRevealed && r.DealerHand.Count > 0 && BlackjackRules.HandValue(r.DealerHand) > 21;

        public static string HandLabel(Hand h)
        {
            if (h.Cards.Count == 0) return Loc.T("gameWaiting");
            if (h.Status == HandStatus.Blackjack) return Loc.T("gameBlackjack");
            if (h.Status == HandStatus.Busted) return Loc.T("gameBusted");
            if (h.Status == HandStatus.Surrendered) return Loc.T("gameSurrendered");
            var soft = BlackjackRules.IsSoft(h.Cards) ? Loc.T("gameSoft") : Loc.T("gameHard");
            return soft + " " + BlackjackRules.HandValue(h.Cards);
        }

        public static MidRoundPot MidRound(RoundState r)
        {
            int? dealerShown = r.HoleRevealed ? BlackjackRules.HandValue(r.DealerHand) : (int?)null;
            var pot = TablePot.Live(r);

            var heroLive = 0;
            foreach (var h in r.Hands)
            {
                if (h.Status == HandStatus.Surrendered) continue;
                var v = BlackjackRules.HandValue(h.Cards);
                if (v > 0 && v <= 21 && v > heroLive) heroLive = v;
            }

            var rivalBest = 0;
            foreach (var n in r.NpcSeats.Where(n => n.Cards.Count > 0))
            {
                if (TablePot.SeatLost(n, dealerShown)) continue;
                rivalBest = System.Math.Max(rivalBest, BlackjackRules.HandValue(n.Cards));
            }

            var heroLeads = pot.IsSweep && heroLive > 0 && heroLive >= rivalBest
                            && (dealerShown == null || dealerShown > 21 || heroLive > dealerShown);

            // Once settled, the pill always resolves to an outcome rather than staying on the live figure.
            var settled = r.Phase == RoundPhase.Settlement;
            var sweep = r.SweepInfo;
            var label = settled ? SettledPotLabel(sweep) : (pot.IsSweep ? Loc.T("gameSweepPot").ToUpperInvariant() : Loc.T("gameNoPot").ToUpperInvariant());
            // Mid-round with nothing forfeited there is no figure to quote.
            var value = settled ? "$" + Chips(sweep?.TotalWin ?? 0) : (pot.IsSweep ? "$" + Chips(pot.Amount) : "");
            return new MidRoundPot(pot.IsSweep, heroLeads, label, value, heroLive);
        }

        private static string SettledPotLabel(SweepInfo sweep)
        {
            if (sweep == null) return Loc.T("gameNoSweep");
            if (sweep.HeroTook) return Loc.T("gameYouTake");
            if (sweep.Winner == "Nobody") return Loc.T("gameDealerTakes");
            return Loc.T("gameOtherTakes", ("name", sweep.Winner.ToUpperInvariant()));
        }

        public static string ShowdownLabel(RoundState r, int heroLive)
        {
            int? dealerShown = r.HoleRevealed ? BlackjackRules.HandValue(r.DealerHand) : (int?)null;
            return Loc.T("gameShowdown", ("you", heroLive), ("dealer", dealerShown?.ToString() ?? "?"));
        }

        public static PotWinnerInfo WinnerInfo(AppState s)
        {
            var r = s.Round;
            var info = r.SweepInfo;
            var plain = Color.white.WithAlpha(0.05f);
            var plainBorder = Color.white.WithAlpha(0.14f);
            if (info == null)
                return new PotWinnerInfo("—", Theme.Hex(0xFF3D4A45), Theme.TextPrimary, plain, plainBorder,
                    Loc.T("gameNoPot"), Loc.T("gameNoForfeit"));

            var breakdown = Loc.T("gamePotBreakdown", ("bet", "$" + Chips(info.WinnerBet)), ("pot", "$" + Chips(info.Pot)));
            if (info.Winner == "Nobody")
                return new PotWinnerInfo("D", Theme.Hex(0xFF5A6763), Theme.LoseLight, Theme.Lose.WithAlpha(0.12f), Theme.Lose.WithAlpha(0.35f),
                    Loc.T("gameDealerPot"), Loc.T("gameNobodyBeat"));
            if (info.HeroTook)
            {
                var name = s.DisplayName.Length > 0 ? s.DisplayName : "G";
                return new PotWinnerInfo(name.Substring(0, 1).ToUpperInvariant(), Theme.Gold, Theme.Gold, Theme.Gold.WithAlpha(0.14f),
                    Theme.Gold.WithAlpha(0.5f), Loc.T("gameYourPot"), breakdown);
            }
            var seats = Roster.TableSeats(s.Friends, r.Stake?.Key);
            var idx = seats.ToList().FindIndex(f => f.FirstName == info.Winner);
            return new PotWinnerInfo(info.Winner.Length > 0 ? info.Winner.Substring(0, 1).ToUpperInvariant() : "?",
                Theme.SeatColors[(idx < 0 ? 0 : idx) % Theme.SeatColors.Length], Theme.TextPrimary, plain, plainBorder,
                Loc.T("gameOtherPot", ("name", info.Winner)), breakdown);
        }
    }
}
