/// Social-era preset — **Facebook "On This Day" Memory**. A light Facebook
/// card: the blue "On This Day · 1 year ago" header strip, a big photo, and a
/// then-vs-now caption ("You couldn't bench 135. Today you hit 225 💪"). The
/// header sub-line and the caption are editable; the photo binds to the share's
/// hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialFbMemoryDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const ink = Color(0xFF111111);
  const fbBlue = Color(0xFF1877F2);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialFbMemory',
    accent: accent,
    background: solidBg(const Color(0xFFFFFFFF)),
    elements: [
      // Blue header strip.
      shapeEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(1, 0.12),
        shape: ShapeKind.rect,
        fill: fbBlue,
      ),
      textEl(
        pos: const Offset(0.5, 0.06),
        size: const Size(0.84, 0.04),
        literal: 'On This Day',
        font: CardFontIx.cond,
        fontSize: 30,
        color: white,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.condMid,
        fontSize: 18,
        color: const Color(0xD9FFFFFF),
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Photo.
      photoEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(1.0, 0.5),
        binding: const DataBinding(BindingSource.heroImageUrl),
        mask: PhotoMask.rect,
        cornerRadius: 0,
      ),
      // Then-vs-now caption.
      textEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.86, 0.14),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 30,
        color: ink,
        align: TextAlign.center,
        lineHeight: 1.3,
        maxLines: 4,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: const Color(0x99111111)),
    ],
  );
}
