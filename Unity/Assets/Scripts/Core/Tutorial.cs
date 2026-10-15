using System.Collections.Generic;

namespace Blackjack.Core
{
    /// <summary>One coach card. Title and body are localization keys; the title may join several with " / ".</summary>
    public sealed record CoachTip(IReadOnlyList<string> TitleKeys, string BodyKey, bool UsesMinimum = false);

    /// <summary>The coached first hands — which card shows in which phase of which lesson.</summary>
    public static class Tutorial
    {
        public const int Rounds = 3;

        /// <summary>
        /// The card for a lesson and phase, or null when the coach stays quiet. Insurance gets the same
        /// card in every lesson: it is dealt at random, so it cannot be taught on a fixed hand.
        /// <paramref name="pushed"/> is whether the hand just settled as a push, which the second
        /// lesson's result card turns on: the hand is dealt, not scripted, so the lesson has to read it.
        /// </summary>
        public static CoachTip TipFor(int lesson, RoundPhase phase, bool pushed = false)
        {
            if (phase == RoundPhase.Insurance)
                return new CoachTip(new[] { "gameInsure" }, "coachInsuranceBody");

            switch (lesson, phase)
            {
                case (0, RoundPhase.Betting): return new CoachTip(new[] { "gameBet" }, "coachBetBody", true);
                case (0, RoundPhase.Npcs): return new CoachTip(new[] { "gamePracticeBots" }, "coachNpcBody");
                case (0, RoundPhase.Playing): return new CoachTip(new[] { "gameHit", "gameStand" }, "coachPlayBody");
                case (0, RoundPhase.Settlement): return new CoachTip(new[] { "gameBalance" }, "coachSettleBody");
                case (1, RoundPhase.Betting): return new CoachTip(new[] { "gameBet" }, "coachBetBody", true);
                case (1, RoundPhase.Playing): return new CoachTip(new[] { "gameAgainstDealer" }, "coachDealerBody");
                // The push card only fits a hand that actually pushed; any other result is taught by the
                // comparison that decided it, rather than by a lesson the sheet above it contradicts.
                case (1, RoundPhase.Settlement): return pushed
                    ? new CoachTip(new[] { "gamePush" }, "coachPushBody")
                    : new CoachTip(new[] { "gameAgainstDealer" }, "coachDealerBody");
                case (2, RoundPhase.Betting): return new CoachTip(new[] { "gameSweepPot" }, "coachPotBody");
                case (2, RoundPhase.Playing): return new CoachTip(new[] { "gameDouble", "gameSplit" }, "coachMovesBody");
                case (2, RoundPhase.Settlement): return new CoachTip(new[] { "howToPlayLabel" }, "coachDoneBody");
                default: return null;
            }
        }

        /// <summary>The card to show now, honouring the Skip switch and the current screen.</summary>
        public static CoachTip Active(bool dismissed, bool onTable, int roundsSeen, RoundPhase phase, bool pushed = false)
        {
            if (dismissed || !onTable) return null;
            if (roundsSeen < 0 || roundsSeen >= Rounds) return null;
            return TipFor(roundsSeen, phase, pushed);
        }
    }

    /// <summary>The "How to play" sheet: each section is a title key and the body keys under it.</summary>
    public static class Guide
    {
        public sealed record Section(IReadOnlyList<string> TitleKeys, IReadOnlyList<string> BodyKeys);

        public static readonly IReadOnlyList<Section> Sections = new[]
        {
            new Section(new[] { "howToPlayLabel" }, new[] { "coachPlayBody", "guideCardsBody" }),
            new Section(new[] { "gameDouble", "gameSplit", "gameSurrender" }, new[] { "coachMovesBody" }),
            new Section(new[] { "gameAgainstDealer" }, new[] { "coachDealerBody", "coachPushBody" }),
            new Section(new[] { "gameInsure" }, new[] { "coachInsuranceBody" }),
            new Section(new[] { "gameBalance" }, new[] { "guidePayoutsBody" }),
            new Section(new[] { "gameSweepPot" }, new[] { "coachPotBody" }),
            new Section(new[] { "gameChipOptions" }, new[] { "guideChipsBody" }),
        };

        /// <summary>
        /// Stored outcomes stay in English so a language change never rewrites history; this maps one to
        /// its localization key at display time.
        /// </summary>
        public static string ResultKey(string result) => result switch
        {
            "Dealer has blackjack" => "gameDealerBlackjack",
            "Blackjack! You win" => "gameBlackjackWin",
            "You win!" => "gameWin",
            "Dealer wins" => "gameLose",
            "Push" => "gamePush",
            "Blackjack — you sweep" => "gameBlackjackSweep",
            "You sweep the table" => "gameSweepWin",
            _ => null,
        };
    }
}
