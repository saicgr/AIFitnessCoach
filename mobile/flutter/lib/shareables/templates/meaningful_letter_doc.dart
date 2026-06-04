/// Editable-card preset — **Letter to Future Me**: a warm-paper journal page.
/// Cream background, Fraunces serif body set as a hand-written note ("Dear
/// future me, …"), the user's hero line woven in, a "— Day N" sign-off, and a
/// "ZEALOVA JOURNAL" footer in condensed caps. Every line is editable so the
/// user can rewrite the letter in their own words.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulLetterDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFF4F1E6);
  const ink = Color(0xFF2A2A2A);
  const faded = Color(0xFF8A8578);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulLetter',
    accent: accent,
    background: solidBg(paper),
    elements: [
      // Salutation.
      textEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.84, 0.04),
        literal: 'Dear future me,',
        font: CardFontIx.serif,
        fontSize: 34,
        color: ink,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Body — the letter, with the user's hero line woven in.
      textEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.84, 0.34),
        literal:
            'Today I showed up when it was hard. Remember this on the days '
            'you want to quit — you are not the person who started.',
        font: CardFontIx.serif,
        fontSize: 26,
        color: ink,
        align: TextAlign.left,
        lineHeight: 1.6,
        maxLines: 8,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // The user's real headline stat, set as a remembered line.
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
      // Sign-off — em-dash marker + the bound period beside it.
      textEl(
        pos: const Offset(0.12, 0.72),
        size: const Size(0.08, 0.04),
        literal: '—',
        font: CardFontIx.serif,
        fontSize: 24,
        color: ink,
        align: TextAlign.left,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.45, 0.72),
        size: const Size(0.66, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
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
      // Journal footer.
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
