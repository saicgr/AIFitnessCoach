import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/trend_series_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/trends/trend_chart.dart';

import '../../../l10n/generated/app_localizations.dart';
/// One per-metric section on the Combined Health hub.
///
/// Shows a header (icon + title + the selected-day value), then a
/// weekly / monthly [TrendChart] driven by [trendSeriesProvider]. The
/// week/month toggle re-scopes the chart (plan edge case 17 — the hub still
/// renders every section even when one metric has no data; that section
/// just shows its own empty state).
///
/// For metrics that have a real [TrendMetric] history source the chart is
/// live; metrics without one ([metric] == null) render the value + a short
/// note only, never a fabricated series.
class MetricHistoryCard extends ConsumerStatefulWidget {
  /// Section title (e.g. "Steps").
  final String title;

  /// Header icon + accent.
  final IconData icon;
  final Color color;

  /// The selected-day value text (already formatted), e.g. "8,412 steps".
  /// Null renders a per-section empty state.
  final String? valueText;

  /// Optional secondary line under the value (e.g. HR min/max breakdown).
  final String? subtitleText;

  /// The trend metric to chart. Null → no chart, just the header + note.
  final TrendMetric? metric;

  final bool isDark;

  /// Gap 5 — optional "edit this day's value" affordance. When provided, a
  /// pencil shows in the header; tapping it lets the user correct the
  /// selected day's reading (writes a locked manual override on the backend).
  final VoidCallback? onEdit;

  const MetricHistoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.valueText,
    this.subtitleText,
    required this.metric,
    required this.isDark,
    this.onEdit,
  });

  @override
  ConsumerState<MetricHistoryCard> createState() =>
      _MetricHistoryCardState();
}

class _MetricHistoryCardState extends ConsumerState<MetricHistoryCard> {
  /// Week vs month range toggle for the chart.
  TrendRange _range = TrendRange.d7;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      widget.valueText ?? AppLocalizations.of(context).metricHistoryCardNoDataForThis,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.valueText != null
                            ? textMuted
                            : textMuted.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.subtitleText != null)
                      Text(
                        widget.subtitleText!,
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                  ],
                ),
              ),
              if (widget.onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: textMuted),
                  tooltip: 'Correct this day',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onEdit,
                ),
            ],
          ),
          if (widget.metric != null) ...[
            const SizedBox(height: 12),
            // ── Week / month toggle
            _RangeToggle(
              range: _range,
              isDark: isDark,
              accent: widget.color,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 10),
            _MetricChart(
              metric: widget.metric!,
              range: _range,
              color: widget.color,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final TrendRange range;
  final bool isDark;
  final Color accent;
  final ValueChanged<TrendRange> onChanged;
  const _RangeToggle({
    required this.range,
    required this.isDark,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill('Week', TrendRange.d7),
        const SizedBox(width: 8),
        _pill('Month', TrendRange.d30),
      ],
    );
  }

  Widget _pill(String label, TrendRange r) {
    final selected = range == r;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return GestureDetector(
      onTap: () {
        if (!selected) {
          HapticService.selection();
          onChanged(r);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MetricChart extends ConsumerWidget {
  final TrendMetric metric;
  final TrendRange range;
  final Color color;
  final bool isDark;
  const _MetricChart({
    required this.metric,
    required this.range,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final seriesAsync =
        ref.watch(trendSeriesProvider(TrendSeriesKey(metric, range)));
    return seriesAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          AppLocalizations.of(context).sleepDetailTrendUnavailable,
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ),
      data: (series) {
        if (series.points.length < 2) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              AppLocalizations.of(context).metricHistoryCardTwoOrMoreSynced,
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          );
        }
        return TrendChart(
          height: 160,
          accent: color,
          primary: TrendChartSeries(
            label: metric.displayName,
            unit: series.unit,
            points: series.points,
          ),
        );
      },
    );
  }
}
