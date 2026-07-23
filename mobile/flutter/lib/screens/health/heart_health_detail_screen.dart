import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/heart_health_repository.dart';
import '../../widgets/glass_back_button.dart';
import '../pillar/widgets/ask_coach_button.dart';
import '../common/app_refresh_indicator.dart';

/// Heart Health Score detail — route `/health/heart-health`.
///
/// A single fused 0-100 cardiovascular habit score (sleep + activity +
/// RHR-trend cardio strain + body composition) shown on an animated 360°
/// gradient gauge with a day-over-day delta chip, a 2x2 component breakdown,
/// and a grounded coach read. Honest "No data" tiles where a driver is absent.
class HeartHealthDetailScreen extends ConsumerWidget {
  const HeartHealthDetailScreen({super.key});

  static const Color _good = Color(0xFF22C55E);
  static const Color _fair = Color(0xFFF59E0B);
  static const Color _poor = Color(0xFFF97316);

  static Color _scoreColor(int s) =>
      s >= 75 ? _good : (s >= 50 ? _fair : _poor);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final async = ref.watch(heartHealthProvider);

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
                  Text('Heart health',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const Spacer(),
                  AskCoachButton(
                    contextLabel: 'Heart health · habit score',
                    statSnapshot: const {'pillar': 'heart_health'},
                    source: 'heart_health',
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text('Couldn\'t load heart health.',
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
      BuildContext context, WidgetRef ref, bool isDark, HeartHealthData data) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final card = isDark ? AppColors.surface : AppColorsLight.surface;
    final scoreColor = _scoreColor(data.score);

    return AppRefreshIndicator(
      onRefresh: () async => ref.invalidate(heartHealthProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Hero gauge ──
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: data.score / 100.0),
                builder: (context, t, _) {
                  return CustomPaint(
                    painter: _GaugePainter(
                        progress: t, color: scoreColor, isDark: isDark),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(t * 100).round()}',
                              style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  color: textPrimary)),
                          const SizedBox(height: 2),
                          Text(data.label,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: scoreColor)),
                          if (data.delta != null && data.delta != 0) ...[
                            const SizedBox(height: 6),
                            _DeltaChip(delta: data.delta!),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Coach read ──
          if (data.body.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
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
          const SizedBox(height: 16),

          // ── Component tiles (2 columns) ──
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: data.components
                .map((c) => _ComponentTile(
                      component: c,
                      card: card,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0-1
  final Color color;
  final bool isDark;
  const _GaugePainter(
      {required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 14;
    const stroke = 18.0;

    // Track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
    );

    // Progress arc with sweep gradient, starting at top.
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = SweepGradient(
      startAngle: start,
      endAngle: start + 2 * math.pi,
      colors: [color.withValues(alpha: 0.55), color],
      stops: const [0.0, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );

    // Leading dot.
    if (progress > 0.01) {
      final ang = start + sweep;
      final dot = Offset(
          center.dx + radius * math.cos(ang), center.dy + radius * math.sin(ang));
      canvas.drawCircle(dot, stroke / 2 + 1, Paint()..color = color);
      canvas.drawCircle(dot, 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.color != color;
}

class _DeltaChip extends StatelessWidget {
  final int delta;
  const _DeltaChip({required this.delta});
  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final c = up ? const Color(0xFF22C55E) : const Color(0xFFF97316);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 13, color: c),
          const SizedBox(width: 2),
          Text('${delta.abs()}',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800, color: c)),
        ],
      ),
    );
  }
}

class _ComponentTile extends StatelessWidget {
  final HeartComponent component;
  final Color card;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  const _ComponentTile({
    required this.component,
    required this.card,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  Color _bandColor() {
    switch (component.band) {
      case 'Good':
        return const Color(0xFF22C55E);
      case 'Fair':
        return const Color(0xFFF59E0B);
      case 'Poor':
        return const Color(0xFFF97316);
      default:
        return textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bandColor = _bandColor();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(component.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(component.display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bandColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(component.band,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: bandColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
