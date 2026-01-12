/// Celebration Animations
///
/// Confetti and particle effects for PR celebrations and achievements.
library;

import 'dart:math';

import 'package:flutter/material.dart';

/// Simple confetti particle
class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  Color color;
  double size;

  ConfettiParticle({
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

/// Confetti overlay widget
class ConfettiOverlay extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    this.particleCount = 100,
    this.duration = const Duration(milliseconds: 3000),
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final Random _random = Random();

  static const List<Color> _colors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Cyan
    Color(0xFFFFE66D), // Yellow
    Color(0xFF95E1D3), // Mint
    Color(0xFFFF8B94), // Pink
    Color(0xFFA8E6CE), // Light green
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });

    _initParticles();
    _controller.forward();
  }

  void _initParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      final angle = _random.nextDouble() * pi * 2;
      final velocity = 200 + _random.nextDouble() * 300;
      return ConfettiParticle(
        x: 0.5, // Start from center
        y: 0.3, // Start from upper third
        vx: cos(angle) * velocity,
        vy: sin(angle) * velocity - 200, // Initial upward burst
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        color: _colors[_random.nextInt(_colors.length)],
        size: 6 + _random.nextDouble() * 8,
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
          painter: ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Custom painter for confetti
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gravity = 500.0; // Gravity acceleration
    final dt = progress * 3; // Time elapsed (3 seconds duration)

    for (final particle in particles) {
      // Calculate position with physics
      final x = size.width * particle.x + particle.vx * dt;
      final y = size.height * particle.y +
          particle.vy * dt +
          0.5 * gravity * dt * dt;

      // Skip if out of bounds
      if (y > size.height || x < -50 || x > size.width + 50) continue;

      // Calculate opacity (fade out at end)
      final opacity = progress < 0.7 ? 1.0 : (1 - progress) / 0.3;

      // Draw confetti piece
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * dt);

      // Draw as rectangle
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
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Burst animation for set completion
class SetCompletionBurst extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onComplete;

  const SetCompletionBurst({
    super.key,
    this.color = const Color(0xFF4CAF50),
    this.size = 60,
    this.onComplete,
  });

  @override
  State<SetCompletionBurst> createState() => _SetCompletionBurstState();
}

class _SetCompletionBurstState extends State<SetCompletionBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    _controller.forward();
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
        final scale = Curves.elasticOut.transform(_controller.value);
        final opacity = 1 - Curves.easeIn.transform(_controller.value);

        return Container(
          width: widget.size * scale * 2,
          height: widget.size * scale * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(opacity * 0.5),
              width: 3,
            ),
          ),
        );
      },
    );
  }
}

/// Ripple effect for PR achievement
class PRRippleEffect extends StatefulWidget {
  final Color color;
  final int rippleCount;
  final VoidCallback? onComplete;

  const PRRippleEffect({
    super.key,
    this.color = const Color(0xFFFFD700),
    this.rippleCount = 3,
    this.onComplete,
  });

  @override
  State<PRRippleEffect> createState() => _PRRippleEffectState();
}

class _PRRippleEffectState extends State<PRRippleEffect>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.rippleCount, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      Future.delayed(Duration(milliseconds: index * 200), () {
        if (mounted) controller.forward();
      });
      return controller;
    });

    _controllers.last.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: _controllers.map((controller) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final scale = 1 + controller.value * 2;
            final opacity = 1 - controller.value;

            return Container(
              width: 50 * scale,
              height: 50 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(opacity * 0.6),
                  width: 2,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// Star burst animation for epic PRs
class StarBurstAnimation extends StatefulWidget {
  final int starCount;
  final Color color;
  final VoidCallback? onComplete;

  const StarBurstAnimation({
    super.key,
    this.starCount = 8,
    this.color = const Color(0xFFFFD700),
    this.onComplete,
  });

  @override
  State<StarBurstAnimation> createState() => _StarBurstAnimationState();
}

class _StarBurstAnimationState extends State<StarBurstAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    _controller.forward();
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
          painter: StarBurstPainter(
            progress: _controller.value,
            starCount: widget.starCount,
            color: widget.color,
          ),
          size: const Size(200, 200),
        );
      },
    );
  }
}

class StarBurstPainter extends CustomPainter {
  final double progress;
  final int starCount;
  final Color color;

  StarBurstPainter({
    required this.progress,
    required this.starCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;

    for (int i = 0; i < starCount; i++) {
      final angle = (i / starCount) * pi * 2;
      final radius = maxRadius * Curves.easeOut.transform(progress);
      final opacity = 1 - Curves.easeIn.transform(progress);

      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Draw star shape
      _drawStar(canvas, Offset(x, y), 8 * (1 - progress * 0.5), paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    const innerRadius = 0.4;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? size : size * innerRadius;
      final angle = (i / (points * 2)) * pi * 2 - pi / 2;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;

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
  bool shouldRepaint(covariant StarBurstPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
