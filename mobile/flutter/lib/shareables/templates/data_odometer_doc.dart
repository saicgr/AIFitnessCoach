/// Editable-card preset for the **Odometer** data/meme template — your lifetime
/// volume on a mechanical odometer: "LIFETIME VOLUME" eyebrow, a row of boxed
/// monospace digits (bound to lifetime volume), and a "KG · AND CLIMBING" volt
/// foot line. The digit row + every label is an editable layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataOdometerDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataOdometer',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF14161C), const Color(0xFF070709)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.86, 0.03),
        literal: 'LIFETIME VOLUME',
        font: CardFontIx.cond,
        fontSize: 22,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Odometer housing.
      shapeEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.88, 0.12),
        shape: ShapeKind.rounded,
        fill: const Color(0xFF000000),
        stroke: const Color(0xFF333333),
        strokeWidth: 1.4,
        cornerRadius: 10,
      ),
      // The rolling digits — bound to lifetime volume (kg). Monospace renders
      // the figure with the boxed-digit feel; the real value substitutes live.
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.84, 0.08),
        binding: const DataBinding(BindingSource.lifetimeVolume),
        font: CardFontIx.mono,
        fontSize: 56,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 6,
        maxLines: 1,
      ),
      // Climbing foot line.
      textEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.86, 0.03),
        literal: 'KG · AND CLIMBING',
        font: CardFontIx.cond,
        fontSize: 22,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Context — title + period.
      textEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 34,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.725),
        size: const Size(0.86, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 15,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.92), color: const Color(0xFFFFFFFF)),
    ],
  );
}
