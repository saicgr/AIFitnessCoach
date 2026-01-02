/// Transition countdown overlay widget
///
/// Displays a countdown (5-10 seconds) before transitioning to the next exercise.
/// Shows the upcoming exercise name and thumbnail with animated countdown.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Transition countdown overlay displayed before moving to next exercise
class TransitionCountdownOverlay extends StatefulWidget {
  /// Current countdown seconds remaining
  final int secondsRemaining;

  /// Initial countdown duration for progress calculation
  final int initialDuration;

  /// Next exercise to show
  final WorkoutExercise nextExercise;

  /// Optional image URL for next exercise
  final String? nextExerciseImageUrl;

  /// Callback to skip transition
  final VoidCallback onSkip;

  const TransitionCountdownOverlay({
    super.key,
    required this.secondsRemaining,
    required this.initialDuration,
    required this.nextExercise,
    this.nextExerciseImageUrl,
    required this.onSkip,
  });

  @override
  State<TransitionCountdownOverlay> createState() =>
      _TransitionCountdownOverlayState();
}

class _TransitionCountdownOverlayState extends State<TransitionCountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Progress for circular indicator (1.0 = full, 0.0 = done)
  double get progress => widget.initialDuration > 0
      ? widget.secondsRemaining / widget.initialDuration
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.pureBlack.withOpacity(0.95)
        : AppColorsLight.surface.withOpacity(0.98);
    final cardBg =
        isDark ? AppColors.elevated.withOpacity(0.9) : AppColorsLight.elevated;
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;
    final subtitleColor =
        isDark ? Colors.white70 : AppColorsLight.textSecondary;

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // GET READY label
              _buildGetReadyLabel(),

              const SizedBox(height: 32),

              // Animated circular countdown
              _buildCircularCountdown(textColor, isDark),

              const SizedBox(height: 40),

              // Next exercise card
              _buildNextExerciseCard(cardBg, textColor, subtitleColor, isDark),

              const Spacer(flex: 2),

              // Skip button
              _buildSkipButton(isDark),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildGetReadyLabel() {
    return Column(
      children: [
        Text(
          'GET READY',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.cyan,
            letterSpacing: 4,
          ),
        ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              delay: 500.ms,
              duration: 1500.ms,
              color: AppColors.cyan.withOpacity(0.3),
            ),
        const SizedBox(height: 8),
        Text(
          'Next exercise starting soon',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularCountdown(Color textColor, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.secondsRemaining <= 3 ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),

                // Progress arc
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: progress,
                      strokeWidth: 8,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      progressColor: widget.secondsRemaining <= 3
                          ? AppColors.orange
                          : AppColors.cyan,
                    ),
                  ),
                ),

                // Countdown number
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.secondsRemaining}',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: widget.secondsRemaining <= 3
                            ? AppColors.orange
                            : textColor,
                        height: 1,
                      ),
                    )
                        .animate(
                          key: ValueKey(widget.secondsRemaining),
                        )
                        .scale(
                          begin: const Offset(1.3, 1.3),
                          end: const Offset(1.0, 1.0),
                          duration: 200.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: 150.ms),
                    const SizedBox(height: 4),
                    Text(
                      'seconds',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.54),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextExerciseCard(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    final exercise = widget.nextExercise;
    final imageUrl = widget.nextExerciseImageUrl ?? exercise.gifUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Exercise thumbnail
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.cyan.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.cyan),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    child: Icon(
                      Icons.fitness_center,
                      color: AppColors.cyan,
                      size: 40,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),

          // "UP NEXT" label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'UP NEXT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Exercise name
          Text(
            exercise.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Exercise details (sets x reps)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDetailChip(
                Icons.repeat,
                '${exercise.sets ?? 3} sets',
                subtitleColor,
                isDark,
              ),
              const SizedBox(width: 12),
              _buildDetailChip(
                Icons.fitness_center,
                '${exercise.reps ?? 10} reps',
                subtitleColor,
                isDark,
              ),
              if (exercise.weight != null && exercise.weight! > 0) ...[
                const SizedBox(width: 12),
                _buildDetailChip(
                  Icons.scale,
                  '${exercise.weight}kg',
                  subtitleColor,
                  isDark,
                ),
              ],
            ],
          ),

          // Body part / muscle group
          if (exercise.primaryMuscle != null || exercise.bodyPart != null) ...[
            const SizedBox(height: 12),
            Text(
              exercise.primaryMuscle ?? exercise.bodyPart ?? '',
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildDetailChip(
    IconData icon,
    String text,
    Color subtitleColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: subtitleColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(bool isDark) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        widget.onSkip();
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        backgroundColor:
            isDark ? Colors.white.withOpacity(0.1) : AppColorsLight.cardBorder,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: Icon(Icons.skip_next, color: AppColors.cyan, size: 22),
      label: Text(
        'Start Now',
        style: TextStyle(
          color: AppColors.cyan,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 300.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
