/// Editable-card preset for the **Tier List** data/meme template (workout
/// edition) — your session's lifts ranked into internet S/A/B/C tiers: coloured
/// bands each with a big letter label, the session's exercises dropped onto the
/// S row as chips, and the hero volume foot. Distinct from the food
/// `macroTierList` preset. Every band + label is an editable layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataTierListDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const ink = Color(0xFF0E0F13);

  // One tier row: coloured band + a square letter label on the left.
  List<CardElement> tier(String letter, Color band, double cy) => [
        shapeEl(
          pos: Offset(0.56, cy),
          size: const Size(0.78, 0.12),
          shape: ShapeKind.rounded,
          fill: band,
          cornerRadius: 10,
        ),
        shapeEl(
          pos: Offset(0.17, cy),
          size: const Size(0.16, 0.12),
          shape: ShapeKind.rounded,
          fill: Color.lerp(band, ink, 0.35)!,
          cornerRadius: 10,
        ),
        textEl(
          pos: Offset(0.17, cy),
          size: const Size(0.16, 0.09),
          literal: letter,
          font: CardFontIx.display,
          fontSize: 54,
          color: Colors.white,
          align: TextAlign.center,
        ),
      ];

  return cardDoc(
    aspect: aspect,
    presetId: 'dataTierList',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF101218), const Color(0xFF050608)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.9, 0.05),
        literal: 'EXERCISE TIER LIST',
        font: CardFontIx.display,
        fontSize: 44,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 1.5,
      ),
      textEl(
        pos: const Offset(0.5, 0.14),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 24,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      ...tier('S', const Color(0xFFEF4444), 0.30),
      ...tier('A', const Color(0xFFF59E0B), 0.44),
      ...tier('B', const Color(0xFF22C55E), 0.58),
      ...tier('C', const Color(0xFF3B82F6), 0.72),
      // The session's exercises land on the S row.
      chipsEl(
        pos: const Offset(0.56, 0.30),
        size: const Size(0.74, 0.1),
        binding: const DataBinding(BindingSource.highlightLabel),
        layout: ChipLayout.wrap,
        maxItems: 5,
        fontSize: 19,
        chipColor: const Color(0x33000000),
        textColor: Colors.white,
      ),
      textEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.045),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 32,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: const Color(0xB3FFFFFF)),
    ],
  );
}
