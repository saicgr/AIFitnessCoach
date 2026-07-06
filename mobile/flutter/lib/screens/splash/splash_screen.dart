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
                // App mark — traces itself in as the pulse line draws,
                // then ignites to a solid fill once the line completes.
                Container(
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
                    child: Container(
                      color: AppColors.pureBlack,
                      padding: const EdgeInsets.all(18),
                      child: CustomPaint(
                        painter: _ZMarkPainter(
                          outlineProgress: Curves.easeInOutCubic
                              .transform(_lineController.value),
                          fillOpacity: _iconFade.value,
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

/// Draws the Zealova "Z" mark tracing itself in as [outlineProgress] (0..1)
/// advances (synced to the pulse line below), then crossfades to a solid
/// fill as [fillOpacity] (0..1) ramps once the line completes.
///
/// Points are the traced silhouette from `assets/svg/zealova_z_mark.svg`,
/// normalized to a 0..1 unit square (that SVG's 24×24 viewBox / 24).
class _ZMarkPainter extends CustomPainter {
  final double outlineProgress;
  final double fillOpacity;

  _ZMarkPainter({required this.outlineProgress, required this.fillOpacity});

  static const List<Offset> _uv = [
    Offset(0.2392, 0.1867),
    Offset(0.1650, 0.3529),
    Offset(0.4871, 0.3542),
    Offset(0.1279, 0.6688),
    Offset(0.0833, 0.8133),
    Offset(0.8338, 0.8133),
    Offset(0.8858, 0.6546),
    Offset(0.7250, 0.6533),
    Offset(0.8117, 0.3671),
    Offset(0.4846, 0.6533),
    Offset(0.3621, 0.6521),
    Offset(0.9167, 0.1867),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(_uv.first.dx * size.width, _uv.first.dy * size.height);
    for (final p in _uv.skip(1)) {
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }
    path.close();

    if (fillOpacity > 0) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: fillOpacity);
      canvas.drawPath(path, fillPaint);
    }

    if (outlineProgress > 0 && fillOpacity < 1) {
      final revealed = Path();
      for (final metric in path.computeMetrics()) {
        revealed.addPath(
          metric.extractPath(0, metric.length * outlineProgress),
          Offset.zero,
        );
      }
      final outlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 1 - fillOpacity);
      canvas.drawPath(revealed, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(_ZMarkPainter oldDelegate) =>
      outlineProgress != oldDelegate.outlineProgress ||
      fillOpacity != oldDelegate.fillOpacity;
}
