namespace Blackjack.Core
{
    public enum AppScreen { Onboarding, Lobby, Table, Stats, Friends, Settings }

    public enum RoundPhase { Betting, Insurance, Npcs, Playing, Dealer, Settlement }

    public enum HandStatus { Active, Stood, Busted, Blackjack, Surrendered }

    public enum MessageType { None, Win, Lose, Push }

    public enum RoundResult { Win, Loss, Push }

    /// <summary>Why a betting action was refused, so the UI can word the toast in the player's language.</summary>
    public enum Rejection { None, NotEnoughChips, TableMaximum, TableMinimum }
}
