import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

// =============================================================================
// intro_animations.dart
//
// Reusable micro-interaction widgets for onboarding, splash screens, and
// intro flows. Designed for the FitWiz dark OLED theme but works on any
// background.
//
// Widgets:
//   1. ShimmerText      – Metallic shine sweep over a Text child.
//   2. BreathingGlow    – Pulsing box-shadow around any child widget.
//   3. ParticleField    – Floating particles drifting upward with sway.
//   4. ParallaxContainer – Scroll-driven vertical parallax offset.
// =============================================================================

// -----------------------------------------------------------------------------
// 1. ShimmerText
// -----------------------------------------------------------------------------

/// Wraps a [Text] widget with a left-to-right metallic shine sweep animation.
///
/// The gradient contains three stops (transparent -> shimmerColor at 30%
/// opacity -> transparent) and continuously sweeps across the text on a loop.
///
/// ```dart
/// ShimmerText(
///   duration: const Duration(seconds: 3),
///   shimmerColor: Colors.white,
///   child: Text('Welcome', style: TextStyle(fontSize: 32)),
/// )
/// ```
class ShimmerText extends StatefulWidget {
  const ShimmerText({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.shimmerColor = Colors.white,
  });

  /// The [Text] widget to apply the shimmer effect to.
  final Text child;

  /// How long one full left-to-right sweep takes.
  final Duration duration;

