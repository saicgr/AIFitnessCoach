/// Editable-card preset for the **Prompt → Plan** template — a monospace
/// terminal transcript: the user's `> generate my push day` prompt, a
/// "thinking ▮▮▮" line, and a green check-list of what the AI produced. Reads
/// like a coding-agent console. Each line is an editable text layer; the title
/// line binds to the real workout title.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiPromptPlanDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cyan = Color(0xFF22D3EE);
  const green = Color(0xFF7CFC7C);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiPromptPlan',
    accent: accent,
    background: solidBg(const Color(0xFF0A0C10)),
    elements: [
      // Console header.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.8, 0.03),
        literal: '✦ zealova ai',
        font: CardFontIx.mono,
        fontSize: 24,
        color: cyan,
      ),
      // The prompt — binds to the workout title.
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.8, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.mono,
        fontSize: 26,
        color: white,
        maxLines: 1,
      ),
      // Thinking line.
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.8, 0.03),
        literal: 'thinking ▮▮▮',
        font: CardFontIx.mono,
        fontSize: 22,
        color: accent,
      ),
      // Result checklist.
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.8, 0.16),
        literal:
            '✓ 4 exercises · 16 sets\n✓ recovery-aware\n✓ +2.5% overload',
        font: CardFontIx.mono,
        fontSize: 24,
        color: green,
        lineHeight: 1.6,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
