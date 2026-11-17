namespace Blackjack.Game
{
    public sealed record LegalSection(string Heading, string Body);

    public sealed record LegalDoc(string Title, string Updated, string Intro, LegalSection[] Sections);

    /// <summary>The Terms of Service and Privacy Policy, ported verbatim from the Flutter app (they open offline).</summary>
    public static class LegalContent
    {
        public const string AppName = "Blackjack 21";

        public static readonly LegalDoc Terms = new LegalDoc(
            "Terms of Service",
            "Last updated 8 November 2026",
            "Blackjack 21 is a free social card game. Playing it means accepting the terms below. They are written plainly on purpose — there is nothing hidden in them.",
            new[]
            {
                new LegalSection("This is a game, not gambling",
                    "Chips in Blackjack 21 are play money. They have no cash value, they cannot be withdrawn, exchanged, transferred outside the game or redeemed for anything of real value, and no real-money wager is ever placed. Success here does not predict success at real gambling."),
                new LegalSection("Rewards",
                    "The daily bonus, the table rebuy and referral rewards all grant play chips inside the game. There is nothing to buy: no money changes hands and no payment details are collected. If that ever changes, prices and terms will be shown before anything is charged."),
                new LegalSection("Your account",
                    "You can play as a guest: the app creates an anonymous account for you automatically, and your full game save stays on this device. Guests and signed-in players alike appear on the leaderboard with a display name and score, and in a friends group if they join one. Signing in with Google adds your Google name to your account. You are responsible for keeping access to your Google account secure."),
                new LegalSection("Friends groups",
                    "A friends group is a six-character code you choose to share. Anyone who enters your code joins your group and can see the display name and scores you post to it. Share it only with people you want in your game."),
                new LegalSection("Fair play",
                    "Do not modify the app, automate play, or tamper with saved data to manufacture chips or leaderboard positions. Accounts doing so may have their chips, scores or group membership reset."),
                new LegalSection("Availability",
                    "The game is provided as it is, without a guarantee that it will be available, uninterrupted or free of faults. Features may change or be withdrawn, and online play depends on services outside our control."),
                new LegalSection("Who can play",
                    "The game simulates casino play with virtual chips only. It is intended for people aged 13 and over, including teenagers, and is not for children under 13."),
                new LegalSection("Contact",
                    "Questions about these terms or your data go to the developer via the app's Google Play listing."),
            });

        public static readonly LegalDoc Privacy = new LegalDoc(
            "Privacy Policy",
            "Last updated 8 November 2026",
            "The short version: Blackjack 21 keeps your full game save on your device, but it also creates an anonymous account for you automatically and publishes a small leaderboard record to Google Firebase. Usage and crash reports can be switched off in Settings, and the game shows ads through Google AdMob. The details are below.",
            new[]
            {
                new LegalSection("What stays on your device",
                    "Your chips, statistics, hand history, unlocked cosmetics and every setting are saved in the app's own storage on this device. The game does not upload that save file and has no cloud save."),
                new LegalSection("Your automatic guest account",
                    "The first time the game opens it creates an anonymous account for your device through Firebase Authentication. You type no name or email address; the account is identified by a random user ID, and Google's Firebase services process technical data such as your IP address to run and secure the service."),
                new LegalSection("What signing in shares",
                    "Signing in with Google is optional. The game asks Google for the \"email\" and \"profile\" information, and Google passes your display name, profile photo and email address to Firebase Authentication, which keeps them in your account record. The game itself does not read or save your email address. Your display name becomes your name in the game; your photo is shown on your device only and is not uploaded to the game's database. No password ever reaches this app."),
                new LegalSection("What the leaderboard and friends groups share",
                    "Guest or signed in, the game stores these in Firebase (Cloud Firestore) against your account's user ID: your display name, chip balance, hourly and daily points, seconds played, app version, platform, and a country code taken from your device's region setting. If you create or join a friends group it also stores the group code, your membership, the table you are sitting at and which player's invite you joined through. These are sent when the game starts, after rounds and about once a minute while it is open. Other players of the game can read the leaderboard and group records, and anyone holding a group's code can see its members, so treat your name and scores as visible within the game."),
                new LegalSection("Notifications",
                    "Notifications are scheduled on your device — a daily-bonus reminder and friends-group activity. They are not sent from a server, and you can turn each type off in Settings or revoke the permission entirely in your system settings."),
                new LegalSection("Usage and crash reports",
                    "These are on by default and you can turn them off in Settings, under Privacy, \"Usage & crash reports\". The game reports counts of what happens in it — hands played and their result, daily bonuses claimed, missions and achievements completed, levels reached, which screens are opened — and sends a report when it crashes, through Google Firebase Analytics and Crashlytics. Crash reports include the device model, Android version and app version, and these Google services use identifiers that Google assigns to the app installation. Firebase Analytics is set not to read your advertising ID, and the game does not attach your display name, group code or anything you type. The same switch controls the game's own install and error records (app version, platform, time, and a shortened error message), which have no name or account ID field. In the EU, the rest of the EEA, the UK and Switzerland, Google's consent form (its User Messaging Platform) asks you first and nothing is collected unless you agree; the same switch there opens that form so you can review or change your answer. Your leaderboard record is separate and is not controlled by this switch."),
                new LegalSection("Advertising",
                    "The game shows ads through Google AdMob: a banner at the bottom of the screen, an optional video you can watch for free chips, and a full-screen ad between hands from time to time. To choose and measure ads, Google and its ad partners receive your advertising ID, IP address and basic device and usage information. The game is for ages 13 and over and does not ask your age, so ads are age-restricted for everyone: every ad request uses Google's teen ad treatment, and nobody is shown personalised ads or remarketing by default. In the EEA, the UK and Switzerland, Google's consent form asks for your consent before the game requests ads or starts analytics, and your answer is passed on to Google's analytics and ads as consent signals (analytics storage, ad storage, ad user data, ad personalization). The game asks for ads rated Teen or lower. Where Google's own privacy options apply, Privacy choices under Privacy in Settings changes your answer. You can also reset or delete the advertising ID in your Android settings. The game does not pass your name, group code or chat to the ad service."),
                new LegalSection("Location",
                    "The flags shown beside leaderboard names are decorative. They are derived from a player identifier, not from any location. The game does not request location permission or use GPS. It does store a country code taken from your device's region setting with your leaderboard record, as described above."),
                new LegalSection("Removing your data",
                    "Open Settings, then Privacy, then Delete account and data. The game stops sending your records and waits for queued ones to finish; asks Google users to sign in again first (nothing is deleted if that fails); replaces your ID with \"deleted\" in the invite pointer of other members' rows that name you and in the record of any group you created; deletes your own member rows, player record and leaderboard record in one step; then deletes your Firebase Authentication account, including the Google email held there. Your save on this phone (chips, statistics, settings) is kept, your Google account itself is not affected, and the game starts a new anonymous guest account the next time it opens, which publishes a new leaderboard record under a new ID. If the game cannot confirm the result it says so, keeps sync paused, and running it again is safe. A friends group you created keeps its code and creation time and other members' records stay. Install and error records have no name or account ID, and data Google already holds for Analytics, Crashlytics and AdMob follows Google's policies. If you cannot open the game, email micorlov@gmail.com with your Account ID (Settings, Privacy, Account ID; a random identifier for your online account, share it only for this) or, if you cannot get it, your display name and friends-group code, and we will delete the records we can match within 30 days. Signing out clears account details from this device but does not delete anything online."),
                new LegalSection("Children",
                    "The game is intended for people aged 13 and over, including teenagers, and is not directed at children under 13. If you believe a child under 13 has used it, contact the developer and their records will be deleted."),
                new LegalSection("Changes",
                    "If this policy changes, the updated date at the top of this page changes with it, and the new version ships inside the app."),
                new LegalSection("Contact",
                    "Questions about these terms or your data go to the developer via the app's Google Play listing."),
            });

    }
}