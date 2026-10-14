using System;
using System.Collections.Generic;

namespace Blackjack.Core
{
    /// <summary>Everything the table needs to draw and play one round. Immutable — every engine step returns a new one.</summary>
    public sealed record RoundState
    {
        public int Chips { get; init; } = TableCatalog.StartingChips;
        public TableStake Stake { get; init; }
        public int Bet { get; init; }

        /// <summary>The stake last actually dealt, so the betting panel can offer to deal it again.</summary>
        public int LastBet { get; init; }

        public RoundPhase Phase { get; init; } = RoundPhase.Betting;
        public IReadOnlyList<PlayingCard> DealerHand { get; init; } = Array.Empty<PlayingCard>();
        public bool HoleRevealed { get; init; }
        public IReadOnlyList<Hand> Hands { get; init; } = new[] { Hand.Empty };
        public int ActiveHandIndex { get; init; }
        public int InsuranceBet { get; init; }
        public IReadOnlyList<NpcSeat> NpcSeats { get; init; } = Array.Empty<NpcSeat>();

        /// <summary>Index of the opponent seat currently acting, or null.</summary>
        public int? ActingSeat { get; init; }

        /// <summary>
        /// When the hero's active hand stands by itself, on the controller's timer clock (seconds); null while no
        /// turn timer is running (another phase, the timer off, a tutorial hand, or paused).
        /// </summary>
        public double? TurnDeadline { get; init; }

        public MessageType MessageType { get; init; } = MessageType.None;
        public string Message { get; init; } = "";

        public int SweepAmount { get; init; }
        public int RoundNet { get; init; }
        public int RoundStake { get; init; }
        public int RoundHandNet { get; init; }
        public SweepInfo SweepInfo { get; init; }

        public IReadOnlyList<RoundResult> History { get; init; } = Array.Empty<RoundResult>();
        public StatsSummary Stats { get; init; } = new StatsSummary();
        public SessionSummary Session { get; init; } = new SessionSummary();

        public Hand ActiveHand => Hands[ActiveHandIndex];
    }

    /// <summary>The outcome of a betting action: the new state plus why it was refused, if it was.</summary>
    public readonly struct BetResult
    {
        public RoundState State { get; }
        public Rejection Rejection { get; }

        /// <summary>The limit that refused the action (table max/min), for the toast text.</summary>
        public int Limit { get; }

        public BetResult(RoundState state, Rejection rejection = Rejection.None, int limit = 0)
        {
            State = state;
            Rejection = rejection;
            Limit = limit;
        }

        public bool Accepted => Rejection == Rejection.None;
    }
}
