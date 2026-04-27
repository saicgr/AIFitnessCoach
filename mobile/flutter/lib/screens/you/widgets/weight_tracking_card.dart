import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/user.dart' as app_user;
import '../../../data/repositories/measurements_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Time-range buckets shown above the weight chart. Mirrors the GymBeat
/// reference (D / W / M / 3M / Y) — local to this card; not promoted to a
/// global provider because the range is a private viewing concern.
enum _WeightRange {
  day('D', Duration(days: 1)),
  week('W', Duration(days: 7)),
  month('M', Duration(days: 30)),
  threeMonths('3M', Duration(days: 90)),
  year('Y', Duration(days: 365));

  final String label;
  final Duration window;
  const _WeightRange(this.label, this.window);
}

/// Rich "Weight Tracking" card — current → target with delta-to-go, ALL-TIME
/// chips, range tabs, line chart, lowest/highest tiles, BMI bar with
/// classification, and the most recent entries.
///
/// Reads from `measurementsProvider` only (no extra fetches). Hides itself
/// when the user has no weight history — first-time users still see the
/// log-your-first-weight UX in `EditableFitnessCard` on the Profile sub-tab.
class WeightTrackingCard extends ConsumerStatefulWidget {
  const WeightTrackingCard({super.key});

  @override
  ConsumerState<WeightTrackingCard> createState() =>
      _WeightTrackingCardState();
}

class _WeightTrackingCardState extends ConsumerState<WeightTrackingCard> {
  _WeightRange _range = _WeightRange.week;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final state = ref.watch(measurementsProvider);
    final user = ref.watch(authStateProvider).user;
    final allEntries = state.historyByType[MeasurementType.weight] ?? const [];

    // Empty-state opt-out: keep the card invisible until the user has at
    // least one weight log. EditableFitnessCard already prompts first-log.
    if (allEntries.isEmpty) return const SizedBox.shrink();

    // Sort ascending so chart x-axis flows left→right by time.
    final sortedAsc = [...allEntries]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final unitIsKg = (user?.weightUnit ?? 'kg').toLowerCase() == 'kg';
    final unitLabel = unitIsKg ? 'kg' : 'lbs';

