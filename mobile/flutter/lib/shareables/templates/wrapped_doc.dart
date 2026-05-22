/// Editable-card preset for the **Wrapped** template — a Spotify-Wrapped
/// styled card: accent gradient canvas, decorative diagonal slashes, a giant
/// WRAPPED masthead, a numbered highlight list, and a low-anchored hero number.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc wrappedDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'wrapped',
    accent: accent,
    background: gradientBg(
      [
        accent,
        Color.lerp(accent, Colors.black, 0.45)!,
        const Color(0xFF05050A),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Decorative slash bands (the Wrapped signature).
      shapeEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(1.3, 0.02),
        fill: const Color(0x24FFFFFF),
      ),
      shapeEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(1.3, 0.013),
        fill: const Color(0x38000000),
      ),
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 0,
        fontSize: 26,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.18),
        size: const Size(0.92, 0.1),
        literal: 'WRAPPED',
        font: 1,
        fontSize: 150,
        align: TextAlign.center,
        letterSpacing: -2.5,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.25),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 32,
        align: TextAlign.center,
        letterSpacing: 2.6,
        allCaps: true,
      ),
      // Numbered highlight list panel.
      shapeEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.84, 0.26),
        fill: const Color(0x5C000000),
        stroke: const Color(0x2EFFFFFF),
        strokeWidth: 1,
        cornerRadius: 18,
      ),
      for (var i = 0; i < 4; i++) ...[
        textEl(
          pos: Offset(0.21, 0.36 + i * 0.06),
          size: const Size(0.1, 0.04),
          literal: (i + 1).toString().padLeft(2, '0'),
          font: 1,
          fontSize: 26,
          color: Colors.white54,
        ),
        textEl(
          pos: Offset(0.46, 0.36 + i * 0.06),
          size: const Size(0.36, 0.04),
          binding: DataBinding(BindingSource.highlightLabel, index: i),
          font: 0,
          fontSize: 22,
          color: Colors.white70,
          letterSpacing: 1.4,
          allCaps: true,
          maxLines: 1,
        ),
        textEl(
          pos: Offset(0.78, 0.36 + i * 0.06),
          size: const Size(0.22, 0.04),
          binding: DataBinding(BindingSource.highlightValue, index: i),
          font: 1,
          fontSize: 30,
          align: TextAlign.right,
        ),
      ],
      textEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.84, 0.03),
        literal: 'YOUR NUMBER',
        font: 1,
        fontSize: 22,
        color: Colors.white70,
        align: TextAlign.center,
        letterSpacing: 3.6,
      ),
      textEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.92, 0.16),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 170,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 1,
        fontSize: 28,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.62, 0.94), color: Colors.white),
    ],
  );
}
