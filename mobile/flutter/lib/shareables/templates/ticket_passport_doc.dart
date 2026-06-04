/// Editable-card preset — **Passport Page + Entry Stamp**. A cream passport
/// spread: a machine-readable zone (barcode) at the bottom, an inked circular
/// ENTRY stamp rotated over the page, a holder/details statGrid, and a
/// perforated binding edge on the left with stitch notches. Volt-lime accent on
/// the stamp. Every text layer editable; holder name / date / stats bind live.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketPassportDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const ink = Color(0xFF1B1A12);
  const paper = Color(0xFFEFEAD8);
  const sub = Color(0x8C1B1A12);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketPassport',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0C0D08), Color(0xFF050604)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Passport page.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.7),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 10,
      ),
      // Binding edge perforation (left).
      perforationEl(
        pos: const Offset(0.105, 0.5),
        size: const Size(0.01, 0.7),
        edge: PerforationEdge.left,
        color: const Color(0x661B1A12),
        notchColor: const Color(0xFF0C0D08),
        notchRadius: 12,
      ),
      // Masthead.
      textEl(
        pos: const Offset(0.55, 0.215),
        size: const Size(0.66, 0.03),
        literal: 'REPUBLIC OF ZEALOVA',
        font: CardFontIx.serif,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.55, 0.255),
        size: const Size(0.66, 0.02),
        literal: 'PASSPORT · TYPE GYM',
        font: CardFontIx.mono,
        fontSize: 14,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      // Holder name.
      textEl(
        pos: const Offset(0.55, 0.32),
        size: const Size(0.66, 0.045),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.display,
        fontSize: 40,
        color: ink,
        align: TextAlign.center,
        allCaps: true,
        maxLines: 1,
      ),
      // Details grid.
      statGridEl(
        pos: const Offset(0.55, 0.43),
        size: const Size(0.66, 0.13),
        columns: 2,
        tiles: const [
          ['ZEA', 'NATIONALITY'],
          ['GAINS', 'CLASS'],
          ['VALID', 'STATUS'],
          ['∞', 'VISAS'],
        ],
        tileColor: const Color(0x141B1A12),
        valueColor: ink,
        labelColor: sub,
        valueFontSize: 26,
        labelFontSize: 12,
        valueFont: CardFontIx.condMid,
      ),
      // Inked ENTRY stamp (rotated).
      shapeEl(
        pos: const Offset(0.66, 0.55),
        size: const Size(0.3, 0.16),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        stroke: volt,
        strokeWidth: 4,
      ),
      textEl(
        pos: const Offset(0.66, 0.535),
        size: const Size(0.26, 0.03),
        literal: 'ENTRY',
        font: CardFontIx.display,
        fontSize: 30,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.66, 0.575),
        size: const Size(0.26, 0.02),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 14,
        color: volt,
        align: TextAlign.center,
        allCaps: true,
      ),
      // Machine-readable zone (barcode).
      barcodeEl(
        pos: const Offset(0.55, 0.74),
        size: const Size(0.7, 0.07),
        data: 'P<ZEAGAINS<<ZEALOVA',
        caption: 'P<ZEA · ZEALOVA',
        captionBinding: const DataBinding(BindingSource.heroString),
        barColor: ink,
        background: paper,
        captionColor: sub,
        captionFontSize: 14,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white70),
    ],
  );
}
