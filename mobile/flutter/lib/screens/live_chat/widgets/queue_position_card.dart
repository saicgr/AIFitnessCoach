import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Queue position card displayed while waiting for an agent
class QueuePositionCard extends StatelessWidget {
  final int position;
  final int estimatedWaitMinutes;
  final VoidCallback onCancel;

  const QueuePositionCard({
    super.key,
    required this.position,
    required this.estimatedWaitMinutes,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated pulsing indicator
          const _PulsingQueueIndicator(),

          const SizedBox(height: 24),

          // Queue position
          Text(
            'You are',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          // Position number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '#$position',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'in queue',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Estimated wait time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estimated wait: ~$estimatedWaitMinutes min',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info text
          Text(
            'Please wait while we connect you\nwith a support agent',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                HapticService.medium();
                onCancel();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Animated pulsing indicator for queue status
class _PulsingQueueIndicator extends StatefulWidget {
  const _PulsingQueueIndicator();

  @override
  State<_PulsingQueueIndicator> createState() => _PulsingQueueIndicatorState();
}

class _PulsingQueueIndicatorState extends State<_PulsingQueueIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulsePainter(
              progress: _controller.value,
              color: AppColors.cyan,
            ),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cyan,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for pulse animation
class _PulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  _PulsePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw multiple expanding circles
    for (int i = 0; i < 3; i++) {
      final circleProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 24.0 + (circleProgress * 32.0);
      final opacity = (1.0 - circleProgress) * 0.3;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Compact queue position badge
class QueuePositionBadge extends StatelessWidget {
  final int position;

  const QueuePositionBadge({
    super.key,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            '#$position in queue',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Waiting animation widget
class WaitingAnimation extends StatefulWidget {
  const WaitingAnimation({super.key});

  @override
  State<WaitingAnimation> createState() => _WaitingAnimationState();
}

class _WaitingAnimationState extends State<WaitingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Icon(
            Icons.hourglass_empty,
            size: 24,
            color: AppColors.warning,
          ),
        );
      },
    );
  }
}
