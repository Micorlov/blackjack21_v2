using System.Collections.Generic;

namespace Blackjack.Core
{
    public sealed record Hand(
        IReadOnlyList<PlayingCard> Cards,
        int Bet = 0,
        HandStatus Status = HandStatus.Active,
        bool Doubled = false)
    {
        public static Hand Empty { get; } = new Hand(System.Array.Empty<PlayingCard>());
    }

    /// <summary>An opponent seat. <see cref="Action"/> is "", "HIT", "STAND" or "BUST".</summary>
    public sealed record NpcSeat(
        int Bet = 0,
        IReadOnlyList<PlayingCard> Cards = null,
        string Action = "",
        bool Done = false)
    {
        public IReadOnlyList<PlayingCard> Cards { get; init; } = Cards ?? System.Array.Empty<PlayingCard>();
    }

    /// <summary>
    /// A room. <see cref="Opponents"/> is how many opponent seats sit beside the hero (4 in the classic 5-seat rooms, 2 in the
    /// trio room, 0 heads-up) and <see cref="SweepPot"/> whether forfeited seat bets are pooled for the best surviving hand.
    /// </summary>
    public sealed record TableStake(string Key, string Name, int Min, int Max, int Opponents = TableCatalog.OpponentSeats, bool SweepPot = true);

    public sealed record SweepContributor(string Name, int Amount, string Reason);

    public sealed record SweepInfo(
        int Pot,
        int WinnerBet,
        int TotalWin,
        string Winner,
        int WinnerTotal,
        bool HeroTook,
        IReadOnlyList<SweepContributor> Contributors);

    public sealed record StatsSummary(
        int HandsPlayed = 0,
        int Wins = 0,
        int Losses = 0,
        int Pushes = 0,
        int Blackjacks = 0,
        int CurrentStreak = 0,
        int BestStreak = 0);

    public sealed record SessionSummary(int Hands = 0, int Wins = 0, int Net = 0);
}
