/// Editable-card preset — **Dear Past Me**: the mirror of the Letter format,
/// addressed backwards. A warm-paper journal page, Fraunces serif body
/// ("Dear past me, you had no idea …"), the user's real hero stat as proof, a
/// "— you, now" sign-off, and a "ZEALOVA JOURNAL" footer. Every line editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulDearPastMeDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFF4F1E6);
  const ink = Color(0xFF2A2A2A);
  const faded = Color(0xFF8A8578);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulDearPastMe',
    accent: accent,
    background: solidBg(paper),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.84, 0.04),
        literal: 'Dear past me,',
        font: CardFontIx.serif,
        fontSize: 34,
        color: ink,
        align: TextAlign.left,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.84, 0.34),
        literal:
            'you had no idea what you were capable of. The early mornings, the '
            'days you almost skipped — they added up to this. Keep going. It '
            'gets so much better.',
        font: CardFontIx.serif,
        fontSize: 26,
        color: ink,
        align: TextAlign.left,
        lineHeight: 1.6,
        maxLines: 9,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Proof — the user's real headline stat.
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.serif,
        fontSize: 24,
        color: accent,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Sign-off.
      textEl(
        pos: const Offset(0.5, 0.72),
        size: const Size(0.84, 0.04),
        literal: '— you, now',
        font: CardFontIx.serif,
        fontSize: 24,
        color: ink,
        align: TextAlign.left,
        maxLines: 1,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(0.84, 0.0025),
        color: const Color(0x33000000),
        thickness: 1.2,
      ),
      textEl(
        pos: const Offset(0.5, 0.94),
        size: const Size(0.84, 0.03),
        literal: 'ZEALOVA JOURNAL',
        font: CardFontIx.cond,
        fontSize: 16,
        color: faded,
        align: TextAlign.left,
        letterSpacing: 3,
      ),
      watermarkEl(pos: const Offset(0.62, 0.94), color: faded),
    ],
  );
}
