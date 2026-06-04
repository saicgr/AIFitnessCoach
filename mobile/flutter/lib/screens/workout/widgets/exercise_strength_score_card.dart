import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/stat_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/exercise_strength_score.dart';
import '../../../data/providers/exercise_strength_score_provider.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/metric_grid.dart';
import 'exercise_mini_chart.dart';

/// Per-exercise strength score card (Gravl-parity, Surface 2 / Image #2).
///
/// Watches [exerciseStrengthScoreProvider] for the given exercise and renders:
///  • a glowing [HexagonBadge] with the strength score in the top-right,
///  • a 2×2 [MetricGrid] of the best lift from the last 3 months
///    (Weight → lb, Reps, One-rep max → lb, Date),
///  • an e1RM sparkline built from the score history.
///
/// States:
///  • `hasData`   → the full card above.
///  • `!hasData`  → a compact "Log a few sets to unlock your strength score".
///  • loading     → a layout-matched skeleton (never a spinner block).
///
/// User works out in LB — weights from the model arrive in kg and are converted
/// with [WeightUtils.kgToLbsGym] so they read as the gym-standard pounds the
/// user recognizes (60 kg → 135 lb), matching the set table.
class ExerciseStrengthScoreCard extends ConsumerWidget {
  /// Exercise display name — the key for [exerciseStrengthScoreProvider].
  final String exerciseName;

  /// Outer margin so callers can drop the card straight into a Column/ListView.
  final EdgeInsetsGeometry margin;

  const ExerciseStrengthScoreCard({
    super.key,
    required this.exerciseName,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(exerciseStrengthScoreProvider(exerciseName));
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final accent = colors.accent;

    return scoreAsync.when(
      loading: () => Padding(
        padding: margin,
        child: const _StrengthScoreSkeleton(),
      ),
      // Never surface a raw error here — the score is a secondary, best-effort
      // enrichment. Treat a failed fetch like "no data yet" so the card stays
      // quiet instead of throwing a red banner over the set list.
      error: (_, __) => Padding(
        padding: margin,
        child: _EmptyStrengthScore(accent: accent, textMuted: colors.textMuted),
      ),
      data: (score) {
        if (!score.hasData || score.best == null) {
          return Padding(
            padding: margin,
            child:
                _EmptyStrengthScore(accent: accent, textMuted: colors.textMuted),
          );
        }
        return Padding(
          padding: margin,
          child: _StrengthScoreContent(
            score: score,
            accent: accent,
            isDark: isDark,
            colors: colors,
          ),
        );
      },
    );
  }
}

/// The populated card — header (title + subtitle + hexagon badge), 2×2 metric
/// grid, and an e1RM sparkline.
class _StrengthScoreContent extends StatelessWidget {
  final ExerciseStrengthScore score;
  final Color accent;
  final bool isDark;
  final ThemeColors colors;

  const _StrengthScoreContent({
    required this.score,
    required this.accent,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final best = score.best!;

    // kg → gym-standard lb (user works out in lb).
    final weightLb = WeightUtils.kgToLbsGym(best.weightKg);
    final oneRmLb = WeightUtils.kgToLbsGym(best.estimated1rmKg);

    final dateText = best.achievedAt != null
        ? DateFormat('d MMM yyyy').format(best.achievedAt!)
        : '—';

    // e1RM sparkline points (oldest first), converted to lb. The mini chart
    // shows a sparkline when ≥2 points exist, else a tidy "not enough history".
    final e1rmLb = <double>[];
    final dateLabels = <String>[];
    for (final p in score.history) {
      if (p.e1rm <= 0) continue;
      e1rmLb.add(WeightUtils.kgToLbsGym(p.e1rm));
      dateLabels.add(p.date != null ? DateFormat('d MMM').format(p.date!) : '');
    }

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: title + subtitle on the left, hexagon badge on the right.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 18, color: accent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Strength Score',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Best lift from the last 3 months',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted,
                      ),
                    ),
                    if (score.levelDisplay.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.12 : 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.35),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          score.levelDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Count-up hexagon score badge. The hexagon glow + accent color
              // matches the foundation HexagonBadge used elsewhere.
              _AnimatedHexScore(value: score.score, accent: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── 2×2 best-lift grid.
          MetricGrid(
            columns: 2,
            items: [
              MetricCell(
                label: 'Weight',
                value: _trimNum(weightLb),
                unit: 'lb',
                accent: accent,
                icon: Icons.fitness_center,
              ),
              MetricCell(
                label: 'Reps',
                value: '${best.reps}',
                accent: colors.textPrimary,
                icon: Icons.repeat_rounded,
              ),
              MetricCell(
                label: 'One-rep max',
                value: _trimNum(oneRmLb),
                unit: 'lb',
                accent: accent,
                icon: Icons.trending_up_rounded,
              ),
              MetricCell(
                label: 'Date',
                value: dateText,
                accent: colors.textPrimary,
                icon: Icons.event_rounded,
              ),
            ],
          ),

          // ── e1RM sparkline (only when there's any history to plot).
          if (e1rmLb.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 14, color: colors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Estimated 1RM trend',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ExerciseMiniChart(
              weights: e1rmLb,
              dates: dateLabels,
              isDark: isDark,
              accentColor: accent,
            ),
          ],
        ],
      ),
    );
  }

  /// Format a lb value with no trailing ".0" (e.g. 135.0 → "135", 137.5 → "137.5").
  String _trimNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

/// A glowing hexagon badge whose number counts up on first build. Mirrors the
/// foundation [HexagonBadge] look (translucent fill + crisp outline + outer
/// glow) but drives the centered number through [AnimatedStatNumber] so it
/// animates 0 → score for a tasteful entrance.
class _AnimatedHexScore extends StatelessWidget {
  final int value;
  final Color accent;

  const _AnimatedHexScore({required this.value, required this.accent});

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _HexGlowPainter(color: accent),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _size * 0.18),
            child: AnimatedStatNumber(
              value: value.toDouble(),
              format: (v) => v.round().toString(),
              size: _size * 0.40,
              color: accent,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Flat-top hexagon with translucent fill, crisp outline, and a soft outer
/// glow — a local copy of the foundation HexagonBadge painter so the animated
/// number can be hosted inside (the shared widget takes a static String value).
class _HexGlowPainter extends CustomPainter {
  final Color color;

  _HexGlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  Path _hexPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width < size.height ? size.width : size.height) / 2 - 2;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final deg = 60.0 * i; // flat-top
      final rad = deg * math.pi / 180.0;
      final x = cx + r * math.cos(rad);
      final y = cy + r * math.sin(rad);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_HexGlowPainter old) => old.color != color;
}

/// Compact empty state shown when the exercise has no logged history yet.
class _EmptyStrengthScore extends StatelessWidget {
  final Color accent;
  final Color textMuted;

  const _EmptyStrengthScore({required this.accent, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log a few sets to unlock your strength score',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layout-matched skeleton: header row (text block + badge), a 2×2 grid block,
/// and a sparkline block. Reflow-free swap to the real content.
class _StrengthScoreSkeleton extends StatelessWidget {
  const _StrengthScoreSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final base = colors.glassSurface;

    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(140, 16),
                    const SizedBox(height: 8),
                    bar(180, 12),
                    const SizedBox(height: 10),
                    bar(64, 18),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: bar(double.infinity, 58)),
              const SizedBox(width: 10),
              Expanded(child: bar(double.infinity, 58)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: bar(double.infinity, 58)),
              const SizedBox(width: 10),
              Expanded(child: bar(double.infinity, 58)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          bar(double.infinity, 60),
        ],
      ),
    );
  }
}
