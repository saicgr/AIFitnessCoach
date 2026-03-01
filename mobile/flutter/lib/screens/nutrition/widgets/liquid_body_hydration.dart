import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import 'package:muscle_selector/src/parser.dart';
import '../../../core/constants/app_colors.dart';

/// Animated anatomical muscle body with liquid water fill effect and wave animation.
/// Uses the muscle_selector package SVG for a realistic body outline.
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

  // Anatomical muscle body paths from SVG
  Path? _bodyOutlinePath;
  List<Path> _musclePaths = [];
  bool _pathsLoaded = false;

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

    _loadMusclePaths();
  }

  Future<void> _loadMusclePaths() async {
    try {
      final muscles = await Parser.instance.svgToMuscleList(Maps.BODY);
      if (!mounted) return;

      Path? bodyOutline;
      final musclePaths = <Path>[];

      for (final muscle in muscles) {
        if (muscle.id == 'human_body') {
          bodyOutline = muscle.path;
        } else {
          musclePaths.add(muscle.path);
        }
      }

      if (bodyOutline != null) {
        setState(() {
          _bodyOutlinePath = bodyOutline;
          _musclePaths = musclePaths;
          _pathsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load muscle SVG paths: $e');
    }
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
              if (_pathsLoaded && _bodyOutlinePath != null)
                CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _LiquidBodyPainter(
                    fillPercentage: fillValue,
                    waveOffset: _waveController.value * 2 * math.pi,
                    waterColor: waterColor,
                    bodyOutlineColor: bodyOutlineColor,
                    isDark: widget.isDark,
                    bodyOutlinePath: _bodyOutlinePath!,
                    musclePaths: _musclePaths,
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
  final Path bodyOutlinePath;
  final List<Path> musclePaths;

  _LiquidBodyPainter({
    required this.fillPercentage,
    required this.waveOffset,
    required this.waterColor,
    required this.bodyOutlineColor,
    required this.isDark,
    required this.bodyOutlinePath,
    required this.musclePaths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Compute transform to fit SVG paths into widget bounds
    final svgBounds = bodyOutlinePath.getBounds();
    const padding = 4.0;
    final availableWidth = size.width - 2 * padding;
    final availableHeight = size.height - 2 * padding;

    final scaleX = availableWidth / svgBounds.width;
    final scaleY = availableHeight / svgBounds.height;
    final scale = math.min(scaleX, scaleY);

    final scaledWidth = svgBounds.width * scale;
    final scaledHeight = svgBounds.height * scale;

    final tx = (size.width - scaledWidth) / 2 - svgBounds.left * scale;
    final ty = (size.height - scaledHeight) / 2 - svgBounds.top * scale;

    // Column-major 4x4 affine transformation matrix
    final matrix = Float64List(16)
      ..[0] = scale // scaleX
      ..[5] = scale // scaleY
      ..[10] = 1.0 // scaleZ
      ..[12] = tx // translateX
      ..[13] = ty // translateY
      ..[15] = 1.0; // w

    final bodyPath = bodyOutlinePath.transform(matrix);
    final bodyBounds = bodyPath.getBounds();

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

      final waterHeight = bodyBounds.height * fillPercentage;
      final waterTop = bodyBounds.bottom - waterHeight;

      // Create water path with wave effect spanning body width
      final waterPath = Path();
      waterPath.moveTo(bodyBounds.left - 2, bodyBounds.bottom + 2);
      waterPath.lineTo(bodyBounds.left - 2, waterTop);

      // Wave at top of water
      const waveAmplitude = 6.0;
      for (double x = bodyBounds.left - 2; x <= bodyBounds.right + 2; x += 1) {
        final normalizedX =
            (x - bodyBounds.left) / bodyBounds.width;
        final wave1 =
            math.sin((normalizedX * 4 * math.pi) + waveOffset) * waveAmplitude;
        final wave2 =
            math.sin((normalizedX * 2 * math.pi) + waveOffset * 0.8) *
                (waveAmplitude * 0.5);
        waterPath.lineTo(x, waterTop + wave1 + wave2);
      }

      waterPath.lineTo(bodyBounds.right + 2, bodyBounds.bottom + 2);
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
        ).createShader(
            Rect.fromLTWH(bodyBounds.left, waterTop, bodyBounds.width, waterHeight));

      canvas.drawPath(waterPath, waterPaint);

      // Add bubbles for extra effect
      _drawBubbles(canvas, bodyBounds, waterTop, waterHeight);

      canvas.restore();
    }

    // Draw muscle outlines for anatomical definition
    final musclePen = Paint()
      ..color = bodyOutlineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (final musclePath in musclePaths) {
      final transformedMuscle = musclePath.transform(matrix);
      canvas.drawPath(transformedMuscle, musclePen);
    }

    // Draw body outline
    final outlinePaint = Paint()
      ..color = bodyOutlineColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, outlinePaint);
  }

  void _drawBubbles(
      Canvas canvas, Rect bodyBounds, double waterTop, double waterHeight) {
    if (waterHeight < 30) return;

    final random = math.Random(42); // Fixed seed for consistent bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      final bubbleX = bodyBounds.left +
          bodyBounds.width * 0.2 +
          random.nextDouble() * bodyBounds.width * 0.6;
      final bubbleY = waterTop + 15 + random.nextDouble() * (waterHeight - 30);
      final bubbleRadius = 2 + random.nextDouble() * 5;

      // Animate bubble position
      final animatedY = bubbleY - (math.sin(waveOffset + i * 0.5) * 5);

      if (animatedY > waterTop + 5 && animatedY < bodyBounds.bottom - 5) {
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
