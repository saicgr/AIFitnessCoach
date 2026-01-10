import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Animated human body silhouette that fills with water based on hydration percentage
class BodyHydrationAnimation extends StatefulWidget {
  final double fillPercentage; // 0.0 to 1.0
  final bool isDark;
  final double size;

  const BodyHydrationAnimation({
    super.key,
    required this.fillPercentage,
    required this.isDark,
    this.size = 200,
  });

  @override
  State<BodyHydrationAnimation> createState() => _BodyHydrationAnimationState();
}

class _BodyHydrationAnimationState extends State<BodyHydrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  double _currentFill = 0.0;

  @override
  void initState() {
    super.initState();

    // Wave animation - continuous loop
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Fill animation - smooth transition when percentage changes
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _currentFill = widget.fillPercentage;
    _fillAnimation = Tween<double>(
      begin: _currentFill,
      end: _currentFill,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(BodyHydrationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillPercentage != widget.fillPercentage) {
      _fillAnimation = Tween<double>(
        begin: _currentFill,
        end: widget.fillPercentage,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ));
      _fillController.forward(from: 0).then((_) {
        _currentFill = widget.fillPercentage;
      });
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterColor =
        widget.isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final bodyOutlineColor =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textColor =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return SizedBox(
      width: widget.size,
      height: widget.size * 1.4, // Body is taller than wide
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _fillAnimation]),
        builder: (context, child) {
          final fillValue = _fillAnimation.value.clamp(0.0, 1.0);
          final percentage = (fillValue * 100).round();

          return Stack(
            alignment: Alignment.center,
            children: [
              // Body with water fill
              CustomPaint(
                size: Size(widget.size, widget.size * 1.4),
                painter: BodyHydrationPainter(
                  fillPercentage: fillValue,
                  waveOffset: _waveController.value * 2 * math.pi,
                  waterColor: waterColor,
                  bodyOutlineColor: bodyOutlineColor,
                  isDark: widget.isDark,
                ),
              ),

              // Percentage text overlay
              Positioned(
                top: widget.size * 0.45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: widget.size * 0.15,
                        fontWeight: FontWeight.bold,
                        color: fillValue > 0.4
                            ? Colors.white.withValues(alpha: 0.9)
                            : textColor,
                        shadows: fillValue > 0.4
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                )
                              ]
                            : null,
                      ),
                    ),
                    Text(
                      'hydrated',
                      style: TextStyle(
                        fontSize: widget.size * 0.06,
                        fontWeight: FontWeight.w500,
                        color: fillValue > 0.4
                            ? Colors.white.withValues(alpha: 0.7)
                            : (widget.isDark
                                ? AppColors.textMuted
                                : AppColorsLight.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BodyHydrationPainter extends CustomPainter {
  final double fillPercentage;
  final double waveOffset;
  final Color waterColor;
  final Color bodyOutlineColor;
  final bool isDark;

  BodyHydrationPainter({
    required this.fillPercentage,
    required this.waveOffset,
    required this.waterColor,
    required this.bodyOutlineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPath = _createBodyPath(size);

    // Draw body background (empty state)
    final emptyPaint = Paint()
      ..color = isDark
          ? AppColors.elevated.withValues(alpha: 0.5)
          : AppColorsLight.elevated.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, emptyPaint);

    // Draw water fill
    if (fillPercentage > 0) {
      canvas.save();
      canvas.clipPath(bodyPath);

      final waterHeight = size.height * fillPercentage;
      final waterTop = size.height - waterHeight;

      // Create water path with wave effect
      final waterPath = Path();
      waterPath.moveTo(0, size.height);

      // Bottom of water
      waterPath.lineTo(0, waterTop);

      // Wave at top of water
      for (double x = 0; x <= size.width; x += 2) {
        final waveHeight = math.sin((x / size.width * 4 * math.pi) + waveOffset) * 4;
        waterPath.lineTo(x, waterTop + waveHeight);
      }

      waterPath.lineTo(size.width, size.height);
      waterPath.close();

      // Water gradient
      final waterPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            waterColor.withValues(alpha: 0.6),
            waterColor.withValues(alpha: 0.8),
            waterColor,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, waterTop, size.width, waterHeight));

      canvas.drawPath(waterPath, waterPaint);

      // Add subtle bubbles
      _drawBubbles(canvas, size, waterTop, waterHeight);

      canvas.restore();
    }

    // Draw body outline
    final outlinePaint = Paint()
      ..color = bodyOutlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, outlinePaint);
  }

  Path _createBodyPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Human silhouette - standing pose with arms slightly away from body
    // Start from top of head

    // HEAD (oval shape)
    path.moveTo(w * 0.42, h * 0.08);
    path.quadraticBezierTo(w * 0.42, h * 0.02, w * 0.50, h * 0.02);
    path.quadraticBezierTo(w * 0.58, h * 0.02, w * 0.58, h * 0.08);
    path.quadraticBezierTo(w * 0.58, h * 0.11, w * 0.54, h * 0.12);

    // NECK (right side)
    path.lineTo(w * 0.54, h * 0.14);

    // RIGHT SHOULDER
    path.quadraticBezierTo(w * 0.60, h * 0.14, w * 0.72, h * 0.16);
    path.quadraticBezierTo(w * 0.80, h * 0.17, w * 0.82, h * 0.20);

    // RIGHT ARM (slightly away from body)
    path.quadraticBezierTo(w * 0.86, h * 0.24, w * 0.84, h * 0.32);
    path.quadraticBezierTo(w * 0.82, h * 0.38, w * 0.78, h * 0.42);
    // Right hand
    path.quadraticBezierTo(w * 0.76, h * 0.44, w * 0.74, h * 0.43);
    // Right arm inner
    path.quadraticBezierTo(w * 0.72, h * 0.40, w * 0.70, h * 0.34);
    path.quadraticBezierTo(w * 0.68, h * 0.28, w * 0.68, h * 0.24);

    // RIGHT TORSO
    path.lineTo(w * 0.66, h * 0.28);
    path.quadraticBezierTo(w * 0.68, h * 0.36, w * 0.66, h * 0.42);

    // RIGHT WAIST & HIP
    path.quadraticBezierTo(w * 0.64, h * 0.46, w * 0.66, h * 0.50);
    path.quadraticBezierTo(w * 0.68, h * 0.54, w * 0.66, h * 0.56);

    // RIGHT LEG (thigh)
    path.quadraticBezierTo(w * 0.66, h * 0.62, w * 0.64, h * 0.68);
    // Right knee
    path.quadraticBezierTo(w * 0.63, h * 0.72, w * 0.62, h * 0.76);
    // Right calf
    path.quadraticBezierTo(w * 0.61, h * 0.84, w * 0.60, h * 0.90);
    // Right ankle
    path.quadraticBezierTo(w * 0.59, h * 0.94, w * 0.60, h * 0.96);
    // Right foot
    path.lineTo(w * 0.64, h * 0.96);
    path.quadraticBezierTo(w * 0.66, h * 0.97, w * 0.66, h * 0.98);
    path.lineTo(w * 0.56, h * 0.98);
    path.lineTo(w * 0.56, h * 0.96);

    // INNER LEGS (crotch area)
    path.lineTo(w * 0.54, h * 0.58);
    path.quadraticBezierTo(w * 0.50, h * 0.56, w * 0.46, h * 0.58);
    path.lineTo(w * 0.44, h * 0.96);

    // LEFT FOOT
    path.lineTo(w * 0.44, h * 0.98);
    path.lineTo(w * 0.34, h * 0.98);
    path.quadraticBezierTo(w * 0.34, h * 0.97, w * 0.36, h * 0.96);
    path.lineTo(w * 0.40, h * 0.96);
    // Left ankle
    path.quadraticBezierTo(w * 0.41, h * 0.94, w * 0.40, h * 0.90);
    // Left calf
    path.quadraticBezierTo(w * 0.39, h * 0.84, w * 0.38, h * 0.76);
    // Left knee
    path.quadraticBezierTo(w * 0.37, h * 0.72, w * 0.36, h * 0.68);
    // Left thigh
    path.quadraticBezierTo(w * 0.34, h * 0.62, w * 0.34, h * 0.56);

    // LEFT HIP & WAIST
    path.quadraticBezierTo(w * 0.32, h * 0.54, w * 0.34, h * 0.50);
    path.quadraticBezierTo(w * 0.36, h * 0.46, w * 0.34, h * 0.42);

    // LEFT TORSO
    path.quadraticBezierTo(w * 0.32, h * 0.36, w * 0.34, h * 0.28);
    path.lineTo(w * 0.32, h * 0.24);

    // LEFT ARM (slightly away from body)
    path.quadraticBezierTo(w * 0.32, h * 0.28, w * 0.30, h * 0.34);
    path.quadraticBezierTo(w * 0.28, h * 0.40, w * 0.26, h * 0.43);
    // Left hand
    path.quadraticBezierTo(w * 0.24, h * 0.44, w * 0.22, h * 0.42);
    // Left arm outer
    path.quadraticBezierTo(w * 0.18, h * 0.38, w * 0.16, h * 0.32);
    path.quadraticBezierTo(w * 0.14, h * 0.24, w * 0.18, h * 0.20);

    // LEFT SHOULDER
    path.quadraticBezierTo(w * 0.20, h * 0.17, w * 0.28, h * 0.16);
    path.quadraticBezierTo(w * 0.40, h * 0.14, w * 0.46, h * 0.14);

    // NECK (left side)
    path.lineTo(w * 0.46, h * 0.12);
    path.quadraticBezierTo(w * 0.42, h * 0.11, w * 0.42, h * 0.08);

    path.close();
    return path;
  }

  void _drawBubbles(Canvas canvas, Size size, double waterTop, double waterHeight) {
    if (waterHeight < 20) return;

    final random = math.Random(42); // Fixed seed for consistent bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final bubbleX = size.width * 0.3 + random.nextDouble() * size.width * 0.4;
      final bubbleY = waterTop + 10 + random.nextDouble() * (waterHeight - 20);
      final bubbleRadius = 2 + random.nextDouble() * 4;

      // Animate bubble position slightly
      final animatedY = bubbleY - (math.sin(waveOffset + i) * 3);

      if (animatedY > waterTop && animatedY < size.height) {
        canvas.drawCircle(
          Offset(bubbleX, animatedY),
          bubbleRadius,
          bubblePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BodyHydrationPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.waveOffset != waveOffset;
  }
}
