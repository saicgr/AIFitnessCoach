import 'package:flutter/material.dart';

import '../core/constants/app_spacing.dart';
import '../core/constants/stat_typography.dart';
import '../core/theme/theme_colors.dart';
import 'glass_card.dart';

/// One cell in a [MetricGrid]: a big glanceable number + a small muted label.
class MetricCell {
  final String label;
  final String value;
  final String? unit;

  /// Per-cell accent for the number. Falls back to the grid's default.
  final Color? accent;
  final IconData? icon;

  const MetricCell({
    required this.label,
    required this.value,
    this.unit,
    this.accent,
    this.icon,
  });
}

/// A clean, always-visible stat grid — the Gravl "2×N" look (Duration / Energy /
/// Volume / Records …). Replaces ad-hoc collapsible stat rows so every metric is
/// glanceable at once. Built on [GlassSurface] + [StatNumber], theme-aware via
/// [ThemeColors]; never hardcodes a color.
class MetricGrid extends StatelessWidget {
  final List<MetricCell> items;
  final int columns;
  final double spacing;

  /// Number size for each cell (defaults to [StatType.secondary]).
  final double numberSize;

  const MetricGrid({
    super.key,
    required this.items,
    this.columns = 2,
    this.spacing = 10,
    this.numberSize = StatType.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      final rowItems = items.sublist(
        i,
        (i + columns) > items.length ? items.length : i + columns,
      );
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var c = 0; c < columns; c++) ...[
            if (c > 0) SizedBox(width: spacing),
            Expanded(
              child: c < rowItems.length
                  ? _MetricTile(cell: rowItems[c], numberSize: numberSize)
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
      if (i + columns < items.length) rows.add(SizedBox(height: spacing));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _MetricTile extends StatelessWidget {
  final MetricCell cell;
  final double numberSize;

  const _MetricTile({required this.cell, required this.numberSize});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = cell.accent ?? c.textPrimary;
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (cell.icon != null) ...[
                Icon(cell.icon, size: 13, color: c.textMuted),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  cell.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: StatType.labelSm,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StatNumber(
            value: cell.value,
            unit: cell.unit,
            size: numberSize,
            color: accent,
          ),
        ],
      ),
    );
  }
}
