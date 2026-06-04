/// Editable-card preset for the **iOS Activity Rings** template — the Apple
/// Fitness "Activity" share card rendered with the new [ringTrioEl] primitive:
/// the three concentric Move/Exercise/Stand rings centered on a near-black
/// canvas, the day label, and a colour-coded legend trio (●/●/● + value +
/// metric). Distinct from the legacy Activity Rings (which used the MacroViz
/// appleRings chart): this uses the standalone ringTrio + a colored legend.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosActivityRingsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white60 = Color(0x99FFFFFF);
  // Apple's canonical ring hues.
  const moveRed = Color(0xFFFA114F);
  const exerciseGreen = Color(0xFF92E82A);
  const standBlue = Color(0xFF1AD6FD);

  return cardDoc(
    aspect: aspect,
    presetId: 'iosActivityRings',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF000000), Color(0xFF0A0E16)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(0.84, 0.04),
        literal: 'ACTIVITY',
        font: CardFontIx.cond,
        fontSize: 28,
        color: white,
        align: TextAlign.center,
        letterSpacing: 5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.grotesk,
        fontSize: 24,
        color: white60,
        align: TextAlign.center,
      ),
      // The three Apple rings.
      ringTrioEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.66, 0.4),
        outer: 0.86,
        middle: 0.72,
        inner: 0.6,
        outerColor: moveRed,
        middleColor: exerciseGreen,
        innerColor: standBlue,
        strokeFraction: 0.1,
      ),
      // ── Legend trio ──
      // Move.
      iconEl(
        pos: const Offset(0.16, 0.72),
        size: const Size(0.05, 0.03),
        emoji: '●',
        color: moveRed,
      ),
      textEl(
        pos: const Offset(0.42, 0.7),
        size: const Size(0.4, 0.035),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: CardFontIx.display,
        fontSize: 30,
        color: white,
      ),
      textEl(
        pos: const Offset(0.42, 0.735),
        size: const Size(0.4, 0.022),
        binding: const DataBinding(BindingSource.highlightLabel, index: 0),
        font: 0,
        fontSize: 15,
        color: white60,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      // Exercise.
      iconEl(
        pos: const Offset(0.16, 0.8),
        size: const Size(0.05, 0.03),
        emoji: '●',
        color: exerciseGreen,
      ),
      textEl(
        pos: const Offset(0.42, 0.78),
        size: const Size(0.4, 0.035),
        binding: const DataBinding(BindingSource.highlightValue, index: 1),
        font: CardFontIx.display,
        fontSize: 30,
        color: white,
      ),
      textEl(
        pos: const Offset(0.42, 0.815),
        size: const Size(0.4, 0.022),
        binding: const DataBinding(BindingSource.highlightLabel, index: 1),
        font: 0,
        fontSize: 15,
        color: white60,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      // Stand.
      iconEl(
        pos: const Offset(0.16, 0.88),
        size: const Size(0.05, 0.03),
        emoji: '●',
        color: standBlue,
      ),
      textEl(
        pos: const Offset(0.42, 0.86),
        size: const Size(0.4, 0.035),
        binding: const DataBinding(BindingSource.highlightValue, index: 2),
        font: CardFontIx.display,
        fontSize: 30,
        color: white,
      ),
      textEl(
        pos: const Offset(0.42, 0.895),
        size: const Size(0.4, 0.022),
        binding: const DataBinding(BindingSource.highlightLabel, index: 2),
        font: 0,
        fontSize: 15,
        color: white60,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.66, 0.95), color: white60),
    ],
  );
}
