/// Editable-card preset for the **Meal Timeline** food template — a vertical
/// rule down the left with dot nodes; each node is a time chip + one-word
/// label, with a calorie total badge pinned at the bottom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealTimelineDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const node = ['07:30', '12:15', '15:40', '19:00', '21:10'];
  const label = ['Wake', 'Lunch', 'Snack', 'Dinner', 'Late'];
  return cardDoc(
    aspect: aspect,
    presetId: 'mealTimeline',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF101218), accent, 0.1)!,
      const Color(0xFF07080B),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.09),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 40,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.15),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 5,
        fontSize: 20,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      // The vertical timeline rule on the left.
      shapeEl(
        pos: const Offset(0.18, 0.52),
        size: const Size(0.008, 0.62),
        shape: ShapeKind.rounded,
        fill: const Color(0x33FFFFFF),
        cornerRadius: 4,
      ),
      // 5 dot nodes + time chips + one-word labels.
      for (var i = 0; i < 5; i++) ...[
        shapeEl(
          pos: Offset(0.18, 0.27 + i * 0.125),
          size: const Size(0.05, 0.028),
          shape: ShapeKind.circle,
          fill: accent,
          stroke: Colors.white,
          strokeWidth: 3,
        ),
        textEl(
          pos: Offset(0.4, 0.255 + i * 0.125),
          size: const Size(0.4, 0.035),
          literal: node[i],
          font: 4,
          fontSize: 24,
          color: Colors.white70,
          align: TextAlign.left,
        ),
        textEl(
          pos: Offset(0.45, 0.295 + i * 0.125),
          size: const Size(0.5, 0.045),
          literal: label[i],
          font: 1,
          fontSize: 34,
          color: Colors.white,
          align: TextAlign.left,
        ),
      ],
      // Calorie total badge bottom.
      badgeEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(0.32, 0.18),
        gradient: [accent, Color.lerp(accent, Colors.black, 0.45)!],
        label: 'KCAL TODAY',
        valueBinding: const DataBinding(BindingSource.calories),
      ),
      watermarkEl(pos: const Offset(0.06, 0.97), color: Colors.white54),
    ],
  );
}
