/// Editable-card preset for the **Minimal** template — a typographic hero
/// stat: eyebrow + title + a large centered hero number.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc minimalDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'minimal',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.82)!,
      const Color(0xFF0D1117),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 30,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.2),
        size: const Size(0.84, 0.12),
        binding: const DataBinding(BindingSource.title),
        fontSize: 52,
        align: TextAlign.center,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.9, 0.28),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 240,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
