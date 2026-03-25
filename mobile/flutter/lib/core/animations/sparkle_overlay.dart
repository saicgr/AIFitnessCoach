import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// A particle-burst sparkle effect that can be shown as an overlay
/// at any position on screen.
///
/// Spawns 4-pointed star particles that burst outward radially,
/// each with random size, velocity, rotation, and fade. Includes
/// an optional brief golden flash behind the burst.
///
/// Usage:
/// ```dart
/// SparkleOverlay.show(
///   context: context,
///   origin: buttonRect.center, // global position
/// );
/// ```
class SparkleOverlay {
  SparkleOverlay._();

  /// Shows a sparkle burst at the given [origin] point (global coordinates).
  static void show({
    required BuildContext context,
    required Offset origin,
    int particleCount = 12,
    Color color = const Color(0xFFFFD700), // Gold
    Duration duration = const Duration(milliseconds: 800),
    bool haptic = true,
    bool showFlash = true,
  }) {
    if (haptic) {
      HapticService.instance.celebration();
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _SparkleAnimation(
        origin: origin,
        particleCount: particleCount,
        color: color,
        duration: duration,
        showFlash: showFlash,
        onComplete: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _SparkleAnimation extends StatefulWidget {
  final Offset origin;
  final int particleCount;
  final Color color;
  final Duration duration;
  final bool showFlash;
  final VoidCallback onComplete;

  const _SparkleAnimation({
    required this.origin,
    required this.particleCount,
    required this.color,
    required this.duration,
    required this.showFlash,
    required this.onComplete,
  });

  @override
  State<_SparkleAnimation> createState() => _SparkleAnimationState();
}

class _SparkleAnimationState extends State<_SparkleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_SparkleParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _initParticles();
    _controller.forward();
  }

  void _initParticles() {
    _particles = List.generate(widget.particleCount, (i) {
      final angle = (i / widget.particleCount) * math.pi * 2 +
          (_random.nextDouble() - 0.5) * 0.5; // slight randomization
      final speed = 80 + _random.nextDouble() * 120;
      return _SparkleParticle(
        angle: angle,
        speed: speed,
        size: 2 + _random.nextDouble() * 5,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        delay: _random.nextDouble() * 0.15, // stagger start
      );
    });
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
        return CustomPaint(
          painter: _SparklePainter(
            origin: widget.origin,
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
            showFlash: widget.showFlash,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SparkleParticle {
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final double delay;

  _SparkleParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.delay,
  });
}

class _SparklePainter extends CustomPainter {
  final Offset origin;
  final List<_SparkleParticle> particles;
  final double progress;
  final Color color;
  final bool showFlash;

  _SparklePainter({
    required this.origin,
    required this.particles,
    required this.progress,
    required this.color,
    required this.showFlash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Brief golden flash
    if (showFlash && progress < 0.2) {
      final flashOpacity = (1 - progress / 0.2) * 0.3;
      final flashPaint = Paint()
        ..color = color.withValues(alpha:flashOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(origin, 40, flashPaint);
    }

    for (final particle in particles) {
      // Apply particle delay
      final adjustedProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      // Eased progress for position
      final easedProgress = Curves.easeOutCubic.transform(adjustedProgress);

      // Position: radial outward movement
      final distance = particle.speed * easedProgress;
      final x = origin.dx + math.cos(particle.angle) * distance;
      final y = origin.dy + math.sin(particle.angle) * distance;

      // Fade out in the last 40%
      final opacity = adjustedProgress < 0.6
          ? 1.0
          : (1 - (adjustedProgress - 0.6) / 0.4);

      // Scale: starts at 0, grows to full, then shrinks
      final scale = adjustedProgress < 0.3
          ? Curves.easeOut.transform(adjustedProgress / 0.3)
          : 1.0 - Curves.easeIn.transform((adjustedProgress - 0.3) / 0.7) * 0.5;

      final actualSize = particle.size * scale;

      final paint = Paint()
        ..color = color.withValues(alpha:opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      // Draw 4-pointed star
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotationSpeed * adjustedProgress);
      _draw4PointStar(canvas, actualSize, paint);
      canvas.restore();
    }
  }

  void _draw4PointStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    // 4-pointed star: alternating outer and inner points
    const points = 4;
    const innerRadius = 0.35;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? size : size * innerRadius;
      final angle = (i / (points * 2)) * math.pi * 2 - math.pi / 2;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
