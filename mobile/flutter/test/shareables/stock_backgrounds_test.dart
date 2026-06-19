import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/shareables/stock_backgrounds.dart';

/// Guards against asset drift: every stock background path declared in
/// `stock_backgrounds.dart` must resolve to a real file on disk. When a tile
/// references a missing asset, the Shareables "Choose a backdrop → Stock" grid
/// (and the editor's Backdrop sheet) render a broken-image placeholder.
///
/// `flutter test` runs with the Flutter package root as the working directory,
/// so the `assets/...` relative paths resolve via `File(path).existsSync()`.
void main() {
  test('every stock background asset path exists on disk', () {
    expect(kAllStockBackgrounds, isNotEmpty,
        reason: 'Expected at least one stock background to be registered.');

    final missing = <String>[
      for (final path in kAllStockBackgrounds)
        if (!File(path).existsSync()) path,
    ];

    expect(
      missing,
      isEmpty,
      reason: 'These stock background asset paths do not exist on disk '
          '(they would render as broken-image tiles):\n'
          '${missing.join('\n')}',
    );
  });
}
