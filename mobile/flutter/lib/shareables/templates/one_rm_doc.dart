/// Editable-card preset for the **1RM Estimate** template — a clean light
/// card: an "1RM Estimate" kicker, the lift name, the estimated 1-rep max in
/// massive type, an Epley + period caption, and a stack of secondary 1RMs.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc oneRmDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF000000);
  const muted = Color(0x8A000000);
  return cardDoc(
    aspect: aspect,
    presetId: 'oneRm',
    accent: accent,
    background: solidBg(const Color(0xFFF8FAFC)),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.84, 0.04),
        literal: '1RM ESTIMATE',
        font: 7,
        fontSize: 28,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.5, 0.36),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.title),
        fontSize: 32,
        color: muted,
        align: TextAlign.center,
        allCaps: true,
        letterSpacing: 1.5,
      ),
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.9, 0.18),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 200,
        color: ink,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 24,
        color: muted,
        align: TextAlign.center,
      ),
      repeaterEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.84, 0.26),
        maxItems: 4,
        fontSize: 28,
        textColor: ink,
        showCalories: false,
      ),
      watermarkEl(pos: const Offset(0.5, 0.95), color: muted),
    ],
  );
}
