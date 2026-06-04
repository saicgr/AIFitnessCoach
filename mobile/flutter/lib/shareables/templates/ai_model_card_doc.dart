/// Editable-card preset for the **Model Card** template — an ML "model card"
/// framing of the lifter: "ZealovaCoach-v3 // your personal model", with
/// trained-on / params / accuracy / last-lift rows in monospace. The last-lift
/// line binds to the hero string. Each field row is an editable mono layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiModelCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const green = Color(0xFF7CFC7C);
  const white = Color(0xFFFFFFFF);
  const dim = Color(0xFF888888);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiModelCard',
    accent: accent,
    background: solidBg(const Color(0xFF0B0E12)),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.33),
        size: const Size(0.82, 0.04),
        literal: 'ZealovaCoach-v3',
        font: CardFontIx.mono,
        fontSize: 28,
        color: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.39),
        size: const Size(0.82, 0.03),
        literal: '// your personal model',
        font: CardFontIx.mono,
        fontSize: 18,
        color: dim,
      ),
      textEl(
        pos: const Offset(0.5, 0.47),
        size: const Size(0.82, 0.03),
        literal: 'trained on: 127 sessions',
        font: CardFontIx.mono,
        fontSize: 20,
        color: white,
      ),
      textEl(
        pos: const Offset(0.5, 0.53),
        size: const Size(0.82, 0.03),
        literal: 'params: you',
        font: CardFontIx.mono,
        fontSize: 20,
        color: white,
      ),
      textEl(
        pos: const Offset(0.5, 0.59),
        size: const Size(0.82, 0.03),
        literal: 'accuracy: getting stronger',
        font: CardFontIx.mono,
        fontSize: 20,
        color: green,
      ),
      // Last lift — binds to hero string.
      textEl(
        pos: const Offset(0.5, 0.65),
        size: const Size(0.82, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: accent,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
