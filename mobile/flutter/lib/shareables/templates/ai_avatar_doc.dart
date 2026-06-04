/// Editable-card preset for the **AI Avatar** template — a stylized AI-art
/// portrait: the user's hero photo under a purple→cyan diffusion wash, an inset
/// hairline frame, an "✦ AI AVATAR" provenance chip, and an Anton name + level
/// strap that binds to the user display name. Reads like a generated game
/// character card.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiAvatarDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiAvatar',
    accent: accent,
    background: photoBg(binding: const DataBinding(BindingSource.heroImageUrl)),
    elements: [
      // Diffusion color wash.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [
          Color(0x597C3AED),
          Color(0x00000000),
          Color(0x4D22D3EE),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      // Bottom legibility scrim.
      scrimEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(1, 0.36),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      // Inset hairline frame.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.92, 0.94),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: const Color(0x4DFFFFFF),
        strokeWidth: 1.4,
        cornerRadius: 16,
      ),
      // Provenance chip.
      shapeEl(
        pos: const Offset(0.2, 0.08),
        size: const Size(0.28, 0.045),
        shape: ShapeKind.rounded,
        fill: const Color(0x80000000),
        cornerRadius: 9,
      ),
      textEl(
        pos: const Offset(0.2, 0.08),
        size: const Size(0.28, 0.035),
        literal: '✦ AI AVATAR',
        font: CardFontIx.cond,
        fontSize: 16,
        color: white,
        align: TextAlign.center,
      ),
      // Name + level strap — binds to display name.
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.88, 0.06),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.display,
        fontSize: 50,
        color: white,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.955), color: const Color(0xCCFFFFFF)),
    ],
  );
}
