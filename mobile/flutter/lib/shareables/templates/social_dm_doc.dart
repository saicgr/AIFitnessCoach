/// Social-era preset — **The DM**. A minimal Instagram-style direct-message
/// thread on black: a "Direct Message" header, an incoming grey bubble asking
/// where the workout card is from, and a single bold outgoing gradient bubble
/// answering "Zealova ⚡ — get it free". Both bubbles are editable; the layout
/// is deliberately the punchy two-line "the reply that converts" format.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialDmDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const incoming = Color(0xFF262629);
  const muted = Color(0xFF8E8E93);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialDm',
    accent: accent,
    background: solidBg(const Color(0xFF000000)),
    elements: [
      // Header.
      textEl(
        pos: const Offset(0.5, 0.18),
        size: const Size(0.7, 0.03),
        literal: 'Direct Message',
        font: CardFontIx.condMid,
        fontSize: 20,
        color: muted,
        align: TextAlign.center,
      ),
      // Incoming question.
      chatBubbleEl(
        pos: const Offset(0.34, 0.42),
        size: const Size(0.66, 0.12),
        text: 'ok where is that workout card from 👀',
        side: ChatSide.left,
        tint: incoming,
        textColor: white,
        fontSize: 30,
      ),
      // Outgoing — the converting reply.
      chatBubbleEl(
        pos: const Offset(0.62, 0.6),
        size: const Size(0.7, 0.12),
        text: 'Zealova ⚡ — get it free',
        side: ChatSide.right,
        tint: accent,
        textColor: const Color(0xFF0B0B0B),
        fontSize: 30,
      ),
      // Subtle seen receipt.
      textEl(
        pos: const Offset(0.86, 0.68),
        size: const Size(0.26, 0.025),
        literal: 'Seen',
        font: CardFontIx.mono,
        fontSize: 14,
        color: muted,
        align: TextAlign.right,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
