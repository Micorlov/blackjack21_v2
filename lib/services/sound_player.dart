import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Short game sound effects bundled under `assets/sfx/`.
enum GameSfx {
  chip,
  deal,
  win,
  lose,
  push,
  blackjack,
  turn,
  npcStand,
  npcBust,
  potCelebration,
}

/// Spoken call-outs announcing the hero's settlement result. Kept apart from
/// [GameSfx] because they play on their own channel — see [SoundPlayer].
enum GameVoice { playerWin, playerLose, bigWin, playerPot }

const Map<GameSfx, String> _sfxAssets = {
  GameSfx.chip: 'sfx/chip.wav',
  GameSfx.deal: 'sfx/deal.wav',
  GameSfx.win: 'sfx/win.wav',
  GameSfx.lose: 'sfx/lose.wav',
  GameSfx.push: 'sfx/push.wav',
  GameSfx.blackjack: 'sfx/blackjack.wav',
  GameSfx.turn: 'sfx/turn.wav',
  // Spoken voice lines (synthesized) announcing an NPC seat's outcome.
  GameSfx.npcStand: 'sfx/npc_stand.wav',
  GameSfx.npcBust: 'sfx/npc_bust.wav',
  // Drum flourish played after the "Player wins the pot" call-out.
  GameSfx.potCelebration: 'sfx/pot_celebration.wav',
};

const Map<GameVoice, String> _voiceAssets = {
  GameVoice.playerWin: 'sfx/player_win.wav',
  GameVoice.playerLose: 'sfx/player_lose.wav',
  GameVoice.bigWin: 'sfx/big_win.wav',
  GameVoice.playerPot: 'sfx/player_pot.wav',
};

/// Thin wrapper around [AudioPlayer] for one-shot game SFX. Playback errors
/// (missing audio output on a simulator, platform channel not available in
/// widget tests) are swallowed — a silent miss is preferable to a crash for
/// a purely cosmetic feature.
///
/// Tones and voice lines get their own [AudioPlayer]. Each channel stops
/// whatever it is playing before starting the next clip, so the two would cut
/// each other short if they shared one player — and a settlement plays a tone
/// and then a spoken result.
class SoundPlayer {
  SoundPlayer() {
    _player.setReleaseMode(ReleaseMode.stop);
    _voicePlayer.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();

  Future<void> play(GameSfx sfx) => _playOn(_player, _sfxAssets[sfx]!);

  Future<void> playVoice(GameVoice voice) =>
      _playOn(_voicePlayer, _voiceAssets[voice]!);

  /// Speaks a run of number-word clips from `assets/sfx/num/` as one line,
  /// e.g. `['table_pot', 'three', 'hundred', 'seventy', 'five', 'dollars']`.
  ///
  /// Pot amounts are arbitrary, so the phrase cannot be pre-recorded. The
  /// clips are joined into a single WAV in memory and handed to the player as
  /// one source — playing them as separate `play()` calls would need each to
  /// report completion before the next began, and any gap or overshoot would
  /// be audible in the middle of a sentence.
  Future<void> playWords(List<String> words) async {
    if (words.isEmpty) return;
    try {
      final clips = <Uint8List>[];
      for (final word in words) {
        clips.add(await _loadWordPcm(word));
      }
      await _voicePlayer.stop();
      await _voicePlayer.play(
        BytesSource(_joinClips(clips), mimeType: 'audio/wav'),
      );
    } on PlatformException {
      // No audio backend available (e.g. running under `flutter test`).
    } on FlutterError {
      // Asset missing from the bundle — nothing sensible to say.
    }
  }

  Future<void> _playOn(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } on PlatformException {
      // No audio backend available (e.g. running under `flutter test`).
    }
  }

  /// Raw PCM for one word clip, without its WAV header. Cached because a
  /// single announcement reuses words and every round says them again.
  Future<Uint8List> _loadWordPcm(String word) async {
    final cached = _wordPcm[word];
    if (cached != null) return cached;

    final data = await rootBundle.load('assets/sfx/num/$word.wav');
    final pcm = _pcmOf(data);
    _wordPcm[word] = pcm;
    return pcm;
  }

  final Map<String, Uint8List> _wordPcm = {};

  /// The contents of the WAV's `data` chunk. Walks the RIFF chunk list rather
  /// than assuming a 44-byte header, since `afconvert` may emit others first.
  static Uint8List _pcmOf(ByteData wav) {
    var offset = 12; // past 'RIFF', size, 'WAVE'
    while (offset + 8 <= wav.lengthInBytes) {
      final id = String.fromCharCodes(
        Uint8List.view(wav.buffer, wav.offsetInBytes + offset, 4),
      );
      final size = wav.getUint32(offset + 4, Endian.little);
      if (id == 'data') {
        return Uint8List.view(
          wav.buffer,
          wav.offsetInBytes + offset + 8,
          size,
        );
      }
      offset += 8 + size + (size.isOdd ? 1 : 0);
    }
    throw const FormatException('WAV has no data chunk');
  }

  /// Joins clips into one WAV, separated by [_kWordGap] of silence so the
  /// words do not run together — each clip was trimmed to its own edges, so
  /// butting them up back to back sounds hurried.
  static Uint8List _joinClips(List<Uint8List> clips) {
    final gap = Uint8List(
      (_kSampleRate * _kWordGap.inMilliseconds ~/ 1000) * _kBytesPerSample,
    );
    final body = BytesBuilder();
    for (var i = 0; i < clips.length; i++) {
      if (i > 0) body.add(gap);
      body.add(clips[i]);
    }
    final pcm = body.takeBytes();

    final out = BytesBuilder()..add(_wavHeader(pcm.length));
    out.add(pcm);
    return out.takeBytes();
  }

  /// A 44-byte canonical PCM WAV header for [dataBytes] of mono 16-bit audio.
  static Uint8List _wavHeader(int dataBytes) {
    final header = ByteData(44);
    void tag(int at, String s) {
      for (var i = 0; i < 4; i++) {
        header.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    const byteRate = _kSampleRate * _kBytesPerSample;
    tag(0, 'RIFF');
    header.setUint32(4, 36 + dataBytes, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, _kSampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, _kBytesPerSample, Endian.little); // block align
    header.setUint16(34, 16, Endian.little); // bits per sample
    tag(36, 'data');
    header.setUint32(40, dataBytes, Endian.little);
    return header.buffer.asUint8List();
  }

  static const int _kSampleRate = 44100;
  static const int _kBytesPerSample = 2;
  static const Duration _kWordGap = Duration(milliseconds: 45);

  Future<void> dispose() async {
    await _player.dispose();
    await _voicePlayer.dispose();
  }
}
