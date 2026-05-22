/// Editable-card preset for the **Meal Chat** food template — a mocked
/// group-chat thread: stacked rounded chat bubbles with short lines, a
/// typing-indicator bubble, timestamp chips, and the meal photo rendered as
/// a sent-image bubble.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealChatDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const receivedGrey = Color(0xFF26282E);
  return cardDoc(
    aspect: aspect,
    presetId: 'mealChat',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF000000), Color(0xFF0A0A0C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Group-chat header.
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.7, 0.035),
        literal: 'Meal Squad',
        font: 0,
        fontSize: 26,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.7, 0.03),
        literal: '3 members',
        font: 0,
        fontSize: 17,
        color: Colors.white38,
        align: TextAlign.center,
      ),
      // Received bubble 1 — meal label.
      shapeEl(
        pos: const Offset(0.36, 0.24),
        size: const Size(0.5, 0.07),
        shape: ShapeKind.rounded,
        fill: receivedGrey,
        cornerRadius: 26,
      ),
      textEl(
        pos: const Offset(0.36, 0.24),
        size: const Size(0.42, 0.05),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 0,
        fontSize: 24,
        maxLines: 1,
      ),
      // Sent image bubble — the meal photo.
      photoEl(
        pos: const Offset(0.62, 0.42),
        size: const Size(0.5, 0.28),
        mask: PhotoMask.rounded,
        cornerRadius: 26,
      ),
      textEl(
        pos: const Offset(0.78, 0.57),
        size: const Size(0.2, 0.025),
        literal: 'Delivered',
        font: 0,
        fontSize: 15,
        color: Colors.white54,
        align: TextAlign.right,
      ),
      // Received bubble 2 — the title as a reaction line.
      shapeEl(
        pos: const Offset(0.4, 0.66),
        size: const Size(0.6, 0.08),
        shape: ShapeKind.rounded,
        fill: receivedGrey,
        cornerRadius: 26,
      ),
      textEl(
        pos: const Offset(0.4, 0.66),
        size: const Size(0.52, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: 0,
        fontSize: 23,
        maxLines: 2,
      ),
      // Sent bubble — calorie brag.
      shapeEl(
        pos: const Offset(0.62, 0.77),
        size: const Size(0.52, 0.07),
        shape: ShapeKind.rounded,
        fill: accent,
        cornerRadius: 26,
      ),
      textEl(
        pos: const Offset(0.62, 0.77),
        size: const Size(0.44, 0.05),
        binding: const DataBinding(BindingSource.calories),
        font: 0,
        fontSize: 24,
        align: TextAlign.right,
        maxLines: 1,
      ),
      // Typing-indicator bubble.
      shapeEl(
        pos: const Offset(0.22, 0.85),
        size: const Size(0.2, 0.06),
        shape: ShapeKind.rounded,
        fill: receivedGrey,
        cornerRadius: 26,
      ),
      textEl(
        pos: const Offset(0.22, 0.85),
        size: const Size(0.16, 0.04),
        literal: '• • •',
        font: 0,
        fontSize: 26,
        color: Colors.white54,
        align: TextAlign.center,
      ),
      // Timestamp chip.
      textEl(
        pos: const Offset(0.5, 0.91),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 0,
        fontSize: 16,
        color: Colors.white38,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white),
    ],
  );
}
