// Guards the sound assets themselves rather than the code that plays them.
//
// `npc_stand.wav` once shipped truncated: 0.21s that stopped dead mid-syllable
// at 47% of full amplitude, so the spoken "Stand" played as an unintelligible
// click. Nothing in the app could detect that — the file loaded and played
// fine, it just held the wrong audio. These tests read the WAVs directly and
// assert every clip decays to near-silence before it ends.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// A clip still playing above this share of its own peak in its final moments
/// was cut mid-sound. Every intact clip currently sits at or under 2.5%.
const double _maxTailRatio = 0.10;

/// Voice lines need enough room for a whole word; the shortest intact one
/// (`big_win.wav`, "Big win") runs 0.513s.
const double _minVoiceSeconds = 0.25;

const Duration _tailWindow = Duration(milliseconds: 10);

const _voiceClips = {
  'npc_stand.wav',
  'npc_bust.wav',
  'player_win.wav',
  'player_lose.wav',
  'big_win.wav',
  'player_pot.wav',
};

/// Number words are stitched into one another mid-sentence, so a truncated or
/// over-trimmed one is even more audible than a standalone line — but they are
/// single words, and short ones like "two" run well under the voice-line floor.
const double _minWordSeconds = 0.12;

/// Mono 16-bit PCM samples plus the sample rate, read out of a RIFF/WAVE file.
class _Wav {
  const _Wav(this.samples, this.sampleRate);

  final Int16List samples;
  final int sampleRate;

  double get seconds => samples.length / sampleRate;
  int get peak => samples.fold(0, (m, s) => s.abs() > m ? s.abs() : m);

  int tailPeak(Duration window) {
    final frames = (sampleRate * window.inMicroseconds / 1e6).round();
    final from = samples.length - frames;
    return samples
        .sublist(from < 0 ? 0 : from)
        .fold(0, (m, s) => s.abs() > m ? s.abs() : m);
  }
}

_Wav _readWav(File file) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF',
      reason: '${file.path} is not a RIFF file');
  expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE',
      reason: '${file.path} is not a WAVE file');

  var sampleRate = 0;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      expect(data.getUint16(body, Endian.little), 1,
          reason: '${file.path} must be uncompressed PCM');
      expect(data.getUint16(body + 2, Endian.little), 1,
          reason: '${file.path} must be mono');
      expect(data.getUint16(body + 14, Endian.little), 16,
          reason: '${file.path} must be 16-bit');
      sampleRate = data.getUint32(body + 4, Endian.little);
    } else if (id == 'data') {
      final samples = Int16List(size ~/ 2);
      for (var i = 0; i < samples.length; i++) {
        samples[i] = data.getInt16(body + i * 2, Endian.little);
      }
      return _Wav(samples, sampleRate);
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  fail('${file.path} has no data chunk');
}

void main() {
  // Recursive: the spoken number words live in assets/sfx/num/, and they are
  // stitched into sentences, so they need the same guarantees.
  final files = Directory('assets/sfx')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.wav'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('every voice clip the game plays is present', () {
    expect(files, isNotEmpty);
    final names = files.map((f) => f.uri.pathSegments.last).toSet();
    expect(names, containsAll(_voiceClips));
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final isWord = file.path.contains('/num/');

    group(name, () {
      test('decays instead of being cut off', () {
        final wav = _readWav(file);
        final ratio = wav.tailPeak(_tailWindow) / wav.peak;
        expect(
          ratio,
          lessThan(_maxTailRatio),
          reason: '$name still plays at ${(ratio * 100).toStringAsFixed(1)}% '
              'of its peak in the final ${_tailWindow.inMilliseconds}ms, so it '
              'was cut short rather than allowed to finish',
        );
      });

      if (_voiceClips.contains(name) || isWord) {
        test('is long enough to hold a spoken word', () {
          final floor = isWord ? _minWordSeconds : _minVoiceSeconds;
          expect(_readWav(file).seconds, greaterThan(floor),
              reason: '$name is too short to contain its call-out');
        });
      }
    });
  }
}
