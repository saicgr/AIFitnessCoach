/// Editable-card preset for the **Chat Bubble** template — a mocked
/// iMessage thread: app-name header, two grey received bubbles, an accent
/// blue sent bubble, and a "Read" receipt.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc chatBubbleDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const iMessageBlue = Color(0xFF0B84FF);
  const receivedGrey = Color(0xFF26282E);
  return cardDoc(
    aspect: aspect,
    presetId: 'chatBubble',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF000000), Color(0xFF0A0A0A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Contact header — avatar disc + app name.
      shapeEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.13, 0.073),
        shape: ShapeKind.circle,
        gradient: [accent, Color.lerp(accent, Colors.black, 0.35)!],
      ),
      iconEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.07, 0.04),
        emoji: '⚡',
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.6, 0.03),
        literal: 'Zealova',
        font: 0,
        fontSize: 24,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.21),
        size: const Size(0.6, 0.03),
        literal: 'Today',
        font: 0,
        fontSize: 18,
        color: Colors.white38,
        align: TextAlign.center,
      ),
      // Received bubble 1 — workout summary.
      shapeEl(
        pos: const Offset(0.4, 0.32),
        size: const Size(0.62, 0.08),
        shape: ShapeKind.rounded,
        fill: receivedGrey,
        cornerRadius: 28,
      ),
      textEl(
        pos: const Offset(0.4, 0.32),
        size: const Size(0.54, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: 0,
        fontSize: 26,
        maxLines: 2,
      ),
      // Received bubble 2 — first highlight.
      shapeEl(
        pos: const Offset(0.38, 0.42),
        size: const Size(0.58, 0.07),
        shape: ShapeKind.rounded,
        fill: receivedGrey,
        cornerRadius: 28,
      ),
      textEl(
        pos: const Offset(0.38, 0.42),
        size: const Size(0.5, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 0,
        fontSize: 26,
      ),
      // Sent bubble — celebration.
      shapeEl(
        pos: const Offset(0.62, 0.54),
        size: const Size(0.6, 0.08),
        shape: ShapeKind.rounded,
        fill: iMessageBlue,
        cornerRadius: 28,
      ),
      textEl(
        pos: const Offset(0.62, 0.54),
        size: const Size(0.52, 0.06),
        binding: const DataBinding(BindingSource.heroString),
        font: 0,
        fontSize: 26,
        align: TextAlign.right,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.78, 0.6),
        size: const Size(0.3, 0.03),
        literal: 'Read',
        font: 0,
        fontSize: 18,
        color: Colors.white54,
        align: TextAlign.right,
      ),
      // Compose pill.
      shapeEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.84, 0.055),
        shape: ShapeKind.pill,
        fill: const Color(0x0AFFFFFF),
        stroke: const Color(0x2EFFFFFF),
        strokeWidth: 1,
        cornerRadius: 999,
      ),
      textEl(
        pos: const Offset(0.46, 0.86),
        size: const Size(0.7, 0.03),
        literal: 'iMessage',
        font: 0,
        fontSize: 22,
        color: Colors.white38,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white),
    ],
  );
}
