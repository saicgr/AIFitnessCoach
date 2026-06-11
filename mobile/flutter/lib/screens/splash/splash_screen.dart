import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Animated splash screen shown while app initializes and checks auth state.
/// This prevents the login screen flash when user is already authenticated.
///
/// v7 first-run redesign ("S3 pulse line"): an orange effort-spike line
/// draws itself across the screen (~900ms), the app icon ignites at
/// completion, then a soft glow breathes while the auth check finishes.
/// The stale pre-rebrand blue (#3B9BD6) is gone — splash is brand orange.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _lineController;
  late final AnimationController _iconController;
  late final AnimationController _pulseController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // The pulse line draws itself left → right.
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Icon ignites as the line completes.
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );

    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );

    // Soft breathing glow while the auth check finishes.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulse = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _lineController.forward().whenComplete(() {
      if (!mounted) return;
      _iconController.forward();
      _pulseController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _lineController.dispose();
    _iconController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_lineController, _iconController, _pulseController]),
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon — ignites when the pulse line arrives.
                FadeTransition(
                  opacity: _iconFade,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withValues(
                              alpha: _pulseController.isAnimating
                                  ? _pulse.value
                                  : 0.35,
                            ),
                            blurRadius: 44,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(21),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // The pulse line.
                SizedBox(
                  width: math.min(
                      320, MediaQuery.of(context).size.width - 70),
                  height: 60,
                  child: CustomPaint(
                    painter: _PulseLinePainter(
                      progress: Curves.easeInOutCubic
                          .transform(_lineController.value),
                      glow: _pulseController.isAnimating
                          ? 0.6 + _pulse.value * 0.5
                          : 1.0,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Draws the 3-beat effort-spike line, revealed by [progress] (0..1).
class _PulseLinePainter extends CustomPainter {
  final double progress;
  final double glow;

  _PulseLinePainter({required this.progress, required this.glow});

  // Normalized to a 320×60 design box (the approved mockup waveform):
  // flat lead-in, small beat, big center spike, medium trailing beat.
  static const List<Offset> _pts = [
    Offset(0, 30),
    Offset(38, 30),
    Offset(46, 21),
    Offset(54, 38),
    Offset(61, 30),
    Offset(112, 30),
    Offset(124, 4),
    Offset(138, 56),
    Offset(152, 12),
    Offset(162, 30),
    Offset(210, 30),
    Offset(219, 17),
    Offset(228, 44),
    Offset(236, 26),
    Offset(243, 30),
    Offset(320, 30),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final sx = size.width / 320.0;
    final sy = size.height / 60.0;

    final path = Path()..moveTo(_pts.first.dx * sx, _pts.first.dy * sy);
    for (final p in _pts.skip(1)) {
      path.lineTo(p.dx * sx, p.dy * sy);
    }

    // Reveal the path up to `progress` of its total length.
    final revealed = Path();
    for (final metric in path.computeMetrics()) {
      revealed.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }

    // Wide blurred under-stroke = glow; crisp core stroke on top.
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.orange.withValues(alpha: 0.45 * glow)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.orange;

    canvas.drawPath(revealed, glowPaint);
    canvas.drawPath(revealed, corePaint);
  }

  @override
  bool shouldRepaint(_PulseLinePainter oldDelegate) =>
      progress != oldDelegate.progress || glow != oldDelegate.glow;
}
