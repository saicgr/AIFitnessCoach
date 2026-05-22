/// Editable-card preset for the **Discord** template — a Discord rich-embed:
/// dark surface, an orange accent left bar, a server header, a title and a
/// 2×2 field grid built from highlights.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc discordDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const orange = Color(0xFFF97316);
  return cardDoc(
    aspect: aspect,
    presetId: 'discord',
    accent: accent,
    background: solidBg(const Color(0xFF202225)),
    elements: [
      // Embed card.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.46),
        shape: ShapeKind.rounded,
        fill: const Color(0xFF36393F),
        cornerRadius: 10,
      ),
      // Orange accent left bar.
      shapeEl(
        pos: const Offset(0.085, 0.5),
        size: const Size(0.014, 0.46),
        shape: ShapeKind.rounded,
        fill: orange,
        cornerRadius: 6,
      ),
      // Server header — avatar + name.
      shapeEl(
        pos: const Offset(0.18, 0.33),
        size: const Size(0.07, 0.04),
        shape: ShapeKind.circle,
        fill: orange,
      ),
      textEl(
        pos: const Offset(0.42, 0.33),
        size: const Size(0.4, 0.04),
        literal: 'Zealova',
        font: 1,
        fontSize: 26,
      ),
      // Title.
      textEl(
        pos: const Offset(0.5, 0.41),
        size: const Size(0.74, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 38,
        maxLines: 2,
      ),
      // 2×2 field grid.
      textEl(
        pos: const Offset(0.32, 0.53),
        size: const Size(0.36, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 0),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        letterSpacing: 0.5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.32, 0.57),
        size: const Size(0.36, 0.04),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 1,
        fontSize: 28,
      ),
      textEl(
        pos: const Offset(0.68, 0.53),
        size: const Size(0.36, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 1),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        letterSpacing: 0.5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.68, 0.57),
        size: const Size(0.36, 0.04),
        binding: const DataBinding(BindingSource.highlightValue, index: 1),
        font: 1,
        fontSize: 28,
      ),
      textEl(
        pos: const Offset(0.32, 0.62),
        size: const Size(0.36, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 2),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        letterSpacing: 0.5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.32, 0.66),
        size: const Size(0.36, 0.04),
        binding: const DataBinding(BindingSource.highlightValue, index: 2),
        font: 1,
        fontSize: 28,
      ),
      textEl(
        pos: const Offset(0.68, 0.62),
        size: const Size(0.36, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 3),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        letterSpacing: 0.5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.68, 0.66),
        size: const Size(0.36, 0.04),
        binding: const DataBinding(BindingSource.highlightValue, index: 3),
        font: 1,
        fontSize: 28,
      ),
      textEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.74, 0.03),
        literal: 'Powered by Zealova',
        font: 0,
        fontSize: 16,
        color: Colors.white38,
      ),
      watermarkEl(pos: const Offset(0.3, 0.86), color: Colors.white70),
    ],
  );
}
