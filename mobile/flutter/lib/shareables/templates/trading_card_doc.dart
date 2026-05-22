/// Editable-card preset for the **Trading Card** template — a Pokémon-card
/// style framed panel: avatar + name header, a bordered hero-stat window, and
/// three highlights rendered as "moves".
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc tradingCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'tradingCard',
    accent: accent,
    background: solidBg(const Color(0xFF15171C)),
    elements: [
      // Foil card body.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.7),
        gradient: [
          accent,
          Color.lerp(accent, Colors.black, 0.3)!,
          Color.lerp(accent, Colors.black, 0.6)!,
        ],
        stroke: const Color(0x66FFFFFF),
        strokeWidth: 3,
        cornerRadius: 24,
      ),
      textEl(
        pos: const Offset(0.46, 0.21),
        size: const Size(0.5, 0.04),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 1,
        fontSize: 34,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.46, 0.25),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 20,
        color: Colors.white70,
        letterSpacing: 1.6,
        allCaps: true,
      ),
      // Bordered hero-stat window.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.72, 0.14),
        fill: const Color(0x47000000),
        stroke: const Color(0x4DFFFFFF),
        strokeWidth: 1.5,
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.66, 0.1),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 88,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      for (var i = 0; i < 3; i++) ...[
        textEl(
          pos: Offset(0.36, 0.56 + i * 0.07),
          size: const Size(0.42, 0.04),
          binding: DataBinding(BindingSource.highlightLabel, index: i),
          font: 0,
          fontSize: 24,
          maxLines: 1,
        ),
        textEl(
          pos: Offset(0.64, 0.56 + i * 0.07),
          size: const Size(0.24, 0.04),
          binding: DataBinding(BindingSource.highlightValue, index: i),
          font: 1,
          fontSize: 26,
          align: TextAlign.right,
        ),
      ],
      watermarkEl(pos: const Offset(0.6, 0.81), color: Colors.white),
    ],
  );
}
