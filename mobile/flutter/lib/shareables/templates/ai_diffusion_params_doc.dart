/// Editable-card preset for the **Diffusion Params** template — a Stable-
/// Diffusion-style generation config dump in monospace: prompt / steps / cfg /
/// seed lines and a green "render complete" footer, with the volume line bound
/// to the hero string. Plays the "your workout was rendered by AI" gag. Each
/// param line is an editable mono text layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiDiffusionParamsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cyan = Color(0xFF22D3EE);
  const green = Color(0xFF7CFC7C);
  const white = Color(0xFFFFFFFF);
  const ink = Color(0xFFCFD2D8);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiDiffusionParams',
    accent: accent,
    background: solidBg(const Color(0xFF0B0E12)),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.33),
        size: const Size(0.82, 0.03),
        literal: '✦ zealova diffusion',
        font: CardFontIx.mono,
        fontSize: 22,
        color: cyan,
      ),
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.82, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.mono,
        fontSize: 20,
        color: white,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.48),
        size: const Size(0.82, 0.03),
        literal: 'steps: 50   cfg: 9.1',
        font: CardFontIx.mono,
        fontSize: 20,
        color: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.54),
        size: const Size(0.82, 0.03),
        literal: 'seed: 912825',
        font: CardFontIx.mono,
        fontSize: 20,
        color: ink,
      ),
      // Volume line — binds to hero string.
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.82, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: green,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.82, 0.03),
        literal: 'render complete · 0.3s',
        font: CardFontIx.mono,
        fontSize: 20,
        color: cyan,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
