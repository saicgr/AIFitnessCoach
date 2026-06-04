/// Editable-card preset — **Showed Up**: the consistency calendar. A big
/// "127 days. Showed up." headline over a contribution-style heatmap grid (the
/// volt fill = a day trained, dim cells = rest), with a quiet "RAIN OR SHINE"
/// footer. The streak count binds to live data so an unedited card tracks the
/// real number.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulShowedUpDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const muted = Color(0x99FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulShowedUp',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0F1620), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Streak count — big, bound to live data.
      textEl(
        pos: const Offset(0.36, 0.12),
        size: const Size(0.42, 0.07),
        binding: const DataBinding(BindingSource.currentStreak),
        font: CardFontIx.display,
        fontSize: 60,
        color: accent,
        align: TextAlign.right,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.7, 0.12),
        size: const Size(0.3, 0.06),
        literal: 'days.',
        font: CardFontIx.display,
        fontSize: 48,
        color: const Color(0xFFFFFFFF),
        align: TextAlign.left,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.205),
        size: const Size(0.86, 0.05),
        literal: 'Showed up.',
        font: CardFontIx.display,
        fontSize: 44,
        color: const Color(0xFFFFFFFF),
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Contribution heatmap — empty cells → built-in demo ramp.
      gridHeatmapEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.86, 0.46),
        columns: 10,
        cellColor: accent,
        emptyColor: const Color(0x14FFFFFF),
        cellRadius: 4,
        gapFraction: 0.22,
      ),
      // Footer.
      textEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.03),
        literal: 'RAIN OR SHINE · 96% CONSISTENCY',
        font: CardFontIx.cond,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: muted),
    ],
  );
}
