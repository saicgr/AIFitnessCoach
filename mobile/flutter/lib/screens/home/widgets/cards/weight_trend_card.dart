import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/models/hormonal_health.dart';
import '../../../../data/providers/hormonal_health_provider.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../widgets/charts/cycle_phase_chart_overlay.dart';

// ════════════════════════════════════════════════════════════════════════
// Cycle-aware weight intelligence (Phase G — MacroFactor 1.1 / 1.3 / 1.11 /
// 1.19).
//
// The home weight-trend card becomes cycle-aware so luteal-phase water
// retention never reads as a discouraging "gain". The data comes from the
// backend `GET /nutrition/adaptive/{user_id}/cycle-aware` endpoint, which
// returns a phase-tagged weigh-in series, a cycle-aware trend, a
// `hold_calorie_target` flag for the pre-period week, and a "same point last
// cycle" comparison.
//
// All of this is a clean no-op for users without cycle tracking enabled:
// `_cycleAwareWeightProvider` returns null and the card renders exactly as
// before.
// ════════════════════════════════════════════════════════════════════════

/// One phase-tagged weigh-in from the cycle-aware adaptive endpoint.
class CycleTaggedWeighIn {
  final DateTime date;
  final double weightKg;
  final CyclePhase? phase;

  const CycleTaggedWeighIn({
    required this.date,
    required this.weightKg,
    this.phase,
  });

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    final d = DateTime.tryParse(s);
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  static CyclePhase? _parsePhase(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'menstrual':
        return CyclePhase.menstrual;
      case 'follicular':
        return CyclePhase.follicular;
      case 'ovulation':
        return CyclePhase.ovulation;
      case 'luteal':
        return CyclePhase.luteal;
      default:
        return null;
    }
  }

  static CycleTaggedWeighIn? fromJson(Map<String, dynamic> json) {
    final date = _parseDate(json['date'] ?? json['logged_at']);
    final w = json['weight_kg'];
    if (date == null || w == null) return null;
    final kg = w is num ? w.toDouble() : double.tryParse(w.toString());
    if (kg == null) return null;
    return CycleTaggedWeighIn(
      date: date,
      weightKg: kg,
      phase: _parsePhase(json['cycle_phase'] ?? json['phase']),
    );
  }
}

/// The parsed response of the cycle-aware adaptive endpoint.
class CycleAwareWeightData {
  /// Phase-tagged weigh-in series for the chart overlay (oldest-first).
  final List<CycleTaggedWeighIn> weightSeries;

  /// Cycle-aware weekly weight change in kg (luteal water weight removed).
  final double? cycleAwareChangeKg;

  /// `losing` | `gaining` | `maintaining` — cycle-aware direction.
  final String? cycleAwareDirection;

  /// True when the adaptive calorie target is being held steady through the
  /// pre-period / period window (no calorie cut during water-weight noise).
  final bool holdCalorieTarget;

  /// Human label for the hold window, e.g. "period week".
  final String? holdWindowLabel;

  /// The cycle-day-matched weigh-in from the previous cycle, for the
  /// "same point last cycle" comparison.
  final double? samePointLastCycleKg;

  /// The cycle day both the current and last-cycle weigh-ins share.
  final int? samePointCycleDay;

  /// Phase D — adaptive calorie delta applied for the current cycle phase
  /// (e.g. +200 kcal during luteal). Positive = bump, negative = cut, null
  /// when no phase-aware adjustment is in effect.
  final int? cycleCalorieDelta;

  /// Current cycle phase string the backend reports (lowercase: "luteal",
  /// "menstrual", "follicular", "ovulation"). Paired with [cycleCalorieDelta]
  /// for the home calorie-card chip.
  final String? cyclePhase;

  const CycleAwareWeightData({
    this.weightSeries = const [],
    this.cycleAwareChangeKg,
    this.cycleAwareDirection,
    this.holdCalorieTarget = false,
    this.holdWindowLabel,
    this.samePointLastCycleKg,
    this.samePointCycleDay,
    this.cycleCalorieDelta,
    this.cyclePhase,
  });

  bool get hasSeries => weightSeries.isNotEmpty;

