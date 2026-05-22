/// Editable-card preset for the **Activity Overview** template — a dark
/// card: eyebrow + title, a large hero count, and a row of stat tiles.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc activityOverviewDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white70 = Color(0xB3FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'activityOverview',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.84)!,
      const Color(0xFF0D1117),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.84, 0.045),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 28,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.19),
        size: const Size(0.86, 0.09),
        binding: const DataBinding(BindingSource.title),
        fontSize: 44,
        align: TextAlign.center,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.9, 0.22),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 210,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Three stat tiles bound to the first highlights.
      for (var i = 0; i < 3; i++) ...[
        shapeEl(
          pos: Offset(0.2 + i * 0.3, 0.72),
          size: const Size(0.26, 0.13),
          fill: const Color(0x14FFFFFF),
          stroke: const Color(0x1FFFFFFF),
          strokeWidth: 1,
          cornerRadius: 18,
        ),
        textEl(
          pos: Offset(0.2 + i * 0.3, 0.69),
          size: const Size(0.24, 0.035),
          binding: DataBinding(BindingSource.highlightLabel, index: i),
          fontSize: 19,
          color: white70,
          align: TextAlign.center,
          letterSpacing: 1.2,
          allCaps: true,
        ),
        textEl(
          pos: Offset(0.2 + i * 0.3, 0.745),
          size: const Size(0.24, 0.05),
          binding: DataBinding(BindingSource.highlightValue, index: i),
          font: 1,
          fontSize: 34,
          align: TextAlign.center,
        ),
      ],
      watermarkEl(pos: const Offset(0.30, 0.93), color: white70),
    ],
  );
}
