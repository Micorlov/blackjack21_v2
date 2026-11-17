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
