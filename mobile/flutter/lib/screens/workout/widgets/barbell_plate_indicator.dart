import 'package:flutter/material.dart';

/// Standard plate weights available in gyms (in lbs).
const _platesLbs = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

/// Standard plate weights available in gyms (in kg).
const _platesKg = [20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

/// Plate visual properties: height, width (thickness), and color.
class _PlateStyle {
  final double height;
  final double width;
  final Color color;
  final Color borderColor;

  const _PlateStyle({
    required this.height,
    required this.width,
    required this.color,
    required this.borderColor,
  });
}

/// Maps plate weight (lbs) to visual style.
final _plateStylesLbs = <double, _PlateStyle>{
  45.0: const _PlateStyle(height: 42, width: 9, color: Color(0xFFD32F2F), borderColor: Color(0xFFB71C1C)),
  35.0: const _PlateStyle(height: 38, width: 8, color: Color(0xFFF9A825), borderColor: Color(0xFFF57F17)),
  25.0: const _PlateStyle(height: 34, width: 7, color: Color(0xFF388E3C), borderColor: Color(0xFF1B5E20)),
  10.0: const _PlateStyle(height: 26, width: 6, color: Color(0xFF1976D2), borderColor: Color(0xFF0D47A1)),
  5.0:  const _PlateStyle(height: 20, width: 5, color: Color(0xFFBDBDBD), borderColor: Color(0xFF9E9E9E)),
  2.5:  const _PlateStyle(height: 16, width: 4, color: Color(0xFF757575), borderColor: Color(0xFF616161)),
};

/// Maps plate weight (kg) to visual style.
final _plateStylesKg = <double, _PlateStyle>{
  20.0:  const _PlateStyle(height: 42, width: 9, color: Color(0xFFD32F2F), borderColor: Color(0xFFB71C1C)),
  15.0:  const _PlateStyle(height: 38, width: 8, color: Color(0xFFF9A825), borderColor: Color(0xFFF57F17)),
  10.0:  const _PlateStyle(height: 34, width: 7, color: Color(0xFF388E3C), borderColor: Color(0xFF1B5E20)),
  5.0:   const _PlateStyle(height: 26, width: 6, color: Color(0xFF1976D2), borderColor: Color(0xFF0D47A1)),
  2.5:   const _PlateStyle(height: 20, width: 5, color: Color(0xFFBDBDBD), borderColor: Color(0xFF9E9E9E)),
  1.25:  const _PlateStyle(height: 16, width: 4, color: Color(0xFF757575), borderColor: Color(0xFF616161)),
};

/// Bar-type keys recognized by the picker + plate calculator. Centralized
/// so the picker UI, the persistence layer, and the indicator widget all
/// agree on the same string identifiers.
///
/// Contract for callers: when [getBarWeight] returns `null`, the bar is a
/// FIXED/PRE-LOADED bar — the labeled weight IS the total. Plate-math callers
/// MUST short-circuit and skip [calculatePlatesPerSide].
const fixedPreloadedBarKey = 'fixed_preloaded';
const presetCurlBarKey = 'preset_curl_bar';
const safetySquatBarKey = 'safety_squat_bar';
const camberedBarKey = 'cambered_bar';
const womensOlympicBarKey = 'womens_barbell';
const techniqueBarKey = 'technique_bar';
const standardBarbellKey = 'barbell';
const ezCurlBarKey = 'ez_curl_bar';
const trapBarKey = 'trap_bar';
const smithMachineKey = 'smith_machine';

/// Common labeled total weights for short fixed/preloaded straight bars.
/// Stored in lb (the project's default workout unit per `feedback_weight_units`).
const fixedPreloadedBarPresetsLb = <double>[5, 10, 12, 15, 20, 25, 30, 35];

/// Common labeled total weights for gym fixed EZ-curl bars (5 lb increments).
const presetCurlBarPresetsLb = <double>[
  20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 90, 100, 110,
];

/// True if the given bar key represents a fixed / pre-loaded bar where the
/// labeled total weight IS the bar — no plates ever go on.
bool isFixedBar(String? barKey) {
  if (barKey == null) return false;
  return barKey == fixedPreloadedBarKey || barKey == presetCurlBarKey;
}

/// Returns bar weight in the given unit for a given equipment / bar-type key.
///
/// For FIXED/PRE-LOADED bars ([fixedPreloadedBarKey], [presetCurlBarKey]),
/// the labeled weight IS the total — no plates go on. This function returns
/// `0` in that case so existing arithmetic callers don't crash; callers
/// rendering plate math MUST first check [isFixedBar] and skip the math.
double getBarWeight(String? equipment, {required bool useKg}) {
  final eq = (equipment ?? '').toLowerCase();
  // Fixed / pre-loaded bars first — the labeled weight IS the total.
  if (eq == fixedPreloadedBarKey ||
      eq.contains('fixed bar') ||
      eq.contains('preloaded')) {
    return 0;
  }
  if (eq == presetCurlBarKey || eq.contains('preset curl')) {
    return 0;
  }
  // Specialty bars (always have plate math).
  if (eq == safetySquatBarKey || eq.contains('safety squat')) {
    return useKg ? 30.0 : 65.0;
  }
  if (eq == camberedBarKey || eq.contains('cambered')) {
    return useKg ? 23.0 : 50.0;
  }
  if (eq == techniqueBarKey || eq.contains('technique')) {
    return useKg ? 7.0 : 15.0;
  }
  if (eq == womensOlympicBarKey ||
      eq.contains("women's") ||
      eq.contains('womens')) {
    return useKg ? 15.0 : 35.0;
  }
  if (eq.contains('ez') || eq.contains('curl bar')) {
    return useKg ? 11.0 : 25.0;
  }
  if (eq.contains('trap')) {
    return useKg ? 25.0 : 55.0;
  }
  if (eq.contains('smith')) {
    return useKg ? 9.0 : 20.0;
  }
  // Standard barbell.
  return useKg ? 20.0 : 45.0;
}

/// Equipment strings that are explicitly non-barbell. When set, we must NOT
/// fall through to name-based heuristics (otherwise "Bulgarian Split Squats"
/// with equipment="bodyweight" gets misclassified as a barbell lift).
const _nonBarbellEquipment = <String>[
  'bodyweight', 'body weight', 'body-weight',
  'dumbbell', 'dumbbells',
  'kettlebell', 'kettlebells',
  'machine', 'cable', 'cables',
  'band', 'bands', 'resistance band', 'resistance bands',
  'medicine ball', 'medicine_ball', 'med ball',
  'stability ball', 'swiss ball', 'bosu',
  'weight plate', 'weight_plate', 'plate',
  'bench', 'box', 'foam roller', 'jump rope',
  'trx', 'suspension',
  'sandbag', 'sled', 'rope',
  'none', 'no equipment',
];

/// Squat variants that are typically done with dumbbells or bodyweight, NOT
/// barbell. Used to suppress the `name.contains('squat')` fallback.
const _nonBarbellSquatVariants = <String>[
  'goblet', 'dumbbell', 'kettlebell',
  'bulgarian', 'split squat', 'split-squat',
  'pistol', 'shrimp', 'cossack', 'sissy',
  'wall sit', 'wall squat',
  'bodyweight', 'air squat',
  'jump squat', 'jumping squat',
  'banded', 'resistance band',
];

/// Returns true if the equipment type uses a barbell.
/// Also checks exercise name as fallback (e.g., "Barbell bench press"
/// may have equipment=null but name clearly indicates barbell).
///
/// Invariant: when `equipment` is an explicit non-barbell value (like
/// "bodyweight"), we return false without consulting the name heuristic —
/// otherwise Bulgarian Split Squats / goblet squats get misclassified.
bool isBarbell(String? equipment, {String? exerciseName}) {
  final eq = (equipment ?? '').trim().toLowerCase();
  if (eq.contains('barbell') ||
      eq.contains('ez bar') ||
      eq.contains('ez curl') ||
      eq.contains('trap bar') ||
      eq.contains('smith')) {
    return true;
  }
  // If equipment is an explicit non-barbell value, trust it — do NOT fall
  // through to name-based guessing.
  if (eq.isNotEmpty && _nonBarbellEquipment.any(eq.contains)) {
    return false;
  }
  // Fallback: check exercise name only when equipment is null/empty/unknown.
  if (exerciseName != null) {
    final name = exerciseName.toLowerCase();
    if (name.contains('barbell') ||
        name.contains('bench press') ||
        name.contains('deadlift')) {
      return true;
    }
    if (name.contains('squat') &&
        !_nonBarbellSquatVariants.any(name.contains)) {
      return true;
    }
  }
  return false;
}

/// Calculates which plates go on each side of the barbell.
/// Returns a list of plate weights per side (largest first, closest to collar).
///
/// For fixed / pre-loaded bars, callers should pass `barType` so we can
/// short-circuit and return an empty list (the bar IS the labeled weight,
/// nothing goes on it).
List<double> calculatePlatesPerSide(
  double totalWeight,
  double barWeight, {
  required bool useKg,
  String? barType,
  List<double>? availablePlates,
}) {
  if (isFixedBar(barType)) return const [];
  final perSide = (totalWeight - barWeight) / 2;
  if (perSide <= 0) return [];

  final platesList = availablePlates ?? (useKg ? _platesKg : _platesLbs);
  final plates = <double>[];
  var remaining = perSide;

  for (final plate in platesList) {
    while (remaining >= plate - 0.01) {
      plates.add(plate);
      remaining -= plate;
    }
  }

  return plates;
}

/// Computes the smallest plate increment achievable per-side with the given
/// available plates. Used to surface availability mismatches when, e.g., the
/// user's gym lacks 1.25 lb micro-plates and the target needs them.
double smallestPlateIncrement({required bool useKg, List<double>? available}) {
  final list = available ?? (useKg ? _platesKg : _platesLbs);
  if (list.isEmpty) return useKg ? 1.25 : 2.5;
  return list.reduce((a, b) => a < b ? a : b);
}

/// A realistic side-view barbell visualization with colored weight plates.
///
/// When [barType] resolves to a fixed/preloaded bar (see [isFixedBar]),
/// the visualization renders a short straight bar with no plates and the
/// caption surfaces "fixed bar" so the user understands the labeled weight
/// IS the total — there is no plate math.
class BarbellPlateIndicator extends StatelessWidget {
  final double totalWeight;
  final double barWeight;
  final bool useKg;

  /// Optional bar-type key (see constants in this file). When provided, used
  /// to detect fixed / pre-loaded bars and disable plate math.
  final String? barType;

  /// Optional list of plate weights actually available at the user's gym
  /// (in the active unit). When provided, plate math will skip plates outside
  /// this list and a small inline warning is shown if a needed denomination
  /// is missing.
  final List<double>? availablePlates;

  const BarbellPlateIndicator({
    super.key,
    required this.totalWeight,
    required this.barWeight,
    required this.useKg,
    this.barType,
    this.availablePlates,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fixed = isFixedBar(barType);
    final plates = fixed
        ? const <double>[]
        : calculatePlatesPerSide(
            totalWeight,
            barWeight,
            useKg: useKg,
            barType: barType,
            availablePlates: availablePlates,
          );
    final unit = useKg ? 'kg' : 'lb';

    // Compute ideal plates against the full standard set; if the user has
    // a restricted plate kit we surface the mismatch.
    final ideal = fixed
        ? const <double>[]
        : calculatePlatesPerSide(totalWeight, barWeight, useKg: useKg);
    final missing = <double>{};
    if (!fixed && availablePlates != null) {
      final avail = availablePlates!.toSet();
      for (final p in ideal) {
        if (!avail.contains(p)) missing.add(p);
      }
    }

    String formatWeight(double w) =>
        w % 1 == 0 ? w.toStringAsFixed(0) : w.toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

    // Build description text.
    String description;
    if (fixed) {
      description =
          '${formatWeight(totalWeight)} $unit · fixed bar (no plates)';
    } else if (plates.isEmpty) {
      description = 'Empty bar (${formatWeight(barWeight)} $unit)';
    } else {
      // Group plates for compact display.
      final grouped = <double, int>{};
      for (final p in plates) {
        grouped[p] = (grouped[p] ?? 0) + 1;
      }
      final parts = grouped.entries.map((e) {
        final w = formatWeight(e.key);
        return e.value > 1 ? '${e.value}×$w' : w;
      }).join(' + ');
      description = '${formatWeight(barWeight)} $unit bar · $parts per side';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Below 360 pt, hide the leading lock icon to free horizontal space.
        final isNarrow = constraints.maxWidth < 360;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: CustomPaint(
                size: const Size(double.infinity, 56),
                painter: _BarbellPainter(
                  plates: plates,
                  useKg: useKg,
                  isDark: isDark,
                  fixedBar: fixed,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (fixed && !isNarrow) ...[
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Plates needed: ${ideal.toSet().map(formatWeight).join(' + ')}'
                  ' — ${missing.map(formatWeight).join(', ')} '
                  '${missing.length > 1 ? 'are' : 'is'} unavailable. '
                  'Try a nearby weight.',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFFF9A825),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BarbellPainter extends CustomPainter {
  final List<double> plates;
  final bool useKg;
  final bool isDark;

  /// When true, render a SHORT straight bar with no plates and no end caps —
  /// represents a fixed/pre-loaded bar.
  final bool fixedBar;

  _BarbellPainter({
    required this.plates,
    required this.useKg,
    required this.isDark,
    this.fixedBar = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final centerX = size.width / 2;
    final styles = useKg ? _plateStylesKg : _plateStylesLbs;

    // Bar dimensions
    const barHeight = 6.0;
    const collarWidth = 4.0;
    const collarHeight = 12.0;
    const endCapWidth = 3.0;
    const endCapHeight = 10.0;

    // Fixed/pre-loaded bar: short straight bar, modest grippy end caps,
    // no removable plates. The labeled weight IS the total.
    if (fixedBar) {
      final barPaint = Paint()
        ..color = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575)
        ..style = PaintingStyle.fill;
      final barHalf = (size.width / 4).clamp(28.0, 48.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(centerX, centerY),
              width: barHalf * 2,
              height: barHeight + 1),
          const Radius.circular(2.5),
        ),
        barPaint,
      );
      // Grippy ends — slightly fatter blocks to imply a labeled fixed bar.
      for (final side in [-1.0, 1.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(centerX + side * barHalf, centerY),
                width: 7,
                height: 16),
            const Radius.circular(1.5),
          ),
          barPaint,
        );
      }
      return;
    }

    // Calculate total plate width per side
    double totalPlateWidth = 0;
    for (final plate in plates) {
      final style = styles[plate];
      totalPlateWidth += (style?.width ?? 6) + 1; // +1 for gap
    }

    // Bar extends from plates to end caps
    const minBarHalf = 40.0;
    final barHalfLength = (totalPlateWidth + collarWidth + endCapWidth + 12).clamp(minBarHalf, size.width / 2 - 4);

    // Draw bar
    final barPaint = Paint()
      ..color = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, centerY), width: barHalfLength * 2, height: barHeight),
        const Radius.circular(2),
      ),
      barPaint,
    );

    // Draw plates and collars on both sides
    for (final side in [-1.0, 1.0]) {
      // Collar
      final collarX = centerX + side * (barHalfLength - totalPlateWidth - collarWidth - endCapWidth - 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(collarX, centerY), width: collarWidth, height: collarHeight),
          const Radius.circular(1),
        ),
        barPaint,
      );

      // End cap
      final endCapX = centerX + side * (barHalfLength - endCapWidth / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(endCapX, centerY), width: endCapWidth, height: endCapHeight),
          const Radius.circular(1),
        ),
        barPaint,
      );

      // Plates (largest closest to collar)
      var plateX = collarX + side * (collarWidth / 2 + 2);
      for (final plate in plates) {
        final style = styles[plate];
        if (style == null) continue;

        final pw = style.width;
        final ph = style.height;
        final x = plateX + side * pw / 2;

        // Plate body
        final platePaint = Paint()
          ..color = style.color
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, centerY), width: pw, height: ph),
            const Radius.circular(1.5),
          ),
          platePaint,
        );

        // Plate border
        final borderPaint = Paint()
          ..color = style.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, centerY), width: pw, height: ph),
            const Radius.circular(1.5),
          ),
          borderPaint,
        );

        plateX += side * (pw + 1);
      }
    }
  }

  @override
  bool shouldRepaint(_BarbellPainter oldDelegate) {
    return plates != oldDelegate.plates ||
        useKg != oldDelegate.useKg ||
        isDark != oldDelegate.isDark ||
        fixedBar != oldDelegate.fixedBar;
  }
}
