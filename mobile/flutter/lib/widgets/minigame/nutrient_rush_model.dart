import 'dart:math' as math;
import 'package:flutter/material.dart';

// =============================================================================
// Nutrient Rush — shared model / config layer.
//
// Holds the data-only pieces of the mini-game so `nutrient_rush_game.dart`
// stays focused on the loop + rendering:
//  - real-life-proportional item sizing
//  - power-up definitions
//  - lightweight particle / banner entities
//  - stage difficulty curve
//
// Nothing here touches Flutter state or the ticker; it is pure config + data.
// =============================================================================

/// Base on-screen font size for a 1.0-scale emoji. Each item's actual rendered
/// size is `kBaseEmojiSize * sizeScaleFor(emoji)`.
const double kBaseEmojiSize = 30.0;

/// Real-world-proportional size scales, keyed by emoji.
///
/// These are deliberately NOT uniform — a burger reads as a big, easy target
/// while a water drop is small and nimble. Bigger items get a bigger hitbox
/// (see [hitboxRadiusFor]) which is good game feel: large junk is easy to
/// catch by accident (punishing) and large healthy food is easy to grab
/// (rewarding). The catcher must actively dodge the chunky burger.
const Map<String, double> kSizeScale = {
  // healthy
  '💧': 0.65, // water drop — smallest, slippery
  '🥚': 0.80, // egg
  '🥑': 0.95, // avocado
  '🍎': 1.00, // apple — the reference size
  '🥦': 1.05, // broccoli
  '🐟': 1.40, // fish — largest healthy item
  // junk
  '🍩': 0.90, // donut
  '🍟': 1.10, // fries
  '🥤': 1.20, // soda cup
  '🍔': 1.30, // burger — big, hard to dodge
  // power-up (the Zealova sparkle mark) — painted, not an emoji
  kPowerUpGlyph: 1.15,
};

/// Sentinel "emoji" string used for the painted Zealova power-up item so it can
/// flow through the same [kSizeScale] / hitbox machinery as real emoji.
const String kPowerUpGlyph = '__zealova_powerup__';

/// Size scale for an item; defaults to 1.0 for anything unmapped (defensive —
/// the game never spawns unmapped emoji, but this keeps rendering crash-free).
double sizeScaleFor(String emoji) => kSizeScale[emoji] ?? 1.0;

/// Rendered font/visual size for an item.
double visualSizeFor(String emoji) => kBaseEmojiSize * sizeScaleFor(emoji);

/// Catch-hitbox radius for an item — scales with the visual size so chunky
/// items are genuinely easier to catch and harder to dodge.
double hitboxRadiusFor(String emoji) => 14.0 + visualSizeFor(emoji) * 0.42;

/// Soft-glow halo radius for an item — also scales with size.
double haloRadiusFor(String emoji) => 12.0 + visualSizeFor(emoji) * 0.34;

// ── Power-ups ────────────────────────────────────────────────────────────────

/// The four power-ups the golden Zealova item can grant. Picked uniformly at
/// random on pickup. Each lasts [kPowerUpDuration] seconds.
enum PowerUpKind { magnet, slowMo, shield, doubleScore }

/// How long a power-up stays active after being caught.
const double kPowerUpDuration = 6.0;

/// Min/max seconds between Zealova power-up spawns. A power-up appears rarely so
/// it always feels like a treat, never routine.
const double kPowerUpMinInterval = 12.0;
const double kPowerUpMaxInterval = 18.0;

extension PowerUpKindMeta on PowerUpKind {
  /// Short HUD label.
  String get label => switch (this) {
        PowerUpKind.magnet => 'MAGNET',
        PowerUpKind.slowMo => 'SLOW-MO',
        PowerUpKind.shield => 'SHIELD',
        PowerUpKind.doubleScore => '2× SCORE',
      };

  /// One-line description shown on the pickup banner + intro legend.
  String get blurb => switch (this) {
        PowerUpKind.magnet => 'Healthy food curves to you',
        PowerUpKind.slowMo => 'Everything falls in slow motion',
        PowerUpKind.shield => 'Blocks the next junk hit',
        PowerUpKind.doubleScore => 'Double points while active',
      };

