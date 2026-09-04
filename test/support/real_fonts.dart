import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gives layout tests the app's real text metrics.
///
/// `flutter test` renders every unresolved font family in its own test font,
/// whose glyphs are all a full em wide — roughly twice the width of the faces
/// the app actually uses. At 2x width a row holding a sentence "overflows" in
/// a test and is perfectly fine on a phone, which makes overflow assertions
/// useless.
///
/// This used to substitute Roboto from the Flutter SDK cache, because the
/// three families were fetched by `google_fonts` at runtime and so were never
/// in the bundle. They are now committed under `assets/fonts`, so the sweep
/// measures the same glyphs the player sees rather than a stand-in that runs
/// ~10% narrow.
///
/// Call from `setUpAll`, before pumping anything.
Future<void> loadRealTestFonts() async {
  const fonts = <String, List<String>>{
    'Sora': ['Sora-Variable.ttf'],
    'Space Mono': ['SpaceMono-Regular.ttf', 'SpaceMono-Bold.ttf'],
    'Instrument Serif': ['InstrumentSerif-Italic.ttf'],
  };

  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      final path = 'assets/fonts/$file';
      final handle = File(path);
      if (!handle.existsSync()) {
        throw StateError(
          'Missing bundled font $path. Layout tests need real font metrics — '
          'run them from the package root.',
        );
      }
      final bytes = await handle.readAsBytes();
      loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    }
    await loader.load();
  }
}
