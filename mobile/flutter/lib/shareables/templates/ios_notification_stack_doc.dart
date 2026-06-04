/// Editable-card preset for the **iOS Notification Stack** template — a stack
/// of three frosted iOS banner notifications on a blurred wallpaper, oldest at
/// the back (smaller / dimmer) with the freshest, full-size banner on top. Each
/// banner has the volt-accent app glyph, an app name + timestamp header line,
/// and a title/body. The top banner binds to the real workout/stat; the two
/// behind it are editable highlight echoes — the "you've been crushing it"
/// notification-pileup brag.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosNotificationStackDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white60 = Color(0x99FFFFFF);

  // One frosted banner = card + glyph tile + glyph + header + title + body.
  // [dim] 0..1 fades the whole banner back for the stacked-depth illusion.
  List<CardElement> banner3({
    required double cy,
    required double scale,
    required double dim,
    required String app,
    required String time,
    required DataBinding titleBinding,
    String titleLiteral = '',
    DataBinding bodyBinding = DataBinding.none,
    String bodyLiteral = '',
  }) {
    final w = 0.84 * scale;
    final a = (1.0 - dim);
    Color fade(int rgb, double base) =>
        Color(rgb).withValues(alpha: base * a);
    final bannerFill = const Color(0xFF121216).withValues(alpha: 0.35 * a);
    final stroke = const Color(0xFFFFFFFF).withValues(alpha: 0.18 * a);
    final glyphA = accent.withValues(alpha: a);
    return [
      shapeEl(
        pos: Offset(0.5, cy),
        size: Size(w, 0.15),
        shape: ShapeKind.rounded,
        fill: bannerFill,
        stroke: stroke,
        strokeWidth: 1.2,
        cornerRadius: 26,
      ),
      shapeEl(
        pos: Offset(0.5 - w * 0.38, cy - 0.03),
        size: Size(0.07 * scale, 0.04 * scale),
        shape: ShapeKind.rounded,
        gradient: [glyphA, Color.lerp(glyphA, Colors.black, 0.4)!],
        cornerRadius: 12,
      ),
      iconEl(
        pos: Offset(0.5 - w * 0.38, cy - 0.03),
        size: Size(0.05 * scale, 0.03 * scale),
        emoji: '🏋️',
      ),
      // Header: APP · time.
      textEl(
        pos: Offset(0.5 - w * 0.05, cy - 0.045),
        size: Size(w * 0.62, 0.02),
        literal: app,
        font: CardFontIx.cond,
        fontSize: 15 * scale,
        color: fade(0xFFFFFFFF, 0.6),
        letterSpacing: 1.4,
        allCaps: true,
      ),
      textEl(
        pos: Offset(0.5 + w * 0.36, cy - 0.045),
        size: Size(w * 0.22, 0.02),
        literal: time,
        font: CardFontIx.grotesk,
        fontSize: 14 * scale,
        color: fade(0xFFFFFFFF, 0.6),
        align: TextAlign.right,
      ),
      // Title.
      textEl(
        pos: Offset(0.5 - w * 0.05, cy - 0.005),
        size: Size(w * 0.84, 0.035),
        binding: titleBinding,
        literal: titleLiteral,
        font: CardFontIx.condMid,
        fontSize: 26 * scale,
        color: fade(0xFFFFFFFF, 1.0),
        maxLines: 1,
      ),
      // Body.
      textEl(
        pos: Offset(0.5 - w * 0.05, cy + 0.04),
        size: Size(w * 0.84, 0.03),
        binding: bodyBinding,
        literal: bodyLiteral,
        font: CardFontIx.grotesk,
        fontSize: 19 * scale,
        color: fade(0xFFFFFFFF, 0.6),
        maxLines: 1,
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'iosNotificationStack',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
      blurred: true,
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x99000000), Color(0xB3000000)],
      ),
      // Status time at top.
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.6, 0.06),
        literal: '9:41',
        font: 2,
        fontSize: 96,
        color: white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Back banner (oldest, dimmest).
      ...banner3(
        cy: 0.44,
        scale: 0.86,
        dim: 0.45,
        app: 'Zealova',
        time: '2h ago',
        titleBinding: DataBinding.none,
        titleLiteral: 'New personal record 🏆',
        bodyBinding: const DataBinding(BindingSource.highlightLabel, index: 0),
      ),
      // Middle banner.
      ...banner3(
        cy: 0.58,
        scale: 0.92,
        dim: 0.22,
        app: 'Zealova',
        time: '1h ago',
        titleBinding: DataBinding.none,
        titleLiteral: 'Streak extended 🔥',
        bodyBinding: const DataBinding(BindingSource.highlightLabel, index: 1),
      ),
      // Front banner (freshest, the real workout).
      ...banner3(
        cy: 0.74,
        scale: 1.0,
        dim: 0.0,
        app: 'Zealova',
        time: 'now',
        titleBinding: const DataBinding(BindingSource.title),
        bodyBinding: const DataBinding(BindingSource.heroString),
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: white60),
    ],
  );
}
