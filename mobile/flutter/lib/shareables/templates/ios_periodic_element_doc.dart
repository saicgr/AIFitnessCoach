/// Editable-card preset for the **Periodic Element** template — the workout /
/// stat styled as a single tile from the periodic table of elements: a bordered
/// square cell on a lab-dark canvas with an atomic-number corner, a huge 1-2
/// letter "symbol" (derived/editable), the element name (workout title), an
/// atomic-mass line (hero stat), and a bottom electron-config style stat strip.
/// Volt accent on the symbol + cell border.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosPeriodicElementDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white60 = Color(0x99FFFFFF);

  // Derive a 2-letter symbol from the title (editable afterward).
  final t = data.title.trim();
  final symbol = t.isEmpty
      ? 'Zv'
      : (t.length == 1
          ? t.toUpperCase()
          : '${t[0].toUpperCase()}${t[1].toLowerCase()}');

  return cardDoc(
    aspect: aspect,
    presetId: 'iosPeriodicElement',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF11151C), Color(0xFF080A0F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    elements: [
      // Element cell.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.78, 0.62),
        shape: ShapeKind.rounded,
        fill: const Color(0x0FFFFFFF),
        stroke: accent,
        strokeWidth: 4,
        cornerRadius: 18,
      ),
      // Atomic number (top-left).
      textEl(
        pos: const Offset(0.22, 0.18),
        size: const Size(0.2, 0.04),
        binding: const DataBinding(BindingSource.prCount),
        literal: '26',
        font: CardFontIx.grotesk,
        fontSize: 36,
        color: white,
      ),
      // Category tag (top-right).
      textEl(
        pos: const Offset(0.72, 0.18),
        size: const Size(0.24, 0.03),
        binding: const DataBinding(BindingSource.rank),
        literal: 'ATHLETE',
        font: CardFontIx.cond,
        fontSize: 18,
        color: accent,
        align: TextAlign.right,
        letterSpacing: 1.6,
        allCaps: true,
      ),
      // Big symbol.
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.6, 0.24),
        literal: symbol,
        font: CardFontIx.display,
        fontSize: 200,
        color: white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Element name (title).
      textEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.68, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 30,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Atomic mass (hero stat).
      textEl(
        pos: const Offset(0.5, 0.61),
        size: const Size(0.6, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: white60,
        align: TextAlign.center,
      ),
      // Electron-config style stat strip beneath the cell.
      statGridEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.82, 0.13),
        columns: 3,
        tileColor: const Color(0x14FFFFFF),
        valueColor: white,
        labelColor: white60,
        valueFontSize: 34,
        labelFontSize: 14,
        valueFont: CardFontIx.mono,
        tiles: const [
          ['—', 'STAT'],
          ['—', 'STAT'],
          ['—', 'STAT'],
        ],
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: white60),
    ],
  );
}
