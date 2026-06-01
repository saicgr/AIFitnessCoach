import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Renders a list of generic, backend-driven "blocks" inline in an AI-coach
/// chat bubble — compact metric cards, charts, stat grids, free text, and
/// dividers.
///
/// The block contract (verbatim from the backend) is:
/// `{"type": <str>, "title"?: <str>, "spec": <Map>}`
///
/// Supported `type`s:
///  - `metric`    → big value + unit, optional subtext + colored delta arrow.
///  - `chart`     → fl_chart line / sparkline / bar from a list of points.
///  - `stat_grid` → a wrap of small labeled stat chips with status colors.
///  - `text`      → styled paragraph.
///  - `divider`   → a thin horizontal rule.
///
/// Forward-compat: any UNKNOWN `type` renders nothing (`SizedBox.shrink()`),
/// so a newer backend can ship block types this client predates without
/// breaking the chat. All parsing is defensive — malformed/empty specs
/// degrade to an empty widget rather than throwing.
class GenericBlocksRenderer extends StatelessWidget {
  final List<Map<String, dynamic>> blocks;

  const GenericBlocksRenderer({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final widget = _buildBlock(context, blocks[i]);
      // Skip anything that rendered to nothing so we don't emit dead spacing.
      if (widget is SizedBox && widget.width == 0 && widget.height == 0) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 10));
      }
      children.add(RepaintBoundary(child: widget));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildBlock(BuildContext context, Map<String, dynamic> block) {
    final type = block['type'];
    if (type is! String) return const SizedBox.shrink();

    final title = block['title'] as String?;
    final spec = block['spec'] is Map
        ? Map<String, dynamic>.from(block['spec'] as Map)
        : const <String, dynamic>{};

    final Widget built;
    switch (type) {
      case 'metric':
        built = _MetricBlock(title: title, spec: spec);
        break;
      case 'chart':
        built = _ChartBlock(title: title, spec: spec);
        break;
      case 'stat_grid':
        built = _StatGridBlock(title: title, spec: spec);
        break;
      case 'text':
        return _TextBlock(spec: spec);
      case 'divider':
        return const _DividerBlock();
      default:
        // Forward-compat: unknown block type renders nothing.
        return const SizedBox.shrink();
    }

    // "Improve even further": a data block may carry an optional `tap_route`
    // (e.g. "/sleep-detail") so tapping the sleep ring / steps chart deep-links
    // into the full metric screen — like Google Health. Only metric/chart/
    // stat_grid get the affordance; these are detail SUB-routes (push is
    // correct; never a StatefulShellRoute branch root — see project memory).
    final tapRoute = spec['tap_route'];
    if (tapRoute is String && tapRoute.isNotEmpty) {
      return _TappableBlock(route: tapRoute, child: built);
    }
    return built;
  }
}

/// Wraps a data block so tapping it deep-links into the full metric screen.
class _TappableBlock extends StatelessWidget {
  final String route;
  final Widget child;

  const _TappableBlock({required this.route, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          try {
            context.push(route);
          } catch (_) {
            // Never let a bad route crash the chat; degrade to no-op.
          }
        },
        child: child,
      ),
    );
  }
}

// ─── Shared parsing helpers ──────────────────────────────────────────────

/// Parse a `#RRGGBB` (or `#AARRGGBB`) hex string into a [Color].
/// Returns null for null/empty/malformed input.
Color? _parseHexColor(Object? raw) {
  if (raw is! String) return null;
  var hex = raw.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) {
    hex = 'ff$hex';
  } else if (hex.length != 8) {
    return null;
  }
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(value);
}

/// Coerce a JSON num/int/double to double; null otherwise.
double? _asDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Render a JSON value (num or str) for display, trimming trailing `.0`.
String _formatValue(Object? v) {
  if (v is num) {
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    return v.toString();
  }
  return v?.toString() ?? '';
}

// ─── metric block ─────────────────────────────────────────────────────────

