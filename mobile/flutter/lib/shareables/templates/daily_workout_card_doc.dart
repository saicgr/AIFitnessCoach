/// Editable-card preset for the **Daily Workout Card** template — a white
/// card on a tinted canvas: watermark + @handle, workout title, period,
/// stat chips, an exercise list, and a share-link footer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dailyWorkoutCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF111111);
  return cardDoc(
    aspect: aspect,
    presetId: 'dailyWorkoutCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.78)!,
      const Color(0xFF0D1117),
    ]),
    elements: [
      // White card surface.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.9, 0.86),
        fill: const Color(0xFFFAFAFA),
        cornerRadius: 20,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.78, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 56,
        color: ink,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.22),
        size: const Size(0.78, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 24,
        color: const Color(0xFF7A7A7A),
      ),
      textEl(
        pos: const Offset(0.5, 0.28),
        size: const Size(0.78, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 7,
        fontSize: 30,
        color: ink,
      ),
      repeaterEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.78, 0.5),
        maxItems: 10,
        fontSize: 26,
        textColor: ink,
        showCalories: false,
      ),
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.78, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        fontSize: 20,
        align: TextAlign.right,
        color: const Color(0xFF999999),
      ),
      watermarkEl(pos: const Offset(0.2, 0.12), color: const Color(0xFF111111)),
    ],
  );
}
