/// Social-era preset — **Comment Thread ("what app is this?")**. A darkened
/// photo with a stack of frosted comment chips overlaid bottom-left — two
/// curious commenters ("wait what app is this??", "okay the card is clean") and
/// your reply naming Zealova. Each comment is a username (accent) + a comment
/// line, all editable text; the photo binds to the share's hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialCommentThreadDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const chip = Color(0x8C000000);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialCommentThread',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(1, 0.6),
        colors: const [Color(0x00000000), Color(0x99000000)],
      ),
      // Comment 1.
      shapeEl(
        pos: const Offset(0.5, 0.73),
        size: const Size(0.88, 0.07),
        shape: ShapeKind.rounded,
        fill: chip,
        cornerRadius: 16,
      ),
      textEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.82, 0.03),
        literal: 'mia_fit',
        font: CardFontIx.cond,
        fontSize: 18,
        color: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.745),
        size: const Size(0.82, 0.03),
        literal: 'wait what app is this?? 😍',
        font: CardFontIx.condMid,
        fontSize: 22,
        color: white,
        maxLines: 1,
      ),
      // Comment 2.
      shapeEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.88, 0.07),
        shape: ShapeKind.rounded,
        fill: chip,
        cornerRadius: 16,
      ),
      textEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.82, 0.03),
        literal: 'jdeadlift',
        font: CardFontIx.cond,
        fontSize: 18,
        color: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.835),
        size: const Size(0.82, 0.03),
        literal: 'okay the card is actually clean',
        font: CardFontIx.condMid,
        fontSize: 22,
        color: white,
        maxLines: 1,
      ),
      // Your reply.
      shapeEl(
        pos: const Offset(0.5, 0.91),
        size: const Size(0.88, 0.07),
        shape: ShapeKind.rounded,
        fill: chip,
        cornerRadius: 16,
      ),
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.82, 0.03),
        literal: 'you',
        font: CardFontIx.cond,
        fontSize: 18,
        color: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.925),
        size: const Size(0.82, 0.03),
        literal: 'Zealova ⚡ — it is free',
        font: CardFontIx.condMid,
        fontSize: 22,
        color: white,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white),
    ],
  );
}
