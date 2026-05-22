/// Editable-card preset for the **Widget** template — an iOS-widget aesthetic:
/// a centered rounded-rect card on a charcoal canvas, with a period header, an
/// app glyph chip, the title, the hero number and a watermark footer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc widgetDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'widget',
    accent: accent,
    background: solidBg(const Color(0xFF0D0F14)),
    elements: [
      // Widget card surface.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.66, 0.42),
        gradient: [
          const Color(0xFF1A1F2C),
          Color.lerp(accent, const Color(0xFF1A1F2C), 0.7)!,
        ],
        stroke: const Color(0x1AFFFFFF),
        strokeWidth: 1,
        cornerRadius: 36,
      ),
      textEl(
        pos: const Offset(0.4, 0.36),
        size: const Size(0.4, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 20,
        color: accent,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      // App glyph chip.
      shapeEl(
        pos: const Offset(0.74, 0.36),
        size: const Size(0.05, 0.028),
        fill: Color.lerp(accent, Colors.black, 0.2)!.withValues(alpha: 0.3),
        cornerRadius: 6,
      ),
      iconEl(
        pos: const Offset(0.74, 0.36),
        size: const Size(0.05, 0.028),
        emoji: '🏋️',
      ),
      textEl(
        pos: const Offset(0.4, 0.4),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 30,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.56, 0.1),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 96,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      watermarkEl(pos: const Offset(0.4, 0.64), color: Colors.white),
      textEl(
        pos: const Offset(0.72, 0.64),
        size: const Size(0.12, 0.025),
        literal: 'NOW',
        font: 0,
        fontSize: 18,
        color: Colors.white54,
        align: TextAlign.right,
        letterSpacing: 1.4,
      ),
    ],
  );
}