  /// The highlight color used at the center of the gradient band.
  final Color shimmerColor;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
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
      builder: (context, child) {
        // Map controller value (0..1) to a gradient position that travels
        // from fully off-screen left (-1.0) to fully off-screen right (2.0).
        final double offset = _controller.value * 3.0 - 1.0;

        // Stack: base text is always visible, shimmer highlight sweeps on top
        return Stack(
          children: [
            // Base text — always visible
            child!,
            // Shimmer highlight overlay
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    widget.shimmerColor.withValues(alpha: 0),
                    widget.shimmerColor.withValues(alpha: 0.6),
                    widget.shimmerColor.withValues(alpha: 0),
                  ],
                  stops: [
                    (offset - 0.3).clamp(0.0, 1.0),
                    offset.clamp(0.0, 1.0),
                    (offset + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: child!,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

// -----------------------------------------------------------------------------
// 2. BreathingGlow
// -----------------------------------------------------------------------------

/// Wraps any child widget with a pulsing box shadow whose opacity animates
/// between [minOpacity] and [maxOpacity] using an [easeInOut] curve.
///
/// ```dart
/// BreathingGlow(
///   color: Colors.white,
///   child: Icon(Icons.fitness_center, size: 48),
/// )
/// ```
class BreathingGlow extends StatefulWidget {
  const BreathingGlow({
    super.key,
    required this.child,
    required this.color,
    this.blurRadius = 30.0,
    this.spreadRadius = 8.0,
    this.duration = const Duration(seconds: 2),
    this.minOpacity = 0.1,
    this.maxOpacity = 0.4,
  });

  /// The widget to wrap with a glowing shadow.
  final Widget child;

  /// Base color of the glow. Opacity is animated automatically.
  final Color color;

  /// Gaussian blur radius for the shadow.
  final double blurRadius;

  /// How far the shadow extends beyond the widget bounds.
  final double spreadRadius;

  /// Duration of one full breathe cycle (fade in + fade out).
  final Duration duration;

  /// Minimum shadow opacity at the dimmest point of the cycle.
  final double minOpacity;

  /// Maximum shadow opacity at the brightest point of the cycle.
  final double maxOpacity;

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _opacityAnimation.value),
                blurRadius: widget.blurRadius,
                spreadRadius: widget.spreadRadius,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// -----------------------------------------------------------------------------
// 3. ParticleField
// -----------------------------------------------------------------------------

/// Renders a field of small translucent particles that drift upward with
/// subtle horizontal sway. Great as a background layer for splash or
/// onboarding screens.
///
/// Uses [CustomPainter] for efficient rendering.
///
/// ```dart
/// ParticleField(
///   particleCount: 20,
///   color: Colors.white,
///   maxSpeed: 0.5,
/// )
/// ```
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    this.particleCount = 20,
    this.color = Colors.white,
    this.maxSpeed = 0.5,
  });

  /// Number of particles to render.
  final int particleCount;

  /// Base color of each particle. Individual opacity varies per-particle.
  final Color color;

  /// Maximum upward drift speed in logical pixels per frame.
  final double maxSpeed;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Seed particles with randomized properties.
    _particles = List.generate(widget.particleCount, (_) => _randomParticle());

    _controller = AnimationController(
      vsync: this,
      // Duration is irrelevant — we repeat forever and use the ticker for
      // per-frame updates via the listener.
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  _Particle _randomParticle({double? startY}) {
    return _Particle(
      x: _random.nextDouble(), // 0..1 normalized
      y: startY ?? _random.nextDouble(),
      size: lerpDouble(1.0, 3.0, _random.nextDouble())!,
      opacity: lerpDouble(0.05, 0.15, _random.nextDouble())!,
      speed: lerpDouble(0.1, widget.maxSpeed, _random.nextDouble())!,
      swayAmplitude: lerpDouble(0.002, 0.008, _random.nextDouble())!,
      swayPhase: _random.nextDouble() * 2 * pi,
    );
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
        return CustomPaint(
          painter: _ParticleFieldPainter(
            particles: _particles,
            color: widget.color,
            tick: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Internal data class representing a single floating particle.
class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.swayAmplitude,
    required this.swayPhase,
  });

  /// Horizontal position, normalized 0..1.
  double x;

  /// Vertical position, normalized 0..1. 0 = top, 1 = bottom.
  double y;

  /// Radius in logical pixels.
  final double size;

  /// Alpha value for this particle (0.05 - 0.15).
  final double opacity;

  /// Upward drift speed — subtracted from [y] each frame.
  final double speed;

  /// Max horizontal sway distance (normalized).
  final double swayAmplitude;

  /// Phase offset so particles don't all sway in sync.
  double swayPhase;
}

class _ParticleFieldPainter extends CustomPainter {
  _ParticleFieldPainter({
    required this.particles,
    required this.color,
    required this.tick,
  });

  final List<_Particle> particles;
  final Color color;
  final double tick;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;

    // The tick cycles 0..1 every second. We use it to drive movement so
    // speed is frame-rate independent (approximately).
    for (final p in particles) {
      // Move upward.
      p.y -= p.speed * 0.002;

      // Horizontal sway using a sine wave.
      p.swayPhase += 0.02;
      final swayOffset = sin(p.swayPhase) * p.swayAmplitude;
      p.x += swayOffset;

      // Wrap around when particle goes off the top.
      if (p.y < -0.02) {
        p.y = 1.02;
        p.x = Random().nextDouble();
      }

      // Wrap horizontal.
      if (p.x < 0) p.x += 1.0;
      if (p.x > 1) p.x -= 1.0;

      paint.color = color.withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticleFieldPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// 4. ParallaxContainer
// -----------------------------------------------------------------------------

/// Applies a vertical parallax translation to its [child] based on a
/// normalized [scrollOffset] (0.0 - 1.0 representing page progress).
///
/// The translation is: `offset = scrollOffset * factor * 100` logical pixels.
///
/// ```dart
/// ParallaxContainer(
///   scrollOffset: pageProgress,  // 0.0 to 1.0
///   factor: 0.15,
///   child: Text('Parallax Title'),
/// )
/// ```
class ParallaxContainer extends StatelessWidget {
  const ParallaxContainer({
    super.key,
    required this.scrollOffset,
    required this.child,
    this.factor = 0.15,
  });

  /// Normalized scroll progress from 0.0 (start) to 1.0 (end).
  final double scrollOffset;

  /// Parallax strength multiplier. Higher values = more movement.
  final double factor;

  /// The widget to apply the parallax offset to.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offset = Offset(0, scrollOffset * factor * 100);

    return Transform.translate(
      offset: offset,
      child: child,
    );
  }
}
