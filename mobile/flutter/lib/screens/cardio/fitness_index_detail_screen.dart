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
class FitnessIndexDetailScreen extends ConsumerWidget {
  const FitnessIndexDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final async = ref.watch(fitnessIndexProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  const GlassBackButton(),
                  const SizedBox(width: 12),
                  Text('Fitness index',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
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
                child: Text(axis.label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
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
