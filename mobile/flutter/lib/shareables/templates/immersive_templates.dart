/// Editable-card presets for the two **Immersive** templates — a minimal,
/// photo-forward "story" card: a single full-bleed atmospheric photo, a subtle
/// dark scrim for legibility, and only a big title + one key metric + a date
/// stamp + the ⚡ watermark. The whole point is sparseness — let the photo carry
/// the card.
///
/// Cloned from the photo-forward `photoStatsDoc` (full-bleed `photoBg` + a
/// multi-stop `scrimEl`), trimmed to the bare minimum and given two anchorings:
///   - [immersiveBottomDoc]  — text anchored bottom-left (editorial story look).
///   - [immersiveCenterDoc]  — text centered (poster look).
///
/// Photo resolution mirrors how the existing photo templates resolve their
/// background: food / nutrition shares bind to their own photo (`foodImageUrl`)
/// ONLY when one is actually present on the payload. When a food/nutrition
/// share carries no real photo, and for workout-shaped kinds
/// (`workoutComplete`, `personalRecords`, `strength`) that rarely carry a hero
/// image, we fall back to a sensible stock background for the kind via
/// [defaultStockPackNameForKind] — so the card is never blank.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import '../stock_backgrounds.dart';
import 'doc_kit.dart';

/// The full-bleed background for an immersive card.
///
/// Food / nutrition payloads bind to their live photo (`foodImageUrls`, or a
/// user-attached `customPhotoPath`) ONLY when one is actually present — so the
/// renderer can track the live log without ever rendering blank. Every other
/// case (non-food kind, OR a food/nutrition share that carries no real photo)
/// falls back to the first stock background of the pack most relevant to the
/// share kind — guaranteeing an atmospheric photo, never a blank card.
CardBackground _immersiveBg(Shareable data) {
  final isFoodLike = data.kind == ShareableKind.foodLog ||
      data.kind == ShareableKind.nutrition;
  final hasFoodPhoto =
      (data.foodImageUrls != null && data.foodImageUrls!.isNotEmpty) ||
          (data.customPhotoPath != null && data.customPhotoPath!.isNotEmpty);
  // Only bind to the live food photo when the payload ACTUALLY has one;
  // otherwise the binding resolves to null and the card renders blank.
  if (isFoodLike && hasFoodPhoto) {
    return photoBg(
      binding: const DataBinding(BindingSource.foodImageUrl, index: 0),
    );
  }
  // No real photo (or non-food kind): fall back to the kind-appropriate stock
  // pack so the immersive card is never blank.
  // Pick the first asset of the kind-appropriate stock pack as a static path.
  final packName = defaultStockPackNameForKind(data.kind);
  final pack = kStockBackgroundPacks.firstWhere(
    (p) => p.name == packName,
    orElse: () => kStockBackgroundPacks.first,
  );
  final assetPath = pack.assets.isNotEmpty
      ? pack.assets.first
      : kAllStockBackgrounds.first;
  return CardBackground(
    kind: CardBackgroundKind.photo,
    photo: CardPhotoRef(staticPath: assetPath),
    photoFit: BoxFit.cover,
  );
}

/// The single key metric value to spotlight — the first populated highlight's
/// value, bound live so it tracks the log.
DataBinding get _metricValueBinding =>
    const DataBinding(BindingSource.highlightValue, index: 0);

/// The label that names that metric.
DataBinding get _metricLabelBinding =>
    const DataBinding(BindingSource.highlightLabel, index: 0);

/// **Immersive · Bottom** — full-bleed photo, a heavy bottom scrim, and the
/// title + one metric + date stamp stacked bottom-left. Sparse on purpose.
CardDoc immersiveBottomDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'immersiveBottom',
    accent: accent,
    background: _immersiveBg(data),
    elements: [
      // Bottom-weighted scrim so the lower-left text reads cleanly while the
      // top of the photo stays open and atmospheric.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [Color(0x00000000), Color(0x33000000), Color(0xE6000000)],
        stops: const [0.0, 0.5, 1.0],
      ),
      // One key metric — big number, anchored just above the title.
      textEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(0.86, 0.16),
        binding: _metricValueBinding,
        font: CardFontIx.display,
        fontSize: 150,
        align: TextAlign.left,
        maxLines: 1,
        shadow: const ShadowSpec(blur: 22),
      ),
      // The metric's label — a quiet accent eyebrow under the big number.
      textEl(
        pos: const Offset(0.5, 0.795),
        size: const Size(0.86, 0.04),
        binding: _metricLabelBinding,
        font: CardFontIx.cond,
        fontSize: 26,
        color: accent,
        align: TextAlign.left,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      // Big title, anchored bottom-left.
      textEl(
        pos: const Offset(0.5, 0.875),
        size: const Size(0.86, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.serif,
        fontSize: 64,
        align: TextAlign.left,
        maxLines: 2,
        shadow: const ShadowSpec(blur: 18),
      ),
      // Date stamp.
      dateEl(
        pos: const Offset(0.5, 0.94),
        size: const Size(0.86, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        color: Colors.white70,
        fontSize: 24,
      ),
      watermarkEl(pos: const Offset(0.68, 0.97), color: Colors.white70),
    ],
  );
}

/// **Immersive · Center** — full-bleed photo, a soft top-and-bottom scrim, and
/// the title + one metric + date stamp centered as a poster. Sparse on purpose.
CardDoc immersiveCenterDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'immersiveCenter',
    accent: accent,
    background: _immersiveBg(data),
    elements: [
      // Even vignette top + bottom so centered text floats on the photo.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [Color(0x99000000), Color(0x22000000), Color(0x99000000)],
        stops: const [0.0, 0.5, 1.0],
      ),
      // The metric's label — a quiet accent eyebrow above the big number.
      textEl(
        pos: const Offset(0.5, 0.36),
        size: const Size(0.86, 0.04),
        binding: _metricLabelBinding,
        font: CardFontIx.cond,
        fontSize: 26,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      // One key metric — the hero number, centered.
      textEl(
        pos: const Offset(0.5, 0.47),
        size: const Size(0.9, 0.16),
        binding: _metricValueBinding,
        font: CardFontIx.display,
        fontSize: 170,
        align: TextAlign.center,
        maxLines: 1,
        shadow: const ShadowSpec(blur: 24),
      ),
      // Big title under the number.
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.86, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.serif,
        fontSize: 56,
        align: TextAlign.center,
        maxLines: 2,
        shadow: const ShadowSpec(blur: 18),
      ),
      // Date stamp.
      dateEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.86, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        color: Colors.white70,
        fontSize: 24,
        pill: true,
      ),
      watermarkEl(pos: const Offset(0.5, 0.95), color: Colors.white70),
    ],
  );
}
