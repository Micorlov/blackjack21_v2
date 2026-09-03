import 'package:blackjack21_v2/services/sound_player.dart';

/// Records which channel each call-out was handed to, and says nothing.
class RecordingSound extends SoundPlayer {
  /// How long the caller is told a line runs for. Zero by default: a test that
  /// only cares which channel a call-out went to should not have to wait for
  /// audio nothing is playing. Set it to make the app wait on the voice — the
  /// dealer paces its turn off exactly this number.
  Duration lineDuration = Duration.zero;
  final List<GameSfx> tones = [];
  final List<GameVoice> voices = [];
  final List<List<String>> words = [];

  /// The seat call-outs.
  Iterable<GameVoice> get spokenSeatLines => voices
      .where((v) => v == GameVoice.npcStand || v == GameVoice.npcBust);

  /// The `You have <total>` lines, whenever they were said.
  List<List<String>> get handTotals =>
      words.where((l) => l.first == 'you_have').toList();

  /// The `Dealer has <total>` lines, said as the hole card turns over.
  List<List<String>> get dealerTotals =>
      words.where((l) => l.first == 'dealer_has').toList();

  /// Everything spoken, in the order it was handed over — a stitched line as
  /// its first word, a pre-recorded one as its [GameVoice]. The two channels
  /// interleave (a dealer natural is called, then the settlement result), and
  /// their order is the point.
  final List<Object> spoken = [];

  void reset() {
    tones.clear();
    voices.clear();
    words.clear();
    spoken.clear();
  }

  @override
  Future<void> play(GameSfx sfx) async => tones.add(sfx);

  @override
  Future<DateTime?> playVoice(GameVoice voice) async {
    voices.add(voice);
    spoken.add(voice);
    return DateTime.now().add(lineDuration);
  }

  @override
  Future<DateTime?> playWords(List<String> line) async {
    words.add(line);
    spoken.add(line.first);
    return DateTime.now().add(lineDuration);
  }
}
