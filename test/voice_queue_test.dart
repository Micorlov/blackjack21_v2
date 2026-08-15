// The spoken call-outs are scheduled from three independent timers — the hand
// total as a card lands, the settlement result, the sweep-pot figure — and
// they all drive the one voice channel. Their windows overlap, so the channel
// queues them. These tests pin the two things that queue depends on: that a
// clip's length really is derivable from its byte count, and that the overlap
// is real, so nobody "simplifies" the queue away and brings back the bug where
// "You have twenty five" was cut off after four syllables by "Player loses".

import 'dart:io';
import 'dart:typed_data';

import 'package:blackjack21_v2/services/sound_player.dart';
import 'package:blackjack21_v2/services/spoken_amount.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

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
