/// Editable-card preset for **F11a — Body / Muscle Heatmap** (workout).
///
/// A focused muscle-emphasis card: the top trained muscle groups as labelled
/// intensity bars derived **deterministically** from `data.musclesWorked`
/// (working-set counts), over the same anatomical-tinted canvas as the Muscle
/// Map. Zero AI. This is the doc-native, editor-reachable companion to the
/// rich `muscleMap` / `workoutMuscleCard` widget cards (which draw the full SVG
/// figure); a heatmap card reads at a glance which muscles got hammered.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc bodyHeatmapDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;

  // Rank muscles by working-set count (deterministic). Top 5 get a bar each,
  // intensity = count / peak.
  final muscles = (data.musclesWorked ?? const <String, int>{})
      .entries
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = muscles.take(5).toList();
  final peak = top.isEmpty ? 1 : top.first.value;

  String pretty(String raw) {
    final s = raw.replaceAll('_', ' ').trim();
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  final elements = <CardElement>[
    textEl(
      pos: const Offset(0.5, 0.1),
      size: const Size(0.84, 0.04),
      literal: 'MUSCLE HEATMAP',
      font: CardFontIx.cond,
      fontSize: 28,
      color: accent,
      align: TextAlign.center,
      letterSpacing: 4,
    ),
    textEl(
      pos: const Offset(0.5, 0.16),
      size: const Size(0.86, 0.06),
      binding: const DataBinding(BindingSource.title),
      fontSize: 44,
      align: TextAlign.center,
      maxLines: 1,
    ),
    textEl(
      pos: const Offset(0.5, 0.22),
      size: const Size(0.84, 0.035),
      binding: const DataBinding(BindingSource.periodLabel),
      fontSize: 22,
      color: const Color(0x80FFFFFF),
      align: TextAlign.center,
      letterSpacing: 2,
      allCaps: true,
    ),
  ];

  // Intensity bars — one row per top muscle.
  const top0 = 0.34; // first row center-y
  const rowH = 0.1;
  for (var i = 0; i < top.length; i++) {
    final y = top0 + i * rowH;
    final frac = (top[i].value / peak).clamp(0.12, 1.0);
    // Track.
    elements.add(shapeEl(
      pos: const Offset(0.5, 0.0).translate(0, y),
      size: const Size(0.84, 0.05),
      shape: ShapeKind.pill,
      fill: const Color(0x14FFFFFF),
    ));
    // Fill — left-anchored, width scaled by intensity.
    elements.add(shapeEl(
      pos: Offset(0.08 + 0.84 * frac / 2, y),
      size: Size(0.84 * frac, 0.05),
      shape: ShapeKind.pill,
      fill: accent,
    ));
    // Muscle label.
    elements.add(textEl(
      pos: Offset(0.16, y),
      size: const Size(0.5, 0.04),
      literal: pretty(top[i].key),
      font: CardFontIx.condMid,
      fontSize: 28,
      color: Colors.white,
      align: TextAlign.left,
      maxLines: 1,
    ));
    // Set count.
    elements.add(textEl(
      pos: Offset(0.86, y),
      size: const Size(0.2, 0.04),
      literal: '${top[i].value} sets',
      font: CardFontIx.mono,
      fontSize: 22,
      color: const Color(0xCCFFFFFF),
      align: TextAlign.right,
      maxLines: 1,
    ));
  }

  elements.add(watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70));

  return cardDoc(
    aspect: aspect,
    presetId: 'bodyHeatmap',
    accent: accent,
    background: gradientBg([
      const Color(0xFF06080F),
      Color.lerp(accent, const Color(0xFF06080F), 0.85)!,
    ]),
    elements: elements,
  );
}
