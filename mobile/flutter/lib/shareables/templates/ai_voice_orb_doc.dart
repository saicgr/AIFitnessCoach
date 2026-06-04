/// Editable-card preset for the **Voice Orb** template — a Siri-style glowing
/// conic orb on a black field, a serif voice-command quote, and a "✦ DONE"
/// confirmation eyebrow that binds to the live hero string. Evokes a hands-free
/// "Hey Zealova, log my push day" interaction.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiVoiceOrbDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cyan = Color(0xFF22D3EE);
  const magenta = Color(0xFFF0429A);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiVoiceOrb',
    accent: accent,
    background: solidBg(const Color(0xFF000000)),
    elements: [
      // Glow halo behind the orb.
      shapeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.5, 0.28),
        shape: ShapeKind.circle,
        gradient: [accent.withValues(alpha: 0.28), const Color(0x00000000)],
        radial: true,
      ),
      // The conic voice orb (layered discs approximate the conic gradient).
      shapeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.3, 0.17),
        shape: ShapeKind.circle,
        gradient: const [cyan, magenta],
      ),
      shapeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.18, 0.1),
        shape: ShapeKind.circle,
        fill: const Color(0xFF000000),
      ),
      shapeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.13, 0.073),
        shape: ShapeKind.circle,
        gradient: [accent, cyan],
      ),
      // The voice command — serif.
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.82, 0.14),
        literal: '"Hey Zealova,\nlog my push day."',
        font: CardFontIx.serif,
        fontSize: 40,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.2,
      ),
      // Confirmation eyebrow — binds to hero string.
      textEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.82, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 20,
        color: muted,
        letterSpacing: 2.4,
        align: TextAlign.center,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