  static double? _asDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static int? _asInt(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  factory CycleAwareWeightData.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['weight_series'];
    final series = <CycleTaggedWeighIn>[];
    if (rawSeries is List) {
      for (final e in rawSeries) {
        if (e is Map) {
          final parsed =
              CycleTaggedWeighIn.fromJson(Map<String, dynamic>.from(e));
          if (parsed != null) series.add(parsed);
        }
      }
    }
    series.sort((a, b) => a.date.compareTo(b.date));

    // The cycle-aware trend block — tolerate either a nested object or flat
    // keys so a backend rename does not silently break the card.
    final trend = json['cycle_aware_trend'];
    final trendMap = trend is Map ? Map<String, dynamic>.from(trend) : json;

    // The "same point last cycle" comparison block.
    final cmp = json['same_point_last_cycle'];
    final cmpMap = cmp is Map ? Map<String, dynamic>.from(cmp) : json;

    return CycleAwareWeightData(
      weightSeries: series,
      cycleAwareChangeKg: _asDouble(
          trendMap['change_kg'] ?? trendMap['cycle_aware_change_kg']),
      cycleAwareDirection:
          (trendMap['direction'] ?? trendMap['cycle_aware_direction'])
              ?.toString(),
      holdCalorieTarget: json['hold_calorie_target'] == true,
      holdWindowLabel: (json['hold_window'] is Map
              ? (json['hold_window'] as Map)['label']
              : json['hold_window_label'])
          ?.toString(),
      samePointLastCycleKg: _asDouble(
          cmpMap['weight_kg'] ?? cmpMap['same_point_last_cycle_kg']),
      samePointCycleDay:
          _asInt(cmpMap['cycle_day'] ?? cmpMap['same_point_cycle_day']),
      // Phase D — cycle calorie delta + phase live at the top of the same
      // response. Tolerate nested or flat keys for both.
      cycleCalorieDelta: _asInt(json['cycle_calorie_delta'] ??
          (json['cycle_adjustment'] is Map
              ? (json['cycle_adjustment'] as Map)['calorie_delta']
              : null)),
      cyclePhase: (json['cycle_phase'] ??
              json['current_phase'] ??
              (json['cycle_adjustment'] is Map
                  ? (json['cycle_adjustment'] as Map)['phase']
                  : null))
          ?.toString()
          .toLowerCase(),
    );
  }
}

