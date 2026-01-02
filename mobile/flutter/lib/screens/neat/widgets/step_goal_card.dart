import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// A card widget displaying step goal progress with animated circular indicator.
///
/// Features:
/// - Large circular progress indicator with animated fill
/// - Current steps / Goal displayed prominently
/// - Percentage completion
/// - Color changes based on progress (red -> yellow -> green)
/// - Celebration animation when goal reached
class StepGoalCard extends StatefulWidget {
  /// Current number of steps taken today
  final int currentSteps;

  /// Daily step goal
  final int goalSteps;

  /// Whether to use dark theme
  final bool isDark;

  /// Callback when the card is tapped (e.g., to edit goal)
  final VoidCallback? onTap;

  /// Whether to show celebration animation when goal is reached
  final bool showCelebration;

  const StepGoalCard({
    super.key,
    required this.currentSteps,
    required this.goalSteps,
    this.isDark = true,
    this.onTap,
    this.showCelebration = true,
  });

  @override
  State<StepGoalCard> createState() => _StepGoalCardState();
}

class _StepGoalCardState extends State<StepGoalCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _celebrationScale;
  late Animation<double> _pulseAnimation;

  bool _hasShownCelebration = false;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Progress fill animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final targetProgress = _calculateProgress();
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // Celebration animation
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _celebrationScale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    // Pulse animation for goal reached state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressController.forward();

    // Check if goal is already reached
    if (targetProgress >= 1.0 && widget.showCelebration) {
      _triggerCelebration();
    }
  }

  double _calculateProgress() {
    if (widget.goalSteps <= 0) return 0.0;
    return (widget.currentSteps / widget.goalSteps).clamp(0.0, 1.0);
  }

  void _triggerCelebration() {
    if (_hasShownCelebration) return;
    _hasShownCelebration = true;

    HapticFeedback.heavyImpact();

    _celebrationController.forward().then((_) {
      _celebrationController.reverse();
    });

    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StepGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentSteps != widget.currentSteps ||
        oldWidget.goalSteps != widget.goalSteps) {
      _previousProgress = _progressAnimation.value;

      final targetProgress = _calculateProgress();
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: targetProgress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));

      _progressController.forward(from: 0.0);

      // Check if goal was just reached
      if (targetProgress >= 1.0 &&
          _previousProgress < 1.0 &&
          widget.showCelebration) {
        _triggerCelebration();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Returns color based on progress:
  /// - 0-33%: Red
  /// - 34-66%: Yellow/Orange
  /// - 67-99%: Yellow-Green
  /// - 100%: Green
  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return AppColors.success;
    } else if (progress >= 0.67) {
      return Color.lerp(AppColors.yellow, AppColors.success, (progress - 0.67) / 0.33)!;
    } else if (progress >= 0.34) {
      return Color.lerp(AppColors.orange, AppColors.yellow, (progress - 0.34) / 0.33)!;
    } else {
      return Color.lerp(AppColors.error, AppColors.orange, progress / 0.34)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final progress = _calculateProgress();
    final isGoalReached = progress >= 1.0;
    final percentage = (progress * 100).toInt();
    final stepsRemaining = (widget.goalSteps - widget.currentSteps).clamp(0, widget.goalSteps);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _progressAnimation,
        _celebrationScale,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        final animatedProgress = _progressAnimation.value;
        final progressColor = _getProgressColor(animatedProgress);
        final scale = isGoalReached ? _pulseAnimation.value : 1.0;
        final celebrationScale = _celebrationController.isAnimating
            ? _celebrationScale.value
            : 1.0;

        return Semantics(
          label: 'Step goal progress: ${widget.currentSteps} of ${widget.goalSteps} steps, $percentage percent complete',
          button: widget.onTap != null,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Transform.scale(
              scale: celebrationScale,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isGoalReached
                        ? AppColors.success.withOpacity(0.5)
                        : progressColor.withOpacity(0.2),
                    width: isGoalReached ? 2 : 1,
                  ),
                  boxShadow: isGoalReached
                      ? [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular progress indicator
                    Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background ring
                            CustomPaint(
                              size: const Size(200, 200),
                              painter: _CircularProgressPainter(
                                progress: 1.0,
                                color: glassSurface,
                                strokeWidth: 16,
                              ),
                            ),
                            // Progress ring
                            CustomPaint(
                              size: const Size(200, 200),
                              painter: _CircularProgressPainter(
                                progress: animatedProgress,
                                color: progressColor,
                                strokeWidth: 16,
                                hasGlow: isGoalReached,
                              ),
                            ),
                            // Center content
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isGoalReached) ...[
                                  Icon(
                                    Icons.emoji_events,
                                    size: 32,
                                    color: AppColors.success,
                                    semanticLabel: 'Goal reached',
                                  ),
                                  const SizedBox(height: 4),
                                ] else ...[
                                  Icon(
                                    Icons.directions_walk,
                                    size: 28,
                                    color: progressColor,
                                    semanticLabel: 'Steps',
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  _formatNumber(widget.currentSteps),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  'of ${_formatNumber(widget.goalSteps)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Percentage and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: progressColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: progressColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isGoalReached)
                                const Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: AppColors.success,
                                )
                              else
                                Icon(
                                  Icons.trending_up,
                                  size: 18,
                                  color: progressColor,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Status message
                    Text(
                      isGoalReached
                          ? 'Goal reached! Great job!'
                          : '${_formatNumber(stepsRemaining)} steps to go',
                      style: TextStyle(
                        fontSize: 14,
                        color: isGoalReached ? AppColors.success : textSecondary,
                        fontWeight: isGoalReached ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),

                    // Celebration particles (when goal is reached)
                    if (isGoalReached && _celebrationController.isAnimating)
                      _CelebrationParticles(
                        animationValue: _celebrationController.value,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool hasGlow;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 12,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (hasGlow) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.hasGlow != hasGlow;
  }
}

/// Simple celebration particles animation
class _CelebrationParticles extends StatelessWidget {
  final double animationValue;

  const _CelebrationParticles({required this.animationValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 50,
      child: CustomPaint(
        painter: _ParticlesPainter(animationValue: animationValue),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double animationValue;

  _ParticlesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.success,
      AppColors.yellow,
      AppColors.cyan,
      AppColors.orange,
    ];

    final random = math.Random(42); // Fixed seed for consistent particles

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final distance = 30 * animationValue;
      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 - math.sin(angle) * distance * 1.5;

      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(1 - animationValue)
        ..style = PaintingStyle.fill;

      final particleSize = 4 + random.nextDouble() * 4;
      canvas.drawCircle(Offset(x, y), particleSize * (1 - animationValue * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
