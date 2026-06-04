/// Editable-card preset for the **Weather Widget** template — the iOS Weather
/// app aesthetic applied to a workout day: a sky gradient (clear-day blue),
/// a location line (workout title), a giant "temperature" hero number with a
/// degree suffix, a condition line (hero/period), and an hourly-forecast strip
/// of frosted pills bound to the highlights. Volt accent on the condition glyph.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosWeatherWidgetDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  final glass = const Color(0xFFFFFFFF).withValues(alpha: 0.14);
  final glassStroke = const Color(0xFFFFFFFF).withValues(alpha: 0.22);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosWeatherWidget',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF2E6FD6), Color(0xFF4FA3E3), Color(0xFF8FD0F0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.5, 1.0],
    ),
    elements: [
      // Sun bloom.
      shapeEl(
        pos: const Offset(0.78, 0.18),
        size: const Size(0.5, 0.32),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        gradient: const [Color(0x66FFE39A), Color(0x00FFE39A)],
        radial: true,
      ),
      // Location (title).
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.86, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.grotesk,
        fontSize: 38,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Condition glyph (volt-tinted).
      iconEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.18, 0.1),
        emoji: '🔥',
        color: accent,
      ),
      // Giant "temperature" hero with degree.
      textEl(
        pos: const Offset(0.52, 0.42),
        size: const Size(0.8, 0.2),
        binding: const DataBinding(BindingSource.heroString),
        font: 2,
        fontSize: 200,
        color: white,
        align: TextAlign.center,
        letterSpacing: -6,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.86, 0.36),
        size: const Size(0.12, 0.06),
        literal: '°',
        font: 2,
        fontSize: 90,
        color: white70,
        align: TextAlign.left,
      ),
      // Condition line (period label).
      textEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.condMid,
        fontSize: 28,
        color: white,
        align: TextAlign.center,
        letterSpacing: 1,
      ),
      // Hourly-forecast frosted strip.
      shapeEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.9, 0.2),
        shape: ShapeKind.rounded,
        fill: glass,
        stroke: glassStroke,
        strokeWidth: 1.4,
        cornerRadius: 28,
      ),
      chipsEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.82, 0.14),
        binding: const DataBinding(BindingSource.highlightValue),
        layout: ChipLayout.row,
        maxItems: 4,
        chipColor: const Color(0x00000000),
        textColor: white,
        fontSize: 26,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: white70),
    ],
  );
}
