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

const _stake = TableStake(
  key: 'bronze',
  name: 'Bronze Table',
  min: 25,
  max: 500,
  tint: Color(0xFF4FAE8E),
  tintDim: Color(0x264FAE8E),
);

/// Records which channel each call-out was handed to, and says nothing.
class _RecordingSound extends SoundPlayer {
  final List<GameSfx> tones = [];
  final List<GameVoice> voices = [];
  final List<List<String>> words = [];

  /// The seat call-outs, which are the ones this file is about.
  Iterable<GameVoice> get spokenSeatLines => voices
      .where((v) => v == GameVoice.npcStand || v == GameVoice.npcBust);

  @override
  Future<void> play(GameSfx sfx) async => tones.add(sfx);

  @override
  Future<DateTime?> playVoice(GameVoice voice) async {
    voices.add(voice);
    return DateTime.now();
  }

  @override
  Future<DateTime?> playWords(List<String> line) async {
    words.add(line);
    return DateTime.now();
  }
}

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

    testWidgets('a seat speaks through the voice channel as it acts',
        (tester) async {
      // The call sites, not just the enum: a seat's outcome must reach
      // playVoice — the queued channel — and never the tone channel, whatever
      // the seat decides to do.
      final sound = _RecordingSound();
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

    test("a seat's call-out is due while the hand total is still speaking", () {
      // The deal cues the hero's total kHandTotalVoiceLead in, and the first
      // seat speaks kNpcDecisionLead in. The total's line outlasts the gap
      // between the two for every total there is, so the seat always arrives
      // mid-sentence — on the tone channel that meant "You have" and then
      // "Bust" over the top of it.
      final gap = GameNotifier.kNpcDecisionLead - GameNotifier.kHandTotalVoiceLead;
      for (var total = 4; total <= 21; total++) {
        expect(
          handTotalLine(total),
          greaterThan(gap),
          reason: 'a $total call-out is over before the first seat speaks, so '
              'the seat lines would not need the queue',
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
