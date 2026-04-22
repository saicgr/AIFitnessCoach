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

/// Returns bar weight in the given unit for a given equipment type.
double getBarWeight(String? equipment, {required bool useKg}) {
  final eq = (equipment ?? '').toLowerCase();
  if (eq.contains('ez') || eq.contains('curl bar')) {
    return useKg ? 11.0 : 25.0;
  }
  if (eq.contains('trap')) {
    return useKg ? 25.0 : 55.0;
  }
  if (eq.contains('smith')) {
    return useKg ? 9.0 : 20.0;
  }
  // Standard barbell
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
List<double> calculatePlatesPerSide(double totalWeight, double barWeight, {required bool useKg}) {
  final perSide = (totalWeight - barWeight) / 2;
  if (perSide <= 0) return [];

  final availablePlates = useKg ? _platesKg : _platesLbs;
  final plates = <double>[];
  var remaining = perSide;

  for (final plate in availablePlates) {
    while (remaining >= plate - 0.01) {
      plates.add(plate);
      remaining -= plate;
    }
  }

  return plates;
}

/// A realistic side-view barbell visualization with colored weight plates.
class BarbellPlateIndicator extends StatelessWidget {
  final double totalWeight;
  final double barWeight;
  final bool useKg;

  const BarbellPlateIndicator({
    super.key,
    required this.totalWeight,
    required this.barWeight,
    required this.useKg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plates = calculatePlatesPerSide(totalWeight, barWeight, useKg: useKg);
    final unit = useKg ? 'kg' : 'lb';

    // Build description text
    String description;
    if (plates.isEmpty) {
      description = 'Empty bar (${barWeight.toStringAsFixed(barWeight % 1 == 0 ? 0 : 1)} $unit)';
    } else {
      // Group plates for compact display
      final grouped = <double, int>{};
      for (final p in plates) {
        grouped[p] = (grouped[p] ?? 0) + 1;
      }
      final parts = grouped.entries.map((e) {
        final w = e.key % 1 == 0 ? e.key.toInt().toString() : e.key.toStringAsFixed(1);
        return e.value > 1 ? '${e.value}×$w' : w;
      }).join(' + ');
      description = '${barWeight.toStringAsFixed(barWeight % 1 == 0 ? 0 : 1)} $unit bar  ·  $parts per side';
    }

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
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 14,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ],
    );
  }
}

class _BarbellPainter extends CustomPainter {
  final List<double> plates;
  final bool useKg;
  final bool isDark;

  _BarbellPainter({
    required this.plates,
    required this.useKg,
    required this.isDark,
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
        isDark != oldDelegate.isDark;
  }
}
