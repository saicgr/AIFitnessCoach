/// Loads the bundled shareable display fonts into the test font system so
/// golden renders show real type (Anton/Barlow/Fraunces/etc.) instead of the
/// Ahem fallback. CI-safe: reads the fonts from the package asset bundle
/// declared in pubspec, no absolute paths.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await load('Anton', ['assets/fonts/Anton-Regular.ttf']);
  await load('Barlow Condensed', [
    'assets/fonts/BarlowCondensed-SemiBold.ttf',
    'assets/fonts/BarlowCondensed-Bold.ttf',
    'assets/fonts/BarlowCondensed-ExtraBold.ttf',
  ]);
  await load('Space Mono', [
    'assets/fonts/SpaceMono-Regular.ttf',
    'assets/fonts/SpaceMono-Bold.ttf',
  ]);
  await load('Fraunces', ['assets/fonts/Fraunces.ttf']);
  await load('Archivo', ['assets/fonts/Archivo.ttf']);

  await testMain();
}
