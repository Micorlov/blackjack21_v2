import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/social_models.dart';
import '../theme/app_colors.dart';

// Table rules config (was editable `props` in the design tool).
const int kStartingChips = 1000;
const int kDeckCount = 6;
const bool kDealerHitsSoft17 = false;
const bool kShowFriendsAtTable = true;

class AchievementDef {
  final String id;
  final String name;
  final String desc;
  final bool Function(GameState) check;

  const AchievementDef({required this.id, required this.name, required this.desc, required this.check});
}

class ReferralTierDef {
  final String id;
  final int need;
  final int reward;
  final String label;

  const ReferralTierDef({required this.id, required this.need, required this.reward, required this.label});
}

class ShopPackDef {
  final String id;
  final int amount;
  final String price;
  final String badge;

  const ShopPackDef({required this.id, required this.amount, required this.price, this.badge = ''});
}

enum CardBackPattern { stripe, gradient }

class CardBackDef {
  final String id;
  final String label;
  final Color borderColor;
  final CardBackPattern pattern;
  final Color colorA;
  final Color colorB;

  const CardBackDef({
    required this.id,
    required this.label,
    required this.borderColor,
    required this.pattern,
    required this.colorA,
    required this.colorB,
  });
}

class FeltDef {
  final String id;
  final String label;
  final Color borderColor;
  final RadialGradient swatchGradient;
  final RadialGradient tableGradient;

  const FeltDef({
    required this.id,
    required this.label,
    required this.borderColor,
    required this.swatchGradient,
    required this.tableGradient,
  });
}

class StoryDef {
  final String id;
  final String name;
  final String initial;
  final Color color;
  final String headline;
  final String detail;

  const StoryDef({
    required this.id,
    required this.name,
    required this.initial,
    required this.color,
    required this.headline,
    required this.detail,
  });
}

const List<Friend> kInitialFriends = [
  Friend(id: 'f1', name: 'Maya T.', chips: 2450, online: true, dailyScore: 320, hourlyScore: 45),
  Friend(id: 'f2', name: 'Jordan K.', chips: 1820, online: true, dailyScore: 210, hourlyScore: 80),
  Friend(id: 'f3', name: 'Sam R.', chips: 990, online: false, dailyScore: -60, hourlyScore: 15),
  Friend(id: 'f4', name: 'Priya N.', chips: 3120, online: false, dailyScore: 540, hourlyScore: 0),
];

/// Chip denominations the betting tray can offer, lowest first.
const List<int> kChipDenoms = [25, 50, 100, 500, 1000];

/// The chips a given table is allowed to offer. A chip worth more than the
/// table maximum can never form a legal bet, so it is never shown — a $500
/// table must not hand the player a $1,000 chip. At least the smallest chip
/// always survives so the tray is never empty.
List<int> chipDenomsFor(TableStake? stake) {
  if (stake == null) return kChipDenoms;
  final allowed = kChipDenoms.where((d) => d <= stake.max).toList();
  return allowed.isEmpty ? [kChipDenoms.first] : allowed;
}

const List<TableStake> kTables = [
  TableStake(key: 'bronze', name: 'Bronze Table', min: 25, max: 500, tint: AppColors.win, tintDim: Color(0x264FAE8E)),
  TableStake(
    key: 'silver',
    name: 'Silver Table',
    min: 100,
    max: 1000,
    tint: Color(0xFF9FB8C9),
    tintDim: Color(0x249FB8C9),
  ),
  TableStake(key: 'vip', name: 'VIP Table', min: 500, max: 5000, tint: AppColors.gold, tintDim: Color(0x26E8C77A)),
];

String tableFriendsHereLabel(String key) {
  switch (key) {
    case 'bronze':
      return '2 friends here';
    case 'silver':
      return '1 friend here';
    default:
      return 'VIP only';
  }
}

final List<AchievementDef> kAchievementDefs = [
  AchievementDef(id: 'first', name: 'First Hand', desc: 'Play your first hand', check: (s) => s.stats.handsPlayed >= 1),
  AchievementDef(id: 'bj', name: 'Blackjack!', desc: 'Hit a natural 21', check: (s) => s.stats.blackjacks >= 1),
  AchievementDef(id: 'streak3', name: 'On Fire', desc: 'Win 3 hands in a row', check: (s) => s.stats.bestStreak >= 3),
  AchievementDef(id: 'highroller', name: 'High Roller', desc: 'Reach 5,000 chips', check: (s) => s.chips >= 5000),
  AchievementDef(id: 'century', name: 'Century', desc: 'Play 100 hands', check: (s) => s.stats.handsPlayed >= 100),
  AchievementDef(id: 'social', name: 'Well Connected', desc: 'Add 3 friends', check: (s) => s.referralsCount >= 3),
  AchievementDef(id: 'vip', name: 'VIP Status', desc: 'Play at the VIP table', check: (s) => s.visitedVIP),
];

