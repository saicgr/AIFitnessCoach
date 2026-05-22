/// Editable-card preset for the **Exercise Showcase** template — a full-bleed
/// hero exercise illustration under a dark scrim, an "Exercise of the Day"
/// kicker pill, the exercise name in massive type, and a sets/reps/weight
/// stat strip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc exerciseShowcaseDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'exerciseShowcase',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
      fit: BoxFit.cover,
    ),
    elements: [
      // Top + bottom darkening scrim for legibility.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x66000000), Color(0x00000000), Color(0xD9000000)],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Accent border frame.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.92, 0.95),
        fill: const Color(0x00000000),
        stroke: accent,
        strokeWidth: 3,
        cornerRadius: 12,
      ),
      // Kicker pill.
      shapeEl(
        pos: const Offset(0.3, 0.1),
        size: const Size(0.46, 0.04),
        shape: ShapeKind.pill,
        fill: accent,
        cornerRadius: 20,
      ),
      textEl(
        pos: const Offset(0.3, 0.1),
        size: const Size(0.46, 0.035),
        literal: 'EXERCISE OF THE DAY',
        font: 7,
        fontSize: 22,
        color: const Color(0xFF000000),
        align: TextAlign.center,
        letterSpacing: 2.4,
      ),
      // Exercise name.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.84, 0.22),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 120,
        color: const Color(0xFFFFFFFF),
        allCaps: true,
        maxLines: 3,
        lineHeight: 0.95,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0xB3000000), blur: 14),
      ),
      // Stat strip backing.
      shapeEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.84, 0.09),
        fill: const Color(0x8C000000),
        stroke: accent,
        strokeWidth: 1.4,
        cornerRadius: 14,
      ),
      chartEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.78, 0.07),
        style: MacroVizStyle.numbers,
      ),
      watermarkEl(pos: const Offset(0.2, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
