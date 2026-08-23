import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/fitness_index_repository.dart';
import '../../widgets/glass_back_button.dart';
import '../pillar/widgets/ask_coach_button.dart';
import '../common/app_refresh_indicator.dart';

/// Fitness Index detail — route `/health/fitness-index`.
///
/// A 5-axis fitness radar (body composition, cardio, strength, endurance,
/// flexibility) with an overall, a goal-driven focus, and a k-anonymous peer
/// percentile per axis. The radar animates in; axes with no data draw at the
/// center with a muted label (honest, never fabricated).
/// What each axis actually measures, keyed by `FitnessAxis.key`. Surfaced
/// under the axis label so near-synonym axes (Cardio's VO2 max test vs
/// Endurance's day-to-day training load) never look like the same metric
/// disagreeing with itself when one has data and the other doesn't.
const Map<String, String> _kAxisSource = {
  'cardio': 'VO2 max from a synced cardio test',
  'endurance': 'Training-load capacity from your cardio session history',
  'body_comp': 'BMI from your latest body measurement',
  'strength': 'Completed working sets in the last 7 days',
  'flexibility': 'Logged mobility/stretch/yoga sets over 28 days',
};

class FitnessIndexDetailScreen extends ConsumerWidget {
  /// True when composed inside the Health tab's shell rather than pushed as
  /// a full-screen route — see [CombinedHealthScreen.embedded]. Drops the
  /// back-button row (nothing to pop) and the opaque background; the
  /// Ask-Coach button and the whole body are unchanged.
  final bool embedded;

  const FitnessIndexDetailScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final async = ref.watch(fitnessIndexProvider);

    return Scaffold(
      backgroundColor: embedded ? Colors.transparent : bg,
      body: SafeArea(
        top: !embedded,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, embedded ? 0 : 8, 16, 4),
              child: Row(
                children: [
                  if (!embedded) ...[
                    const GlassBackButton(),
                    const SizedBox(width: 12),
                    Text('Fitness index',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                  ],
                  const Spacer(),
                  AskCoachButton(
                    contextLabel: 'Fitness index · 5-axis',
                    statSnapshot: const {'pillar': 'fitness_index'},
                    source: 'fitness_index',
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text('Couldn\'t load fitness index.',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColorsLight.textSecondary)),
                ),
                data: (data) => _buildBody(context, ref, isDark, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, bool isDark, FitnessIndexData data) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final card = isDark ? AppColors.surface : AppColorsLight.surface;
    // A radar with fewer than 4 of 5 axes plotted collapses to a near-vertical
    // line, not a shape — it conveys nothing. Fall back to the per-axis bar
    // rows (already rendered below) until there's enough data for a polygon
    // to actually read as one (E2E register #250).
    final axesWithData = data.axes.where((a) => a.hasData).length;
    final showRadar = axesWithData >= 4;

    return AppRefreshIndicator(
      onRefresh: () async => ref.invalidate(fitnessIndexProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Hero: overall + focus + radar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textSecondary)),
                        Text(data.overall?.toString() ?? '—',
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                color: textPrimary)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Focus: ${data.focus}',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (showRadar)
                  AspectRatio(
                    aspectRatio: 1,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, t, _) => CustomPaint(
                        painter: _FitnessRadarPainter(
                          axes: data.axes,
                          accent: accent,
                          t: t,
                          labelColor: textSecondary,
                          valueColor: textPrimary,
                          gridColor: textSecondary.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Track ${5 - axesWithData} more area${5 - axesWithData == 1 ? '' : 's'} to unlock the radar view — here\'s what\'s tracked so far:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Coach read ──
          if (data.body.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.headline,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const SizedBox(height: 8),
                  Text(data.body,
                      style: TextStyle(
                          fontSize: 14, height: 1.4, color: textSecondary)),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // ── Per-axis rows (value bar + peer percentile) ──
          ...data.axes.map((a) => _AxisRow(
                axis: a,
                accent: accent,
                card: card,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              )),
        ],
      ),
    );
  }
}

class _FitnessRadarPainter extends CustomPainter {
  final List<FitnessAxis> axes;
  final Color accent;
  final double t; // 0-1 animation
  final Color labelColor;
  final Color valueColor;
  final Color gridColor;

  const _FitnessRadarPainter({
    required this.axes,
    required this.accent,
    required this.t,
    required this.labelColor,
    required this.valueColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 34;
    final n = axes.length;
    if (n < 3) return;

    double angleAt(int i) => -math.pi / 2 + (i / n) * 2 * math.pi;

    // Concentric grid (4 rings).
    final ringPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final a = angleAt(i);
        final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, ringPaint);
    }

    // Spokes + labels + per-axis value.
    for (int i = 0; i < n; i++) {
      final a = angleAt(i);
      final outer =
          Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a));
      canvas.drawLine(center, outer, ringPaint);

      final axis = axes[i];
      final labelPos = Offset(
          center.dx + (radius + 20) * math.cos(a),
          center.dy + (radius + 20) * math.sin(a));
      final valText = axis.hasData ? '${axis.value}' : '–';
      final tp = TextPainter(
        text: TextSpan(children: [
          TextSpan(
            text: '${axis.label}\n',
            style: TextStyle(
                color: labelColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.3),
          ),
          TextSpan(
            text: valText,
            style: TextStyle(
                color: axis.hasData ? valueColor : labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w900),
          ),
        ]),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
    }

    // Value polygon (animated).
    final fillPath = Path();
    final dots = <Offset>[];
    for (int i = 0; i < n; i++) {
      final a = angleAt(i);
      final frac = axes[i].fraction.clamp(0.0, 1.0) * t;
      final r = radius * frac;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      dots.add(p);
      i == 0 ? fillPath.moveTo(p.dx, p.dy) : fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(colors: [
          accent.withValues(alpha: 0.45),
          accent.withValues(alpha: 0.18),
        ]).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = accent,
    );
    for (int i = 0; i < n; i++) {
      if (!axes[i].hasData) continue;
      canvas.drawCircle(dots[i], 4.5, Paint()..color = accent);
      canvas.drawCircle(dots[i], 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _FitnessRadarPainter old) =>
      old.t != t || old.axes != axes || old.accent != accent;
}

class _AxisRow extends StatelessWidget {
  final FitnessAxis axis;
  final Color accent;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  const _AxisRow({
    required this.axis,
    required this.accent,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final frac = (axis.value ?? 0) / 100.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(axis.label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary)),
                    if (_kAxisSource[axis.key] != null)
                      Text(_kAxisSource[axis.key]!,
                          style: TextStyle(
                              fontSize: 11.5, color: textSecondary)),
                  ],
                ),
              ),
              Text(axis.hasData ? '${axis.value}' : 'No data',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: axis.hasData ? textPrimary : textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 7,
              backgroundColor: accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            axis.percentile != null
                ? 'Better than ${axis.percentile}% of similar members'
                : (axis.hasData
                    ? 'Peer ranking unlocks as more members join'
                    : 'Log this area to start tracking it'),
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }
}
