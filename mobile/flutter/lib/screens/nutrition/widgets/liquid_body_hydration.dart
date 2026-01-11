import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Animated human body with liquid water fill effect and wave animation
class LiquidBodyHydration extends StatefulWidget {
  final double fillPercentage; // 0.0 to 1.0
  final bool isDark;
  final double width;
  final double height;

  const LiquidBodyHydration({
    super.key,
    required this.fillPercentage,
    required this.isDark,
    this.width = 200,
    this.height = 280,
  });

  @override
  State<LiquidBodyHydration> createState() => _LiquidBodyHydrationState();
}

class _LiquidBodyHydrationState extends State<LiquidBodyHydration>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  double _currentFill = 0.0;

  @override
  void initState() {
    super.initState();

    // Wave animation - continuous loop for liquid effect
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
  void didUpdateWidget(LiquidBodyHydration oldWidget) {
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
      width: widget.width,
      height: widget.height,
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
                size: Size(widget.width, widget.height),
                painter: _LiquidBodyPainter(
                  fillPercentage: fillValue,
                  waveOffset: _waveController.value * 2 * math.pi,
                  waterColor: waterColor,
                  bodyOutlineColor: bodyOutlineColor,
                  isDark: widget.isDark,
                ),
              ),

              // Percentage text overlay - positioned at chest level
              Positioned(
                top: widget.height * 0.28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: widget.width * 0.18,
                        fontWeight: FontWeight.bold,
                        color: fillValue > 0.4
                            ? Colors.white.withValues(alpha: 0.95)
                            : textColor,
                        shadows: fillValue > 0.4
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'hydrated',
                      style: TextStyle(
                        fontSize: widget.width * 0.07,
                        fontWeight: FontWeight.w600,
                        color: fillValue > 0.4
                            ? Colors.white.withValues(alpha: 0.8)
                            : (widget.isDark
                                ? AppColors.textMuted
                                : AppColorsLight.textMuted),
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

class _LiquidBodyPainter extends CustomPainter {
  final double fillPercentage;
  final double waveOffset;
  final Color waterColor;
  final Color bodyOutlineColor;
  final bool isDark;

  _LiquidBodyPainter({
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

    // Draw water fill with wave effect
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

      // Wave at top of water - more pronounced wave
      final waveAmplitude = 6.0;
      for (double x = 0; x <= size.width; x += 1) {
        final wave1 = math.sin((x / size.width * 4 * math.pi) + waveOffset) * waveAmplitude;
        final wave2 = math.sin((x / size.width * 2 * math.pi) + waveOffset * 0.8) * (waveAmplitude * 0.5);
        waterPath.lineTo(x, waterTop + wave1 + wave2);
      }

      waterPath.lineTo(size.width, size.height);
      waterPath.close();

      // Water gradient - more vibrant
      final waterPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            waterColor.withValues(alpha: 0.5),
            waterColor.withValues(alpha: 0.7),
            waterColor.withValues(alpha: 0.9),
            waterColor,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, waterTop, size.width, waterHeight));

      canvas.drawPath(waterPath, waterPaint);

      // Add bubbles for extra effect
      _drawBubbles(canvas, size, waterTop, waterHeight);

      canvas.restore();
    }

    // Draw body outline - thicker and more visible
    final outlinePaint = Paint()
      ..color = bodyOutlineColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, outlinePaint);
  }

  Path _createBodyPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Realistic human silhouette - anatomically proportioned standing pose
    // Head is ~1/8 of body height, shoulders ~3 head widths

    final headRadius = w * 0.09;
    final centerX = w * 0.5;

    // HEAD - circular
    path.addOval(Rect.fromCircle(
      center: Offset(centerX, h * 0.05 + headRadius),
      radius: headRadius,
    ));

    // Create body path separately and combine
    final bodyPath = Path();

    // NECK
    bodyPath.moveTo(centerX - w * 0.04, h * 0.12);
    bodyPath.lineTo(centerX - w * 0.04, h * 0.15);

    // LEFT SHOULDER curve
    bodyPath.quadraticBezierTo(
      centerX - w * 0.12, h * 0.15,
      centerX - w * 0.22, h * 0.18,
    );

    // LEFT ARM - down along body
    bodyPath.quadraticBezierTo(
      centerX - w * 0.26, h * 0.22,
      centerX - w * 0.27, h * 0.28,
    );
    bodyPath.quadraticBezierTo(
      centerX - w * 0.28, h * 0.34,
      centerX - w * 0.26, h * 0.40,
    );
    // Left hand
    bodyPath.quadraticBezierTo(
      centerX - w * 0.25, h * 0.43,
      centerX - w * 0.22, h * 0.44,
    );
    bodyPath.quadraticBezierTo(
      centerX - w * 0.19, h * 0.44,
      centerX - w * 0.18, h * 0.42,
    );
    // Left inner arm back up
    bodyPath.quadraticBezierTo(
      centerX - w * 0.19, h * 0.36,
      centerX - w * 0.18, h * 0.30,
    );
    bodyPath.quadraticBezierTo(
      centerX - w * 0.17, h * 0.24,
      centerX - w * 0.15, h * 0.20,
    );

    // LEFT TORSO
    bodyPath.lineTo(centerX - w * 0.14, h * 0.24);
    bodyPath.quadraticBezierTo(
      centerX - w * 0.15, h * 0.32,
      centerX - w * 0.13, h * 0.38,
    );

    // LEFT WAIST (narrower)
    bodyPath.quadraticBezierTo(
      centerX - w * 0.11, h * 0.42,
      centerX - w * 0.12, h * 0.46,
    );

    // LEFT HIP (wider)
    bodyPath.quadraticBezierTo(
      centerX - w * 0.14, h * 0.50,
      centerX - w * 0.13, h * 0.54,
    );

    // LEFT THIGH
    bodyPath.quadraticBezierTo(
      centerX - w * 0.14, h * 0.60,
      centerX - w * 0.12, h * 0.68,
    );

    // LEFT KNEE
    bodyPath.quadraticBezierTo(
      centerX - w * 0.11, h * 0.72,
      centerX - w * 0.10, h * 0.76,
    );

    // LEFT CALF
    bodyPath.quadraticBezierTo(
      centerX - w * 0.11, h * 0.82,
      centerX - w * 0.09, h * 0.90,
    );

    // LEFT ANKLE & FOOT
    bodyPath.quadraticBezierTo(
      centerX - w * 0.08, h * 0.94,
      centerX - w * 0.10, h * 0.96,
    );
    bodyPath.lineTo(centerX - w * 0.14, h * 0.96);
    bodyPath.quadraticBezierTo(
      centerX - w * 0.15, h * 0.98,
      centerX - w * 0.12, h * 0.99,
    );
    bodyPath.lineTo(centerX - w * 0.04, h * 0.99);
    bodyPath.lineTo(centerX - w * 0.04, h * 0.96);

    // CROTCH - go to right leg
    bodyPath.lineTo(centerX - w * 0.03, h * 0.54);
    bodyPath.quadraticBezierTo(centerX, h * 0.52, centerX + w * 0.03, h * 0.54);
    bodyPath.lineTo(centerX + w * 0.04, h * 0.96);

    // RIGHT FOOT
    bodyPath.lineTo(centerX + w * 0.04, h * 0.99);
    bodyPath.lineTo(centerX + w * 0.12, h * 0.99);
    bodyPath.quadraticBezierTo(
      centerX + w * 0.15, h * 0.98,
      centerX + w * 0.14, h * 0.96,
    );
    bodyPath.lineTo(centerX + w * 0.10, h * 0.96);

    // RIGHT ANKLE
    bodyPath.quadraticBezierTo(
      centerX + w * 0.08, h * 0.94,
      centerX + w * 0.09, h * 0.90,
    );

    // RIGHT CALF
    bodyPath.quadraticBezierTo(
      centerX + w * 0.11, h * 0.82,
      centerX + w * 0.10, h * 0.76,
    );

    // RIGHT KNEE
    bodyPath.quadraticBezierTo(
      centerX + w * 0.11, h * 0.72,
      centerX + w * 0.12, h * 0.68,
    );

    // RIGHT THIGH
    bodyPath.quadraticBezierTo(
      centerX + w * 0.14, h * 0.60,
      centerX + w * 0.13, h * 0.54,
    );

    // RIGHT HIP
    bodyPath.quadraticBezierTo(
      centerX + w * 0.14, h * 0.50,
      centerX + w * 0.12, h * 0.46,
    );

    // RIGHT WAIST
    bodyPath.quadraticBezierTo(
      centerX + w * 0.11, h * 0.42,
      centerX + w * 0.13, h * 0.38,
    );

    // RIGHT TORSO
    bodyPath.quadraticBezierTo(
      centerX + w * 0.15, h * 0.32,
      centerX + w * 0.14, h * 0.24,
    );
    bodyPath.lineTo(centerX + w * 0.15, h * 0.20);

    // RIGHT inner arm
    bodyPath.quadraticBezierTo(
      centerX + w * 0.17, h * 0.24,
      centerX + w * 0.18, h * 0.30,
    );
    bodyPath.quadraticBezierTo(
      centerX + w * 0.19, h * 0.36,
      centerX + w * 0.18, h * 0.42,
    );
    // Right hand
    bodyPath.quadraticBezierTo(
      centerX + w * 0.19, h * 0.44,
      centerX + w * 0.22, h * 0.44,
    );
    bodyPath.quadraticBezierTo(
      centerX + w * 0.25, h * 0.43,
      centerX + w * 0.26, h * 0.40,
    );
    // Right outer arm
    bodyPath.quadraticBezierTo(
      centerX + w * 0.28, h * 0.34,
      centerX + w * 0.27, h * 0.28,
    );
    bodyPath.quadraticBezierTo(
      centerX + w * 0.26, h * 0.22,
      centerX + w * 0.22, h * 0.18,
    );

    // RIGHT SHOULDER
    bodyPath.quadraticBezierTo(
      centerX + w * 0.12, h * 0.15,
      centerX + w * 0.04, h * 0.15,
    );

    // Back to neck
    bodyPath.lineTo(centerX + w * 0.04, h * 0.12);
    bodyPath.close();

    // Combine head and body
    path.addPath(bodyPath, Offset.zero);

    return path;
  }

  void _drawBubbles(Canvas canvas, Size size, double waterTop, double waterHeight) {
    if (waterHeight < 30) return;

    final random = math.Random(42); // Fixed seed for consistent bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      final bubbleX = size.width * 0.3 + random.nextDouble() * size.width * 0.4;
      final bubbleY = waterTop + 15 + random.nextDouble() * (waterHeight - 30);
      final bubbleRadius = 2 + random.nextDouble() * 5;

      // Animate bubble position
      final animatedY = bubbleY - (math.sin(waveOffset + i * 0.5) * 5);

      if (animatedY > waterTop + 5 && animatedY < size.height - 5) {
        canvas.drawCircle(
          Offset(bubbleX, animatedY),
          bubbleRadius,
          bubblePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LiquidBodyPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.waveOffset != waveOffset;
  }
}
