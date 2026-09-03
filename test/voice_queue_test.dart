// The spoken call-outs are scheduled from four independent timers — the hand
// total as a card lands, an NPC seat's "Stand"/"Bust" as it acts, the
// settlement result, the sweep-pot figure — and they all drive the one voice
// channel. Their windows overlap, so the channel
// queues them. These tests pin the two things that queue depends on: that a
// clip's length really is derivable from its byte count, and that the overlap
// is real, so nobody "simplifies" the queue away and brings back the bug where
// "You have twenty five" was cut off after four syllables by "Player loses".

import 'dart:io';
import 'dart:typed_data';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/services/sound_player.dart';
import 'package:blackjack21_v2/services/spoken_amount.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_sound.dart';

const _stake = TableStake(
  key: 'bronze',
  name: 'Bronze Table',
  min: 25,
  max: 500,
  tint: Color(0xFF4FAE8E),
  tintDim: Color(0x264FAE8E),
);

/// Seated at a table with chips and the voice on, ready to be dealt.
class _TableNotifier extends GameNotifier {
  _TableNotifier(SoundPlayer sound) : super(sound: sound) {
    state = const GameState(
      screen: AppScreen.table,
      displayName: 'Guest',
      chips: 5000,
      stake: _stake,
      friends: kInitialFriends,
    );
  }
}

/// The parts of a WAV header the voice channel relies on.
class _Wav {
  const _Wav({
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.dataBytes,
  });

  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final int dataBytes;

  Duration get duration => Duration(
        microseconds:
            dataBytes ~/ (channels * bitsPerSample ~/ 8) * 1000000 ~/ sampleRate,
      );
}

/// Walks the RIFF chunk list the same way [SoundPlayer] does, rather than
/// assuming a 44-byte header.
_Wav _readWav(File file) {
  final bytes = ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  var offset = 12; // past 'RIFF', size, 'WAVE'
  int? sampleRate, channels, bitsPerSample, dataBytes;

  while (offset + 8 <= bytes.lengthInBytes) {
    final id = String.fromCharCodes(
      Uint8List.sublistView(bytes, offset, offset + 4),
    );
    final size = bytes.getUint32(offset + 4, Endian.little);
    if (id == 'fmt ') {
      channels = bytes.getUint16(offset + 10, Endian.little);
      sampleRate = bytes.getUint32(offset + 12, Endian.little);
      bitsPerSample = bytes.getUint16(offset + 22, Endian.little);
    } else if (id == 'data') {
      dataBytes = size;
    }
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }

  if (sampleRate == null ||
      channels == null ||
      bitsPerSample == null ||
      dataBytes == null) {
    throw FormatException('${file.path} is missing a fmt or data chunk');
  }
  return _Wav(
    sampleRate: sampleRate,
    channels: channels,
    bitsPerSample: bitsPerSample,
    dataBytes: dataBytes,
  );
}

List<File> _clips(String dir) => Directory(dir)
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.wav'))
    .toList()
  ..sort((a, b) => a.path.compareTo(b.path));

