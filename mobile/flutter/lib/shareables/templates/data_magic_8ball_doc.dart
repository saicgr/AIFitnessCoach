/// Editable-card preset for the **Magic 8-Ball** data/meme template — ask the
/// ball about your next PR: a radial-shaded black sphere with a blue triangular
/// answer window reading "PR SOON", under an "OUTLOOK: UNSTOPPABLE" verdict and
/// the real streak/volume line. Every label is editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataMagic8ballDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataMagic8ball',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF222222), const Color(0xFF000000)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Question eyebrow.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.86, 0.03),
        literal: 'WILL I HIT A PR THIS WEEK?',
        font: CardFontIx.cond,
        fontSize: 24,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2.5,
      ),
      // The black sphere.
      shapeEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.6, 0.34),
        shape: ShapeKind.circle,
        gradient: const [Color(0xFF3A3A3A), Color(0xFF050505)],
        radial: true,
      ),
      // Inner blue answer disc.
      shapeEl(
        pos: const Offset(0.5, 0.47),
        size: const Size(0.28, 0.16),
        shape: ShapeKind.circle,
        fill: const Color(0xFF0A1A3A),
        stroke: const Color(0x33FFFFFF),
        strokeWidth: 1.2,
      ),
      // The answer.
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.24, 0.1),
        literal: 'PR\nSOON',
        font: CardFontIx.display,
        fontSize: 30,
        color: volt,
        align: TextAlign.center,
        lineHeight: 1.0,
      ),
      // Verdict.
      textEl(
        pos: const Offset(0.5, 0.72),
        size: const Size(0.86, 0.04),
        literal: 'OUTLOOK: UNSTOPPABLE',
        font: CardFontIx.cond,
        fontSize: 30,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      // The real evidence — hero string.
      textEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: volt,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.835),
        size: const Size(0.86, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 15,
        color: const Color(0x80FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
