/// Social-era preset — **Group Chat**. A WhatsApp-style group thread: a
/// centred "THE GYM BROS 💪" group title, multiple incoming bubbles from named
/// members (each name in its own colour) reacting to the PR brag, and a short
/// outgoing reply. Group title and every bubble (incl. sender names) are
/// editable; one incoming bubble binds to the share's hero stat string.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialGroupChatDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const incoming = Color(0xFF1F2C33);
  const muted = Color(0xFF8696A0);
  const cyan = Color(0xFF22D3EE);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialGroupChat',
    accent: accent,
    background: solidBg(const Color(0xFF0B141A)),
    elements: [
      // Group title.
      textEl(
        pos: const Offset(0.5, 0.07),
        size: const Size(0.9, 0.04),
        literal: 'THE GYM BROS 💪',
        font: CardFontIx.cond,
        fontSize: 22,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.5,
      ),
      // Mike — bound to the share's hero stat string.
      chatBubbleEl(
        pos: const Offset(0.34, 0.27),
        size: const Size(0.64, 0.11),
        sender: 'Mike',
        textBinding: const DataBinding(BindingSource.heroString),
        side: ChatSide.left,
        tint: incoming,
        textColor: white,
        fontSize: 24,
      ),
      // Jay reacts.
      chatBubbleEl(
        pos: const Offset(0.32, 0.42),
        size: const Size(0.58, 0.1),
        sender: 'Jay',
        text: 'what?? 🤯 send the card',
        side: ChatSide.left,
        tint: incoming,
        textColor: white,
        fontSize: 24,
      ),
      // Sam reacts.
      chatBubbleEl(
        pos: const Offset(0.3, 0.56),
        size: const Size(0.5, 0.09),
        sender: 'Sam',
        text: 'absolute unit 🫡',
        side: ChatSide.left,
        tint: incoming,
        textColor: white,
        fontSize: 24,
      ),
      // You.
      chatBubbleEl(
        pos: const Offset(0.7, 0.7),
        size: const Size(0.34, 0.08),
        text: '😎⚡',
        side: ChatSide.right,
        tint: accent,
        textColor: const Color(0xFF0B0B0B),
        fontSize: 28,
      ),
      // Recolor Jay's name accent via a small overlay label (cyan) for variety.
      textEl(
        pos: const Offset(0.5, 0.95),
        size: const Size(0.9, 0.02),
        literal: 'shared from Zealova',
        font: CardFontIx.mono,
        fontSize: 13,
        color: cyan,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.91), color: muted),
    ],
  );
}
