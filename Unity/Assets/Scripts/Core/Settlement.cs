using System;
using System.Collections.Generic;
using System.Linq;

namespace Blackjack.Core
{
    /// <summary>
    /// "Closest to 21" settlement, ported from the Flutter <c>_settle</c>. Pays the hero's hands,
    /// then awards the sweep pot of forfeited seat bets to the best surviving hand. Chips, stats,
    /// history and the result line only — hourly points, streaks and analytics live above this layer.
    /// </summary>
    public static class Settlement
    {
        private const string Win = "win", Lose = "lose", Push = "push", Blackjack = "blackjack";
        private const int HistoryLimit = 10;

        private readonly struct SeatResult
        {
            public string Name { get; }
            public int Bet { get; }
            public int Total { get; }
            public bool Lost { get; }
            public bool Busted { get; }

            public SeatResult(string name, int bet, int total, bool lost, bool busted)
            {
                Name = name; Bet = bet; Total = total; Lost = lost; Busted = busted;
            }
        }

        public static RoundState Settle(RoundState s, IReadOnlyList<string> seatNames)
        {
            var dealerValue = BlackjackRules.HandValue(s.DealerHand);
            var dealerBlackjack = s.DealerHand.Count == 2 && dealerValue == 21;

            var chipsDelta = s.InsuranceBet > 0 && dealerBlackjack ? s.InsuranceBet * 3 : 0;
            var netDelta = chipsDelta - s.InsuranceBet;
            int wins = 0, losses = 0, pushes = 0, blackjacks = 0;
            var history = s.History.ToList();
            var outcomes = new List<string>();

            foreach (var hand in s.Hands)
            {
                var value = BlackjackRules.HandValue(hand.Cards);
                var playerBlackjack = hand.Cards.Count == 2 && value == 21;
                string outcome;
                if (hand.Status == HandStatus.Surrendered)
                {
                    outcome = Lose; losses++; history.Add(RoundResult.Loss);
                    // Surrender already refunded floor(bet/2); the other half is the loss.
                    netDelta -= hand.Bet - hand.Bet / 2;
                }
                else if (value > 21 || (dealerBlackjack && !playerBlackjack))
                {
                    outcome = Lose; losses++; history.Add(RoundResult.Loss);
                    netDelta -= hand.Bet;
                }
                else if (playerBlackjack && !dealerBlackjack)
                {
                    outcome = Blackjack;
                    var win = hand.Bet * 3 / 2;
                    chipsDelta += hand.Bet + win;
                    netDelta += win;
                    wins++; blackjacks++; history.Add(RoundResult.Win);
                }
                else if (playerBlackjack && dealerBlackjack)
                {
                    outcome = Push; chipsDelta += hand.Bet; pushes++; history.Add(RoundResult.Push);
                }
                else if (dealerValue > 21 || value > dealerValue)
                {
                    outcome = Win;
                    chipsDelta += hand.Bet * 2;
                    netDelta += hand.Bet;
                    wins++; history.Add(RoundResult.Win);
                }
                else if (value == dealerValue)
                {
                    outcome = Push; chipsDelta += hand.Bet; pushes++; history.Add(RoundResult.Push);
                }
                else
                {
                    outcome = Lose; losses++; history.Add(RoundResult.Loss);
                    netDelta -= hand.Bet;
                }
                outcomes.Add(outcome);
            }

            if (history.Count > HistoryLimit) history = history.GetRange(history.Count - HistoryLimit, HistoryLimit);

            var (message, messageType) = HeadlineFor(outcomes, dealerBlackjack);

            // Seats that bust or lose to the dealer forfeit their bets to the best surviving hand; a tie is a push and keeps its bet.
            var dealerBust = dealerValue > 21;
            var seatResults = new List<SeatResult>();
            for (var i = 0; i < s.NpcSeats.Count; i++)
            {
                var seat = s.NpcSeats[i];
                if (seat.Cards.Count == 0) continue;
                var total = BlackjackRules.HandValue(seat.Cards);
                // Live friends can change mid-round; never index past the current list.
                var name = i < seatNames.Count ? seatNames[i] : "Player";
                seatResults.Add(new SeatResult(name, seat.Bet, total,
                    lost: total > 21 || (!dealerBust && total < dealerValue), busted: total > 21));
            }

            var heroWon = outcomes.Contains(Win) || outcomes.Contains(Blackjack);
            var heroBest = s.Hands
                .Where(h => h.Status != HandStatus.Surrendered)
                .Select(h => BlackjackRules.HandValue(h.Cards))
                .Where(v => v <= 21)
                .Append(0)
                .Max();
            var rivalBest = seatResults.Where(r => !r.Lost).Select(r => r.Total).Append(0).Max();
            var tablePot = seatResults.Where(r => r.Lost).Sum(r => r.Bet);

            var sweep = 0;
            var heroBlackjack = outcomes.Contains(Blackjack);
            var heroTakesPot = heroWon && tablePot > 0 && heroBest >= rivalBest;
            if (heroTakesPot)
            {
                sweep = tablePot;
                chipsDelta += sweep;
                netDelta += sweep;
                // Kept short on purpose: it shares a row with the round's net figure on a phone.
                message = heroBlackjack ? "Blackjack — you sweep" : "You sweep the table";
                messageType = MessageType.Win;
            }

            var rival = seatResults.Where(r => !r.Lost).OrderByDescending(r => r.Total).Cast<SeatResult?>().FirstOrDefault();
            var heroBetTotal = s.Hands.Sum(h => h.Bet);
            var winnerBet = heroTakesPot ? heroBetTotal : rival?.Bet ?? 0;
            var sweepInfo = tablePot == 0
                ? null
                : new SweepInfo(
                    Pot: tablePot,
                    WinnerBet: winnerBet,
                    TotalWin: tablePot + winnerBet,
                    Winner: heroTakesPot ? "You" : rival?.Name ?? "Nobody",
                    WinnerTotal: heroTakesPot ? heroBest : rival?.Total ?? 0,
                    HeroTook: heroTakesPot,
                    Contributors: seatResults.Where(r => r.Lost)
                        .Select(r => new SweepContributor(r.Name, r.Bet, r.Busted ? "bust" : "lost"))
                        .ToArray());

            var streakWin = wins > 0 && losses == 0;
            var newStreak = streakWin ? s.Stats.CurrentStreak + 1 : 0;

            return s with
            {
                Chips = s.Chips + chipsDelta,
                Phase = RoundPhase.Settlement,
                Message = message,
                MessageType = messageType,
                SweepAmount = sweep,
                RoundNet = netDelta,
                RoundStake = heroBetTotal + s.InsuranceBet,
                RoundHandNet = netDelta - sweep,
                SweepInfo = sweepInfo,
                History = history,
                Stats = s.Stats with
                {
                    HandsPlayed = s.Stats.HandsPlayed + s.Hands.Count,
                    Wins = s.Stats.Wins + wins,
                    Losses = s.Stats.Losses + losses,
                    Pushes = s.Stats.Pushes + pushes,
                    Blackjacks = s.Stats.Blackjacks + blackjacks,
                    CurrentStreak = newStreak,
                    BestStreak = Math.Max(s.Stats.BestStreak, newStreak),
                },
                Session = s.Session with
                {
                    Hands = s.Session.Hands + s.Hands.Count,
                    Wins = s.Session.Wins + wins,
                    Net = s.Session.Net + netDelta,
                },
            };
        }

        private static (string, MessageType) HeadlineFor(List<string> outcomes, bool dealerBlackjack)
        {
            if (dealerBlackjack && !outcomes.Contains(Blackjack) && !outcomes.Contains(Push))
                return ("Dealer has blackjack", MessageType.Lose);
            if (outcomes.Contains(Blackjack)) return ("Blackjack! You win", MessageType.Win);
            if (outcomes.Contains(Win)) return ("You win!", MessageType.Win);
            if (outcomes.All(o => o == Lose)) return ("Dealer wins", MessageType.Lose);
            return ("Push", MessageType.Push);
        }
    }
}
