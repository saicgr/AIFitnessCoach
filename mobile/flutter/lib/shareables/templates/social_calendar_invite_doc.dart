/// Social-era preset — **Calendar Invite**. A light calendar-event card: an
/// accent header bar, the date eyebrow, a big Anton event title bound to the
/// share, a time + location line, and the three RSVP chips (Going / Maybe / No)
/// with "Going" pre-selected in the accent colour. Date, title, time/location
/// and the chip labels are editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialCalendarInviteDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF111111);
  const sub = Color(0xFF888888);
  const body = Color(0xFF444444);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialCalendarInvite',
    accent: accent,
    background: solidBg(const Color(0xFFFFFFFF)),
    elements: [
      // Accent header bar.
      shapeEl(
        pos: const Offset(0.5, 0.04),
        size: const Size(1, 0.025),
        shape: ShapeKind.rect,
        fill: accent,
      ),
      // Date eyebrow.
      textEl(
        pos: const Offset(0.5, 0.22),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 22,
        color: sub,
        allCaps: true,
        letterSpacing: 1.5,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Event title.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.86, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 60,
        color: ink,
        align: TextAlign.center,
        lineHeight: 1.0,
        maxLines: 2,
      ),
      // Time + location.
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.86, 0.04),
        literal: '6:40 – 7:41 AM  ·  Nine Fitness',
        font: CardFontIx.condMid,
        fontSize: 24,
        color: body,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // RSVP chips.
      shapeEl(
        pos: const Offset(0.27, 0.6),
        size: const Size(0.24, 0.07),
        shape: ShapeKind.rounded,
        fill: accent,
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.27, 0.6),
        size: const Size(0.24, 0.04),
        literal: 'Going',
        font: CardFontIx.cond,
        fontSize: 22,
        color: ink,
        align: TextAlign.center,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.24, 0.07),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: const Color(0x33000000),
        strokeWidth: 1.4,
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.24, 0.04),
        literal: 'Maybe',
        font: CardFontIx.cond,
        fontSize: 22,
        color: body,
        align: TextAlign.center,
      ),
      shapeEl(
        pos: const Offset(0.73, 0.6),
        size: const Size(0.24, 0.07),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: const Color(0x33000000),
        strokeWidth: 1.4,
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.73, 0.6),
        size: const Size(0.24, 0.04),
        literal: 'No',
        font: CardFontIx.cond,
        fontSize: 22,
        color: body,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: sub),
    ],
  );
}
