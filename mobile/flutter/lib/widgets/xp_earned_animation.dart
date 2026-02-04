import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';

/// XP goal types with their associated icons and colors
enum XPGoalType {
  dailyLogin,
  weightLog,
  mealLog,
  workoutComplete,
  proteinGoal,
  bodyMeasurements,
}

extension XPGoalTypeExtension on XPGoalType {
  /// Icon for this goal type
  IconData get icon {
    switch (this) {
      case XPGoalType.dailyLogin:
        return Icons.login_rounded;
      case XPGoalType.weightLog:
        return Icons.scale_rounded;
      case XPGoalType.mealLog:
        return Icons.restaurant_rounded;
      case XPGoalType.workoutComplete:
        return Icons.fitness_center_rounded;
      case XPGoalType.proteinGoal:
        return Icons.egg_rounded;
      case XPGoalType.bodyMeasurements:
        return Icons.straighten_rounded;
    }
  }

  /// Color for this goal type
  Color get color {
    switch (this) {
      case XPGoalType.dailyLogin:
        return AppColors.orange;
      case XPGoalType.weightLog:
        return const Color(0xFF06B6D4); // Cyan
      case XPGoalType.mealLog:
        return AppColors.purple;
      case XPGoalType.workoutComplete:
        return AppColors.orange;
      case XPGoalType.proteinGoal:
        return AppColors.green;
      case XPGoalType.bodyMeasurements:
        return const Color(0xFFEC4899); // Pink
    }
  }

  /// Display label for this goal type
  String get label {
    switch (this) {
      case XPGoalType.dailyLogin:
        return 'Daily login';
      case XPGoalType.weightLog:
        return 'Weight logged';
      case XPGoalType.mealLog:
        return 'Meal logged';
      case XPGoalType.workoutComplete:
        return 'Workout complete';
      case XPGoalType.proteinGoal:
        return 'Protein goal';
      case XPGoalType.bodyMeasurements:
        return 'Measurements logged';
    }
  }
}

/// Event representing XP earned that should trigger an animation
class XPEarnedEvent {
  final int xpAmount;
  final XPGoalType goalType;
  final DateTime timestamp;

  XPEarnedEvent({
    required this.xpAmount,
    required this.goalType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Floating XP toast animation that shows at the top of the screen
/// with mini confetti and haptic feedback
class XPEarnedToast extends StatefulWidget {
  final int xpAmount;
  final XPGoalType goalType;
  final VoidCallback? onDismiss;

  const XPEarnedToast({
    super.key,
    required this.xpAmount,
    required this.goalType,
    this.onDismiss,
  });

  @override
  State<XPEarnedToast> createState() => _XPEarnedToastState();
}

class _XPEarnedToastState extends State<XPEarnedToast>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late List<_ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Trigger haptic feedback on entry
    HapticFeedback.lightImpact();

    // Initialize confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initParticles();
    _confettiController.forward();

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  void _initParticles() {
    final goalColor = widget.goalType.color;
    final colors = [
      goalColor,
      goalColor.withValues(alpha: 0.8),
      AppColors.orange,
      const Color(0xFFFFD700), // Gold
      Colors.white,
    ];

    _particles = List.generate(15, (index) {
      // Particles spread in a semi-circle above the toast
      final angle = (pi * 0.3) + (_random.nextDouble() * pi * 0.4);
      final velocity = 80 + _random.nextDouble() * 120;
      return _ConfettiParticle(
        x: 0,
        y: 0,
        vx: cos(angle) * velocity * (_random.nextBool() ? 1 : -1),
        vy: -sin(angle) * velocity, // Upward burst
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        color: colors[_random.nextInt(colors.length)],
        size: 4 + _random.nextDouble() * 4,
      );
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goalColor = widget.goalType.color;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Confetti particles
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                    size: const Size(200, 100),
                  );
                },
              ),

              // Main toast container
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.elevated.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: goalColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: goalColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Goal type icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.goalType.icon,
                        color: goalColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // XP amount and label
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // XP amount with glow
                        Text(
                          '+${widget.xpAmount} XP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: goalColor,
                            shadows: [
                              Shadow(
                                color: goalColor.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        // Goal type label
                        Text(
                          widget.goalType.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColorsLight.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  // Entry: slide down from top with elastic bounce
                  .slideY(
                    begin: -1.5,
                    end: 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                  )
                  // Scale pop on entry
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                  )
                  // Fade in
                  .fadeIn(duration: const Duration(milliseconds: 150))
                  // Then after 1.2 seconds, start exit animation
                  .then(delay: const Duration(milliseconds: 1200))
                  // Exit: fade out and slide up
                  .fadeOut(duration: const Duration(milliseconds: 500))
                  .slideY(
                    begin: 0,
                    end: -0.5,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple confetti particle
class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  Color color;
  double size;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });
}

/// Custom painter for mini confetti burst
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const gravity = 200.0;
    final dt = progress * 0.8; // Time elapsed (800ms duration)

    for (final particle in particles) {
      // Calculate position with physics
      final x = centerX + particle.vx * dt;
      final y = centerY + particle.vy * dt + 0.5 * gravity * dt * dt;

      // Calculate opacity (fade out towards end)
      final opacity = progress < 0.6 ? 1.0 : (1 - progress) / 0.4;

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * dt);

      // Draw as small rectangle
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Overlay manager for showing XP earned animations
class XPEarnedOverlay {
  static OverlayEntry? _currentEntry;

  /// Show XP earned animation at the top of the screen
  static void show(
    BuildContext context, {
    required int xpAmount,
    required XPGoalType goalType,
  }) {
    // Dismiss any existing toast
    dismiss();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: XPEarnedToast(
            xpAmount: xpAmount,
            goalType: goalType,
            onDismiss: dismiss,
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);
  }

  /// Dismiss the current toast
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
