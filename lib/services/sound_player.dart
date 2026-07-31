import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short game sound effects bundled under `assets/sfx/`.
enum GameSfx { chip, deal, win, lose, push, blackjack, turn, npcStand, npcBust }

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

  Future<void> _playOn(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } on PlatformException {
      // No audio backend available (e.g. running under `flutter test`).
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _voicePlayer.dispose();
  }
}
