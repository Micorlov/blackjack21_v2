import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gives layout tests realistic text metrics.
///
/// `flutter test` renders every unresolved font family in its own test font,
/// whose glyphs are all a full em wide — twice the width of the proportional
/// faces the app actually uses (Sora, Space Mono and Instrument Serif are
/// fetched by `google_fonts` at runtime, so they are never in the test
/// bundle). At 2x width any row holding a sentence "overflows" in a test and
/// is perfectly fine on a phone, which makes overflow assertions useless.
///
/// This registers Roboto — shipped inside the Flutter SDK, so nothing new is
/// committed — under the family names `google_fonts` asks for, bringing the
/// measured advance to ~0.50 em/char against Sora's ~0.55. Text therefore
/// measures a little narrower than the real thing, so the sweep's 1.3x
/// text-scale pass is what covers the difference.
///
/// Call from `setUpAll`, before pumping anything.
Future<void> loadRealTestFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  final dir = Directory('${root ?? ''}/bin/cache/artifacts/material_fonts');
  if (root == null || !dir.existsSync()) {
    throw StateError(
      'Cannot find the Flutter SDK font cache at ${dir.path}. Layout tests need real font '
      'metrics — run them through `flutter test` so FLUTTER_ROOT is set.',
    );
  }

  Future<ByteData> read(String file) async {
    final bytes = await File('${dir.path}/$file').readAsBytes();
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  // `GoogleFonts.sora(weight: w700)` resolves to the family `Sora_700`, so
  // one loader is needed per variant the app can ask for.
  for (final family in _families) {
    for (final weight in _weights) {
      final file = weight >= 600 ? 'Roboto-Bold.ttf' : 'Roboto-Regular.ttf';
      final upright = weight == 400 ? 'regular' : '$weight';
      final italic = weight == 400 ? 'italic' : '${weight}italic';
      for (final variant in [upright, italic]) {
        await (FontLoader('${family}_$variant')..addFont(read(file))).load();
      }
    }
  }
}

const _families = ['Sora', 'SpaceMono', 'InstrumentSerif'];
const _weights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