class _MetricBlock extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> spec;

  const _MetricBlock({this.title, required this.spec});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final value = _formatValue(spec['value']);
    if (value.isEmpty) return const SizedBox.shrink();

    final unit = spec['unit'] as String?;
    final subtext = spec['subtext'] as String?;
    final accent = _parseHexColor(spec['color']) ?? cs.primary;

    final delta = spec['delta'] is Map
        ? Map<String, dynamic>.from(spec['delta'] as Map)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(
              title!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
              if (unit != null && unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: accent.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (delta != null) ...[
                const SizedBox(width: 8),
                _DeltaPill(delta: delta),
              ],
            ],
          ),
          if (subtext != null && subtext.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtext,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final Map<String, dynamic> delta;

  const _DeltaPill({required this.delta});

  @override
  Widget build(BuildContext context) {
    final direction = (delta['direction'] as String?) ?? 'flat';
    final value = _formatValue(delta['value']);
    final unit = delta['unit'] as String?;
    if (value.isEmpty) return const SizedBox.shrink();

    final IconData icon;
    final Color color;
    switch (direction) {
      case 'up':
        icon = Icons.arrow_upward_rounded;
        color = const Color(0xFF22C55E);
        break;
      case 'down':
        icon = Icons.arrow_downward_rounded;
        color = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.remove_rounded;
        color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            unit != null && unit.isNotEmpty ? '$value$unit' : value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── chart block ────────────────────────────────────────────────────────

class _ChartBlock extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> spec;

  const _ChartBlock({this.title, required this.spec});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final rawPoints = spec['points'];
    if (rawPoints is! List || rawPoints.isEmpty) {
      return const SizedBox.shrink();
    }
    final points = rawPoints.map(_asDouble).whereType<double>().toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final chartType = (spec['chart_type'] as String?) ?? 'line';
    final accent = _parseHexColor(spec['color']) ?? cs.primary;
    final unit = spec['unit'] as String?;
    final xLabels = (spec['x_labels'] is List)
        ? (spec['x_labels'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final yMin = _asDouble(spec['y_min']);
    final yMax = _asDouble(spec['y_max']);
    final highlightLast = spec['highlight_last'] == true;
    final isSparkline = chartType == 'sparkline';

    final Widget chart = (chartType == 'bar')
        ? _buildBarChart(
            context: context,
            points: points,
            accent: accent,
            xLabels: xLabels,
            yMin: yMin,
            yMax: yMax,
            highlightLast: highlightLast,
          )
        : _buildLineChart(
            context: context,
            points: points,
            accent: accent,
            xLabels: xLabels,
            yMin: yMin,
            yMax: yMax,
            highlightLast: highlightLast,
            isSparkline: isSparkline,
            unit: unit,
          );

    final chartBox = SizedBox(
      height: isSparkline ? 44 : 140,
      child: chart,
    );

    if (isSparkline && (title == null || title!.isEmpty)) {
      return chartBox;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, isSparkline ? 8 : 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(
              title!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          chartBox,
        ],
      ),
    );
  }

  // y bounds, with a little headroom when not explicitly provided.
  (double, double) _yBounds(List<double> points, double? yMin, double? yMax) {
    var lo = points.reduce((a, b) => a < b ? a : b);
    var hi = points.reduce((a, b) => a > b ? a : b);
    if (lo == hi) {
      // Flat series — pad so the line/bar is visible.
      lo = lo - 1;
      hi = hi + 1;
    } else {
      final pad = (hi - lo) * 0.12;
      lo -= pad;
      hi += pad;
    }
    return (yMin ?? lo, yMax ?? hi);
  }

  Widget _buildLineChart({
    required BuildContext context,
    required List<double> points,
    required Color accent,
    required List<String> xLabels,
    required double? yMin,
    required double? yMax,
    required bool highlightLast,
    required bool isSparkline,
    required String? unit,
  }) {
    final cs = Theme.of(context).colorScheme;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i]),
    ];
    final (lo, hi) = _yBounds(points, yMin, yMax);
    final showAxes = !isSparkline;
    final hasXLabels = showAxes && xLabels.isNotEmpty;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble().clamp(0, double.infinity),
        minY: lo,
        maxY: hi,
        gridData: FlGridData(
          show: showAxes,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: showAxes,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showAxes,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _formatValue(value),
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: hasXLabels,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= xLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    xLabels[idx],
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: accent,
            barWidth: isSparkline ? 1.8 : 2.4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: highlightLast,
              checkToShowDot: (spot, _) =>
                  highlightLast && spot.x == spots.last.x,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: accent,
                strokeWidth: 1.5,
                strokeColor: cs.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: isSparkline ? 0.18 : 0.25),
                  accent.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required BuildContext context,
    required List<double> points,
    required Color accent,
    required List<String> xLabels,
    required double? yMin,
    required double? yMax,
    required bool highlightLast,
  }) {
    final cs = Theme.of(context).colorScheme;
    final (lo, hi) = _yBounds(points, yMin, yMax);
    // Bars read from a baseline; honor an explicit y_min, else start at 0
    // (or the data min when the series dips negative).
    final baseline = yMin ?? (lo < 0 ? lo : 0.0);
    final hasXLabels = xLabels.isNotEmpty;

    return BarChart(
      BarChartData(
        minY: baseline < lo ? baseline : lo,
        maxY: hi,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _formatValue(value),
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: hasXLabels,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= xLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    xLabels[idx],
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i],
                  fromY: baseline,
                  color: (highlightLast && i == points.length - 1)
                      ? accent
                      : accent.withValues(alpha: 0.55),
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── stat_grid block ───────────────────────────────────────────────────────

class _StatGridBlock extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> spec;

  const _StatGridBlock({this.title, required this.spec});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final rawItems = spec['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      return const SizedBox.shrink();
    }
    final items = rawItems
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['label'] != null && e['value'] != null)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Text(
            title!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items) _StatChip(item: item),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final Map<String, dynamic> item;

  const _StatChip({required this.item});

  Color _statusColor(BuildContext context, String? status) {
    switch (status) {
      case 'good':
        return const Color(0xFF22C55E);
      case 'warn':
        return const Color(0xFFF59E0B);
      case 'bad':
        return const Color(0xFFEF4444);
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = item['status'] as String?;
    final color = _statusColor(context, status);
    final hasStatus =
        status == 'good' || status == 'warn' || status == 'bad';

    final label = item['label']?.toString() ?? '';
    final value = _formatValue(item['value']);
    final unit = item['unit'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: hasStatus
            ? color.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasStatus
              ? color.withValues(alpha: 0.35)
              : cs.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: hasStatus ? color : cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit != null && unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: (hasStatus ? color : cs.onSurface)
                        .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── text block ────────────────────────────────────────────────────────────

class _TextBlock extends StatelessWidget {
  final Map<String, dynamic> spec;

  const _TextBlock({required this.spec});

  @override
  Widget build(BuildContext context) {
    final text = spec['text'] as String?;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
        height: 1.4,
      ),
    );
  }
}

// ─── divider block ───────────────────────────────────────────────────────

class _DividerBlock extends StatelessWidget {
  const _DividerBlock();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