  /// HUD / banner icon.
  IconData get icon => switch (this) {
        PowerUpKind.magnet => Icons.adjust_rounded,
        PowerUpKind.slowMo => Icons.hourglass_bottom_rounded,
        PowerUpKind.shield => Icons.shield_rounded,
        PowerUpKind.doubleScore => Icons.bolt_rounded,
      };

  /// Distinct accent colour per power-up so the HUD chips read at a glance.
  Color get color => switch (this) {
        PowerUpKind.magnet => const Color(0xFF42A5F5),
        PowerUpKind.slowMo => const Color(0xFF26C6DA),
        PowerUpKind.shield => const Color(0xFF66BB6A),
        PowerUpKind.doubleScore => const Color(0xFFFFC107),
      };
}

/// A currently-active power-up with its remaining lifetime (seconds).
class ActivePowerUp {
  final PowerUpKind kind;
  double remaining;
  ActivePowerUp(this.kind, this.remaining);

  /// 0..1 fraction of life left — drives the HUD timer ring.
  double get fraction => (remaining / kPowerUpDuration).clamp(0.0, 1.0);
}

// ── Stages ───────────────────────────────────────────────────────────────────

/// Per-stage difficulty snapshot. Stages are endless; difficulty keeps ramping
/// via [forStage] which is a smooth function of the (1-based) stage number.
class StageConfig {
  /// 1-based stage number.
  final int stage;

  /// Points needed (counted within this stage) to clear it.
  final int targetScore;

  /// Multiplier applied to base fall speed.
  final double speedMul;

  /// Probability a spawned item is junk.
  final double junkChance;

  /// Seconds between spawns (lower = more simultaneous items on screen).
  final double spawnInterval;

  const StageConfig({
    required this.stage,
    required this.targetScore,
    required this.speedMul,
    required this.junkChance,
    required this.spawnInterval,
  });

  /// Builds the config for a given 1-based [stage]. Everything ramps but is
  /// clamped so very deep stages stay humanly survivable.
  factory StageConfig.forStage(int stage) {
    final s = math.max(1, stage);
    // Each stage needs a bit more than the last: 120, 165, 210, …
    final target = 120 + (s - 1) * 45;
    // Fall speed climbs ~12%/stage, capped at 2.4×.
    final speed = math.min(2.4, 1.0 + (s - 1) * 0.12);
    // Junk share climbs slowly, capped at 0.46 so it stays fair.
    final junk = math.min(0.46, 0.20 + (s - 1) * 0.035);
    // Spawns get tighter, floored at 0.40s so the screen never floods.
    final interval = math.max(0.40, 0.95 - (s - 1) * 0.07);
    return StageConfig(
      stage: s,
      targetScore: target,
      speedMul: speed,
      junkChance: junk,
      spawnInterval: interval,
    );
  }

  /// Every 3rd stage clear awards a life back (capped elsewhere) — true here
  /// signals the loop to grant the bonus.
  bool get grantsLifeBack => stage % 3 == 0;
}

// ── Particles ────────────────────────────────────────────────────────────────

/// A lightweight particle for catch bursts / confetti. The game keeps a capped
/// pool of these and recycles dead ones, so allocation stays flat at 60fps.
class Particle {
  double x = 0, y = 0; // position (px, play-field local)
  double vx = 0, vy = 0; // velocity (px/s)
  double life = 0; // seconds lived
  double maxLife = 0.6; // seconds until dead
  double size = 3; // radius (px)
  Color color = Colors.white;
  bool alive = false;

