/// Editable-card preset for the **AI Form Check** template — a computer-vision
/// pose overlay on the hero photo: a stick-figure skeleton drawn from joint
/// dots + connector bones in the accent color, an "✦ AI FORM CHECK" eyebrow,
/// and a verdict line. Sells the on-device form-analysis feature. Joints and
/// labels are editable layers.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiPoseCheckDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);

  // Skeleton joints (head, shoulders, hips, knees) in fractional space.
  const joints = <Offset>[
    Offset(0.5, 0.26), // head
    Offset(0.4, 0.42), // L shoulder
    Offset(0.6, 0.42), // R shoulder
    Offset(0.5, 0.55), // pelvis
    Offset(0.42, 0.72), // L knee
    Offset(0.58, 0.72), // R knee
  ];

  return cardDoc(
    aspect: aspect,
    presetId: 'aiPoseCheck',
    accent: accent,
    background: photoBg(binding: const DataBinding(BindingSource.heroImageUrl)),
    elements: [
      // Slight darken for overlay contrast.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x33000000), Color(0x66000000)],
      ),
      // Bones as thin pills between joints (vertical/near-vertical segments).
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.01, 0.28),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      // Joint dots.
      for (final j in joints)
        shapeEl(
          pos: j,
          size: const Size(0.05, 0.028),
          shape: ShapeKind.circle,
          fill: accent,
        ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.84, 0.03),
        literal: '✦ AI FORM CHECK',
        font: CardFontIx.cond,
        fontSize: 18,
        color: accent,
        letterSpacing: 2.6,
        align: TextAlign.center,
      ),
      // Verdict.
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.84, 0.04),
        literal: 'Depth clean · spine neutral · bar path A',
        font: CardFontIx.condMid,
        fontSize: 24,
        color: white,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.955), color: const Color(0xCCFFFFFF)),
    ],
  );
}
