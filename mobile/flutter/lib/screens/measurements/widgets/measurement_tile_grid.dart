import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/repositories/measurements_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Tile-view fallback when the user toggles away from the body figure. Renders
/// every [MeasurementType] as a compact 2-column tile, grouped by body area.
/// Tap a tile → [onLogRequested] (opens the pre-locked add-measurement sheet).
/// Long-press → full detail screen.
class MeasurementTileGrid extends ConsumerWidget {
  final MeasurementsState state;
  final bool isMetric;

  /// Called with the metric the user wants to log. The parent owns the sheet
  /// so the tile widget doesn't need the whole measurements screen context.
  final void Function(MeasurementType type) onLogRequested;

  const MeasurementTileGrid({
    super.key,
    required this.state,
    required this.isMetric,
    required this.onLogRequested,
  });

  // Each group defines an explicit list of ROWS so paired L/R metrics
  // (Biceps L/R, Forearm L/R, Thigh L/R, Calf L/R) always sit on the same
  // row. A row can hold 1-3 tiles; tiles in a row share width evenly.
  static const _groups = [
    _Group('Body Composition', [
      [MeasurementType.weight, MeasurementType.bodyFat],
    ]),
    _Group('Upper Body', [
      [MeasurementType.neck, MeasurementType.shoulders, MeasurementType.chest],
      [MeasurementType.bicepsLeft, MeasurementType.bicepsRight],
      [MeasurementType.forearmLeft, MeasurementType.forearmRight],
    ]),
    _Group('Core', [
      [MeasurementType.waist, MeasurementType.hips],
    ]),
    _Group('Lower Body', [
      [MeasurementType.thighLeft, MeasurementType.thighRight],
      [MeasurementType.calfLeft, MeasurementType.calfRight],
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.colors(context).accent;

    Widget buildTile(MeasurementType type) {
      return _MetricTile(
        type: type,
        latest: state.summary?.latestByType[type],
        change: state.summary?.changeFromPrevious[type],
        isMetric: isMetric,
        elevated: elevated,
        textPrimary: textPrimary,
        textMuted: textMuted,
        cardBorder: cardBorder,
        accent: accent,
        onTap: () {
          HapticService.light();
          onLogRequested(type);
        },
        onLongPress: () {
          HapticService.light();
          context.push('/measurements/${type.name}');
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in _groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
            child: Text(
              group.title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          for (final row in group.rows)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: SizedBox(
                // Match the previous grid's childAspectRatio (~1.1) so tiles
                // stay square-ish regardless of how many share the row.
                height: _tileHeightForRow(row.length),
                child: Row(
                  children: [
                    for (int i = 0; i < row.length; i++) ...[
                      Expanded(child: buildTile(row[i])),
                      if (i < row.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  // Tile heights tuned for vertical compactness — "just trying to save
  // space". Slightly shorter than square so the whole tile grid reads as
  // a tight, glanceable list.
  double _tileHeightForRow(int count) {
    if (count == 1) return 88;
    if (count == 2) return 92;   // ~150 wide / 92 tall → friendly pair tiles
    return 86;                   // 3 per row: ~94 wide / 86 tall
  }
}

class _Group {
  final String title;
  final List<List<MeasurementType>> rows;
  const _Group(this.title, this.rows);
}

class _MetricTile extends StatelessWidget {
  final MeasurementType type;
  final MeasurementEntry? latest;
  final double? change;
  final bool isMetric;
  final Color elevated;
  final Color textPrimary;
  final Color textMuted;
  final Color cardBorder;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MetricTile({
    required this.type,
    required this.latest,
    required this.change,
    required this.isMetric,
    required this.elevated,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBorder,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  IconData get _icon {
    switch (type) {
      case MeasurementType.weight:
        return Icons.monitor_weight;
      case MeasurementType.bodyFat:
        return Icons.percent;
      case MeasurementType.chest:
        return Icons.accessibility_new;
      case MeasurementType.waist:
      case MeasurementType.hips:
        return Icons.straighten;
      case MeasurementType.bicepsLeft:
      case MeasurementType.bicepsRight:
        return Icons.fitness_center;
      case MeasurementType.thighLeft:
      case MeasurementType.thighRight:
        return Icons.directions_walk;
      case MeasurementType.calfLeft:
      case MeasurementType.calfRight:
        return Icons.directions_run;
      case MeasurementType.neck:
        return Icons.face;
      case MeasurementType.shoulders:
        return Icons.accessibility;
      case MeasurementType.forearmLeft:
      case MeasurementType.forearmRight:
        return Icons.back_hand;
    }
  }

  Color _changeColor() {
    // Weight & body fat: down is good. Muscle circumferences: up is good.
    final lowerIsBetter = type == MeasurementType.weight || type == MeasurementType.bodyFat;
    if (change == null || change!.abs() < 0.1) return textMuted;
    final positive = change! > 0;
    final good = lowerIsBetter ? !positive : positive;
    return good ? AppColors.success : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = latest != null;
    final unit = isMetric ? type.metricUnit : type.imperialUnit;
    final valueText = hasData
        ? '${_stripTrailingZero(latest!.getValueInUnit(isMetric).toStringAsFixed(1))} $unit'
        : '—';
    final borderColor = hasData ? accent.withValues(alpha: 0.3) : cardBorder;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Icon on top — centred — followed by short name then value.
            // 3-per-row tiles are too narrow for a side-by-side icon/label
            // layout, so stack vertically with tight spacing.
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: (hasData ? accent : textMuted).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(_icon, size: 14, color: hasData ? accent : textMuted),
            ),
            // FittedBox.scaleDown keeps the name at base font size on
            // normal phones and shrinks it on narrow screens rather than
            // ellipsizing — "Biceps (L)" / "Forearm (R)" stay readable.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                type.displayName,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      valueText,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasData ? accent : textMuted,
                      ),
                    ),
                  ),
                ),
                if (hasData && change != null && change!.abs() >= 0.1) ...[
                  const SizedBox(width: 2),
                  Icon(
                    change! > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 10,
                    color: _changeColor(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _stripTrailingZero(String s) {
    if (s.contains('.') && s.endsWith('0')) {
      final t = s.substring(0, s.length - 1);
      return t.endsWith('.') ? t.substring(0, t.length - 1) : t;
    }
    return s;
  }
}