  /// Re-arms a (possibly dead) particle for reuse — no allocation.
  void spawn({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double size,
    required Color color,
    required double maxLife,
  }) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.size = size;
    this.color = color;
    this.maxLife = maxLife;
    life = 0;
    alive = true;
  }

  /// Advances the particle; applies gravity + drag. Marks itself dead at EOL.
  void step(double dt) {
    if (!alive) return;
    life += dt;
    if (life >= maxLife) {
      alive = false;
      return;
    }
    vy += 320 * dt; // gravity
    vx *= (1 - 1.6 * dt).clamp(0.0, 1.0); // air drag
    x += vx * dt;
    y += vy * dt;
  }

  /// 0..1 remaining-life fraction — drives fade + shrink.
  double get fraction => (1.0 - life / maxLife).clamp(0.0, 1.0);
}

/// Fixed-size, self-recycling particle pool. [emit] grabs the first dead slot;
/// if the pool is full the oldest is overwritten, so the cost is bounded.
class ParticlePool {
  final List<Particle> particles;
  ParticlePool(int capacity)
      : particles = List.generate(capacity, (_) => Particle());

  /// Emits one particle, reusing a dead slot when possible.
  void emit({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double size,
    required Color color,
    required double maxLife,
  }) {
    Particle? slot;
    for (final p in particles) {
      if (!p.alive) {
        slot = p;
        break;
      }
    }
    // Pool full — recycle the longest-lived one (least visually disruptive).
    if (slot == null) {
      double worst = -1;
      for (final p in particles) {
        if (p.life > worst) {
          worst = p.life;
          slot = p;
        }
      }
    }
    slot!.spawn(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      size: size,
      color: color,
      maxLife: maxLife,
    );
  }

  /// Emits a radial burst of [count] particles from a point.
  void burst({
    required double x,
    required double y,
    required int count,
    required Color color,
    double speed = 180,
    double maxLife = 0.55,
    double sizeMin = 2,
    double sizeMax = 5,
  }) {
    final rng = math.Random();
    for (var i = 0; i < count; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final spd = speed * (0.45 + rng.nextDouble() * 0.55);
      _emitOne(rng, ang, spd, x, y, color, maxLife, sizeMin, sizeMax);
    }
  }

  // Small helper kept separate to avoid re-reading rng fields in a hot loop.
  void _emitOne(math.Random rng, double ang, double spd, double x, double y,
      Color color, double maxLife, double sizeMin, double sizeMax) {
    emit(
      x: x,
      y: y,
      vx: math.cos(ang) * spd,
      vy: math.sin(ang) * spd - 40, // slight upward bias
      size: sizeMin + rng.nextDouble() * (sizeMax - sizeMin),
      color: color,
      maxLife: maxLife * (0.7 + rng.nextDouble() * 0.6),
    );
  }

  /// Advances every live particle.
  void step(double dt) {
    for (final p in particles) {
      p.step(dt);
    }
  }

  /// True if any particle is still alive (lets the painter skip work).
  bool get anyAlive => particles.any((p) => p.alive);
}

// ── Ambient background drift shapes ──────────────────────────────────────────

/// A slow-drifting ambient blob/star behind the playfield. Purely cosmetic;
/// gives the dark field depth instead of flat black.
class AmbientShape {
  double x, y; // 0..1 normalised position
  final double radius; // px
  final double driftY; // normalised units/sec (slow upward drift)
  final double twinklePhase; // radians — desync the twinkle
  final bool isStar; // star sparkle vs soft blob

  AmbientShape({
    required this.x,
    required this.y,
    required this.radius,
    required this.driftY,
    required this.twinklePhase,
    required this.isStar,
  });

  /// Builds a randomised ambient layer.
  static List<AmbientShape> build(int count, math.Random rng) {
    return List.generate(count, (i) {
      final star = rng.nextBool();
      return AmbientShape(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: star
            ? 1.2 + rng.nextDouble() * 2.2
            : 26 + rng.nextDouble() * 64,
        driftY: 0.012 + rng.nextDouble() * 0.03,
        twinklePhase: rng.nextDouble() * math.pi * 2,
        isStar: star,
      );
    });
  }

  /// Advances drift; wraps from top back to bottom for an endless field.
  void step(double dt) {
    y -= driftY * dt;
    if (y < -0.1) {
      y = 1.1;
      x = math.Random().nextDouble();
    }
  }
}
