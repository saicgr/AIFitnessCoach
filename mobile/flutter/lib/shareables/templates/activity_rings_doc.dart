/// Editable-card preset for the **Activity Rings** template — Apple-Watch
/// styled concentric progress rings on a near-black canvas with a 3-up
/// legend strip below.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc activityRingsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'activityRings',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF000000), Color(0xFF050810)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.04),
        literal: 'ACTIVITY',
        font: 1,
        fontSize: 26,
        color: Colors.white70,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.15),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 2,
        fontSize: 26,
        color: Colors.white54,
        align: TextAlign.center,
      ),
      chartEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.78, 0.42),
        style: MacroVizStyle.appleRings,
      ),
      // 3-up legend strip.
      textEl(
        pos: const Offset(0.22, 0.78),
        size: const Size(0.3, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 1,
        fontSize: 32,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.3, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 1),
        font: 1,
        fontSize: 32,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.78, 0.78),
        size: const Size(0.3, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 2),
        font: 1,
        fontSize: 32,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.22, 0.83),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 0),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 1),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.78, 0.83),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 2),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white),
    ],
  );
}
