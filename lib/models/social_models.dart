import 'package:flutter/material.dart';

import 'playing_card.dart';

class Friend {
  final String id;
  final String name;
  final int chips;
  final bool online;
  final int dailyScore;
  final int hourlyScore;

  const Friend({
    required this.id,
    required this.name,
    required this.chips,
    required this.online,
    required this.dailyScore,
    required this.hourlyScore,
  });

  String get firstName => name.split(' ').first;
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  Friend copyWith({int? chips}) => Friend(
    id: id,
    name: name,
    chips: chips ?? this.chips,
    online: online,
    dailyScore: dailyScore,
    hourlyScore: hourlyScore,
  );
}

class NpcSeat {
  final int bet;
  final List<PlayingCard> cards;
  final String action; // '', 'HIT', 'STAND', 'BUST'
  final bool done;

  const NpcSeat({this.bet = 0, this.cards = const [], this.action = '', this.done = false});

  NpcSeat copyWith({int? bet, List<PlayingCard>? cards, String? action, bool? done}) {
    return NpcSeat(
      bet: bet ?? this.bet,
      cards: cards ?? this.cards,
      action: action ?? this.action,
      done: done ?? this.done,
    );
  }
}

class TableStake {
  final String key;
  final String name;
  final int min;
  final int max;
  final Color tint;
  final Color tintDim;

  const TableStake({
    required this.key,
    required this.name,
    required this.min,
    required this.max,
    required this.tint,
    required this.tintDim,
  });
}

class ChatMessage {
  final String name;
  final String text;
  final int id;

  const ChatMessage({required this.name, required this.text, required this.id});
}

class SweepContributor {
  final String name;
  final int amount;
  final String reason; // 'bust' | 'lost'

  const SweepContributor({required this.name, required this.amount, required this.reason});
}

class SweepInfo {
  final int pot;
  final int winnerBet;
  final int totalWin;
  final String winner;
  final int winnerTotal;
  final bool heroTook;
  final List<SweepContributor> contributors;

  const SweepInfo({
    required this.pot,
    required this.winnerBet,
    required this.totalWin,
    required this.winner,
    required this.winnerTotal,
    required this.heroTook,
    required this.contributors,
  });
}
