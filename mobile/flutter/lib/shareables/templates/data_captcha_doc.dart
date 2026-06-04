/// Editable-card preset for the **Captcha** data/meme template — the classic
/// "Select all squares with GAINS" reCAPTCHA gag: a blue Google-style header
/// bar, a 3×3 grid where the diagonal tiles are "selected" (volt highlight via
/// the grid-heatmap intensity), and an "I'm not a robot, I lift" footer. Every
/// caption is editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataCaptchaDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const googleBlue = Color(0xFF4285F4);
  const panel = Color(0xFFF1F3F4);
  // Diagonal "selected" pattern over a 3×3 grid (1 = selected, 0 = empty).
  const selected = <double>[1, 0, 0, 0, 1, 0, 0, 0, 1];
  return cardDoc(
    aspect: aspect,
    presetId: 'dataCaptcha',
    accent: volt,
    background: solidBg(panel),
    elements: [
      // Blue prompt header.
      shapeEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.84, 0.16),
        shape: ShapeKind.rounded,
        fill: googleBlue,
        cornerRadius: 12,
      ),
      textEl(
        pos: const Offset(0.5, 0.095),
        size: const Size(0.74, 0.03),
        literal: 'Select all squares with',
        font: CardFontIx.grotesk,
        fontSize: 22,
        color: Colors.white,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.155),
        size: const Size(0.74, 0.05),
        literal: 'GAINS',
        font: CardFontIx.display,
        fontSize: 44,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      // The 3×3 grid — selected diagonal lights up in volt.
      gridHeatmapEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.84, 0.56),
        cells: selected,
        columns: 3,
        cellColor: volt,
        emptyColor: const Color(0xFFDADCE0),
        cellRadius: 6,
        gapFraction: 0.06,
      ),
      // Checkmarks float on the selected tiles (decorative, editable).
      textEl(
        pos: const Offset(0.21, 0.30),
        size: const Size(0.16, 0.1),
        literal: '✓',
        font: CardFontIx.display,
        fontSize: 40,
        color: const Color(0xFF111111),
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.16, 0.1),
        literal: '✓',
        font: CardFontIx.display,
        fontSize: 40,
        color: const Color(0xFF111111),
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.79, 0.74),
        size: const Size(0.16, 0.1),
        literal: '✓',
        font: CardFontIx.display,
        fontSize: 40,
        color: const Color(0xFF111111),
        align: TextAlign.center,
      ),
      // Footer — "not a robot, I lift" + the real verified stat.
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.86, 0.03),
        literal: "I'm not a robot — I lift",
        font: CardFontIx.grotesk,
        fontSize: 20,
        color: const Color(0xFF202124),
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.925),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 22,
        color: googleBlue,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.965), color: const Color(0xFF202124)),
    ],
  );
}
