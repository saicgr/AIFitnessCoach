/// Editable-card preset for the **iOS Glass Widget** template — a 2×2 grid of
/// frosted-glass home-screen widgets floating on a soft mesh wallpaper, the way
/// iOS 18+ tinted/clear widgets look. Top-left is a large stat widget (title +
/// hero), top-right a single progress ring, and the bottom row is a 2-up stat
/// grid widget. Glassmorphic translucent fills + hairline strokes, volt accent.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosGlassWidgetDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white60 = Color(0x99FFFFFF);
  final glass = const Color(0xFFFFFFFF).withValues(alpha: 0.08);
  final glassStroke = const Color(0xFFFFFFFF).withValues(alpha: 0.22);

  // Soft mesh wallpaper from the accent.
  final mesh = [
    Color.lerp(accent, const Color(0xFF312E81), 0.6)!,
    Color.lerp(accent, const Color(0xFF7C3AED), 0.35)!,
    const Color(0xFF0B0B14),
  ];

  return cardDoc(
    aspect: aspect,
    presetId: 'iosGlassWidget',
    accent: accent,
    background: gradientBg(
      mesh,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.45, 1.0],
    ),
    elements: [
      // Header date.
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 24,
        color: white60,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      // ── Top-left large stat widget ──
      shapeEl(
        pos: const Offset(0.3, 0.36),
        size: const Size(0.4, 0.26),
        shape: ShapeKind.rounded,
        fill: glass,
        stroke: glassStroke,
        strokeWidth: 1.4,
        cornerRadius: 36,
      ),
      iconEl(
        pos: const Offset(0.18, 0.27),
        size: const Size(0.05, 0.035),
        emoji: '🏋️',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.3, 0.33),
        size: const Size(0.34, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 56,
        color: white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.3, 0.41),
        size: const Size(0.34, 0.03),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 20,
        color: white60,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // ── Top-right progress-ring widget ──
      shapeEl(
        pos: const Offset(0.72, 0.36),
        size: const Size(0.4, 0.26),
        shape: ShapeKind.rounded,
        fill: glass,
        stroke: glassStroke,
        strokeWidth: 1.4,
        cornerRadius: 36,
      ),
      ringStatEl(
        pos: const Offset(0.72, 0.34),
        size: const Size(0.2, 0.2),
        progress: 0.74,
        centerBinding: const DataBinding(BindingSource.highlightValue, index: 0),
        centerValue: '74%',
        label: '',
        ringColor: accent,
        centerFontSize: 40,
      ),
      textEl(
        pos: const Offset(0.72, 0.45),
        size: const Size(0.32, 0.025),
        binding: const DataBinding(BindingSource.highlightLabel, index: 0),
        font: 0,
        fontSize: 16,
        color: white60,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      // ── Bottom-row 2-up stat-grid widget ──
      shapeEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.84, 0.26),
        shape: ShapeKind.rounded,
        fill: glass,
        stroke: glassStroke,
        strokeWidth: 1.4,
        cornerRadius: 36,
      ),
      statGridEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.72, 0.2),
        columns: 2,
        tileColor: const Color(0x00000000),
        valueColor: white,
        labelColor: white60,
        valueFontSize: 46,
        labelFontSize: 16,
        valueFont: CardFontIx.display,
      ),
      watermarkEl(pos: const Offset(0.3, 0.92), color: white60),
    ],
  );
}
