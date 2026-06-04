/// Editable-card preset for the **Recovery Ring** data template — a WHOOP-style
/// readiness card: a big radial recovery ring (`ringStatEl`, center bound to
/// `recoveryPct`), a strain progress bar underneath, and the title / period
/// frame. Every label is an editable layer; the ring tracks real recovery.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataRecoveryRingDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const teal = Color(0xFF16E0A6);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataRecoveryRing',
    accent: volt,
    background: solidBg(const Color(0xFF0A0A0A)),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.10),
        size: const Size(0.86, 0.03),
        literal: 'READINESS',
        font: CardFontIx.cond,
        fontSize: 26,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 5,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.86, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 42,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Big recovery ring — center value bound to recoveryPct.
      ringStatEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.62, 0.34),
        progress: 0.84,
        valueBinding: const DataBinding(BindingSource.recoveryPct),
        maxValue: 100,
        centerBinding: const DataBinding(BindingSource.recoveryPct),
        centerValue: '84%',
        label: 'RECOVERY',
        ringColor: teal,
        trackColor: const Color(0x1AFFFFFF),
        centerFontSize: 80,
        labelFontSize: 20,
        font: CardFontIx.display,
      ),
      // Strain bar label.
      textEl(
        pos: const Offset(0.2, 0.68),
        size: const Size(0.3, 0.025),
        literal: 'STRAIN',
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        align: TextAlign.left,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.8, 0.68),
        size: const Size(0.3, 0.025),
        literal: '14.2',
        font: CardFontIx.display,
        fontSize: 22,
        color: Colors.white,
        align: TextAlign.right,
      ),
      // Strain track + fill.
      shapeEl(
        pos: const Offset(0.5, 0.72),
        size: const Size(0.78, 0.008),
        shape: ShapeKind.pill,
        fill: const Color(0x1FFFFFFF),
      ),
      shapeEl(
        pos: const Offset(0.39, 0.72),
        size: const Size(0.55, 0.008),
        shape: ShapeKind.pill,
        fill: const Color(0xFF3B82F6),
      ),
      // Context foot.
      textEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.86, 0.035),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 26,
        color: volt,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.865),
        size: const Size(0.86, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 15,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
