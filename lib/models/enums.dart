/// Enum types mirroring string-based state fields in the JS design spec.
enum AppScreen { onboarding, tips, lobby, table, stats, friends, shop, settings, cup }

enum RoundPhase { betting, insurance, npcs, playing, dealer, settlement }

enum StatsTab { recent, alltime, achievements }

enum LeaderboardPeriod { hourly, daily, alltime }

enum AdState { ready, watching, cooldown }

enum HandStatus { active, stood, busted, blackjack, surrendered }

enum MessageType { none, win, lose, push }

enum RoundResult { win, loss, push }
