/// Editable-card preset for the **Coach Review** template — a coach's
/// report card on cream lined paper: eyebrow + period, a circular letter
/// grade, an italic note, a rubric panel, sticker highlights and a signature.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc coachReviewDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF1A1A1A);
  const redInk = Color(0xFFB91C1C);
  return cardDoc(
    aspect: aspect,
    presetId: 'coachReview',
    accent: accent,
    background: solidBg(const Color(0xFFFFFEF7)),
    elements: [
      // Red margin line.
      shapeEl(
        pos: const Offset(0.13, 0.5),
        size: const Size(0.004, 1),
        shape: ShapeKind.rect,
        fill: redInk.withValues(alpha: 0.55),
      ),
      textEl(
        pos: const Offset(0.46, 0.1),
        size: const Size(0.5, 0.03),
        literal: '✦ COACH REVIEW',
        font: 1,
        fontSize: 22,
        color: accent,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.46, 0.14),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 0,
        fontSize: 20,
        color: const Color(0x8C1A1A1A),
        letterSpacing: 1.6,
        allCaps: true,
      ),
      // Circular letter grade.
      shapeEl(
        pos: const Offset(0.83, 0.12),
        size: const Size(0.18, 0.1),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        stroke: redInk,
        strokeWidth: 3,
      ),
      textEl(
        pos: const Offset(0.83, 0.12),
        size: const Size(0.16, 0.08),
        literal: 'A',
        font: 8,
        fontSize: 56,
        color: redInk,
        align: TextAlign.center,
      ),
      // Italic note.
      textEl(
        pos: const Offset(0.55, 0.3),
        size: const Size(0.76, 0.16),
        binding: const DataBinding(BindingSource.caption),
        font: 6,
        fontSize: 30,
        color: ink,
        lineHeight: 1.45,
        maxLines: 4,
      ),
      // Rubric panel.
      shapeEl(
        pos: const Offset(0.55, 0.52),
        size: const Size(0.76, 0.17),
        shape: ShapeKind.rounded,
        fill: const Color(0x99FFF8E1),
        stroke: const Color(0x261A1A1A),
        strokeWidth: 1,
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.27, 0.46),
        size: const Size(0.2, 0.03),
        literal: 'RUBRIC',
        font: 1,
        fontSize: 18,
        color: redInk,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.55, 0.52),
        size: const Size(0.66, 0.1),
        literal: '✓ Form    ✓ Volume    ✓ Consistency',
        font: 3,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
        lineHeight: 1.6,
        maxLines: 3,
      ),
      // Sticker highlight.
      shapeEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.5, 0.06),
        shape: ShapeKind.rounded,
        fill: accent.withValues(alpha: 0.18),
        stroke: accent.withValues(alpha: 0.55),
        strokeWidth: 1.2,
        cornerRadius: 6,
      ),
      textEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.46, 0.04),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 3,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
      ),
      // Signature.
      dividerEl(
        pos: const Offset(0.34, 0.84),
        size: const Size(0.36, 0.004),
        color: const Color(0x661A1A1A),
        thickness: 1,
      ),
      textEl(
        pos: const Offset(0.34, 0.88),
        size: const Size(0.36, 0.04),
        literal: '— Coach ✦',
        font: 6,
        fontSize: 26,
        color: ink,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: ink),
    ],
  );
}
