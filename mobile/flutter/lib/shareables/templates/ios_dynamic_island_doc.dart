/// Editable-card preset for the **iOS Dynamic Island** template — a faithful
/// recreation of the iPhone Dynamic Island "live activity" pill: a blurred
/// wallpaper behind a glassy black capsule that grows into an expanded live
/// activity showing the live workout, a real scrubber with elapsed/total time
/// and a leading volt-accent app glyph. Every text + the watermark are
/// editable layers; data binds to the live workout title + hero stat.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosDynamicIslandDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white60 = Color(0x99FFFFFF);
  const island = Color(0xFF000000);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosDynamicIsland',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
      blurred: true,
    ),
    elements: [
      // Dim + tint the wallpaper so the island reads as glass-on-screen.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x99000000), Color(0xCC0A0A0F)],
      ),
      // Status-bar time + signal hint (sells the iOS lock-screen feel).
      textEl(
        pos: const Offset(0.14, 0.06),
        size: const Size(0.22, 0.03),
        literal: '9:41',
        font: CardFontIx.grotesk,
        fontSize: 26,
        color: white,
      ),
      textEl(
        pos: const Offset(0.88, 0.06),
        size: const Size(0.2, 0.03),
        literal: '5G  ▮▮▮',
        font: CardFontIx.mono,
        fontSize: 16,
        color: white60,
        align: TextAlign.right,
      ),
      // The expanded Dynamic Island capsule.
      shapeEl(
        pos: const Offset(0.5, 0.32),
        size: const Size(0.9, 0.2),
        shape: ShapeKind.rounded,
        fill: island,
        cornerRadius: 56,
      ),
      // Leading rounded app glyph tile (volt accent).
      shapeEl(
        pos: const Offset(0.2, 0.275),
        size: const Size(0.13, 0.075),
        shape: ShapeKind.rounded,
        gradient: [accent, Color.lerp(accent, Colors.black, 0.45)!],
        cornerRadius: 20,
      ),
      iconEl(
        pos: const Offset(0.2, 0.275),
        size: const Size(0.1, 0.05),
        emoji: '🏋️',
      ),
      // Live-activity eyebrow.
      textEl(
        pos: const Offset(0.58, 0.255),
        size: const Size(0.52, 0.022),
        literal: 'LIVE · ZEALOVA',
        font: CardFontIx.cond,
        fontSize: 15,
        color: accent,
        letterSpacing: 2.4,
      ),
      // Workout title.
      textEl(
        pos: const Offset(0.58, 0.295),
        size: const Size(0.52, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 30,
        color: white,
        maxLines: 1,
      ),
      // Trailing live hero metric.
      textEl(
        pos: const Offset(0.85, 0.275),
        size: const Size(0.22, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 40,
        color: accent,
        align: TextAlign.right,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Scrubber row inside the expanded island.
      scrubberEl(
        pos: const Offset(0.5, 0.355),
        size: const Size(0.74, 0.03),
        progress: 0.62,
        leftLabel: '28:12',
        rightLabel: '45:00',
        fillColor: accent,
        knobColor: accent,
        textColor: white60,
      ),
      // Caption / pinned note below the island.
      textEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 24,
        color: white,
        align: TextAlign.center,
        letterSpacing: 1.6,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: white60),
    ],
  );
}
