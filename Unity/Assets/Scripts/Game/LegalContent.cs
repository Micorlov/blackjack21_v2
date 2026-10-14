namespace Blackjack.Game
{
    public sealed record LegalSection(string Heading, string Body);

    public sealed record LegalDoc(string Title, string Updated, string Intro, LegalSection[] Sections);

    /// <summary>The Terms of Service and Privacy Policy, ported verbatim from the Flutter app (they open offline).</summary>
    public static class LegalContent
    {
        public const string AppName = "Blackjack 21";
        public const string AppVersionLabel = "1.6.0 (7)";

        public static readonly LegalDoc Terms = new LegalDoc(
            "Terms of Service",
            "Last updated 3 September 2026",
            "Blackjack 21 is a free social card game. Playing it means accepting the terms below. They are written plainly on purpose — there is nothing hidden in them.",
            new[]
            {
                new LegalSection("This is a game, not gambling",
                    "Chips in Blackjack 21 are play money. They have no cash value, they cannot be withdrawn, exchanged, transferred outside the game or redeemed for anything of real value, and no real-money wager is ever placed. Success here does not predict success at real gambling."),
                new LegalSection("Rewards",
                    "The daily bonus, the table rebuy and referral rewards all grant play chips inside the game. There is nothing to buy: no money changes hands and no payment details are collected. If that ever changes, prices and terms will be shown before anything is charged."),
                new LegalSection("Your account",
                    "You can play as a guest, in which case your progress stays on this device only. Signing in with Google creates an account so your score can appear on your friends group's leaderboard across devices. You are responsible for keeping access to your Google account secure."),
                new LegalSection("Friends groups",
                    "A friends group is a six-character code you choose to share. Anyone who enters your code joins your group and can see the display name and scores you post to it. Share it only with people you want in your game."),
                new LegalSection("Fair play",
                    "Do not modify the app, automate play, or tamper with saved data to manufacture chips or leaderboard positions. Accounts doing so may have their chips, scores or group membership reset."),
                new LegalSection("Availability",
                    "The game is provided as it is, without a guarantee that it will be available, uninterrupted or free of faults. Features may change or be withdrawn, and online play depends on services outside our control."),
                new LegalSection("Who can play",
                    "The game simulates casino play and is intended for adults aged 18 and over."),
                new LegalSection("Contact",
                    "Questions about these terms or your data go to the developer via the app's Google Play listing."),
            });

        public static readonly LegalDoc Privacy = new LegalDoc(
            "Privacy Policy",
            "Last updated 5 September 2026",
            "The short version: Blackjack 21 keeps your game on your device, and only sends anything to a server when you sign in, join a friends group, or — unless you turn it off — report an anonymous count of what happened in a hand. There are no ads and no third-party trackers.",
            new[]
            {
                new LegalSection("What stays on your device",
                    "Your chips, statistics, hand history, unlocked cosmetics and every setting are stored in the app's own storage on this device. Playing as a guest sends none of it anywhere. Uninstalling the app removes it."),
                new LegalSection("What signing in shares",
                    "Signing in with Google passes your Google display name, profile photo and account identifier to Firebase Authentication so the game can recognise you. No password ever reaches this app."),
                new LegalSection("What a friends group shares",
                    "Joining or creating a group stores your display name, your group code and your current hourly, daily and all-time scores so the group's leaderboard can be assembled. Everyone holding the code can see those entries. Nothing else about your play is uploaded."),
                new LegalSection("Notifications",
                    "Notifications are scheduled on your device — a daily-bonus reminder and friends-group activity. They are not sent from a server, and you can turn each type off in Settings or revoke the permission entirely in your system settings."),
                new LegalSection("Usage and crash reports",
                    "The app reports anonymous counts of what happens in the game — hands played and their result, daily bonuses claimed, missions and achievements completed, levels reached, which screens are opened — and sends a report when it crashes, through Google Firebase Analytics and Crashlytics. These carry no display name, no group code, no account identifier and nothing you type. Turn the whole thing off under Privacy in Settings and nothing further is collected."),
                new LegalSection("No advertising",
                    "This build contains no advertising SDK and no third-party trackers. No ad is ever loaded and no ad network sees you."),
                new LegalSection("Location",
                    "The flags shown beside leaderboard names are decorative. They are derived from a player identifier, not from any location. The app never requests or stores location data."),
                new LegalSection("Removing your data",
                    "Signing out clears your account details from this device. To have your leaderboard entries removed from a friends group, ask the group to drop your code or contact the developer."),
                new LegalSection("Children",
                    "The game is intended for adults aged 18 and over and is not directed at children."),
                new LegalSection("Changes",
                    "If this policy changes, the updated date at the top of this page changes with it, and the new version ships inside the app."),
                new LegalSection("Contact",
                    "Questions about these terms or your data go to the developer via the app's Google Play listing."),
            });

    }
}