    final latest = sortedAsc.last;
    final currentKg = latest.value;
    final targetKg = user?.targetWeightKg;
    final allTimeMin = sortedAsc
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);
    final allTimeMax = sortedAsc
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    // BMI from the shared helper so classification + color match the rest of
    // the app (Stats / Measurements / hub).
    final summary = state.summary;
    final derived = summary == null
        ? <DerivedMetricType, DerivedMetricResult>{}
        : computeDerivedMetrics(
            summary: summary,
            heightCm: user?.heightCm,
            gender: user?.gender,
          );
    final bmi = derived[DerivedMetricType.bmi];

    // Filter for chart by chosen range. Always keep at least 2 points so
    // fl_chart has a line to draw on a fresh account; fall back to the
    // most-recent two entries when the range window is empty.
    final cutoff = DateTime.now().subtract(_range.window);
    var ranged =
        sortedAsc.where((e) => !e.recordedAt.isBefore(cutoff)).toList();
    if (ranged.length < 2) {
      ranged = sortedAsc.length >= 2
          ? sortedAsc.sublist(sortedAsc.length - 2)
          : [sortedAsc.last, sortedAsc.last];
    }
    final rangeLow =
        ranged.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final rangeHigh =
        ranged.map((e) => e.value).reduce((a, b) => a > b ? a : b);

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
          _buildHeader(textPrimary, textMuted),
          const SizedBox(height: 16),
          _buildHeroRow(
            currentKg: currentKg,
            targetKg: targetKg,
            unitIsKg: unitIsKg,
            unitLabel: unitLabel,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          const SizedBox(height: 10),
          _buildAllTimeChips(
            allTimeMin: allTimeMin,
            allTimeMax: allTimeMax,
            unitIsKg: unitIsKg,
            unitLabel: unitLabel,
          ),
          const SizedBox(height: 16),
          _buildRangeTabs(textMuted),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: _buildChart(
              entries: ranged,
              isDark: isDark,
              textMuted: textMuted,
              cardBorder: cardBorder,
              unitIsKg: unitIsKg,
            ),
          ),
          const SizedBox(height: 14),
          _buildHighLowRow(
            low: rangeLow,
            high: rangeHigh,
            unitIsKg: unitIsKg,
            unitLabel: unitLabel,
            textPrimary: textPrimary,
            textMuted: textMuted,
            isDark: isDark,
          ),
          if (bmi != null) ...[
            const SizedBox(height: 18),
            _buildBmiBlock(bmi: bmi, textPrimary: textPrimary, textMuted: textMuted),
          ],
          const SizedBox(height: 18),
          _buildRecentEntries(
            entries: sortedAsc,
            unitIsKg: unitIsKg,
            unitLabel: unitLabel,
            textPrimary: textPrimary,
            textMuted: textMuted,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ─── Pieces

  Widget _buildHeader(Color textPrimary, Color textMuted) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.monitor_weight_rounded,
              color: AppColors.success, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          'Weight Tracking',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticService.light();
            context.push('/measurements');
          },
          child: Icon(Icons.add_circle_outline_rounded,
              size: 22, color: AppColors.success),
        ),
      ],
    );
  }

  Widget _buildHeroRow({
    required double currentKg,
    required double? targetKg,
    required bool unitIsKg,
    required String unitLabel,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final current = _displayValue(currentKg, unitIsKg);
    final target = targetKg == null ? null : _displayValue(targetKg, unitIsKg);
    final deltaToGoKg =
        targetKg == null ? null : (currentKg - targetKg);

    Color pillColor;
    String pillText;
    if (targetKg == null) {
      pillColor = AppColors.success;
      pillText = 'Set a target';
    } else if (deltaToGoKg!.abs() < 0.1) {
      pillColor = AppColors.success;
      pillText = 'At target';
    } else {
      // Negative pill = need to lose; positive = need to gain. Color stays
      // green either way since "to go" is neutral framing.
      final disp = _displayValue(deltaToGoKg.abs(), unitIsKg);
      final dir = deltaToGoKg > 0 ? '-' : '+';
      pillColor = AppColors.success;
      pillText = '$dir$disp$unitLabel to go';
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        _bigNumber(current, unitLabel, textPrimary, textMuted),
        if (target != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Icon(Icons.arrow_forward_rounded,
                color: textMuted, size: 22),
          ),
          _bigNumber(target, unitLabel, textPrimary, textMuted),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pillText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: pillColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bigNumber(String value, String unit, Color textPrimary, Color textMuted) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -1.1,
              color: textPrimary,
            ),
          ),
          TextSpan(
            text: ' $unit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeChips({
    required double allTimeMin,
    required double allTimeMax,
    required bool unitIsKg,
    required String unitLabel,
  }) {
    Widget chip(String label, IconData icon, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        chip(
          'ALL-TIME HIGH ${_displayValue(allTimeMax, unitIsKg)}$unitLabel',
          Icons.trending_up_rounded,
          AppColors.error,
        ),
        chip(
          'ALL-TIME LOW ${_displayValue(allTimeMin, unitIsKg)}$unitLabel',
          Icons.trending_down_rounded,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildRangeTabs(Color textMuted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = AppColors.success;
    final inactiveBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: inactiveBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _WeightRange.values.map((r) {
          final selected = r == _range;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.selection();
                setState(() => _range = r);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart({
    required List<MeasurementEntry> entries,
    required bool isDark,
    required Color textMuted,
    required Color cardBorder,
    required bool unitIsKg,
  }) {
    final accent = AppColors.success;
    final spots = entries
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), _displayDouble(e.value.value, unitIsKg)))
        .toList();
    final values = spots.map((s) => s.y).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    if ((maxY - minY).abs() < 0.5) {
      // Flat lines look broken — pad ±0.5 so the line sits centered.
      minY -= 0.5;
      maxY += 0.5;
    } else {
      final pad = (maxY - minY) * 0.15;
      minY -= pad;
      maxY += pad;
    }

    final stepCount = entries.length;
    final bottomInterval =
        stepCount <= 1 ? 1.0 : (stepCount / 4).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: cardBorder.withValues(alpha: 0.5),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: bottomInterval,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('M/d').format(entries[i].recordedAt),
                    style: TextStyle(fontSize: 9, color: textMuted),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length < 20,
              getDotPainter: (spot, p, bar, i) => FlDotCirclePainter(
                radius: 3,
                color: accent,
                strokeWidth: 1.5,
                strokeColor: isDark ? AppColors.pureBlack : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }

  Widget _buildHighLowRow({
    required double low,
    required double high,
    required bool unitIsKg,
    required String unitLabel,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: _LowHighTile(
            icon: Icons.south_rounded,
            color: AppColors.success,
            value: '${_displayValue(low, unitIsKg)} $unitLabel',
            label: 'Lowest',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LowHighTile(
            icon: Icons.north_rounded,
            color: AppColors.error,
            value: '${_displayValue(high, unitIsKg)} $unitLabel',
            label: 'Highest',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBmiBlock({
    required DerivedMetricResult bmi,
    required Color textPrimary,
    required Color textMuted,
  }) {
    // Map BMI value (15→40 visual range) to fractional position.
    const bmiMin = 15.0;
    const bmiMax = 40.0;
    final clamped = bmi.value.clamp(bmiMin, bmiMax);
    final fraction = (clamped - bmiMin) / (bmiMax - bmiMin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.accessibility_new_rounded,
                size: 16, color: bmi.color),
            const SizedBox(width: 6),
            Text('BMI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: 0.4,
                )),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: bmi.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${bmi.value.toStringAsFixed(1)} · ${bmi.label}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: bmi.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Gradient bar with thumb.
        LayoutBuilder(builder: (ctx, c) {
          final width = c.maxWidth;
          final thumbX = (width * fraction).clamp(0.0, width - 14);
          return SizedBox(
            height: 18,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6), // Underweight blue
                        Color(0xFF22C55E), // Normal green
                        Color(0xFFF59E0B), // Overweight orange
                        Color(0xFFEF4444), // Obese red
                      ],
                      stops: [0.0, 0.14, 0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: thumbX,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bmi.color,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final s in const ['15', '18.5', '25', '30', '40'])
              Text(s, style: TextStyle(fontSize: 9, color: textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentEntries({
    required List<MeasurementEntry> entries,
    required bool unitIsKg,
    required String unitLabel,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    final recent = entries.reversed.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded,
                size: 16, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              'Recent Entries',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticService.light();
                context.push('/measurements');
              },
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.warning),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < recent.length; i++)
          _RecentEntryRow(
            entry: recent[i],
            previous: i + 1 < entries.length
                ? entries[entries.length - 2 - i]
                : null,
            unitIsKg: unitIsKg,
            unitLabel: unitLabel,
            textPrimary: textPrimary,
            textMuted: textMuted,
            isDark: isDark,
          ),
      ],
    );
  }

  // ─── Unit helpers (storage is always kg)
  double _displayDouble(double kg, bool unitIsKg) =>
      unitIsKg ? kg : kg * 2.2046226218;

  String _displayValue(double kg, bool unitIsKg) {
    final v = _displayDouble(kg, unitIsKg);
    return v.toStringAsFixed(1);
  }
}

class _LowHighTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool isDark;
  const _LowHighTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final tileBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentEntryRow extends StatelessWidget {
  final MeasurementEntry entry;
  final MeasurementEntry? previous;
  final bool unitIsKg;
  final String unitLabel;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  const _RecentEntryRow({
    required this.entry,
    required this.previous,
    required this.unitIsKg,
    required this.unitLabel,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final value = unitIsKg ? entry.value : entry.value * 2.2046226218;
    final dateLabel = _humanDate(entry.recordedAt);
    final delta = previous == null ? 0.0 : (entry.value - previous!.value);
    final showBadge = previous != null && delta.abs() >= 0.05;
    final isUp = delta > 0;
    final badgeColor = isUp ? AppColors.error : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              Text(DateFormat('HH:mm').format(entry.recordedAt),
                  style: TextStyle(fontSize: 11, color: textMuted)),
            ],
          ),
          const Spacer(),
          if (showBadge) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 11,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isUp ? 'HIGH' : 'LOW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            '${value.toStringAsFixed(1)} $unitLabel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 16, color: textMuted),
        ],
      ),
    );
  }

  String _humanDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    final diff = today.difference(dDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('MMM d').format(d);
  }
}

// Avoid unused import warnings — `app_user.User` is used implicitly via the
// auth provider's user field type; this file doesn't need to reach into it
// directly.
// ignore: unused_element
typedef _UnusedUserAlias = app_user.User;
