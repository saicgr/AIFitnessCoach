import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/metrics/metric_descriptor.dart';
import '../../data/metrics/metric_registry.dart';
import '../../data/providers/today_score_provider.dart';
import '../../services/score_history_service.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/trends/premium_metric_chart.dart';
import '../../widgets/trends/trend_correlation.dart';

/// The universal, descriptor-driven "metric over time" detail screen. Every
/// home-carousel tile, the TODAY ring, and (Phase C) every Stats & Scores row
/// resolves to `/metric/<id>` → this screen.
class MetricDetailScreen extends ConsumerStatefulWidget {
  final String metricId;
  const MetricDetailScreen({super.key, required this.metricId});

  @override
  ConsumerState<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends ConsumerState<MetricDetailScreen> {
  TrendRange _range = TrendRange.d30;
  PremiumChartType? _chartType;
  MetricSubView? _subView;

  static const _metColor = Color(0xFF37D67A);
  static const _missColor = Color(0xFFFF9F43);

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final d = metricDescriptorFor(widget.metricId);

    if (d == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Metric')),
        body: const Center(child: Text('Unknown metric.')),
      );
    }

    final active = _activeSub(d);
    final chartType = _chartType ?? active?.chart ?? d.defaultChart;

    // Resolve the time series (or the composite TODAY history).
    final List<TrendPoint> points = _resolvePoints(d);
    final goal = (active?.goalOf ?? d.goalOf)?.call(ref);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _appBar(c, d),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rangeTabs(c),
                    const SizedBox(height: 16),
                    _header(c, d, points, goal),
                    if (d.subViews.length > 1) ...[
                      const SizedBox(height: 16),
                      _subViewChips(c, d),
                    ],
                    const SizedBox(height: 18),
                    if (d.series == null && points.isEmpty)
                      _noHistoryNote(c, d)
                    else ...[
                      _chartCard(c, d, points, goal, chartType),
                      const SizedBox(height: 14),
                      _chartTypeSelector(c, d, chartType),
                      const SizedBox(height: 16),
                      _statsRow(c, d, points),
                    ],
                    const SizedBox(height: 18),
                    _actions(c, d),
                    if (points.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _dailyList(c, d, points, goal),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Data ────────────────────────────────────────────────────────────────
  /// The active sub-view (or null when the metric has no chips).
  MetricSubView? _activeSub(MetricDescriptor d) {
    if (d.subViews.isEmpty) return null;
    if (_subView != null && d.subViews.contains(_subView)) return _subView;
    return d.subViews.first;
  }

  /// The series in effect (sub-view overrides the base).
  TrendMetric? _effSeries(MetricDescriptor d) =>
      _activeSub(d)?.series ?? d.series;

  /// The unit in effect.
  String _unit(MetricDescriptor d) => _activeSub(d)?.unit ?? d.unit;

  List<TrendPoint> _resolvePoints(MetricDescriptor d) {
    if (d.id == kTodayMetricId) {
      final hist = ref.watch(scoreHistoryProvider);
      final start = _range.startDate();
      return [
        for (final day in hist.days)
          if (start == null || !day.date.isBefore(start))
            TrendPoint(date: day.date, value: day.score.toDouble()),
      ];
    }
    final series = _effSeries(d);
    if (series == null) return const [];
    final async =
        ref.watch(trendSeriesProvider(TrendSeriesKey(series, _range)));
    return async.valueOrNull?.points ?? const [];
  }

  Widget _subViewChips(ThemeColors c, MetricDescriptor d) {
    final active = _activeSub(d);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final sv in d.subViews)
            GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() {
                  _subView = sv;
                  _chartType = null; // fall back to the sub-view's default
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: sv == active
                      ? LinearGradient(colors: [
                          Color.lerp(d.color, Colors.white, 0.15)!,
                          d.color,
                        ])
                      : null,
                  color: sv == active ? null : c.surface,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      sv == active ? null : Border.all(color: c.cardBorder),
                ),
                child: Text(
                  sv.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: sv == active ? Colors.white : c.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isMet(MetricDescriptor d, double v, double goal) =>
      d.goalDirectionUp ? v >= goal : v <= goal;

  // ── App bar ───────────────────────────────────────────────────────────
  Widget _appBar(ThemeColors c, MetricDescriptor d) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _circleBtn(c, Icons.arrow_back_ios_new_rounded,
            () => context.pop(), size: 16),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: d.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(d.title,
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: c.textPrimary)),
        ],
      ),
      centerTitle: false,
      titleSpacing: 4,
      actions: [
        _aiBtn(c, d),
        if (d.series != null)
          _circleBtn(c, Icons.show_chart_rounded, () => _openCustomTrend(d)),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _aiBtn(ThemeColors c, MetricDescriptor d) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: () => _openCoachReview(d),
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD86B), Color(0xFFFF9F1C)],
              ),
              boxShadow: [
                BoxShadow(
                    color: Color(0x66FF9F1C), blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 18, color: Color(0xFF3A2400)),
          ),
        ),
      );

  Widget _circleBtn(ThemeColors c, IconData icon, VoidCallback onTap,
          {double size = 18}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: c.cardBorder),
          ),
          child: Icon(icon, size: size, color: c.textSecondary),
        ),
      );

  // ── Range tabs ────────────────────────────────────────────────────────
  Widget _rangeTabs(ThemeColors c) {
    return Row(
      children: [
        for (final r in TrendRange.values)
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() => _range = r);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _range == r
                      ? const LinearGradient(
                          colors: [Color(0xFF9AF23A), Color(0xFF5FD11E)])
                      : null,
                  color: _range == r ? null : c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      _range == r ? null : Border.all(color: c.cardBorder),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _range == r
                        ? const Color(0xFF08210A)
                        : c.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Header big number + goal status ───────────────────────────────────
  Widget _header(ThemeColors c, MetricDescriptor d, List<TrendPoint> points,
      double? goal) {
    final headline = _headlineValue(d, points);
    final aggLabel = switch (d.agg) {
      MetricAgg.latest => 'latest',
      MetricAgg.avgPerDay => '/ day avg',
      MetricAgg.sumPerDay => '/ day avg',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  headline,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 0.95,
                    color: d.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${_unit(d).isEmpty ? '' : '${_unit(d)} '}$aggLabel',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _goalStatus(d, points, goal),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _goalStatusColor(d, points, goal, c),
          ),
        ),
      ],
    );
  }

  String _headlineValue(MetricDescriptor d, List<TrendPoint> points) {
    if (d.id == kTodayMetricId) {
      return ref.watch(todayScoreProvider).score.toString();
    }
    if (points.isEmpty) return '—';
    final values = points.map((p) => p.value).toList();
    final v = switch (d.agg) {
      MetricAgg.latest => values.last,
      _ => values.reduce((a, b) => a + b) / values.length,
    };
    return _fmt(v);
  }

  String _goalStatus(MetricDescriptor d, List<TrendPoint> points, double? goal) {
    if (points.isEmpty) return 'No data in this range yet';
    if (goal != null) {
      final n = points.length;
      final met = points.where((p) => _isMet(d, p.value, goal)).length;
      if (met == n) return 'Goal met every day 🎯';
      if (met == 0) return "You haven't hit your ${_fmt(goal)}${_unit(d)} goal";
      return 'Goal met $met of $n days';
    }
    if (points.length >= 2) {
      final delta = points.last.value - points.first.value;
      if (delta.abs() < 0.05) return 'Holding steady over ${points.length} days';
      final dir = delta > 0 ? 'Up' : 'Down';
      return '$dir ${_fmt(delta.abs())}${_unit(d)} over ${points.length} days';
    }
    return '${points.length} day tracked';
  }

  Color _goalStatusColor(
      MetricDescriptor d, List<TrendPoint> points, double? goal, ThemeColors c) {
    if (goal == null || points.isEmpty) return c.textSecondary;
    final met = points.where((p) => _isMet(d, p.value, goal)).length;
    return met >= points.length / 2 ? _metColor : _missColor;
  }

  // ── Chart card ─────────────────────────────────────────────────────────
  Widget _chartCard(ThemeColors c, MetricDescriptor d, List<TrendPoint> points,
      double? goal, PremiumChartType chartType) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.surface,
            c.surface.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.4 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          if (points.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text('No data in this range',
                    style: TextStyle(color: c.textMuted)),
              ),
            )
          else
            PremiumMetricChart(
              points: points,
              type: chartType,
              color: d.color,
              unit: _unit(d),
              goal: goal,
              goalDirectionUp: d.goalDirectionUp,
              height: 210,
            ),
          if (goal != null) _legend(c),
        ],
      ),
    );
  }

  Widget _legend(ThemeColors c) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem('goal', _metColor, isLine: true),
            const SizedBox(width: 16),
            _legendItem('met', _metColor),
            const SizedBox(width: 16),
            _legendItem('missed', _missColor),
          ],
        ),
      );

  Widget _legendItem(String label, Color color, {bool isLine = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLine ? 14 : 9,
            height: isLine ? 2 : 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(isLine ? 1 : 5),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B93A3))),
        ],
      );

  // ── Chart-type selector ────────────────────────────────────────────────
  Widget _chartTypeSelector(
      ThemeColors c, MetricDescriptor d, PremiumChartType active) {
    Widget seg(String label, IconData icon, PremiumChartType t) {
      final on = active == t;
      return GestureDetector(
        onTap: () {
          HapticService.light();
          setState(() => _chartType = t);
        },
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: on ? c.textPrimary.withValues(alpha: 0.12) : c.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: on ? c.textPrimary.withValues(alpha: 0.25) : c.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: on ? c.textPrimary : c.textMuted),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: on ? c.textPrimary : c.textMuted)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('Line', Icons.show_chart_rounded, PremiumChartType.line),
        seg('Area', Icons.area_chart_rounded, PremiumChartType.area),
        seg('Bars', Icons.bar_chart_rounded, PremiumChartType.bar),
      ],
    );
  }

  // ── Min / Avg / Max ────────────────────────────────────────────────────
  Widget _statsRow(ThemeColors c, MetricDescriptor d, List<TrendPoint> points) {
    if (points.isEmpty) return const SizedBox.shrink();
    final values = points.map((p) => p.value).toList();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final avgV = values.reduce((a, b) => a + b) / values.length;

    Widget cell(String k, double v, Color col) => Expanded(
          child: Column(
            children: [
              Text(k,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: c.textMuted)),
              const SizedBox(height: 3),
              Text('${_fmt(v)}${_unit(d).isEmpty ? '' : ' ${_unit(d)}'}',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: col)),
            ],
          ),
        );
    Widget div() =>
        Container(width: 1, height: 28, color: c.cardBorder);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          cell('MIN', minV, _metColor),
          div(),
          cell('AVG', avgV, d.color),
          div(),
          cell('MAX', maxV, c.error),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────
  Widget _actions(ThemeColors c, MetricDescriptor d) {
    Widget act(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 18, color: c.textSecondary),
                  const SizedBox(height: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary)),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        act(Icons.auto_awesome_rounded, 'AI insight', () => _openCoachReview(d)),
        if (d.series != null)
          act(Icons.show_chart_rounded, 'Custom trend', () => _openCustomTrend(d)),
        if (d.fullScreenRoute != null)
          act(Icons.open_in_full_rounded, 'View full',
              () => context.push(d.fullScreenRoute!)),
      ],
    );
  }

  // ── Daily list ─────────────────────────────────────────────────────────
  Widget _dailyList(ThemeColors c, MetricDescriptor d, List<TrendPoint> points,
      double? goal) {
    final reversed = points.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_rangeHeading(),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: c.textPrimary)),
        const SizedBox(height: 10),
        for (final p in reversed.take(60))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.cardBorder),
            ),
            child: Row(
              children: [
                if (goal != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isMet(d, p.value, goal) ? _metColor : _missColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(_dayLabel(p.date),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary)),
                const Spacer(),
                Text('${_fmt(p.value)}${_unit(d).isEmpty ? '' : ' ${_unit(d)}'}',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _noHistoryNote(ThemeColors c, MetricDescriptor d) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: c.cardBorder, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.insights_rounded, size: 18, color: c.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No history to chart yet. Keep logging and your ${d.title.toLowerCase()} trend will appear here.',
                style: TextStyle(fontSize: 13, height: 1.4, color: c.textSecondary),
              ),
            ),
          ],
        ),
      );

  // ── Navigation ─────────────────────────────────────────────────────────
  void _openCoachReview(MetricDescriptor d) {
    HapticService.light();
    final n = d.id;
    context.push(
      '/chat?source=metric_$n&mode=metric:$n'
      '&context=${Uri.encodeComponent(d.title)}',
      extra: {
        'initialMessage':
            'Review my ${d.title} trend over the last ${_range.label}.',
      },
    );
  }

  void _openCustomTrend(MetricDescriptor d) {
    HapticService.light();
    if (d.series == null) return;
    context.push('/trends/custom', extra: d.series);
  }

  // ── Formatting ─────────────────────────────────────────────────────────
  String _rangeHeading() => switch (_range) {
        TrendRange.d7 => 'This week',
        TrendRange.d30 => 'This month',
        TrendRange.d90 => 'Last 90 days',
        TrendRange.m6 => 'Last 6 months',
        TrendRange.y1 => 'This year',
        TrendRange.all => 'All time',
      };

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  static String _fmt(double v) {
    if (v.abs() >= 1000) return NumberFormat.compact().format(v);
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
