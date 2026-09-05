/// Enum types mirroring string-based state fields in the JS design spec.
enum AppScreen { onboarding, lobby, table, stats, friends, settings }

enum RoundPhase { betting, insurance, npcs, playing, dealer, settlement }

enum StatsTab { recent, alltime }

enum LeaderboardPeriod { hourly, daily, alltime }

enum HandStatus { active, stood, busted, blackjack, surrendered }

enum MessageType { none, win, lose, push }

enum RoundResult { win, loss, push }
