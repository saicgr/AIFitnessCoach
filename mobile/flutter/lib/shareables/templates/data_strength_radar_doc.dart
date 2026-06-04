/// Editable-card preset for the **Strength Radar (Data)** template — a true
/// spider/radar chart of your muscle balance: a "STRENGTH BALANCE" kicker, the
/// title, a six-axis radar (`ChartKind.radar`, bound to `musclesWorked`), and a
/// muscle-name chip rail. Distinct from the legacy plate-based `strengthRadar`
/// preset — this one renders the real radar painter. Every label editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataStrengthRadarDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataStrengthRadar',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF0F1620), const Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      iconEl(
        pos: const Offset(0.13, 0.085),
        size: const Size(0.05, 0.03),
        emoji: '🎯',
        color: volt,
      ),
      textEl(
        pos: const Offset(0.45, 0.085),
        size: const Size(0.56, 0.03),
        literal: 'STRENGTH BALANCE',
        font: CardFontIx.cond,
        fontSize: 26,
        color: volt,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.82, 0.085),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 22,
        color: muted,
        align: TextAlign.right,
        allCaps: true,
        letterSpacing: 1.6,
      ),
      textEl(
        pos: const Offset(0.5, 0.165),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 50,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // The real radar — axes from musclesWorked.
      chartEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.78, 0.52),
        kind: ChartKind.radar,
      ),
      // Muscle chip rail — which muscles the radar spans.
      chipsEl(
        pos: const Offset(0.5, 0.85),
        size: const Size(0.86, 0.08),
        binding: const DataBinding(BindingSource.highlightLabel),
        layout: ChipLayout.wrap,
        maxItems: 6,
        fontSize: 18,
        chipColor: const Color(0x18B8FF2F),
        textColor: Colors.white,
      ),
      // Hero balance score.
      textEl(
        pos: const Offset(0.5, 0.92),
        size: const Size(0.86, 0.035),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 26,
        color: volt,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: const Color(0xFFFFFFFF)),
    ],
  );
}
