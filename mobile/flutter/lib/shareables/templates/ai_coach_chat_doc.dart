/// Editable-card preset for the **AI Coach Chat** template — a faithful
/// AI-chat thread: a small ✦ assistant header, a user question bubble on the
/// right, and the coach's data-grounded answer on the left in a volt-lime
/// tinted bubble. Every line is an editable layer; the answer binds to the
/// share's hero string so it tracks the real session stats.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiCoachChatDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cyan = Color(0xFF22D3EE);
  const volt = Color(0xFFD8FF3A);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiCoachChat',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0D0E14), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // ✦ assistant glyph chip.
      shapeEl(
        pos: const Offset(0.135, 0.135),
        size: const Size(0.07, 0.04),
        shape: ShapeKind.rounded,
        gradient: const [volt, cyan],
        cornerRadius: 9,
      ),
      textEl(
        pos: const Offset(0.135, 0.135),
        size: const Size(0.07, 0.04),
        literal: '✦',
        fontSize: 22,
        color: const Color(0xFF0B0B0B),
        align: TextAlign.center,
      ),
      // Assistant label.
      textEl(
        pos: const Offset(0.42, 0.135),
        size: const Size(0.5, 0.03),
        literal: 'ZEALOVA AI COACH',
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        letterSpacing: 2.2,
      ),
      // User question bubble (right).
      chatBubbleEl(
        pos: const Offset(0.6, 0.4),
        size: const Size(0.72, 0.12),
        text: 'did I crush push day?',
        side: ChatSide.right,
        tint: const Color(0xFF2A2D36),
        textColor: white,
        fontSize: 30,
      ),
      // Coach answer bubble (left) — binds to the live hero string.
      chatBubbleEl(
        pos: const Offset(0.46, 0.6),
        size: const Size(0.84, 0.2),
        text: 'Best volume in 6 weeks + a fresh PR — you earned tomorrow. 🔥',
        textBinding: const DataBinding(BindingSource.heroString),
        side: ChatSide.left,
        tint: const Color(0x1FD8FF3A),
        textColor: const Color(0xFFEAF3D0),
        fontSize: 30,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
