namespace Blackjack.Core
{
    public enum AppScreen { Onboarding, Lobby, Table, Stats, Friends, Settings }

    /// <summary>
    /// The round in casino seat order: the seats on the hero's right (first base) act in <see cref="Npcs"/>, the
    /// hero in <see cref="Playing"/>, the seats on the hero's left (third base) in <see cref="NpcsAfter"/>.
    /// </summary>
    public enum RoundPhase { Betting, Insurance, Npcs, Playing, NpcsAfter, Dealer, Settlement }

    public enum HandStatus { Active, Stood, Busted, Blackjack, Surrendered }

    public enum MessageType { None, Win, Lose, Push }

    public enum RoundResult { Win, Loss, Push }

    /// <summary>Why a betting action was refused, so the UI can word the toast in the player's language.</summary>
    public enum Rejection { None, NotEnoughChips, TableMaximum, TableMinimum }
}
