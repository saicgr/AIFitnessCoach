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

    // Start at neck (left side)
    path.moveTo(w * 0.35, h * 0.12);

    // Head - left side
    path.quadraticBezierTo(w * 0.25, h * 0.10, w * 0.25, h * 0.06);
    path.quadraticBezierTo(w * 0.25, h * 0.01, w * 0.5, h * 0.01);

    // Head - right side
    path.quadraticBezierTo(w * 0.75, h * 0.01, w * 0.75, h * 0.06);
    path.quadraticBezierTo(w * 0.75, h * 0.10, w * 0.65, h * 0.12);

    // Neck to right shoulder
    path.lineTo(w * 0.65, h * 0.15);
    path.quadraticBezierTo(w * 0.90, h * 0.16, w * 0.92, h * 0.22);

    // Right arm
    path.quadraticBezierTo(w * 0.95, h * 0.28, w * 0.88, h * 0.38);
    path.quadraticBezierTo(w * 0.85, h * 0.42, w * 0.78, h * 0.40);

    // Right side of torso
    path.lineTo(w * 0.72, h * 0.42);
    path.quadraticBezierTo(w * 0.75, h * 0.52, w * 0.72, h * 0.58);

    // Right hip
    path.quadraticBezierTo(w * 0.70, h * 0.62, w * 0.68, h * 0.65);

    // Right leg
    path.lineTo(w * 0.65, h * 0.75);
    path.quadraticBezierTo(w * 0.64, h * 0.85, w * 0.62, h * 0.92);
    path.quadraticBezierTo(w * 0.61, h * 0.97, w * 0.56, h * 0.98);

    // Right foot
    path.lineTo(w * 0.54, h * 0.99);

    // Between legs
    path.lineTo(w * 0.54, h * 0.65);
    path.quadraticBezierTo(w * 0.50, h * 0.63, w * 0.46, h * 0.65);
    path.lineTo(w * 0.46, h * 0.99);

    // Left foot
    path.lineTo(w * 0.44, h * 0.98);
    path.quadraticBezierTo(w * 0.39, h * 0.97, w * 0.38, h * 0.92);

    // Left leg
    path.quadraticBezierTo(w * 0.36, h * 0.85, w * 0.35, h * 0.75);
    path.lineTo(w * 0.32, h * 0.65);

    // Left hip
    path.quadraticBezierTo(w * 0.30, h * 0.62, w * 0.28, h * 0.58);

    // Left side of torso
    path.quadraticBezierTo(w * 0.25, h * 0.52, w * 0.28, h * 0.42);
    path.lineTo(w * 0.22, h * 0.40);

    // Left arm
    path.quadraticBezierTo(w * 0.15, h * 0.42, w * 0.12, h * 0.38);
    path.quadraticBezierTo(w * 0.05, h * 0.28, w * 0.08, h * 0.22);

    // Left shoulder to neck
    path.quadraticBezierTo(w * 0.10, h * 0.16, w * 0.35, h * 0.15);

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
