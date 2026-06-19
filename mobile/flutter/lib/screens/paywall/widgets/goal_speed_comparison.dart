import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/science_citations.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../screens/onboarding/goal_speed_calculator.dart';
import '../../../widgets/citation_link.dart';

/// The bold "⚡ N× FASTER with your plan" paywall hero.
///
/// The multiplier is DERIVED — it comes straight from the user's own
/// plan-vs-solo projection ([GoalSpeedCalculator]) and is anchored to a
/// tappable cited basis. It is never a fixed, un-cited "4.2×": the number is
/// the user's data × a cited factor, which keeps it substantiated under
/// Apple 3.1.2 / FTC and the project's no-fabricated-stats policy.
///
/// When [projection] is null (missing body metrics or maintain-mode) it
/// degrades gracefully to the cited "~2× more likely to hit your goal" line
/// — no fabricated number is ever shown.
class GoalSpeedComparison extends ConsumerStatefulWidget {
  final GoalSpeedProjection? projection;
  final ThemeColors colors;
  final Color accent;

  const GoalSpeedComparison({
    super.key,
    required this.projection,
    required this.colors,
    required this.accent,
  });

  @override
  ConsumerState<GoalSpeedComparison> createState() =>
      _GoalSpeedComparisonState();
}

class _GoalSpeedComparisonState extends ConsumerState<GoalSpeedComparison>
    with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _glow;
  bool _hapticFired = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _reveal.addListener(() {
      // Fire one tactile pulse as the number lands.
      if (!_hapticFired && _reveal.value >= 0.62) {
        _hapticFired = true;
        HapticFeedback.mediumImpact();
      }
    });

    // Analytics: the variant + the derived multiplier actually shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final props = <String, Object>{
        'has_projection': widget.projection != null,
      };
      final m = widget.projection?.speedMultiplier;
      if (m != null) props['paywall_goal_speed_multiplier'] = m;
      ref.read(posthogServiceProvider).capture(
            eventName: 'paywall_goal_speed_comparison_viewed',
            properties: props,
          );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reducedMotion) {
      _reveal.value = 1.0;
      _hapticFired = true;
      if (_glow.isAnimating) _glow.stop();
    } else if (!_reveal.isAnimating && _reveal.value == 0) {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final accent = widget.accent;
    final proj = widget.projection;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: proj == null
          ? _buildFallback(c, accent)
          : _buildHero(proj, c, accent),
    );
  }

  // ── Derived multiplier hero ───────────────────────────────────────────
  Widget _buildHero(GoalSpeedProjection proj, ThemeColors c, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Reach your goal',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        // The headline: glow + spark + count-up multiplier.
        AnimatedBuilder(
          animation: Listenable.merge([_reveal, _glow]),
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_reveal.value);
            final value = 1.0 + (proj.speedMultiplier - 1.0) * t;
            final scale = 0.7 + 0.3 * Curves.easeOutBack.transform(_reveal.value);
            final glowT = _reducedMotion ? 0.5 : _glow.value;
            final label = value.toStringAsFixed(1);
            final shown = label.endsWith('.0')
                ? label.substring(0, label.length - 2)
                : label;
            return SizedBox(
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing radial glow behind the number.
                  Container(
                    width: 200,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.22 + 0.14 * glowT),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // One-shot spark burst as the number settles.
                  if (!_reducedMotion)
                    CustomPaint(
                      size: const Size(220, 84),
                      painter: _SparkBurstPainter(
                        progress: Curves.easeOut.transform(
                            ((_reveal.value - 0.55) / 0.45).clamp(0.0, 1.0)),
                        color: accent,
                      ),
                    ),
                  Transform.scale(
                    scale: scale,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '⚡',
                          style: TextStyle(
                            fontSize: 30,
                            shadows: [
                              Shadow(
                                color: accent.withValues(
                                    alpha: 0.5 + 0.4 * glowT),
                                blurRadius: 14 + 10 * glowT,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$shown×',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -1.5,
                            color: accent,
                            shadows: [
                              Shadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'FASTER',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Text(
          'with your plan vs. going solo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        _MiniComparisonChart(
          projection: proj,
          accent: accent,
          colors: c,
          reveal: _reveal,
        ),
        const SizedBox(height: 10),
        _legend(c, accent),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: CitationLink(
            citation: proj.citation,
            accent: accent,
            fontSize: 11,
            leading: 'Based on your goal + ',
          ),
        ),
      ],
    );
  }

  // ── Graceful fallback (no per-user multiplier available) ──────────────
  Widget _buildFallback(ThemeColors c, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Flexible(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: c.textPrimary),
                  children: [
                    const TextSpan(
                      text: '2× more likely',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFC4C02),
                      ),
                    ),
                    const TextSpan(
                      text: ' to reach your goal',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'when you track consistently with a plan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: c.textSecondary),
        ),
        const SizedBox(height: 10),
        CitationLink(
          citation: ScienceCitations.selfMonitoring,
          accent: accent,
          fontSize: 11,
          leading: 'Source: ',
        ),
      ],
    );
  }

  Widget _legend(ThemeColors c, Color accent) {
    Widget item(Color color, String label, {required bool dashed}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 3.5,
            decoration: BoxDecoration(
              color: dashed ? Colors.transparent : color,
              borderRadius: BorderRadius.circular(2),
              border: dashed ? Border.all(color: color, width: 1.2) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(accent, 'Your plan', dashed: false),
        const SizedBox(width: 18),
        item(c.textSecondary.withValues(alpha: 0.6), 'On your own',
            dashed: true),
      ],
    );
  }
}