/// Cache-first, error-tolerant provider for the cycle-aware weight payload.
///
/// Returns null (a clean no-op) for users without cycle tracking enabled or
/// when the endpoint is unavailable — the card then renders exactly as the
/// pre-cycle version did. Never throws into the widget tree.
final cycleAwareWeightProvider =
    FutureProvider.autoDispose<CycleAwareWeightData?>((ref) async {
  // Gate on the cycle-tracking flag — no request at all when it is off.
  final tracksCycle = ref.watch(hasHormonalTrackingProvider);
  if (!tracksCycle) return null;

  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final api = ref.watch(apiClientProvider);
  try {
    final Response<dynamic> resp =
        await api.get('/nutrition/adaptive/${user.id}/cycle-aware');
    final data = resp.data;
    if (data is Map) {
      return CycleAwareWeightData.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  } catch (e) {
    // No silent fabricated data — just degrade to the non-cycle card.
    debugPrint('⚠️ [WeightTrendCard] cycle-aware fetch failed: $e');
    return null;
  }
});

/// Weight Trend Tile - Shows weekly weight change with trend arrow.
///
/// Green arrow down = losing weight (good for fat loss);
/// red arrow up = gaining weight.
///
/// When cycle tracking is enabled the tile additionally shades cycle phases
/// behind a mini weight chart, surfaces a "same point last cycle" comparison
/// and a "calorie target held" marker for the pre-period week.
class WeightTrendCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const WeightTrendCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final nutritionState = ref.watch(nutritionPreferencesProvider);
    final weightTrend = nutritionState.weightTrend;
    final weightHistory = nutritionState.weightHistory;
    final isLoading = nutritionState.isLoading;

    // Cycle-aware overlay data — null when cycle tracking is off (no-op).
    final tracksCycle = ref.watch(hasHormonalTrackingProvider);
    final cycleAware =
        tracksCycle ? ref.watch(cycleAwareWeightProvider).value : null;
    final prediction =
        tracksCycle ? ref.watch(cyclePredictionProvider).value : null;

    // Get latest weight
    final latestWeight = weightHistory.isNotEmpty ? weightHistory.first : null;

    // Prefer the cycle-aware change (luteal water weight removed) when it is
    // available — that is the whole point of MacroFactor 1.2 / 1.19.
    final changeKg = cycleAware?.cycleAwareChangeKg ??
        weightTrend?.changeKg ??
        0.0;
    final direction = cycleAware?.cycleAwareDirection ??
        weightTrend?.direction ??
        'maintaining';
    final isLosing = direction == 'losing';
    final isGaining = direction == 'gaining';

    // Colors based on direction (for fat loss: losing is good)
    final trendColor = isLosing
        ? AppColors.success
        : isGaining
            ? AppColors.error
            : AppColors.orange;

    // Format change for display
    final changeLbs = (changeKg.abs() * 2.20462);
    final changeText = changeLbs >= 0.1
        ? '${changeLbs.toStringAsFixed(1)} lbs'
        : 'No change';

    // Build the appropriate layout based on size
    if (size == TileSize.compact) {
      return _buildCompactLayout(
        context,
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        trendColor: trendColor,
        cardBorder: cardBorder,
        isLosing: isLosing,
        isGaining: isGaining,
        changeText: changeText,
        isLoading: isLoading,
        hasData: weightHistory.isNotEmpty,
      );
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: AppColors.orange, width: 4),
            top: BorderSide(color: trendColor.withValues(alpha: 0.3)),
            right: BorderSide(color: trendColor.withValues(alpha: 0.3)),
            bottom: BorderSide(color: trendColor.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? _buildLoadingState(textMuted)
            : weightHistory.isEmpty
                ? _buildEmptyState(textMuted, trendColor)
                : _buildContentState(
                    context: context,
                    textColor: textColor,
                    textMuted: textMuted,
                    trendColor: trendColor,
                    latestWeight: latestWeight,
                    isLosing: isLosing,
                    isGaining: isGaining,
                    changeText: changeText,
                    direction: direction,
                    changeLbs: changeLbs,
                    cycleAware: cycleAware,
                    prediction: prediction,
                  ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context, {
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required Color trendColor,
    required Color cardBorder,
    required bool isLosing,
    required bool isGaining,
    required String changeText,
    required bool isLoading,
    required bool hasData,
  }) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: AppColors.orange, width: 4),
            top: BorderSide(color: trendColor.withValues(alpha: 0.3)),
            right: BorderSide(color: trendColor.withValues(alpha: 0.3)),
            bottom: BorderSide(color: trendColor.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLosing
                  ? Icons.trending_down
                  : isGaining
                      ? Icons.trending_up
                      : Icons.trending_flat,
              color: trendColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isLoading
                  ? '...'
                  : hasData
                      ? changeText
                      : 'No data',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading weight...',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textMuted, Color trendColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.scale, color: trendColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Weight Trends',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Log your weight to see trends',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: trendColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Tap to log weight',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentState({
    required BuildContext context,
    required Color textColor,
    required Color textMuted,
    required Color trendColor,
    required dynamic latestWeight,
    required bool isLosing,
    required bool isGaining,
    required String changeText,
    required String direction,
    required double changeLbs,
    required CycleAwareWeightData? cycleAware,
    required CyclePrediction? prediction,
  }) {
    // Format the message based on direction
    String getMessage() {
      if (isLosing) {
        return 'Down $changeText this week!';
      } else if (isGaining) {
        return 'Up $changeText this week';
      } else {
        return 'Weight stable this week';
      }
    }

    final cycleAdjusted = cycleAware?.cycleAwareChangeKg != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLosing
                  ? Icons.trending_down
                  : isGaining
                      ? Icons.trending_up
                      : Icons.trending_flat,
              color: trendColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large change number with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: changeLbs),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, _) {
                      final displayText = animatedValue >= 0.1
                          ? '${animatedValue.toStringAsFixed(1)} lbs'
                          : 'No change';
                      return Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.0,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  // Small label
                  Text(
                    cycleAdjusted
                        ? '${getMessage().replaceAll(changeText, '').trim()} · cycle-adjusted'
                        : getMessage().replaceAll(changeText, '').trim(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
        if (size == TileSize.full) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (latestWeight != null) ...[
                Flexible(
                  child: Text(
                    'Current: ${latestWeight.weightLbs.toStringAsFixed(1)} lbs',
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  direction == 'losing'
                      ? 'On track'
                      : direction == 'gaining'
                          ? 'Review goals'
                          : 'Maintaining',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ),
            ],
          ),
          // ── Cycle-aware extras (only when tracking enabled) ───────────
          if (cycleAware != null) ...[
            if (cycleAware.hasSeries) ...[
              const SizedBox(height: 12),
              _CyclePhaseWeightChart(
                series: cycleAware.weightSeries,
                prediction: prediction,
                isDark: isDark,
                trendColor: trendColor,
              ),
              const SizedBox(height: 6),
              CyclePhaseChartOverlay.legend(
                context,
                isDark: isDark,
                compact: true,
              ),
            ],
            if (cycleAware.samePointLastCycleKg != null &&
                latestWeight != null)
              _SamePointLastCycleRow(
                currentKg: (latestWeight.weightLbs as double) / 2.20462,
                lastCycleKg: cycleAware.samePointLastCycleKg!,
                cycleDay: cycleAware.samePointCycleDay,
                textMuted: textMuted,
                isDark: isDark,
              ),
            if (cycleAware.holdCalorieTarget)
              _TargetHeldMarker(
                windowLabel: cycleAware.holdWindowLabel ?? 'period week',
                isDark: isDark,
              ),
          ],
        ],
      ],
    );
  }
}

