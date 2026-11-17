using System;

namespace Blackjack.Core
{
    /// <summary>
    /// The 8 PM evening gift: a daily local notification, and +500 play-money chips when the player taps it, once per local
    /// calendar day. Separate from the claim ladder (<see cref="DailyBonus"/>) and the play streak, and keyed independently.
    /// </summary>
    public static class EveningGift
    {
        public const int Hour = 20;
        public const int Chips = 500;

        /// <summary>The next 20:00 on the device clock: today's if it is still ahead, otherwise tomorrow's.</summary>
        public static DateTime NextFire(DateTime now)
        {
            var today = now.Date.AddHours(Hour);
            return now < today ? today : today.AddDays(1);
        }

        /// <summary>How many different reminder texts rotate (loc keys <c>eveningTitleN</c> / <c>eveningBodyN</c>, N from 1).</summary>
        public const int Variants = 5;

        /// <summary>Reminders scheduled ahead, so a player who skips the app for days still gets one per day, each with its own text.</summary>
        public const int DaysAhead = 7;

        /// <summary>Which text a reminder on <paramref name="day"/>'s local date uses, 1..<see cref="Variants"/>; the same date always gives the same one.</summary>
        public static int VariantFor(DateTime day) =>
            (int)(((long)(day.Date - new DateTime(2026, 1, 1)).TotalDays % Variants + Variants) % Variants) + 1;

        /// <summary>The reminders to keep pending: one per local date for <see cref="DaysAhead"/> days from <paramref name="firstAt"/>, each with that date's text.</summary>
        public static System.Collections.Generic.IReadOnlyList<(DateTime At, int Variant)> Upcoming(DateTime firstAt)
        {
            var list = new System.Collections.Generic.List<(DateTime, int)>();
            for (var i = 0; i < DaysAhead; i++)
            {
                var at = firstAt.AddDays(i);
                list.Add((at, VariantFor(at)));
            }
            return list;
        }

        /// <summary>The local calendar date a gift is keyed by.</summary>
        public static string KeyOf(DateTime now) => Points.DayKeyOf(now);

        /// <summary>True when no gift has been taken yet on <paramref name="now"/>'s local date.</summary>
        public static bool CanGrant(string lastGrantKey, DateTime now) => lastGrantKey != KeyOf(now);
    }

    /// <summary>When to show the system notification-permission dialog: after a win, never on a cold first launch.</summary>
    public static class NotifPermissionPrompt
    {
        /// <summary>Hands the player must have played so the dialog never lands on a first-minute screen.</summary>
        public const int MinHands = 5;

        public static bool ShouldAsk(bool won, int handsPlayed, bool alreadyAsked, bool hasPermission, bool reminderOn) =>
            won && reminderOn && !alreadyAsked && !hasPermission && handsPlayed >= MinHands;
    }
}
