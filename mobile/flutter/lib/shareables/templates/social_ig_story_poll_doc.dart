/// Social-era preset — **Instagram Story (Poll)**. A full-bleed photo with the
/// story progress bar across the top, an avatar + handle pill, and a centred
/// interactive poll sticker ("New PR? 💪 — YES / NO") with a results split.
/// The poll question, both options and the result percent are editable text;
/// the photo binds to the share's hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialIgStoryPollDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const ink = Color(0xFF111111);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialIgStoryPoll',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x33000000), Color(0x66000000)],
      ),
      // Story progress segment.
      shapeEl(
        pos: const Offset(0.5, 0.035),
        size: const Size(0.92, 0.005),
        shape: ShapeKind.pill,
        fill: const Color(0x66FFFFFF),
      ),
      shapeEl(
        pos: const Offset(0.32, 0.035),
        size: const Size(0.56, 0.005),
        shape: ShapeKind.pill,
        fill: white,
      ),
      // Header — avatar + handle.
      avatarRowEl(
        pos: const Offset(0.5, 0.085),
        size: const Size(0.9, 0.05),
        fallbackGlyph: '🏋️',
        sub: 'just now',
        fontSize: 24,
      ),
      // Poll sticker card.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.18),
        shape: ShapeKind.rounded,
        fill: const Color(0xF2FFFFFF),
        cornerRadius: 24,
      ),
      textEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.7, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 34,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // YES option (accent, winning).
      shapeEl(
        pos: const Offset(0.36, 0.55),
        size: const Size(0.3, 0.07),
        shape: ShapeKind.rounded,
        fill: accent,
        cornerRadius: 16,
      ),
      textEl(
        pos: const Offset(0.36, 0.55),
        size: const Size(0.3, 0.04),
        literal: 'YES 87%',
        font: CardFontIx.cond,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
      ),
      // NO option.
      shapeEl(
        pos: const Offset(0.66, 0.55),
        size: const Size(0.26, 0.07),
        shape: ShapeKind.rounded,
        fill: const Color(0xFFEDEDED),
        cornerRadius: 16,
      ),
      textEl(
        pos: const Offset(0.66, 0.55),
        size: const Size(0.26, 0.04),
        literal: 'NO',
        font: CardFontIx.cond,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: white),
    ],
  );
}
