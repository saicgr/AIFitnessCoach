/// Social-era preset — **Venmo Payment**. A light Venmo transaction card: a
/// payer-row ("Chetan paid The Grind"), a giant Venmo-blue dollar amount bound
/// to the share's hero stat, a "for: push day 💪" memo line, and the
/// "Friday · 6:51 AM · 🔒 Private" footer. Payer line, memo and footer are
/// editable; the amount binds to the share's hero string.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialVenmoPaymentDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF2F3033);
  const sub = Color(0xFF888888);
  const venmoBlue = Color(0xFF008CFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialVenmoPayment',
    accent: accent,
    background: solidBg(const Color(0xFFFFFFFF)),
    elements: [
      // Payer avatar.
      shapeEl(
        pos: const Offset(0.16, 0.18),
        size: const Size(0.12, 0.066),
        shape: ShapeKind.circle,
        fill: venmoBlue,
      ),
      // Payer line.
      textEl(
        pos: const Offset(0.62, 0.18),
        size: const Size(0.66, 0.05),
        literal: 'Chetan paid The Grind',
        font: CardFontIx.cond,
        fontSize: 28,
        color: ink,
        maxLines: 2,
      ),
      // Giant amount.
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.9, 0.14),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 110,
        color: venmoBlue,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Memo.
      textEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 26,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.86, 0.002),
        color: const Color(0x1A000000),
      ),
      // Footer.
      textEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.86, 0.03),
        literal: 'Friday · 6:51 AM · 🔒 Private',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: sub,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: sub),
    ],
  );
}
