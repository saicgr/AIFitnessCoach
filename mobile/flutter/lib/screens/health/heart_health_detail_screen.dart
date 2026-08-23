import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/stats/state_valence.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
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
class HeartHealthDetailScreen extends ConsumerStatefulWidget {
  /// True when composed inside the Health tab's shell rather than pushed as
  /// a full-screen route — see [CombinedHealthScreen.embedded]. Drops the
  /// back-button row (nothing to pop) and the opaque background; the
  /// Ask-Coach button and the whole body are unchanged.
  final bool embedded;

  const HeartHealthDetailScreen({super.key, this.embedded = false});

  @override
  ConsumerState<HeartHealthDetailScreen> createState() =>
      _HeartHealthDetailScreenState();
}

class _HeartHealthDetailScreenState
    extends ConsumerState<HeartHealthDetailScreen> {
  // Instant-load standard (Part 1): a true first-ever open shows the layout
  // skeleton below, never a bare spinner. Every later open renders cached
  // content instantly (see CacheFirstView / heartHealthProvider).
  bool _isFirstEver = false;

  static const Color _good = Color(0xFF22C55E); // accent-allowlist: heart-rate zone severity scale, matches hr_zones_card.dart convention
  static const Color _fair = Color(0xFFF59E0B); // accent-allowlist: heart-rate zone severity scale, matches hr_zones_card.dart convention
  static const Color _poor = Color(0xFFF97316); // accent-allowlist: heart-rate zone severity scale, matches hr_zones_card.dart convention

  static Color _scoreColor(int s) =>
      s >= 75 ? _good : (s >= 50 ? _fair : _poor);

  @override
  void initState() {
    super.initState();
    CacheFirstView.hasBeenSeen('heart_health_detail').then((seen) {
      if (mounted) setState(() => _isFirstEver = !seen);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final async = ref.watch(heartHealthProvider);

    return Scaffold(
      backgroundColor: widget.embedded ? Colors.transparent : bg,
      body: SafeArea(
        top: !widget.embedded,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, widget.embedded ? 0 : 8, 16, 4),
              child: Row(
                children: [
                  if (!widget.embedded) ...[
                    const GlassBackButton(),
                    const SizedBox(width: 12),
                  ],
                  // Shown even when embedded in the Health tab's RECOVERY
                  // chip — the score here is the Heart Health composite, a
                  // different metric from the Overview tab's Recovery ring,
                  // and nothing else on screen names it.
                  //
                  // Flexible + ellipsis: at larger Dynamic Type sizes this
                  // title otherwise grows wide enough to push the
                  // AskCoachButton past the right edge instead of yielding to
                  // it.
                  Flexible(
                    child: Text('Heart health',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                  ),
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
              child: CacheFirstView<HeartHealthData>(
                value: async,
                isFirstEver: _isFirstEver,
                traceLabel: 'heart_health_detail',
                skeletonBuilder: (_) => _buildSkeleton(isDark),
                errorBuilder: (_, __, ___) => Center(
                  child: Text('Couldn\'t load heart health.',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColorsLight.textSecondary)),
                ),
                contentBuilder: (context, data) {
                  CacheFirstView.markSeen('heart_health_detail');
                  return _buildBody(context, isDark, data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(child: SkeletonCircle(size: 220)),
        const SizedBox(height: 16),
        const SkeletonBox(height: 96, radius: 18),
        const SizedBox(height: 16),
        SkeletonGrid(itemCount: 4, crossAxisCount: 2, childAspectRatio: 1.55),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, HeartHealthData data) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final card = isDark ? AppColors.surface : AppColorsLight.surface;
    final textMuted = ThemeColors.of(context).textMuted;
    final hasScore = data.hasScore;
    final scoreColor = hasScore ? _scoreColor(data.score!) : textMuted;

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
                tween: Tween(begin: 0, end: hasScore ? data.score! / 100.0 : 0),
                builder: (context, t, _) {
                  return CustomPaint(
                    painter: _GaugePainter(
                        progress: t, color: scoreColor, isDark: isDark),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(hasScore ? '${(t * 100).round()}' : '—',
                              style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  color: hasScore ? textPrimary : textMuted)),
                          const SizedBox(height: 2),
                          Text(hasScore ? data.label! : 'Not enough data yet',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: scoreColor)),
                          if (hasScore &&
                              data.delta != null &&
                              data.delta != 0) ...[
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
    // Heart-health score declares higher-is-better: a rising composite
    // supports, a falling one strains. Was two raw hexes picked off the sign.
    final c = SemanticState.resolve(
      valence: MetricValence.forKey('heart_health'),
      deviation: delta.toDouble(),
    ).color(context);
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
        return const Color(0xFF22C55E); // accent-allowlist: heart-rate zone severity scale, matches hr_zones_card.dart convention
      case 'Fair':
        return const Color(0xFFF59E0B); // accent-allowlist: heart-rate zone severity scale, matches hr_zones_card.dart convention
      case 'Poor':
        return const Color(0xFFF97316); // accent-allowlist: heart-rate zone severity scale, matches hr_zones_card.dart convention
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
