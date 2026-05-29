import 'package:flutter/material.dart';

/// One source of truth for the size of glanceable stat numbers.
///
/// The product goal (see the "big, glanceable stats" redesign) is that every
/// stats surface reads like a modern health dashboard: a single bold number
/// that you can take in at a glance, with a small muted label beneath it.
/// Instead of every widget inventing its own `fontSize`, they all pull from
/// this tiered scale so the look is identical app-wide.
///
/// Mirrors the documented-constants pattern of [AppSpacing]/[AppRadius].
///
/// ```dart
/// StatNumber(value: '98.7', unit: 'kg', size: StatType.hero, color: accent)
/// Text('Weight', style: TextStyle(fontSize: StatType.label, ...))
/// ```
class StatType {
  StatType._();

  // ── Number sizes ──────────────────────────────────────────────────────────
  // Use with [StatNumber] (or FontWeight.w700 + height 1.0 + tabular figures).

  /// 46px — the single focal metric on a card (body-weight avg, fitness score).
  static const double hero = 46;

  /// 34px — two-up metric cards (weight / body-fat side by side).
  static const double primary = 34;

  /// 24px — 3–4-up grids, quick-stat rows, secondary tiles.
  static const double secondary = 24;

  /// 19px — width-constrained spots: pills, inline strips.
  static const double compact = 19;

  /// 17px — inline badges inside list rows (decoration, not a hero).
  static const double badge = 17;

  // ── Label sizes ─────────────────────────────────────────────────────────
  // Always muted, w500/600 — small on purpose so the number dominates.

  /// 12px — the standard tile label under a number.
  static const double label = 12;

  /// 11px — tighter label for compact tiles.
  static const double labelSm = 11;

  /// Negative tracking tightens big numbers so they read as one unit. Only
  /// applied to [hero]/[primary]; smaller sizes keep `0` to avoid cramping
  /// multi-digit values.
  static double letterSpacingFor(double size) =>
      size >= primary ? -0.5 : 0.0;
}

/// A big, glanceable stat number with an optional smaller trailing unit.
///
/// Why a shared widget instead of raw `Text`:
///  * **No overflow, ever.** Wrapped in `FittedBox(scaleDown)` so a long or
///    localized value ("12,340 kg", a large step count) shrinks to fit rather
///    than clipping — critical on SE-class devices.
///  * **No jitter.** `FontFeature.tabularFigures()` keeps every digit the same
///    width, so live-ticking / count-up numbers don't shuffle horizontally.
///  * **Consistent weight + line-height.** `w700`, `height: 1.0` everywhere.
///
/// [color] is required — this widget never hardcodes a color, so callers keep
/// their accent / theme / macro-color logic.
class StatNumber extends StatelessWidget {
  final String value;
  final String? unit;
  final double size;
  final Color color;

  /// Defaults to a muted derivative of [color] when null.
  final Color? unitColor;
  final FontWeight weight;

  /// How the number aligns inside the space the parent gives it.
  final Alignment alignment;

  const StatNumber({
    super.key,
    required this.value,
    required this.size,
    required this.color,
    this.unit,
    this.unitColor,
    this.weight = FontWeight.w700,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final unitSize = (size * 0.42).clamp(11.0, 18.0);
    final resolvedUnitColor = unitColor ?? color.withValues(alpha: 0.6);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: RichText(
        maxLines: 1,
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: size,
                fontWeight: weight,
                color: color,
                height: 1.0,
                letterSpacing: StatType.letterSpacingFor(size),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (unit != null && unit!.isNotEmpty)
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: unitSize,
                  fontWeight: FontWeight.w600,
                  color: resolvedUnitColor,
                  height: 1.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
