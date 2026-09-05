import 'package:flutter/material.dart';

import '../models/social_models.dart';
import '../theme/app_colors.dart';

// Table rules config (was editable `props` in the design tool).
const int kStartingChips = 1000;
const int kDeckCount = 6;
const bool kDealerHitsSoft17 = false;
const bool kShowFriendsAtTable = true;

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

  /// Background of the whole table screen behind the felt.
  final RadialGradient tableGradient;

  /// The felt ellipse itself, inside the wooden rim.
  final RadialGradient ovalGradient;

  const FeltDef({
    required this.id,
    required this.label,
    required this.borderColor,
    required this.swatchGradient,
    required this.tableGradient,
    required this.ovalGradient,
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

const List<String> kChatPool = ['Nice hand!', 'GG', 'So close!', "Let's go!", 'Tough beat', 'Wow, 21!'];

/// The one card back the game draws. There used to be three, sold through a
/// shop that no longer exists.
const CardBackDef kCardBack = CardBackDef(
  id: 'gold',
  label: 'Classic Gold',
  borderColor: AppColors.gold,
  pattern: CardBackPattern.stripe,
  colorA: Color(0xFF14100A),
  colorB: AppColors.goldDark,
);

// Reproduces exactly what table_screen.dart and table_felt.dart used to
// hardcode. The Deep Ocean and Ember felts went with the shop.
const FeltDef kFelt = FeltDef(
  id: 'default',
  label: 'Casino Green',
  borderColor: Color(0x59E8C77A),
  swatchGradient: RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xFF1E7D5D), Color(0xFF08201A)]),
  tableGradient: RadialGradient(
    center: Alignment(0, 0.92),
    radius: 1.3,
    colors: [Color(0xFF123A2C), Color(0xFF0A1F18), Color(0xFF05100C)],
    stops: [0.0, 0.45, 1.0],
  ),
  ovalGradient: RadialGradient(
    center: Alignment(0, -0.48),
    radius: 0.9,
    colors: [Color(0xFF2A8F70), Color(0xFF166248), Color(0xFF0B3527), Color(0xFF082A20)],
    stops: [0.0, 0.42, 0.78, 1.0],
  ),
);

/// Quick-reply chips in the table chat, per the design's chat sheet.
const List<String> kReactions = ['GG', 'Nice hand', 'Ouch', 'One more', 'Dealer luck'];

/// How many chat bubbles the table keeps — old lines scroll off the log.
const int kChatLogLimit = 6;
