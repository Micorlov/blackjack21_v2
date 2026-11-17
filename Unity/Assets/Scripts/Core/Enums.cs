namespace Blackjack.Core
{
    public enum AppScreen { Onboarding, Lobby, Table, Stats, Friends, Settings }

    /// <summary>
    /// The round: every opponent seat acts in <see cref="Npcs"/>, then the hero (last of the player seats) in
    /// <see cref="Playing"/>, then the dealer. <see cref="NpcsAfter"/> is unused since 1.8.6 (no seat acts after the hero).
    /// </summary>
    public enum RoundPhase { Betting, Insurance, Npcs, Playing, NpcsAfter, Dealer, Settlement }

    public enum HandStatus { Active, Stood, Busted, Blackjack, Surrendered }

    public enum MessageType { None, Win, Lose, Push }

    public enum RoundResult { Win, Loss, Push }

    /// <summary>Why a betting action was refused, so the UI can word the toast in the player's language.</summary>
    public enum Rejection { None, NotEnoughChips, TableMaximum, TableMinimum }
}
