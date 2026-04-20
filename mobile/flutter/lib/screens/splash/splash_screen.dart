import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animated splash screen shown while app initializes and checks auth state.
/// This prevents the login screen flash when user is already authenticated.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Logo entrance: scale up + fade in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Glow pulse: continuous breathing effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer ring rotation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Start animations
    _logoController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    // Use the FitWiz brand blue from the icon
    const brandBlue = Color(0xFF3B9BD6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_logoController, _pulseController, _shimmerController]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with glow + shimmer ring
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating shimmer ring
                        Transform.rotate(
                          angle: _shimmerController.value * 2 * pi,
                          child: CustomPaint(
                            size: const Size(140, 140),
                            painter: _ShimmerRingPainter(
                              progress: _shimmerController.value,
                              color: brandBlue,
                              opacity: _pulseAnimation.value * 0.6,
                            ),
                          ),
                        ),

                        // Glow behind logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: brandBlue
                                    .withValues(alpha: _pulseAnimation.value),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),

                        // Logo icon with scale
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: brandBlue.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    color: brandBlue,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Animated dots loading indicator
                  _LoadingDots(color: brandBlue),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Three bouncing dots loading indicator
class _LoadingDots extends StatefulWidget {
  final Color color;

  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Stagger each dot by 0.2
            final delay = index * 0.2;
            final t = (_controller.value - delay) % 1.0;
            // Bounce curve: peak at t=0.3, settle by t=0.6
            final bounce = t < 0.3
                ? Curves.easeOut.transform(t / 0.3)
                : t < 0.6
                    ? Curves.easeIn.transform(1.0 - (t - 0.3) / 0.3)
                    : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -8 * bounce),
                child: Opacity(
                  opacity: 0.4 + 0.6 * bounce,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Draws a partial arc ring with gradient opacity for shimmer effect
class _ShimmerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double opacity;

  _ShimmerRingPainter({
    required this.progress,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw a partial arc (120 degrees) with fading edges
    const sweepAngle = 2 * pi / 3; // 120 degrees
    const steps = 40;

    for (int i = 0; i < steps; i++) {
      final t = i / steps;
      // Fade from full opacity in middle to 0 at edges
      final edgeFade = sin(t * pi);
      paint.color = color.withValues(alpha: opacity * edgeFade);

      final angle = progress * 2 * pi + t * sweepAngle;
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(_ShimmerRingPainter oldDelegate) =>
      progress != oldDelegate.progress || opacity != oldDelegate.opacity;
}
