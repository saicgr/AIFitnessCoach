/// Editable-card preset for the **Food Collage** food template — a grid of
/// food photos with a summed-macro footer band. The doc lays the photos as a
/// 2×2 grid of bound photo elements and a footer card with the meal label
/// and a stacked-bar macro chart.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc foodCollageDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'foodCollage',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0B0D12), Color(0xFF050608)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // 2×2 photo grid — each cell bound to a food photo by index.
      photoEl(
        pos: const Offset(0.27, 0.27),
        size: const Size(0.44, 0.32),
        binding: const DataBinding(BindingSource.foodImageUrl, index: 0),
        mask: PhotoMask.rounded,
        cornerRadius: 14,
      ),
      photoEl(
        pos: const Offset(0.73, 0.27),
        size: const Size(0.44, 0.32),
        binding: const DataBinding(BindingSource.foodImageUrl, index: 1),
        mask: PhotoMask.rounded,
        cornerRadius: 14,
      ),
      photoEl(
        pos: const Offset(0.27, 0.61),
        size: const Size(0.44, 0.32),
        binding: const DataBinding(BindingSource.foodImageUrl, index: 2),
        mask: PhotoMask.rounded,
        cornerRadius: 14,
      ),
      photoEl(
        pos: const Offset(0.73, 0.61),
        size: const Size(0.44, 0.32),
        binding: const DataBinding(BindingSource.foodImageUrl, index: 3),
        mask: PhotoMask.rounded,
        cornerRadius: 14,
      ),
      // Footer band.
      shapeEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.92, 0.16),
        shape: ShapeKind.rounded,
        fill: const Color(0x10FFFFFF),
        stroke: const Color(0x14FFFFFF),
        strokeWidth: 1.5,
        cornerRadius: 18,
      ),
      textEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        fontSize: 30,
        align: TextAlign.center,
        maxLines: 1,
      ),
      chartEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(0.84, 0.07),
        style: MacroVizStyle.stackedBar,
      ),
      watermarkEl(pos: const Offset(0.30, 0.96), color: Colors.white70),
    ],
  );
}
