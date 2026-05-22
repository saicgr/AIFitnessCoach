/// Editable-card preset for the **Instagram Story** template — a
/// Story-native card: pink→orange→yellow gradient, a handle pill, a centered
/// emoji + giant hero number + unit, and a brand wordmark.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc instagramStoryDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'instagramStory',
    accent: accent,
    background: gradientBg(
      const [Color(0xFFEC4899), Color(0xFFF97316), Color(0xFFEAB308)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Handle pill.
      shapeEl(
        pos: const Offset(0.24, 0.07),
        size: const Size(0.34, 0.045),
        shape: ShapeKind.pill,
        fill: const Color(0x66000000),
        cornerRadius: 999,
      ),
      textEl(
        pos: const Offset(0.24, 0.07),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 0,
        fontSize: 22,
        align: TextAlign.center,
      ),
      // Centered emoji.
      iconEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.24, 0.13),
        emoji: '💪',
      ),
      // Giant hero number.
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.92, 0.2),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 200,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Unit.
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 30,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      // First highlight caption.
      textEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 0,
        fontSize: 24,
        color: Colors.white70,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      // Brand wordmark.
      textEl(
        pos: const Offset(0.22, 0.94),
        size: const Size(0.4, 0.04),
        literal: 'zealova',
        font: 0,
        fontSize: 26,
        color: Colors.white70,
      ),
      watermarkEl(pos: const Offset(0.7, 0.94), color: Colors.white70),
    ],
  );
}
