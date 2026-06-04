/// Editable-card preset for the **404 Page** data/meme template — a terminal
/// "404 · excuses not found" gag: a giant volt 404, a monospace "but [volume]
/// was located ✓" line, and a "↻ retry tomorrow" retry pill. Every line is an
/// editable text layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataError404Doc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const sub = Color(0xFF888888);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataError404',
    accent: volt,
    background: solidBg(const Color(0xFF0A0A0A)),
    elements: [
      // URL-bar eyebrow.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.86, 0.025),
        literal: 'zealova.app/excuses',
        font: CardFontIx.mono,
        fontSize: 16,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 1,
      ),
      // Giant 404.
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.9, 0.12),
        literal: '404',
        font: CardFontIx.display,
        fontSize: 140,
        color: volt,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.86, 0.04),
        literal: 'excuses not found',
        font: CardFontIx.mono,
        fontSize: 26,
        color: Colors.white,
        align: TextAlign.center,
      ),
      // "but [volume] was located ✓" — real hero string.
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.86, 0.035),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: sub,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.665),
        size: const Size(0.86, 0.025),
        literal: '↑ was located ✓',
        font: CardFontIx.mono,
        fontSize: 16,
        color: volt,
        align: TextAlign.center,
      ),
      // Retry pill.
      shapeEl(
        pos: const Offset(0.5, 0.75),
        size: const Size(0.5, 0.06),
        shape: ShapeKind.pill,
        fill: const Color(0x00000000),
        stroke: const Color(0xFF333333),
        strokeWidth: 1.4,
        cornerRadius: 16,
      ),
      textEl(
        pos: const Offset(0.5, 0.75),
        size: const Size(0.46, 0.035),
        literal: '↻  retry tomorrow',
        font: CardFontIx.mono,
        fontSize: 18,
        color: volt,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
