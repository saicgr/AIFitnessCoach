/// Editable-card preset for the **Quote** template — moody dark canvas, a
/// large serif italic quote, accent kicker rule + period label above, an
/// attribution line + accent rule below.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc quoteDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'quote',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF06070A), Color(0xFF0F1118)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      shapeEl(
        pos: const Offset(0.13, 0.1),
        size: const Size(0.1, 0.004),
        shape: ShapeKind.rect,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.18, 0.13),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 22,
        color: accent,
        letterSpacing: 3,
        allCaps: true,
      ),
      iconEl(
        pos: const Offset(0.14, 0.42),
        size: const Size(0.14, 0.07),
        emoji: '❝',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.84, 0.3),
        binding: const DataBinding(BindingSource.caption),
        font: 6,
        fontSize: 64,
        lineHeight: 1.2,
        letterSpacing: -0.4,
        maxLines: 6,
      ),
      shapeEl(
        pos: const Offset(0.21, 0.78),
        size: const Size(0.16, 0.004),
        shape: ShapeKind.rect,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 1,
        fontSize: 24,
        color: Colors.white70,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white),
    ],
  );
}
