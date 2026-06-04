/// Editable-card preset for the **Scratch Ticket** collectible — a "SCRATCH &
/// WIN" instant-lottery card: a gold foil panel on black, a grey "scratch-off"
/// strip stamped WINNER, the prize line (the headline PR / lift), a perforated
/// tear edge along the bottom, and a "no luck involved" mono footer. Every text
/// is editable; the prize + footer bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleScratchTicketDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ticketInk = Color(0xFF1A1A1A);
  const scratch = Color(0xFF777777);
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleScratchTicket',
    accent: accent,
    background: solidBg(ticketInk),
    elements: [
      // Gold foil panel.
      shapeEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.88, 0.78),
        gradient: const [Color(0xFFFFD700), Color(0xFFB8860B)],
        cornerRadius: 12,
      ),
      // Header.
      textEl(
        pos: const Offset(0.5, 0.2),
        size: const Size(0.8, 0.05),
        literal: 'SCRATCH & WIN',
        font: CardFontIx.display,
        fontSize: 40,
        color: ticketInk,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Scratch-off strip.
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.56, 0.12),
        fill: scratch,
        cornerRadius: 8,
      ),
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.54, 0.08),
        literal: 'WINNER',
        font: CardFontIx.display,
        fontSize: 50,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Prize label.
      textEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.8, 0.03),
        literal: 'PRIZE',
        font: CardFontIx.cond,
        fontSize: 16,
        color: ticketInk,
        align: TextAlign.center,
        letterSpacing: 5,
        maxLines: 1,
      ),
      // Prize value (the PR / headline).
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.84, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 32,
        color: ticketInk,
        align: TextAlign.center,
        maxLines: 2,
      ),
      // Hero stat callout.
      textEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: ticketInk,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Perforated tear edge.
      perforationEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.92, 0.05),
        edge: PerforationEdge.horizontalCenter,
        color: const Color(0x66FFD700),
        notchColor: ticketInk,
      ),
      // Footer — literal disclaimer + bound period.
      textEl(
        pos: const Offset(0.5, 0.91),
        size: const Size(0.84, 0.025),
        literal: 'no luck involved · just work',
        font: CardFontIx.mono,
        fontSize: 14,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.94),
        size: const Size(0.84, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 13,
        color: const Color(0x66FFFFFF),
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.975), color: white),
    ],
  );
}
