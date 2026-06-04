/// Editable-card preset for the **Agent Log** template — a coding-agent style
/// task trace on a near-black terminal: "✦ zealova agent", a sequence of
/// "↳ task … result" lines, and a green "✓ N tasks · 0.4s" footer. Each log
/// line is an editable mono text layer; the volume line binds to the hero
/// string so it reflects the real session.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiAgentLogDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cyan = Color(0xFF22D3EE);
  const green = Color(0xFF7CFC7C);
  const ink = Color(0xFFCFD2D8);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiAgentLog',
    accent: accent,
    background: solidBg(const Color(0xFF0B0E0B)),
    elements: [
      // Agent header.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.8, 0.03),
        literal: '✦ zealova agent',
        font: CardFontIx.mono,
        fontSize: 24,
        color: cyan,
      ),
      // Task trace.
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.82, 0.04),
        literal: '↳ read workout log ✓',
        font: CardFontIx.mono,
        fontSize: 22,
        color: ink,
      ),
      // Compute volume — binds to hero string for the value.
      textEl(
        pos: const Offset(0.5, 0.51),
        size: const Size(0.82, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 22,
        color: ink,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.57),
        size: const Size(0.82, 0.04),
        literal: '↳ detect PR … bench 225',
        font: CardFontIx.mono,
        fontSize: 22,
        color: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.63),
        size: const Size(0.82, 0.04),
        literal: '↳ plan tomorrow … pull day',
        font: CardFontIx.mono,
        fontSize: 22,
        color: green,
      ),
      // Footer.
      textEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(0.82, 0.04),
        literal: '✓ 5 tasks · 0.4s',
        font: CardFontIx.mono,
        fontSize: 22,
        color: cyan,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
