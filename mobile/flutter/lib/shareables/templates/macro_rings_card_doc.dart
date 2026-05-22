/// Editable-card preset for the **Rings** food template — eyebrow + title,
/// a centered Apple-rings macro chart, and a macro-pills strip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroRingsCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'macroRingsCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.80)!,
      const Color(0xFF0D1117),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.045),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 28,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.86, 0.1),
        binding: const DataBinding(BindingSource.title),
        fontSize: 46,
        align: TextAlign.center,
        maxLines: 2,
      ),
      chartEl(
        pos: const Offset(0.5, 0.47),
        size: const Size(0.74, 0.4),
        style: MacroVizStyle.appleRings,
      ),
      chartEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.82, 0.09),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
