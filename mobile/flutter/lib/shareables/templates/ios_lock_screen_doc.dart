/// Editable-card preset for the **iOS Lock Screen** template — a full-bleed
/// wallpaper behind the signature iOS lock-screen stack: a thin date line, a
/// huge ultralight clock, and a row of three frosted "Lock Screen widgets"
/// (rectangular workout widget + two circular ring widgets) pinned beneath the
/// clock. Distinct from PhotoLockscreen: this is the multi-widget tray layout,
/// driven by real stats highlights rather than a single summary card.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosLockScreenDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  const glass = Color(0x40000000);
  const glassStroke = Color(0x33FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosLockScreen',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.customPhotoPath),
      blurred: false,
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x59000000), Color(0x00000000), Color(0x66000000)],
        stops: const [0.0, 0.4, 1.0],
      ),
      // Date.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.grotesk,
        fontSize: 30,
        color: white,
        align: TextAlign.center,
        letterSpacing: 0.4,
      ),
      // Big ultralight clock.
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.92, 0.16),
        literal: '9:41',
        font: 2,
        fontSize: 300,
        color: white,
        align: TextAlign.center,
        letterSpacing: -10,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // ── Lock-screen widget tray (one wide rect + two circular) ──
      // Wide workout widget.
      shapeEl(
        pos: const Offset(0.3, 0.42),
        size: const Size(0.44, 0.11),
        shape: ShapeKind.rounded,
        fill: glass,
        stroke: glassStroke,
        strokeWidth: 1.4,
        cornerRadius: 24,
      ),
      iconEl(
        pos: const Offset(0.17, 0.42),
        size: const Size(0.06, 0.04),
        emoji: '🏋️',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.36, 0.4),
        size: const Size(0.26, 0.025),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 19,
        color: white,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.36, 0.435),
        size: const Size(0.26, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 26,
        color: accent,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Circular widget 1.
      ringStatEl(
        pos: const Offset(0.64, 0.42),
        size: const Size(0.13, 0.13),
        progress: 0.78,
        centerBinding: const DataBinding(BindingSource.highlightValue, index: 0),
        centerValue: '78%',
        label: '',
        ringColor: accent,
        centerFontSize: 30,
      ),
      textEl(
        pos: const Offset(0.64, 0.495),
        size: const Size(0.16, 0.02),
        binding: const DataBinding(BindingSource.highlightLabel, index: 0),
        font: 0,
        fontSize: 13,
        color: white70,
        align: TextAlign.center,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      // Circular widget 2.
      ringStatEl(
        pos: const Offset(0.84, 0.42),
        size: const Size(0.13, 0.13),
        progress: 0.55,
        centerBinding: const DataBinding(BindingSource.highlightValue, index: 1),
        centerValue: '55%',
        label: '',
        ringColor: const Color(0xFF1AD6FD),
        centerFontSize: 30,
      ),
      textEl(
        pos: const Offset(0.84, 0.495),
        size: const Size(0.16, 0.02),
        binding: const DataBinding(BindingSource.highlightLabel, index: 1),
        font: 0,
        fontSize: 13,
        color: white70,
        align: TextAlign.center,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      // Unlock hint.
      textEl(
        pos: const Offset(0.5, 0.93),
        size: const Size(0.7, 0.03),
        literal: 'swipe up to open Zealova',
        font: CardFontIx.grotesk,
        fontSize: 18,
        color: white70,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.97), color: white70),
    ],
  );
}
