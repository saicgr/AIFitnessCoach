/// Editable-card preset — **Identity**: a stark, near-black field with a huge
/// Anton declaration ("I AM AN ATHLETE", the role bound to the user's rank) and
/// a small Fraunces italic coda ("not someday. now."). The most minimal of the
/// meaningful set — pure identity affirmation, no chrome.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulIdentityDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulIdentity',
    accent: accent,
    background: solidBg(const Color(0xFF070709)),
    elements: [
      // "I AM AN" — quiet line one.
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.86, 0.1),
        literal: 'I AM AN',
        font: CardFontIx.display,
        fontSize: 64,
        color: white,
        align: TextAlign.center,
        lineHeight: 0.88,
        maxLines: 1,
      ),
      // The role, in volt, bound to rank.
      textEl(
        pos: const Offset(0.5, 0.53),
        size: const Size(0.9, 0.12),
        binding: const DataBinding(BindingSource.rank),
        font: CardFontIx.display,
        fontSize: 72,
        color: accent,
        align: TextAlign.center,
        lineHeight: 0.88,
        allCaps: true,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Coda.
      textEl(
        pos: const Offset(0.5, 0.65),
        size: const Size(0.78, 0.04),
        literal: 'not someday. now.',
        font: CardFontIx.serif,
        fontSize: 24,
        color: muted,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: muted),
    ],
  );
}
