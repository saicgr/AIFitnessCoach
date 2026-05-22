/// Editable-card preset — **Soft Card**: the meal photo in a rounded frame
/// floating with a soft shadow on an off-white pastel ground, a delicate
/// thin-serif title and the macros as small outlined pill chips.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc softCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // An off-white pastel ground, faintly tinted toward the accent.
  final ground = Color.lerp(const Color(0xFFF6F4EF), accent, 0.08)!;
  const ink = Color(0xFF3A3733);
  const muted = Color(0xFF8A857C);

  return cardDoc(
    aspect: aspect,
    presetId: 'softCard',
    accent: accent,
    background: solidBg(ground),
    elements: [
      // Floating photo in a rounded frame with a soft drop shadow.
      _softPhoto(),
      // Eyebrow above the title.
      textEl(
        pos: const Offset(0.5, 0.67),
        size: const Size(0.7, 0.035),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 2,
        fontSize: 20,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
        maxLines: 1,
      ),
      // Delicate thin-serif title.
      textEl(
        pos: const Offset(0.5, 0.75),
        size: const Size(0.82, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: 2,
        fontSize: 50,
        color: ink,
        align: TextAlign.center,
        lineHeight: 1.05,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Macros as small outlined pill chips.
      chipsEl(
        pos: const Offset(0.5, 0.85),
        size: const Size(0.84, 0.06),
        layout: ChipLayout.row,
        maxItems: 3,
        chipColor: const Color(0x00000000),
        textColor: muted,
        fontSize: 20,
      ),
      watermarkEl(
        pos: const Offset(0.34, 0.93),
        color: muted.withValues(alpha: 0.7),
        iconSize: 16,
        fontSize: 11,
      ),
    ],
  );
}

/// The floating photo element — extracted so its soft-shadow effect stays
/// readable. A rounded frame, gentle white border, large blurred shadow.
CardElement _softPhoto() => CardElement(
      id: CardDoc.newId(),
      type: CardElementType.photo,
      transform: const ElementTransform(
        position: Offset(0.5, 0.36),
        size: Size(0.68, 0.46),
      ),
      effects: const ElementEffects(
        shadow: ShadowSpec(
          color: Color(0x33000000),
          blur: 48,
          offset: Offset(0, 24),
        ),
      ),
      props: const PhotoProps(
        mask: PhotoMask.rounded,
        cornerRadius: 44,
        frameColor: Color(0xFFFFFFFF),
        frameWidth: 10,
      ),
    );
