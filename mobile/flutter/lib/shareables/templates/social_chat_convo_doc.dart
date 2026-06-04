/// Social-era preset — **WhatsApp / iMessage Chat Convo**. A dark messaging
/// thread: a contact-name header bar, a few alternating chat bubbles (incoming
/// grey on the left, your accent-tinted bubbles on the right) telling a little
/// PR-brag story, and a "Delivered" receipt. Every bubble is an editable
/// chatBubble layer; the last outgoing bubble binds to the share title.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialChatConvoDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const incoming = Color(0xFF1F2C33);
  const muted = Color(0xFF8696A0);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialChatConvo',
    accent: accent,
    background: solidBg(const Color(0xFF0B141A)),
    elements: [
      // Header bar.
      shapeEl(
        pos: const Offset(0.5, 0.06),
        size: const Size(1, 0.08),
        shape: ShapeKind.rect,
        fill: const Color(0xFF1F2C33),
      ),
      textEl(
        pos: const Offset(0.5, 0.06),
        size: const Size(0.7, 0.035),
        literal: '‹  Gym Bros 💪',
        font: CardFontIx.cond,
        fontSize: 26,
        color: white,
        align: TextAlign.center,
      ),
      // Incoming bubble.
      chatBubbleEl(
        pos: const Offset(0.33, 0.28),
        size: const Size(0.6, 0.08),
        text: 'how was the gym today?',
        side: ChatSide.left,
        tint: incoming,
        textColor: white,
        fontSize: 26,
      ),
      // Outgoing reply.
      chatBubbleEl(
        pos: const Offset(0.62, 0.42),
        size: const Size(0.66, 0.1),
        text: 'just hit a new bench PR 💪',
        side: ChatSide.right,
        tint: accent,
        textColor: const Color(0xFF0B0B0B),
        fontSize: 26,
      ),
      // Incoming reaction.
      chatBubbleEl(
        pos: const Offset(0.28, 0.56),
        size: const Size(0.5, 0.08),
        text: 'no way?? 🤯 proof?',
        side: ChatSide.left,
        tint: incoming,
        textColor: white,
        fontSize: 26,
      ),
      // Outgoing — the share title (the brag).
      chatBubbleEl(
        pos: const Offset(0.6, 0.72),
        size: const Size(0.7, 0.12),
        textBinding: const DataBinding(BindingSource.title),
        side: ChatSide.right,
        tint: accent,
        textColor: const Color(0xFF0B0B0B),
        fontSize: 26,
      ),
      // Delivered receipt.
      textEl(
        pos: const Offset(0.86, 0.81),
        size: const Size(0.26, 0.025),
        literal: '6:51 AM ✓✓',
        font: CardFontIx.mono,
        fontSize: 14,
        color: muted,
        align: TextAlign.right,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
