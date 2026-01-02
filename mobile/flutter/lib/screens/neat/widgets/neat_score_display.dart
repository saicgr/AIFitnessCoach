import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Grade levels for NEAT score
enum NeatGrade {
  poor(0, 49, 'Poor', Icons.sentiment_very_dissatisfied),
  fair(50, 64, 'Fair', Icons.sentiment_dissatisfied),
  good(65, 79, 'Good', Icons.sentiment_satisfied),
  excellent(80, 89, 'Excellent', Icons.sentiment_satisfied_alt),
  perfect(90, 100, 'Perfect', Icons.emoji_events);

  final int min;
  final int max;
  final String label;
  final IconData icon;

  const NeatGrade(this.min, this.max, this.label, this.icon);

  static NeatGrade fromScore(int score) {
    if (score >= 90) return perfect;
    if (score >= 80) return excellent;
    if (score >= 65) return good;
    if (score >= 50) return fair;
    return poor;
  }

  Color get color {
    switch (this) {
      case poor:
        return AppColors.error;
      case fair:
        return AppColors.orange;
      case good:
        return AppColors.yellow;
      case excellent:
        return AppColors.cyan;
      case perfect:
        return AppColors.success;
    }
  }
}

/// Trend direction for score comparison
enum ScoreTrend {
  up,
  down,
  stable;

  IconData get icon {
    switch (this) {
      case up:
        return Icons.trending_up;
      case down:
        return Icons.trending_down;
      case stable:
        return Icons.trending_flat;
    }
  }

  Color get color {
    switch (this) {
      case up:
        return AppColors.success;
      case down:
        return AppColors.error;
      case stable:
        return AppColors.textMuted;
    }
  }
}

/// Breakdown component for NEAT score formula
class NeatScoreComponent {
  final String name;
  final int value;
  final int maxValue;
  final String description;

  const NeatScoreComponent({
    required this.name,
    required this.value,
    required this.maxValue,
    required this.description,
  });

  double get percentage => maxValue > 0 ? value / maxValue : 0;
}

/// A widget displaying the NEAT score with a circular gauge.
///
/// Features:
/// - Large circular gauge for NEAT score (0-100)
/// - Score grade: Poor (<50), Fair (50-64), Good (65-79), Excellent (80-89), Perfect (90-100)
/// - Trend arrow (up/down/stable) compared to yesterday
/// - Breakdown tooltip showing formula components
class NeatScoreDisplay extends StatefulWidget {
  /// The current NEAT score (0-100)
  final int score;

  /// Yesterday's score for trend comparison
  final int? yesterdayScore;

  /// Breakdown components of the score
  final List<NeatScoreComponent>? breakdown;

  /// Whether to use dark theme
  final bool isDark;

  /// Callback when tapped (e.g., to show details)
  final VoidCallback? onTap;

  const NeatScoreDisplay({
    super.key,
    required this.score,
    this.yesterdayScore,
    this.breakdown,
    this.isDark = true,
    this.onTap,
  });

  @override
  State<NeatScoreDisplay> createState() => _NeatScoreDisplayState();
}

class _NeatScoreDisplayState extends State<NeatScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;
  bool _showBreakdown = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(NeatScoreDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = Tween<double>(
        begin: _scoreAnimation.value,
        end: widget.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  ScoreTrend get _trend {
    if (widget.yesterdayScore == null) return ScoreTrend.stable;
    final diff = widget.score - widget.yesterdayScore!;
    if (diff > 2) return ScoreTrend.up;
    if (diff < -2) return ScoreTrend.down;
    return ScoreTrend.stable;
  }

  void _toggleBreakdown() {
    if (widget.breakdown == null || widget.breakdown!.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _showBreakdown = !_showBreakdown);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final grade = NeatGrade.fromScore(widget.score);

    return GestureDetector(
      onTap: widget.onTap ?? _toggleBreakdown,
      child: AnimatedBuilder(
        animation: _scoreAnimation,
        builder: (context, child) {
          final animatedScore = _scoreAnimation.value.round();
          final animatedGrade = NeatGrade.fromScore(animatedScore);

          return Semantics(
            label: 'NEAT Score: $animatedScore out of 100, grade: ${grade.label}',
            button: widget.onTap != null || widget.breakdown != null,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: animatedGrade.color.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 20,
                            color: animatedGrade.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NEAT Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      // Trend indicator
                      if (widget.yesterdayScore != null)
                        Semantics(
                          label: 'Trend: ${_trend.name}',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _trend.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _trend.icon,
                                  size: 16,
                                  color: _trend.color,
                                ),
                                if (_trend != ScoreTrend.stable) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(_trend == ScoreTrend.up ? '+' : '')}${widget.score - widget.yesterdayScore!}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _trend.color,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Gauge
                  SizedBox(
                    width: 180,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(180, 120),
                          painter: _GaugePainter(
                            score: animatedScore,
                            maxScore: 100,
                            gradeColor: animatedGrade.color,
                            backgroundColor: glassSurface,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                animatedScore.toString(),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  letterSpacing: -2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Grade badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: animatedGrade.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: animatedGrade.color.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          animatedGrade.icon,
                          size: 18,
                          color: animatedGrade.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          animatedGrade.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: animatedGrade.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Breakdown section
                  if (widget.breakdown != null && widget.breakdown!.isNotEmpty)
                    AnimatedCrossFade(
                      firstChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap for breakdown',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondChild: _BreakdownSection(
                        breakdown: widget.breakdown!,
                        isDark: isDark,
                      ),
                      crossFadeState: _showBreakdown
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final int maxScore;
  final Color gradeColor;
  final Color backgroundColor;

  _GaugePainter({
    required this.score,
    required this.maxScore,
    required this.gradeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    const strokeWidth = 16.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc
    final progress = score / maxScore;
    final progressPaint = Paint()
      ..color = gradeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Glow effect
    final glowPaint = Paint()
      ..color = gradeColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      glowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );

    // Draw tick marks
    final tickPaint = Paint()
      ..color = backgroundColor.withOpacity(0.8)
      ..strokeWidth = 2;

    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepAngle * i / 10);
      final outerPoint = Offset(
        center.dx + (radius + 4) * math.cos(angle),
        center.dy + (radius + 4) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 6) * math.cos(angle),
        center.dy + (radius - 6) * math.sin(angle),
      );
      canvas.drawLine(outerPoint, innerPoint, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.gradeColor != gradeColor;
  }
}

class _BreakdownSection extends StatelessWidget {
  final List<NeatScoreComponent> breakdown;
  final bool isDark;

  const _BreakdownSection({
    required this.breakdown,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: textMuted.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(
            'SCORE BREAKDOWN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...breakdown.map((component) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          component.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${component.value}/${component.maxValue}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: component.percentage,
                      backgroundColor: glassSurface,
                      color: cyan,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    component.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