/// Compact dual plan-vs-solo curve. The solo line draws with a deliberate lag
/// so the speed gap is felt during the reveal.
class _MiniComparisonChart extends StatelessWidget {
  final GoalSpeedProjection projection;
  final Color accent;
  final ThemeColors colors;
  final Animation<double> reveal;

  const _MiniComparisonChart({
    required this.projection,
    required this.accent,
    required this.colors,
    required this.reveal,
  });

  @override
  Widget build(BuildContext context) {
    final plan = projection.planCurve;
    final solo = projection.soloCurve;
    final n = plan.length;

    // Shared y-range across both curves.
    double lo = double.infinity, hi = -double.infinity;
    for (final p in [...plan, ...solo]) {
      lo = math.min(lo, p.weightKg);
      hi = math.max(hi, p.weightKg);
    }
    final pad = (hi - lo) * 0.12 + 0.5;

    return SizedBox(
      height: 76,
      child: AnimatedBuilder(
        animation: reveal,
        builder: (context, _) {
          final planCount = (reveal.value * n).ceil().clamp(1, n);
          final soloT = math.pow(reveal.value, 1.8).toDouble();
          final soloCount = (soloT * n).ceil().clamp(1, n);

          return LineChart(
            LineChartData(
              minX: 0,
              maxX: (n - 1).toDouble(),
              minY: lo - pad,
              maxY: hi + pad,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              // Tappable: show how far along the goal each path is at that
              // point. Unit-free ("% there") so it never conflicts with the
              // user's lb/kg preference. Plan is the last bar (index 1).
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchSpotThreshold: 22,
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((_) {
                    final isSolo = barData.dashArray != null;
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: accent.withValues(alpha: 0.3),
                        strokeWidth: 1.5,
                        dashArray: const [3, 3],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                          radius: isSolo ? 3.5 : 4.5,
                          color: isSolo
                              ? colors.textSecondary.withValues(alpha: 0.6)
                              : accent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 10,
                  getTooltipColor: (_) =>
                      colors.surface.withValues(alpha: 0.97),
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    final start = plan.first.weightKg;
                    final goal = plan.last.weightKg;
                    final denom = goal - start;
                    double pct(double w) => denom.abs() < 1e-6
                        ? 0
                        : (((w - start) / denom).clamp(0.0, 1.0)) * 100;
                    return touchedSpots.map((spot) {
                      if (spot.barIndex != 1) return null; // plan bar only
                      final idx = spot.spotIndex.clamp(0, n - 1);
                      final wk = (plan[idx].dayOffset / 7).round();
                      final header =
                          idx == 0 ? 'Now' : idx == n - 1 ? 'Goal' : 'Week $wk';
                      return LineTooltipItem(
                        header,
                        TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(
                            text: '\nYour plan  ${pct(plan[idx].weightKg).round()}% there',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          TextSpan(
                            text: '\nOn your own  ${pct(solo[idx].weightKg).round()}% there',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // Solo (grey, dashed, lags)
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < soloCount; i++)
                      FlSpot(i.toDouble(), solo[i].weightKg),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: colors.textSecondary.withValues(alpha: 0.5),
                  barWidth: 2,
                  dashArray: const [5, 4],
                  dotData: const FlDotData(show: false),
                ),
                // Plan (accent gradient), on top
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < planCount; i++)
                      FlSpot(i.toDouble(), plan[i].weightKg),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.35,
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                      radius: idx == planCount - 1 ? 4 : 0,
                      color: accent,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A brief radial spark burst that fires once as the multiplier settles.
class _SparkBurstPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  _SparkBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.42;
    final r = maxR * Curves.easeOut.transform(progress);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const rays = 10;
    for (int i = 0; i < rays; i++) {
      final angle = (i / rays) * 2 * math.pi;
      final inner = r * 0.55;
      final p1 = center + Offset(math.cos(angle) * inner, math.sin(angle) * inner);
      final p2 = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkBurstPainter old) =>
      old.progress != progress || old.color != color;
}
