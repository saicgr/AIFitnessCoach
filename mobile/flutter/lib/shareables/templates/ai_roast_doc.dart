/// Editable-card preset for the **AI Roast** template — the coach in
/// roast-mode: a magenta "ROAST MODE 🔥" eyebrow, an italic serif jab, and a
/// big "9.2 / 10 · would lift again" score. Playful, shareable banter. The
/// roast line and score are editable; the score reads from a literal so the
/// user can dial it to their taste.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiRoastDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const magenta = Color(0xFFF0429A);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiRoast',
    accent: accent,
    background: solidBg(const Color(0xFF15101C)),
    elements: [
      // Roast-mode eyebrow.
      textEl(
        pos: const Offset(0.5, 0.36),
        size: const Size(0.84, 0.03),
        literal: 'AI COACH · ROAST MODE 🔥',
        font: CardFontIx.cond,
        fontSize: 19,
        color: magenta,
        letterSpacing: 1.8,
        align: TextAlign.center,
      ),
      // The roast — italic serif.
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.84, 0.22),
        literal:
            '"9,128 kg? Respectable. But we both saw you rack early on that last set. Tomorrow we finish it."',
        font: CardFontIx.serif,
        fontSize: 38,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.32,
      ),
      // Big score.
      textEl(
        pos: const Offset(0.36, 0.66),
        size: const Size(0.32, 0.08),
        literal: '9.2',
        font: CardFontIx.display,
        fontSize: 76,
        color: accent,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.66, 0.67),
        size: const Size(0.4, 0.04),
        literal: '/ 10 · would lift again',
        font: CardFontIx.cond,
        fontSize: 20,
        color: muted,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
