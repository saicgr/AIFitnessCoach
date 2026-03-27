import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/services/posthog_service.dart';

/// Full-screen celebration shown after subscription purchase is verified.
/// Dark gym-aesthetic with animated confetti and bold typography.
class SubscriptionSuccessScreen extends ConsumerStatefulWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  ConsumerState<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState
    extends ConsumerState<SubscriptionSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _confettiController;
  late final Animation<double> _imageFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    // Track subscription success screen view
    Future.microtask(() {
      ref.read(posthogServiceProvider).capture(
        eventName: 'paywall_subscription_success_viewed',
      );
    });
    HapticFeedback.heavyImpact();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Staggered entrance: image → text → button (faster)
    _imageFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onContinue() {
    HapticFeedback.mediumImpact();
    context.go('/workout-loading');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: dark gradient with subtle gym icon pattern
          _GymBackground(imageFade: _imageFade),

          // Bottom gradient overlay for text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.4, 0.65, 0.8],
                ),
              ),
            ),
          ),

          // Confetti particles
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _ConfettiPainter(
                progress: _confettiController.value,
                accent: colors.accent,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 5),

                  // Heading
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Checkmark badge
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome to\nFitWiz Pro!',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your AI-powered fitness journey starts now. '
                            'Personalized workouts, smart nutrition tracking, '
                            'and a coach that never sleeps — all unlocked.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // CTA button
                  SlideTransition(
                    position: _buttonSlide,
                    child: FadeTransition(
                      opacity: _buttonFade,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "LET'S GO",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Background with gym-themed visuals
// =============================================================================

class _GymBackground extends StatelessWidget {
  final Animation<double> imageFade;

  const _GymBackground({required this.imageFade});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: imageFade,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark base
          const ColoredBox(color: Colors.black),

          // Subtle gym-themed icon grid for visual texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(
                painter: _GymIconGridPainter(),
              ),
            ),
          ),

          // Gradient color accent at top
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            height: 400,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Gym icon grid painter — draws subtle dumbbell/fitness icons
// =============================================================================

class _GymIconGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const spacing = 80.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * spacing + (r.isOdd ? spacing / 2 : 0);
        final y = r * spacing;
        final type = (r * cols + c) % 3;

        if (type == 0) {
          // Dumbbell
          canvas.drawLine(Offset(x - 12, y), Offset(x + 12, y), paint);
          canvas.drawRect(
            Rect.fromCenter(center: Offset(x - 12, y), width: 6, height: 14),
            paint,
          );
          canvas.drawRect(
            Rect.fromCenter(center: Offset(x + 12, y), width: 6, height: 14),
            paint,
          );
        } else if (type == 1) {
          // Heart / health
          canvas.drawCircle(Offset(x, y), 8, paint);
          canvas.drawLine(
            Offset(x - 5, y),
            Offset(x + 5, y),
            paint..strokeWidth = 1.5,
          );
          canvas.drawLine(
            Offset(x, y - 5),
            Offset(x, y + 5),
            paint,
          );
          paint.strokeWidth = 2.0;
        } else {
          // Lightning bolt (energy)
          final path = Path()
            ..moveTo(x + 2, y - 10)
            ..lineTo(x - 4, y + 1)
            ..lineTo(x + 1, y + 1)
            ..lineTo(x - 2, y + 10);
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// Confetti particle painter
// =============================================================================

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color accent;

  _ConfettiPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final rng = math.Random(42);
    const count = 40;

    for (int i = 0; i < count; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = -20.0 - rng.nextDouble() * 100;
      final speed = 0.5 + rng.nextDouble() * 0.8;
      final drift = (rng.nextDouble() - 0.5) * 60;
      final rotationSpeed = rng.nextDouble() * 4;

      final t = (progress * speed).clamp(0.0, 1.0);
      final x = startX + drift * t;
      final y = startY + size.height * 1.2 * t;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final colors = [
        accent,
        Colors.white,
        accent.withValues(alpha: 0.7),
        const Color(0xFFF59E0B),
        const Color(0xFF8B5CF6),
      ];
      final color = colors[i % colors.length].withValues(alpha: opacity * 0.8);

      final paint = Paint()..color = color;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotationSpeed * progress * math.pi);

      // Small rectangle confetti
      final w = 4.0 + rng.nextDouble() * 4;
      final h = 2.0 + rng.nextDouble() * 3;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
