/// Editable-card preset for the **iOS Vinyl Record** template — a spinning
/// 12" record with the user's photo as the center label seen through the
/// spindle, concentric grooves, a tonearm, and an iOS now-playing transport
/// strip below (scrubber + ◀◀ ❚❚ ▶▶) so the workout reads as the track that's
/// "playing". Distinct from the legacy Vinyl: photo label, tonearm, real
/// scrubber + transport row instead of a flat SIDE-A disc.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosVinylRecordDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white60 = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosVinylRecord',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF101014), Color(0xFF050505)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Record disc.
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.86, 0.86),
        shape: ShapeKind.circle,
        gradient: const [Color(0xFF222227), Color(0xFF0C0C0E)],
        radial: true,
      ),
      // Concentric grooves.
      for (var i = 0; i < 6; i++)
        shapeEl(
          pos: const Offset(0.5, 0.4),
          size: Size(0.8 - i * 0.1, 0.8 - i * 0.1),
          shape: ShapeKind.circle,
          fill: const Color(0x00000000),
          stroke: const Color(0x12FFFFFF),
          strokeWidth: 1,
        ),
      // Accent label ring (volt rim).
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.36, 0.36),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        stroke: accent,
        strokeWidth: 5,
      ),
      // Photo center label.
      photoEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.32, 0.32),
        binding: const DataBinding(BindingSource.heroImageUrl),
        mask: PhotoMask.circle,
      ),
      // Spindle hole.
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.022, 0.022),
        shape: ShapeKind.circle,
        fill: const Color(0xFF000000),
      ),
      // Tonearm pivot + arm reaching toward the groove (vertical strut keeps
      // the helper-only API; shapeEl exposes no rotation).
      shapeEl(
        pos: const Offset(0.86, 0.12),
        size: const Size(0.05, 0.05),
        shape: ShapeKind.circle,
        fill: const Color(0xFF8A8A92),
      ),
      shapeEl(
        pos: const Offset(0.8, 0.28),
        size: const Size(0.012, 0.34),
        shape: ShapeKind.pill,
        fill: const Color(0xFFBFBFC6),
      ),
      // Tonearm head touching the record edge.
      shapeEl(
        pos: const Offset(0.79, 0.44),
        size: const Size(0.03, 0.025),
        shape: ShapeKind.rounded,
        fill: const Color(0xFFD8D8DE),
        cornerRadius: 4,
      ),
      // Now-playing eyebrow.
      textEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.84, 0.025),
        literal: 'NOW SPINNING',
        font: CardFontIx.cond,
        fontSize: 16,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      // Track title (workout name).
      textEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 44,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Artist line (hero stat).
      textEl(
        pos: const Offset(0.5, 0.785),
        size: const Size(0.7, 0.025),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 18,
        color: white60,
        align: TextAlign.center,
      ),
      // Transport scrubber.
      scrubberEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.74, 0.03),
        progress: 0.48,
        leftLabel: '2:14',
        rightLabel: '4:33',
        fillColor: accent,
        knobColor: accent,
        textColor: white60,
      ),
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.5, 0.04),
        literal: '⏮     ❚❚     ⏭',
        fontSize: 26,
        color: white,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: white60),
    ],
  );
}
