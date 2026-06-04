/// Editable-card preset for the **AI Caption** template — a full-bleed hero
/// photo with a glassy bottom caption card: an "✦ AI CAPTION" eyebrow over an
/// AI-written, hashtag-laden caption. Designed to be pasted straight into a
/// social post. The caption text and eyebrow are editable layers.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiCaptionDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiCaption',
    accent: accent,
    background: photoBg(binding: const DataBinding(BindingSource.heroImageUrl)),
    elements: [
      // Darken the whole photo.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x4D000000), Color(0xB3000000)],
      ),
      // Glass caption card.
      shapeEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.86, 0.2),
        shape: ShapeKind.rounded,
        fill: const Color(0x80000000),
        stroke: accent.withValues(alpha: 0.4),
        strokeWidth: 1.2,
        cornerRadius: 18,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.745),
        size: const Size(0.78, 0.025),
        literal: '✦ AI CAPTION',
        font: CardFontIx.cond,
        fontSize: 17,
        color: accent,
        letterSpacing: 2.2,
      ),
      // The AI caption.
      textEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.78, 0.13),
        literal:
            '"9,128 kg says discipline tastes better than excuses. Push day conquered 💪 #ZealovaStrong"',
        font: CardFontIx.condMid,
        fontSize: 26,
        color: white,
        lineHeight: 1.4,
      ),
      watermarkEl(pos: const Offset(0.3, 0.955), color: const Color(0xCCFFFFFF)),
    ],
  );
}