/// A compact phase-shaded weight sparkline. The cycle-phase columns are
/// painted behind a smooth weight line so a luteal-phase bump is visually
/// attributable to water retention, not fat gain. (MacroFactor 1.1.)
class _CyclePhaseWeightChart extends StatelessWidget {
  final List<CycleTaggedWeighIn> series;
  final CyclePrediction? prediction;
  final bool isDark;
  final Color trendColor;

  const _CyclePhaseWeightChart({
    required this.series,
    required this.prediction,
    required this.isDark,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) return const SizedBox.shrink();

    final rangeStart = series.first.date;
    final rangeEnd = series.last.date;
    final totalDays = rangeEnd.difference(rangeStart).inDays;
    if (totalDays <= 0) return const SizedBox.shrink();

    double minW = series.first.weightKg;
    double maxW = series.first.weightKg;
    for (final w in series) {
      if (w.weightKg < minW) minW = w.weightKg;
      if (w.weightKg > maxW) maxW = w.weightKg;
    }
    final pad = (maxW - minW) * 0.15 + 0.3;
    final yMin = minW - pad;
    final yMax = maxW + pad;

    final spots = <FlSpot>[
      for (final w in series)
        FlSpot(
          w.date.difference(rangeStart).inDays.toDouble(),
          w.weightKg,
        ),
    ];

    final lineColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return SizedBox(
      height: 96,
      child: RepaintBoundary(
        child: Stack(
          children: [
            // Layer 1 — phase columns behind the data.
            CyclePhaseChartOverlay(
              prediction: prediction,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
            ),
            // Layer 2 — the weight line.
            LineChart(
              LineChartData(
                minX: 0,
                maxX: totalDays.toDouble(),
                minY: yMin,
                maxY: yMax,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final phase = series[index].phase;
                        return FlDotCirclePainter(
                          radius: 3,
                          color: phase != null
                              ? cyclePhaseOverlayColor(phase)
                              : lineColor,
                          strokeWidth: 1.5,
                          strokeColor: isDark
                              ? AppColors.elevated
                              : AppColorsLight.elevated,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Same point last cycle" comparison row (MacroFactor 1.11). Aligns the
/// current weight with the cycle-day-matched weigh-in from the prior cycle so
/// the user compares like-for-like instead of against luteal noise.
class _SamePointLastCycleRow extends StatelessWidget {
  final double currentKg;
  final double lastCycleKg;
  final int? cycleDay;
  final Color textMuted;
  final bool isDark;

  const _SamePointLastCycleRow({
    required this.currentKg,
    required this.lastCycleKg,
    required this.cycleDay,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final diffLbs = (currentKg - lastCycleKg) * 2.20462;
    final down = diffLbs < -0.1;
    final up = diffLbs > 0.1;
    final color = down
        ? AppColors.success
        : up
            ? AppColors.error
            : textMuted;
    final magnitude = diffLbs.abs().toStringAsFixed(1);
    final label = (down || up)
        ? '${down ? 'Down' : 'Up'} $magnitude lbs vs same cycle day last month'
        : 'Same as this cycle day last month';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.compare_arrows, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              cycleDay != null ? '$label (day $cycleDay)' : label,
              style: TextStyle(fontSize: 11, color: color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A subtle marker shown when the adaptive calorie target is being held
/// steady through the pre-period / period water-weight window. (MacroFactor
/// 1.3 / 1.19.)
class _TargetHeldMarker extends StatelessWidget {
  final String windowLabel;
  final bool isDark;

  const _TargetHeldMarker({
    required this.windowLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF64B5F6); // luteal blue
    // Phase D — surface the hold as a tight one-liner directly under the
    // weight-change number. When the backend supplies a window label (e.g.
    // "until May 26") splice it inline; otherwise use the static copy.
    final label = (windowLabel.isNotEmpty &&
            windowLabel.toLowerCase() != 'period week')
        ? 'Target held $windowLabel — luteal water smoothing'
        : 'Target held — luteal water smoothing';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.pause_circle_outline, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, color: color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