void main() {
  final wordClips = _clips('assets/sfx/num');
  final lineClips = _clips('assets/sfx');

  group('clip format', () {
    test('every clip is 44.1kHz mono 16-bit, as the voice channel assumes', () {
      // SoundPlayer strips each clip to raw PCM and re-wraps the run in one
      // canonical header. A clip in another format would be re-labelled rather
      // than converted, and would play back at the wrong speed and pitch.
      for (final file in [...wordClips, ...lineClips]) {
        final wav = _readWav(file);
        expect(wav.sampleRate, 44100, reason: '${file.path} sample rate');
        expect(wav.channels, 1, reason: '${file.path} channel count');
        expect(wav.bitsPerSample, 16, reason: '${file.path} bit depth');
      }
    });

    test('wavDuration reads a canonical-header clip to within a millisecond', () {
      // The queue times what follows a line from this number alone, so it has
      // to match the audio actually in the file.
      for (final file in [...wordClips, ...lineClips]) {
        final wav = _readWav(file);
        final fromBytes = SoundPlayer.wavDuration(wav.dataBytes + 44);
        expect(
          (fromBytes - wav.duration).inMilliseconds.abs(),
          lessThanOrEqualTo(1),
          reason: '${file.path}: ${fromBytes.inMilliseconds}ms from byte count '
              'vs ${wav.duration.inMilliseconds}ms of audio',
        );
      }
    });
  });

  group('every spoken line is on the queued channel', () {
    // The NPC seats' "Stand"/"Bust" were filed under GameSfx and played on the
    // tone channel, which the queue cannot hold back. The opening deal talked
    // over itself as a result: "You have sixteen" starts 350ms after the cards
    // land and runs over a second, the first seat acts 520ms in, and the hero
    // heard "You have" and then "Bust" on top of it.
    const spokenClips = {
      'sfx/npc_stand.wav',
      'sfx/npc_bust.wav',
      'sfx/player_win.wav',
      'sfx/player_lose.wav',
      'sfx/player_push.wav',
      'sfx/big_win.wav',
      'sfx/player_pot.wav',
    };

    test('no spoken clip is reachable from the tone channel', () {
      final tones = GameSfx.values.map(SoundPlayer.sfxAsset).toSet();
      expect(
        tones.intersection(spokenClips),
        isEmpty,
        reason: 'a clip of words on the tone channel plays over whatever the '
            'voice channel is in the middle of saying — nothing queues it',
      );
    });

    test('every spoken clip is reachable from the voice channel', () {
      final voices = GameVoice.values.map(SoundPlayer.voiceAsset).toSet();
      expect(voices, containsAll(spokenClips));
    });

    testWidgets('the pot is called, then a beat, then the hand the hero holds',
        (tester) async {
      // "You have sixteen" used to be said as the cards landed, on top of the
      // seats playing their own turns. It is about the hand the hero is being
      // asked to play, so it is held until they are the one being asked — and
      // it comes last, after what the table is playing for has been called and
      // allowed to land.
      final sound = RecordingSound();
      final notifier = _TableNotifier(sound);
      addTearDown(notifier.dispose);

      /// Runs the fake clock until [done], or gives up.
      Future<void> pumpUntil(bool Function() done, {int steps = 300}) async {
        for (var i = 0; i < steps && !done(); i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // A dealer ace goes to insurance and a natural settles on the spot;
      // either skips the hero's turn, so retry rather than leaving the test to
      // the shoe. Every turn that does arrive is called the same way, pot or
      // no pot.
      for (var round = 0;
          round < 8 && notifier.state.phase != RoundPhase.playing;
          round++) {
        sound.reset();
        notifier.placeBet(25);
        notifier.dealRound();

        if (notifier.state.phase == RoundPhase.npcs) {
          // Every seat plays. Not a word about the hero's hand over any of it.
          await pumpUntil(() => notifier.state.phase != RoundPhase.npcs);
          expect(sound.handTotals, isEmpty,
              reason: "the hero's total was announced while the seats were "
                  'still playing');
        }
        if (notifier.state.phase == RoundPhase.playing) break;

        await pumpUntil(() => notifier.state.phase == RoundPhase.settlement);
        notifier.nextHand();
      }
      expect(notifier.state.phase, RoundPhase.playing,
          reason: 'never dealt a round that reached the hero');

      // The turn cue, and on it what the table is playing for — a figure when
      // a seat has forfeited a bet, "No sweep pot" when none has.
      await tester.pump(GameNotifier.kTurnVoiceLead);
      expect(
        sound.words.map((l) => l.first),
        anyOf(contains('sweep_pot'), contains('no_sweep_pot')),
        reason: 'the hero was not told what the table is playing for',
      );
      expect(sound.handTotals, isEmpty,
          reason: 'the total was said over the pot call-out');

      // A beat to let it land, and only then the hand to play it with. The
      // margins are the 100ms granularity of pumpUntil above: the turn can
      // have begun up to one step before this clock started.
      await tester.pump(
        GameNotifier.kPostPotPause - const Duration(milliseconds: 200),
      );
      expect(sound.handTotals, isEmpty,
          reason: 'the beat after the pot call-out was cut short');
      await tester.pump(const Duration(milliseconds: 400));

      expect(sound.handTotals, hasLength(1),
          reason: 'the hero is asked to act without being told what they hold');
      expect(
        sound.words.indexWhere(
            (l) => l.first == 'sweep_pot' || l.first == 'no_sweep_pot'),
        lessThan(sound.words.indexOf(sound.handTotals.single)),
        reason: "the hero's own total was called before the table's pot",
      );
    });

    testWidgets('a seat speaks through the voice channel as it acts',
        (tester) async {
      // The call sites, not just the enum: a seat's outcome must reach
      // playVoice — the queued channel — and never the tone channel, whatever
      // the seat decides to do.
      final sound = RecordingSound();
      final notifier = _TableNotifier(sound);

      // A deal can skip the seats entirely — a dealer ace goes to insurance,
      // and a natural settles on the spot — so retry a few rounds rather than
      // leaving the test to the shoe.
      for (var round = 0; round < 8 && sound.spokenSeatLines.isEmpty; round++) {
        notifier.placeBet(25);
        notifier.dealRound();
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 600));
        }
        notifier.nextHand();
      }

      expect(sound.spokenSeatLines, isNotEmpty,
          reason: 'no seat ever said anything, so this proves nothing');
      expect(
        sound.tones.where((t) => t == GameSfx.deal),
        isNotEmpty,
        reason: 'the tone channel should still be carrying the tones',
      );
      notifier.dispose();
    });
  });

  group('the voice schedule overlaps, which is why the channel queues', () {
    /// Lower bound on "You have <total>" — the clips alone, ignoring the gaps
    /// [SoundPlayer] inserts between them.
    Duration handTotalLine(int total) {
      final words = ['you_have', ...spokenAmountWords(total)];
      return words
          .map((w) => _readWav(File('assets/sfx/num/$w.wav')).duration)
          .reduce((a, b) => a + b);
    }

    test('every hand total is still speaking when the result call-out is due', () {
      // A bust, a double and a natural blackjack all schedule the hand total
      // and the settlement result from the same instant, kHandTotalVoiceLead
      // and kVoiceLead apart. If the line is longer than that gap — and it
      // always is — the second call-out arrives mid-sentence.
      final gap = GameNotifier.kVoiceLead - GameNotifier.kHandTotalVoiceLead;
      // 4 is the lowest two-card total; 31 the highest a hit can reach.
      for (var total = 4; total <= 31; total++) {
        expect(
          handTotalLine(total),
          greaterThan(gap),
          reason: 'a $total call-out fits inside the ${gap.inMilliseconds}ms '
              'gap, so the queue would no longer be doing anything',
        );
      }
    });

    test('the longest call-out still fits inside the queue window', () {
      // Past kMaxVoiceWait a queued line is dropped rather than said late. The
      // hand total is the longest thing that can be ahead of another line, so
      // it must not push the next one over that limit.
      final longest = [
        for (var total = 4; total <= 31; total++) handTotalLine(total),
      ].reduce((a, b) => a > b ? a : b);
      expect(
        GameNotifier.kHandTotalVoiceLead + longest,
        lessThan(SoundPlayer.kMaxVoiceWait),
        reason: 'the settlement call-out would be dropped instead of queued',
      );
    });
  });
}
