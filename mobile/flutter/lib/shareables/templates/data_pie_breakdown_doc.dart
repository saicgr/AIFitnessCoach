/// Editable-card preset for the **Pie / Macro Breakdown** data template — your
/// macros as a clean calorie-split pie: a "MACRO SPLIT" kicker, the meal label,
/// a macro pie (`MacroViz.macroPie`, bound to the meal's real macros), a P/C/F
/// legend chip rail, and the calorie hero. Every label is an editable layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataPieBreakdownDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataPieBreakdown',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF101015), const Color(0xFF06070A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.86, 0.03),
        literal: 'MACRO SPLIT',
        font: CardFontIx.cond,
        fontSize: 26,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 5,
      ),
      textEl(
        pos: const Offset(0.5, 0.145),
        size: const Size(0.86, 0.045),
        binding: const DataBinding(BindingSource.mealLabel),
        font: CardFontIx.display,
        fontSize: 42,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // The real macro pie (calorie-share wedges).
      chartEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.72, 0.42),
        style: MacroVizStyle.macroPie,
      ),
      // P/C/F legend rail.
      chipsEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.86, 0.07),
        binding: const DataBinding(BindingSource.foodItemName),
        layout: ChipLayout.wrap,
        maxItems: 5,
        fontSize: 18,
        chipColor: const Color(0x14FFFFFF),
        textColor: Colors.white,
      ),
      // Calorie hero.
      textEl(
        pos: const Offset(0.5, 0.85),
        size: const Size(0.86, 0.06),
        binding: const DataBinding(BindingSource.calories),
        font: CardFontIx.display,
        fontSize: 56,
        color: volt,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.905),
        size: const Size(0.86, 0.025),
        literal: 'TOTAL CALORIES',
        font: CardFontIx.mono,
        fontSize: 15,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: const Color(0xFFFFFFFF)),
    ],
  );
}