const List<ReferralTierDef> kReferralTierDefs = [
  ReferralTierDef(id: 't1', need: 1, reward: 100, label: 'Invite 1 friend'),
  ReferralTierDef(id: 't2', need: 3, reward: 500, label: 'Invite 3 friends'),
  ReferralTierDef(id: 't3', need: 5, reward: 1500, label: 'Invite 5 friends + VIP access'),
];

const List<String> kChatPool = ['Nice hand!', 'GG', 'So close!', "Let's go!", 'Tough beat', 'Wow, 21!'];

const List<StoryDef> kStoriesData = [
  StoryDef(
    id: 'st1',
    name: 'Maya T.',
    initial: 'M',
    color: AppColors.gold,
    headline: 'Blackjack!',
    detail: 'Maya hit a natural 21 and won 450 chips.',
  ),
  StoryDef(
    id: 'st2',
    name: 'Jordan K.',
    initial: 'J',
    color: AppColors.win,
    headline: '5-win streak',
    detail: 'Jordan is on fire with 5 wins in a row.',
  ),
  StoryDef(
    id: 'st3',
    name: 'Sam R.',
    initial: 'S',
    color: Color(0xFF9FB8C9),
    headline: 'VIP debut',
    detail: 'Sam played their first hand at the VIP table.',
  ),
  StoryDef(
    id: 'st4',
    name: 'Priya N.',
    initial: 'P',
    color: AppColors.cardRed,
    headline: 'Big double down',
    detail: 'Priya doubled down and won 800 chips.',
  ),
];

const List<CardBackDef> kCardBackDefs = [
  CardBackDef(
    id: 'gold',
    label: 'Classic Gold',
    borderColor: AppColors.gold,
    pattern: CardBackPattern.stripe,
    colorA: Color(0xFF14100A),
    colorB: AppColors.goldDark,
  ),
  CardBackDef(
    id: 'emerald',
    label: 'Emerald Foil',
    borderColor: AppColors.win,
    pattern: CardBackPattern.stripe,
    colorA: AppColors.feltDarkest,
    colorB: AppColors.win,
  ),
  CardBackDef(
    id: 'crimson',
    label: 'Crimson Back',
    borderColor: AppColors.lose,
    pattern: CardBackPattern.gradient,
    colorA: Color(0xFF9A332E),
    colorB: Color(0xFF5A1B18),
  ),
];

const List<FeltDef> kFeltDefs = [
  FeltDef(
    id: 'default',
    label: 'Casino Green',
    borderColor: Color(0x59E8C77A),
    swatchGradient: RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xFF1E7D5D), Color(0xFF08201A)]),
    tableGradient: RadialGradient(
      center: Alignment(0, -1),
      radius: 1.3,
      colors: [Color(0xFF1E7D5D), Color(0xFF0D3A2C), Color(0xFF08201A)],
      stops: [0.0, 0.55, 1.0],
    ),
  ),
  FeltDef(
    id: 'ocean',
    label: 'Deep Ocean',
    borderColor: Color(0x59E8C77A),
    swatchGradient: RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xFF1D5F7D), Color(0xFF07161F)]),
    tableGradient: RadialGradient(
      center: Alignment(0, -1),
      radius: 1.3,
      colors: [Color(0xFF1D5F7D), Color(0xFF0C2F3F), Color(0xFF07161F)],
      stops: [0.0, 0.55, 1.0],
    ),
  ),
  FeltDef(
    id: 'ember',
    label: 'Ember',
    borderColor: Color(0x59E8C77A),
    swatchGradient: RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xFF8A3A2C), Color(0xFF1F0C08)]),
    tableGradient: RadialGradient(
      center: Alignment(0, -1),
      radius: 1.3,
      colors: [Color(0xFF8A3A2C), Color(0xFF4A1D16), Color(0xFF1F0C08)],
      stops: [0.0, 0.55, 1.0],
    ),
  ),
];

const List<ShopPackDef> kShopPacks = [
  ShopPackDef(id: 'p1', amount: 500, price: r'$0.99'),
  ShopPackDef(id: 'p2', amount: 2000, price: r'$2.99', badge: 'Popular'),
  ShopPackDef(id: 'p3', amount: 5000, price: r'$5.99'),
  ShopPackDef(id: 'p4', amount: 15000, price: r'$12.99', badge: 'Best Value'),
];

const List<String> kReactions = ['Nice!', 'So close', "Let's go!", 'Rough'];
