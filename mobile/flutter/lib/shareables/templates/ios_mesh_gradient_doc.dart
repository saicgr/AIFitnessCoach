/// Editable-card preset for the **iOS Mesh Gradient** template — the SwiftUI
/// `MeshGradient` aesthetic: layered soft radial blooms over a multi-stop
/// diagonal mesh, with a centered editorial stack (eyebrow, giant hero number,
/// label) and a frosted stat-strip pill near the bottom. Distinct from the food
/// mesh-big-number card: stats-driven, layered blooms, and a glass stat strip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosMeshGradientDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);

  final mesh = [
    Color.lerp(accent, const Color(0xFFEC4899), 0.4)!,
    Color.lerp(accent, const Color(0xFF6366F1), 0.45)!,
    accent,
    Color.lerp(accent, const Color(0xFF06B6D4), 0.55)!,
    const Color(0xFF15131F),
  ];

  return cardDoc(
    aspect: aspect,
    presetId: 'iosMeshGradient',
    accent: accent,
    background: gradientBg(
      mesh,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.28, 0.52, 0.76, 1.0],
    ),
    elements: [
      // Layered soft blooms (mesh control points).
      shapeEl(
        pos: const Offset(0.22, 0.22),
        size: const Size(0.8, 0.5),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        gradient: const [Color(0x55FFFFFF), Color(0x00FFFFFF)],
        radial: true,
      ),
      shapeEl(
        pos: const Offset(0.82, 0.7),
        size: const Size(0.9, 0.55),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        gradient: const [Color(0x44FFFFFF), Color(0x00FFFFFF)],
        radial: true,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.2),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 26,
        color: const Color(0xCCFFFFFF),
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      // Giant hero number.
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.94, 0.3),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 300,
        color: white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0x66000000), blur: 36),
      ),
      // Label / title under the number.
      textEl(
        pos: const Offset(0.5, 0.63),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 32,
        color: const Color(0xE6FFFFFF),
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Frosted stat-strip pill.
      shapeEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.86, 0.12),
        shape: ShapeKind.rounded,
        fill: const Color(0x33000000),
        stroke: const Color(0x33FFFFFF),
        strokeWidth: 1.2,
        cornerRadius: 28,
      ),
      statGridEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.78, 0.09),
        columns: 3,
        tileColor: const Color(0x00000000),
        valueColor: white,
        labelColor: const Color(0x99FFFFFF),
        valueFontSize: 34,
        labelFontSize: 14,
        valueFont: CardFontIx.display,
        tiles: const [
          ['—', 'STAT'],
          ['—', 'STAT'],
          ['—', 'STAT'],
        ],
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: white),
    ],
  );
}
