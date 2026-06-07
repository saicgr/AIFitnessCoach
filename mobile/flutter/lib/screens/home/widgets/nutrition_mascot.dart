/// Nutrition mascot — "Finn" the shark, rendered inside the calorie ring.
///
/// Uses five pre-rendered hero poses (`assets/mascot/shark/*.png`) that
/// cross-fade as the day's calorie progress changes, with calm procedural
/// micro-motion layered on top — a slow breathe, a faint underwater sway, a
/// per-state particle, and a soft scale-pulse when a meal is logged.
///
/// Deliberately NO bouncy/hopping motion (product decision): the character
/// reads as alive but settled. See `docs/planning/nutrition-mascot-mockups-v5.html`.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The five mood states across the calorie arc.
enum NutritionMascotMood { hungry, mid, almost, goal, over }

/// Map an eaten/goal ratio (0..1.3+) to a mood. Thresholds match the mockup.
NutritionMascotMood mascotMoodForProgress(double progress) {
  if (progress < 0.14) return NutritionMascotMood.hungry;
  if (progress < 0.55) return NutritionMascotMood.mid;
  if (progress < 0.86) return NutritionMascotMood.almost;
  if (progress <= 1.01) return NutritionMascotMood.goal;
  return NutritionMascotMood.over;
}

String _assetFor(NutritionMascotMood m) {
  switch (m) {
    case NutritionMascotMood.hungry:
      return 'assets/mascot/shark/empty.png';
    case NutritionMascotMood.mid:
      return 'assets/mascot/shark/mid.png';
    case NutritionMascotMood.almost:
      return 'assets/mascot/shark/almost.png';
    case NutritionMascotMood.goal:
      return 'assets/mascot/shark/goal.png';
    case NutritionMascotMood.over:
      return 'assets/mascot/shark/over.png';
  }
}

/// Per-mood particle glyph (emoji) drifting near the mascot.
String? _particleFor(NutritionMascotMood m) {
  switch (m) {
    case NutritionMascotMood.hungry:
      return '\u{1F4A4}'; // 💤
    case NutritionMascotMood.mid:
      return '\u{1F499}'; // 💙
    case NutritionMascotMood.almost:
      return '\u{2728}'; // ✨
    case NutritionMascotMood.goal:
      return '\u{1F389}'; // 🎉
    case NutritionMascotMood.over:
      return '\u{1F4A6}'; // 💦
  }
}

/// Human caption variant pools (≥4 each) so it never reads robotic.
/// `overKcal` substitutes into the "over" pool.
String mascotCaption(NutritionMascotMood mood, {int seed = 0, int overKcal = 0}) {
  late final List<String> pool;
  switch (mood) {
    case NutritionMascotMood.hungry:
      pool = const ['Running on empty.', 'Feed me?', 'Out of fuel.', 'So hungry.'];
      break;
    case NutritionMascotMood.mid:
      pool = const ['Fueling up nicely.', 'Right on pace!', 'Tasty start.', 'Munch munch.'];
      break;
    case NutritionMascotMood.almost:
      pool = const ['Almost there!', 'So close now.', 'Home stretch.', 'Nearly nailed it.'];
      break;
    case NutritionMascotMood.goal:
      pool = const ['Nailed it!', 'Perfect day!', 'Bang on target!', 'Champion.'];
      break;
    case NutritionMascotMood.over:
      pool = ['A touch over.', 'Over by $overKcal kcal.', 'Bit much, all good.', 'Past the line by $overKcal.'];
      break;
  }
  return pool[seed.abs() % pool.length];
}

class NutritionMascot extends StatefulWidget {
  /// eaten / goal (0..1.3+).
  final double progress;

  /// Rendered height of the character (fits inside the ring's inner hole).
  final double size;

  /// Bump this each time a meal is logged to fire the soft pulse.
  final int justAteTick;

  /// Toggle the per-state particle (off in dense/compact contexts).
  final bool showParticles;

  const NutritionMascot({
    super.key,
    required this.progress,
    this.size = 140,
    this.justAteTick = 0,
    this.showParticles = true,
  });

  @override
  State<NutritionMascot> createState() => _NutritionMascotState();
}

class _NutritionMascotState extends State<NutritionMascot>
    with TickerProviderStateMixin {
  // Master loop drives the calm breathe + sway + particle drift.
  late final AnimationController _idle;
  // Short controller for the just-ate pulse.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant NutritionMascot old) {
    super.didUpdateWidget(old);
    if (widget.justAteTick != old.justAteTick) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = mascotMoodForProgress(widget.progress);
    final particle = widget.showParticles ? _particleFor(mood) : null;

    return SizedBox(
      width: widget.size * 1.25,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _pulse]),
        builder: (context, child) {
          final v = _idle.value; // 0..1
          final breathe = 1 + 0.018 * math.sin(2 * math.pi * v);
          final sway = 0.022 * math.sin(2 * math.pi * v * 0.7); // ~1.3°
          // Pulse: a soft scale bump that eases back to 1.
          final pv = _pulse.value; // 0..1, rests at 1
          final pulse = 1 + 0.06 * math.sin(math.pi * pv.clamp(0.0, 1.0));
          return Transform.rotate(
            angle: sway,
            child: Transform.scale(
              scale: breathe * pulse,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Cross-fading hero pose.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Image.asset(
                _assetFor(mood),
                key: ValueKey(mood),
                height: widget.size,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
            // Drifting particle (rises + fades on the idle loop).
            if (particle != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (context, _) =>
                        _ParticleLayer(phase: _idle.value, glyph: particle),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Two staggered glyphs drifting up and fading, driven by the idle loop.
class _ParticleLayer extends StatelessWidget {
  final double phase; // 0..1
  final String glyph;
  const _ParticleLayer({required this.phase, required this.glyph});

  double _at(double p) => (phase + p) % 1.0;

  @override
  Widget build(BuildContext context) {
    Widget one(double offset, double dx, double scale) {
      final t = _at(offset);
      // rise from ~55% to ~10% height, fade in then out.
      final dy = 0.55 - t * 0.5;
      final opacity = (t < 0.2 ? t / 0.2 : (1 - t) / 0.8).clamp(0.0, 1.0);
      return Align(
        alignment: Alignment(dx, dy * 2 - 1),
        child: Opacity(
          opacity: opacity * 0.9,
          child: Text(glyph, style: TextStyle(fontSize: 16 * scale)),
        ),
      );
    }

    return Stack(children: [
      one(0.0, 0.45, 1.0),
      one(0.5, 0.72, 0.85),
    ]);
  }
}
