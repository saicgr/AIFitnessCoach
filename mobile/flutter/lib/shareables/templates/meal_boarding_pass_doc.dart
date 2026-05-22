/// Editable-card preset for the **Meal Boarding Pass** food template — the
/// meal styled as an airline boarding pass: a light ticket panel, the meal
/// name as the destination, the time/date as the departure, a perforated
/// tear line, a macro stub, and a faux barcode.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealBoardingPassDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ticket = Color(0xFFF4F1E8);
  const ink = Color(0xFF15171C);
  final faint = ink.withValues(alpha: 0.55);
  return cardDoc(
    aspect: aspect,
    presetId: 'mealBoardingPass',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0B0D11), accent, 0.18)!,
      const Color(0xFF050608),
    ]),
    elements: [
      // Ticket panel.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.84, 0.6),
        shape: ShapeKind.rounded,
        fill: ticket,
        cornerRadius: 20,
      ),
      // Accent header band.
      shapeEl(
        pos: const Offset(0.5, 0.255),
        size: const Size(0.84, 0.11),
        shape: ShapeKind.rounded,
        gradient: [accent, Color.lerp(accent, ink, 0.4)!],
        cornerRadius: 20,
      ),
      textEl(
        pos: const Offset(0.5, 0.255),
        size: const Size(0.78, 0.06),
        literal: 'MEAL BOARDING PASS',
        font: 5,
        fontSize: 26,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Destination label + meal name.
      textEl(
        pos: const Offset(0.18, 0.35),
        size: const Size(0.3, 0.03),
        literal: 'DESTINATION',
        font: 4,
        fontSize: 15,
        color: faint,
        align: TextAlign.left,
        letterSpacing: 1.5,
      ),
      textEl(
        pos: const Offset(0.5, 0.41),
        size: const Size(0.74, 0.075),
        binding: const DataBinding(BindingSource.title),
        font: 0,
        fontSize: 40,
        color: ink,
        align: TextAlign.left,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Departure label + time.
      textEl(
        pos: const Offset(0.18, 0.48),
        size: const Size(0.3, 0.03),
        literal: 'DEPARTURE',
        font: 4,
        fontSize: 15,
        color: faint,
        align: TextAlign.left,
        letterSpacing: 1.5,
      ),
      textEl(
        pos: const Offset(0.31, 0.52),
        size: const Size(0.56, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 4,
        fontSize: 22,
        color: ink,
        align: TextAlign.left,
      ),
      // Perforated tear line.
      dividerEl(
        pos: const Offset(0.5, 0.585),
        size: const Size(0.84, 0.01),
        style: DividerStyle.perforated,
        color: faint,
        thickness: 3,
      ),
      // Macro stub.
      textEl(
        pos: const Offset(0.18, 0.63),
        size: const Size(0.3, 0.03),
        literal: 'NUTRITION',
        font: 4,
        fontSize: 15,
        color: faint,
        align: TextAlign.left,
        letterSpacing: 1.5,
      ),
      chartEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.74, 0.08),
        style: MacroVizStyle.numbers,
      ),
      // Faux barcode.
      shapeEl(
        pos: const Offset(0.5, 0.755),
        size: const Size(0.6, 0.035),
        shape: ShapeKind.rect,
        fill: ink,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.755),
        size: const Size(0.54, 0.035),
        shape: ShapeKind.rect,
        fill: ticket,
      ),
      watermarkEl(pos: const Offset(0.3, 0.84), color: Colors.white70),
    ],
  );
}
