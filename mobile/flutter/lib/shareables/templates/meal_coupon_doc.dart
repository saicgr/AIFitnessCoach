/// Editable-card preset for the **Meal Coupon** food template — a redeemable
/// voucher: a dashed cut-line border, a "REDEEMED" headline, the calories as
/// the coupon value, a scissors cue, and an expiry-style date.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealCouponDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ticket = Color(0xFFFFF6E2);
  const ink = Color(0xFF2B2418);
  final stamp = Color.lerp(accent, const Color(0xFFCB4B2E), 0.4)!;

  // A dashed cut-line side (vertical divider scaled thin).
  CardElement cut(double x) => dividerEl(
        pos: Offset(x, 0.5),
        size: const Size(0.004, 0.74),
        style: DividerStyle.dashed,
        color: ink.withValues(alpha: 0.35),
        thickness: 2,
      );

  return cardDoc(
    aspect: aspect,
    presetId: 'mealCoupon',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF14110A), accent, 0.16)!,
      const Color(0xFF07060A),
    ]),
    elements: [
      // Voucher body.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.74),
        shape: ShapeKind.rounded,
        fill: ticket,
        cornerRadius: 16,
      ),
      // Dashed cut frame.
      dividerEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.78, 0.004),
        style: DividerStyle.dashed,
        color: ink.withValues(alpha: 0.35),
        thickness: 2,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.78, 0.004),
        style: DividerStyle.dashed,
        color: ink.withValues(alpha: 0.35),
        thickness: 2,
      ),
      cut(0.1),
      cut(0.9),
      iconEl(
        pos: const Offset(0.12, 0.16),
        size: const Size(0.09, 0.04),
        emoji: '✂️',
      ),
      textEl(
        pos: const Offset(0.5, 0.24),
        size: const Size(0.7, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 22,
        color: stamp,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.82, 0.09),
        literal: 'REDEEMED',
        font: 1,
        fontSize: 72,
        color: ink,
        align: TextAlign.center,
        letterSpacing: -1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Coupon value.
      textEl(
        pos: const Offset(0.5, 0.49),
        size: const Size(0.8, 0.15),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 150,
        color: stamp,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.555),
        size: const Size(0.5, 0.03),
        literal: 'CALORIES',
        font: 5,
        fontSize: 18,
        color: ink.withValues(alpha: 0.5),
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.78, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 36,
        color: ink.withValues(alpha: 0.85),
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.62, 0.004),
        style: DividerStyle.dotted,
        color: ink.withValues(alpha: 0.3),
      ),
      iconEl(
        pos: const Offset(0.31, 0.77),
        size: const Size(0.05, 0.03),
        emoji: '🧾',
      ),
      textEl(
        pos: const Offset(0.55, 0.77),
        size: const Size(0.56, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 4,
        fontSize: 17,
        color: ink.withValues(alpha: 0.55),
        align: TextAlign.center,
        letterSpacing: 1.5,
      ),
      watermarkEl(pos: const Offset(0.30, 0.9), color: Colors.white60),
    ],
  );
}
