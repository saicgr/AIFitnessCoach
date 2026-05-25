import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/leaderboard_service.dart';
import '../../data/services/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import 'nutrient_rush_model.dart';
import '../glass_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
// =============================================================================
// Nutrient Rush — an immersive, optional fitness-themed arcade mini-game.
//
// Self-contained: no game engine, no sound, no network for the game loop. A
// `Ticker`-driven fixed-timestep loop renders via a single `CustomPainter`; a
// `GestureDetector` reads horizontal drag/tap to steer a glowing catcher.
//
// Loop: healthy food (🥦🍎🥚💧🥑🐟) falls — catch it for points; junk
// (🍩🍔🍟🥤) costs a life. Items are sized to their real-world proportions
// (a burger is a big easy target, a water drop is small) and the catch hitbox
// scales with size. A rare golden Zealova power-up grants Magnet / Slow-Mo /
// Shield / 2× Score for a few seconds.
//
// The run is split into endless STAGES — clear a target score to advance, with
// rising fall speed / junk ratio / spawn density and a juicy stage banner.
// Lives carry over; every 3rd stage hands a life back. A HUD progress bar
// tracks the personal best and the game fires a "NEW BEST!" confetti moment
// the instant the player overtakes it.
//
// It is launched (optionally) from the level-up celebration. It is dismissible
// at any time and can be safely abandoned (the Ticker stops on dispose).
//
// The game owns its OWN dark palette on purpose — it is an immersive game
// canvas and deliberately does NOT follow the app's light/dark theme. `accent`
// is the purple Zealova brand colour, passed in by the caller.
// =============================================================================

/// Shows the Nutrient Rush mini-game as a full-screen route.
///
/// Returns the final score (0 if abandoned without playing).
///
/// [rewardEligible] controls anti-farm reward wiring:
///  - `true`  — launched from a one-shot celebration (level-up, trophy,
///    weekly recap). The *caller* awards real XP for the returned score via
///    `xpProvider.notifier.awardMinigameXP()`, guarded so re-playing the
///    bonus round in the same dialog can't double-award. The game-over screen
///    shows an "XP earned" message.
///  - `false` — launched from the unlocked permanent FREEPLAY entry point.
///    No XP is awarded (prevents farming); the game-over screen shows a
///    cosmetic "Practice run" message instead.
///
/// The game itself never touches the XP system — it only renders the correct
/// game-over copy from this flag and returns the score. All awarding is the
/// caller's responsibility.
///
/// [ref] — when supplied, the game persists the run's score to the backend on
/// every game-over (both celebration and freeplay plays count toward the
/// personal best; this is separate from the XP anti-farm cap) and shows the
/// persisted personal best + a friends high-score view. When `null` (e.g. a
/// context with no Riverpod scope) the game runs fully offline with only a
/// session-local best — no crash.
Future<int> showNutrientRushGame(
  BuildContext context,
  Color accentColor, {
  bool rewardEligible = false,
  WidgetRef? ref,
}) async {
  // Build the persistence hooks only when a Riverpod ref is available.
  LeaderboardService? service;
  String? userId;
  if (ref != null) {
    try {
      service = LeaderboardService(ref.read(apiClientProvider));
      userId = ref.read(authStateProvider).user?.id;
    } catch (e) {
      // No API client in scope — degrade to offline (session-local best).
      debugPrint('⚠️ [NutrientRush] leaderboard service unavailable: $e');
      service = null;
      userId = null;
    }
  }
  // Persistence needs an authenticated user; without one, run offline.
  if (userId == null) service = null;

  // Pre-fetch the persisted personal best so the intro/game-over can show it
  // immediately. Failure is non-fatal — the game still runs.
  int? initialBest;
  if (service != null) {
    try {
      final data = await service.getMinigameHighScore();
      initialBest = (data['high_score'] as num?)?.toInt();
    } catch (e) {
      debugPrint('⚠️ [NutrientRush] could not fetch personal best: $e');
    }
  }

  // Submit callback: posts the final score, returns the post-submit best.
  Future<int?> Function(int)? onSubmitScore;
  if (service != null) {
    final s = service;
    onSubmitScore = (int score) async {
      try {
        final res = await s.submitMinigameScore(score: score);
        return (res['high_score'] as num?)?.toInt();
      } catch (e) {
        debugPrint('⚠️ [NutrientRush] score submit failed: $e');
        return null;
      }
    };
  }

  if (!context.mounted) return 0;
  final result = await Navigator.of(context).push<int>(
    PageRouteBuilder<int>(
      opaque: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => NutrientRushGame(
        accentColor: accentColor,
        rewardEligible: rewardEligible,
        initialPersonalBest: initialBest,
        onSubmitScore: onSubmitScore,
        leaderboardService: service,
        userId: userId,
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    ),
  );
  return result ?? 0;
}

class NutrientRushGame extends StatefulWidget {
  final Color accentColor;

  /// When true, the game-over screen states the run earned XP; when false it
  /// shows a cosmetic-only "practice run" message. Does NOT itself award XP —
  /// see [showNutrientRushGame].
  final bool rewardEligible;

  /// The user's persisted personal best, pre-fetched before launch. `null`
  /// when persistence is unavailable (offline / no Riverpod scope).
  final int? initialPersonalBest;

  /// Called on every game-over with the run's final score. Returns the
  /// post-submission persisted personal best, or `null` if the submit failed.
  /// When `null`, the game keeps only a session-local best.
  final Future<int?> Function(int score)? onSubmitScore;

  /// Used to power the in-game friends high-score view. `null` → no view.
  final LeaderboardService? leaderboardService;

  /// The authenticated user's id — required by the leaderboard query for the
  /// high-score view. `null` → high-score view is unavailable.
  final String? userId;

  const NutrientRushGame({
    super.key,
    required this.accentColor,
    this.rewardEligible = false,
    this.initialPersonalBest,
    this.onSubmitScore,
    this.leaderboardService,
    this.userId,
  });

  @override
  State<NutrientRushGame> createState() => _NutrientRushGameState();
}

enum _GamePhase { intro, playing, paused, gameOver }

class _NutrientRushGameState extends State<NutrientRushGame>
    with SingleTickerProviderStateMixin {
  // ── Game loop ──
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _accumulator = 0; // fixed-timestep accumulator (seconds)
  static const double _fixedStep = 1 / 60; // simulate at 60 Hz

  // ── Game state ──
  _GamePhase _phase = _GamePhase.intro;
  final math.Random _rng = math.Random();

  final List<_FallingItem> _items = [];
  final List<_Pop> _pops = [];

  // Lightweight, capped, self-recycling particle pool — see ParticlePool.
  final ParticlePool _particles = ParticlePool(140);

  // Slow-drifting ambient background layer (built once on first layout).
  List<AmbientShape> _ambient = const [];

  // Catcher: position is a 0..1 fraction of the play width.
  double _catcherX = 0.5;
  double _catcherTargetX = 0.5;

  int _score = 0;
  int _lives = 3;
  int _combo = 0;
  int _bestCombo = 0;

  // ── Stages ──
  // Endless stages; `_stageScore` counts points earned within the current
  // stage and clears it once it reaches the stage's target.
  int _stageNumber = 1;
  int _stageScore = 0;
  StageConfig _stage = StageConfig.forStage(1);
  // Banner shown briefly when a stage is cleared ("STAGE 2").
  double _stageBannerLife = 0; // counts up while a banner is showing
  String _stageBannerText = '';
  // Short breather after a stage clear during which spawns pause.
  double _breather = 0;

  // ── Power-ups ──
  final List<ActivePowerUp> _activePowerUps = [];
  double _powerUpSpawnTimer = 0; // seconds until the next Zealova item spawns
  // Banner shown briefly on power-up pickup.
  double _powerUpBannerLife = 0;
  String _powerUpBannerText = '';
  IconData _powerUpBannerIcon = Icons.bolt_rounded;
  Color _powerUpBannerColor = Colors.amber;

  // ── Juice ──
  double _shake = 0; // screen-shake magnitude, decays each frame
  double _powerFlash = 0; // white pickup flash, decays each frame

  // ── Persisted personal best ──
  // Seeded from the pre-fetched value; updated after each game-over submit.
  int? _personalBest;
  // True while a score is being POSTed to the backend.
  bool _submittingScore = false;
  // True when the just-finished run set a new persisted personal best.
  bool _isNewBest = false;
  // The best the player had BEFORE this run started — used for the delta.
  int? _bestBeforeRun;
  // True once this run has overtaken the pre-run best mid-game (fires the
  // celebratory "NEW BEST!" moment exactly once).
  bool _beatBestThisRun = false;
  double _newBestCelebration = 0; // counts down while the moment plays

  double _elapsed = 0; // seconds since play started
  double _spawnTimer = 0;

  // Play area is measured on first layout; the loop is a no-op until known.
  Size _playSize = Size.zero;

  // ── Item catalogue ──
  static const List<String> _healthy = ['🥦', '🍎', '🥚', '💧', '🥑', '🐟'];
  static const List<String> _junk = ['🍩', '🍔', '🍟', '🥤'];

  // Catcher geometry (kept here so loop + painter agree).
  static const double _catcherHalfW = 46.0;
  double get _catcherY => _playSize.height - 92.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _personalBest = widget.initialPersonalBest;
  }

  @override
  void dispose() {
    // Safe abandon: stopping + disposing the ticker halts the loop cleanly.
    _ticker.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────── lifecycle ──

  void _startGame() {
    setState(() {
      _phase = _GamePhase.playing;
      _items.clear();
      _pops.clear();
      for (final p in _particles.particles) {
        p.alive = false; // reset the pool
      }
      _score = 0;
      _lives = 3;
      _combo = 0;
      _bestCombo = 0;
      _elapsed = 0;
      _spawnTimer = 0;
      _stageNumber = 1;
      _stageScore = 0;
      _stage = StageConfig.forStage(1);
      _stageBannerLife = 0;
      _breather = 0;
      _activePowerUps.clear();
      _powerUpSpawnTimer = _randomPowerUpInterval();
      _powerUpBannerLife = 0;
      _shake = 0;
      _powerFlash = 0;
      _catcherX = 0.5;
      _catcherTargetX = 0.5;
      _isNewBest = false;
      _submittingScore = false;
      // Snapshot the best so the in-run "NEW BEST!" moment + game-over delta
      // both compare against where the player STARTED, not a moving target.
      _bestBeforeRun = _personalBest;
      _beatBestThisRun = false;
      _newBestCelebration = 0;
    });
    _lastTick = Duration.zero;
    _accumulator = 0;
    HapticService.medium();
    _ticker.start();
  }

  void _togglePause() {
    if (_phase == _GamePhase.playing) {
      setState(() => _phase = _GamePhase.paused);
      _ticker.stop();
    } else if (_phase == _GamePhase.paused) {
      setState(() => _phase = _GamePhase.playing);
      _lastTick = Duration.zero; // avoid a huge delta after a pause
      _ticker.start();
    }
    HapticService.light();
  }

  void _endGame() {
    _ticker.stop();
    HapticService.heavy();
    setState(() => _phase = _GamePhase.gameOver);
    _submitScore();
  }

  /// Submits the finished run's score to the backend (every game-over counts —
  /// freeplay and celebration plays alike). Updates the persisted personal
  /// best shown on the game-over screen. Best-effort: a failed submit leaves
  /// the session-local state intact and never blocks the UI.
  Future<void> _submitScore() async {
    final submit = widget.onSubmitScore;
    if (submit == null) {
      // No persistence wired — fall back to a session-local best so the
      // game-over screen still shows something meaningful.
      if (mounted) {
        setState(() {
          _isNewBest = _personalBest == null || _score > _personalBest!;
          if (_isNewBest) _personalBest = _score;
        });
      }
      return;
    }

    final prevBest = _personalBest;
    if (mounted) setState(() => _submittingScore = true);
    final newBest = await submit(_score);
    if (!mounted) return;
    setState(() {
      _submittingScore = false;
      if (newBest != null) {
        _personalBest = newBest;
        _isNewBest = prevBest == null || _score > prevBest;
      } else {
        // Submit failed — keep an optimistic session-local best.
        _isNewBest = prevBest == null || _score > prevBest;
        if (_isNewBest) _personalBest = _score;
      }
    });
    if (_isNewBest && _score > 0) HapticService.success();
  }

  /// Closes the game, returning the final score to the caller.
  void _exit() {
    HapticService.light();
    Navigator.of(context).maybePop(_phase == _GamePhase.gameOver ? _score : 0);
  }

  // ───────────────────────────────────────────────────────── game loop ──

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    double dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    // Clamp huge deltas (app paused / hot reload) so the sim never explodes.
    if (dt > 0.1) dt = 0.1;

    _accumulator += dt;
    var stepped = false;
    while (_accumulator >= _fixedStep) {
      _simulate(_fixedStep);
      _accumulator -= _fixedStep;
      stepped = true;
    }
    if (stepped && mounted) setState(() {});
  }

  void _simulate(double dt) {
    if (_phase != _GamePhase.playing || _playSize == Size.zero) return;

    _elapsed += dt;

    // ── Decaying juice timers ──
    if (_shake > 0) _shake = math.max(0, _shake - dt * 26);
    if (_powerFlash > 0) _powerFlash = math.max(0, _powerFlash - dt * 3.2);
    if (_stageBannerLife > 0) {
      _stageBannerLife += dt;
      if (_stageBannerLife > 1.8) _stageBannerLife = 0;
    }
    if (_powerUpBannerLife > 0) {
      _powerUpBannerLife += dt;
      if (_powerUpBannerLife > 2.2) _powerUpBannerLife = 0;
    }
    if (_newBestCelebration > 0) {
      _newBestCelebration = math.max(0, _newBestCelebration - dt);
    }
    if (_breather > 0) _breather = math.max(0, _breather - dt);

    // ── Power-up lifetimes ──
    for (final pu in _activePowerUps) {
      pu.remaining -= dt;
    }
    _activePowerUps.removeWhere((pu) => pu.remaining <= 0);

    final slowMo = _hasPowerUp(PowerUpKind.slowMo);
    final magnet = _hasPowerUp(PowerUpKind.magnet);
    // Slow-Mo halves the *effective* fall speed of every item.
    final timeScale = slowMo ? 0.5 : 1.0;

    // Ambient background drift (cosmetic — runs at real time, not slow-mo).
    for (final a in _ambient) {
      a.step(dt);
    }
    // Particles always advance at real time so bursts stay snappy.
    _particles.step(dt);

    // Smoothly chase the drag target so the catcher feels weighty.
    _catcherX += (_catcherTargetX - _catcherX) * math.min(1.0, dt * 14);

    // ── Spawn (paused during the post-stage breather) ──
    if (_breather <= 0) {
      _spawnTimer -= dt;
      if (_spawnTimer <= 0) {
        _spawnItem();
        // Stage-driven interval, with a little jitter so it never feels metric.
        _spawnTimer = _stage.spawnInterval + _rng.nextDouble() * 0.35;
      }
      // ── Rare Zealova power-up spawn ──
      _powerUpSpawnTimer -= dt;
      if (_powerUpSpawnTimer <= 0) {
        _spawnPowerUpItem();
        _powerUpSpawnTimer = _randomPowerUpInterval();
      }
    }

    final w = _playSize.width;
    final h = _playSize.height;
    final catcherPx = _catcherX * w;
    final catcherY = _catcherY;

    // ── Move + resolve items ──
    for (final item in _items) {
      // Vertical fall, scaled by stage speed + slow-mo.
      item.y += item.speed * _stage.speedMul * timeScale * dt;
      item.spin += dt * item.spinSpeed * timeScale;

      // Magnet: healthy items gently curve horizontally toward the catcher.
      if (magnet && item.healthy && !item.isPowerUp) {
        final dx = catcherPx - item.x;
        // Pull strength grows as the item nears the catcher line.
        final proximity = (1.0 - ((catcherY - item.y).abs() / h)).clamp(0.0, 1.0);
        item.x += dx * math.min(1.0, dt * (2.2 + proximity * 4.0));
      }

      if (item.resolved) continue;

      // Catch test: item overlaps the catcher band. Hitbox scales with size.
      final reach = _catcherHalfW + item.hitbox;
      if (item.y >= catcherY - 30 && item.y <= catcherY + 34) {
        if ((item.x - catcherPx).abs() < reach) {
          item.resolved = true;
          _onCatch(item, Offset(item.x, catcherY - 12));
          continue;
        }
      }

      // Missed: fell past the bottom.
      if (item.y > h + 48) {
        item.resolved = true;
        if (item.healthy && !item.isPowerUp) {
          _combo = 0; // miss a good item → combo break (no life lost)
          HapticService.selection();
        }
        // Missing a power-up is no penalty — it just floats away.
      }
    }
    // Drop resolved items immediately (caught items vanish into the catcher;
    // missed items have already fallen off-screen).
    _items.removeWhere((i) => i.resolved);

    // ── Pops (catch flourishes) ──
    for (final p in _pops) {
      p.life += dt;
    }
    _pops.removeWhere((p) => p.life > 0.7);

    // ── Stage clear ──
    if (_stageScore >= _stage.targetScore) {
      _advanceStage();
    }

    // ── End condition ──
    if (_lives <= 0) {
      _endGame();
      return;
    }
  }

  /// Clears the current stage: bumps the stage, resets the per-stage counter,
  /// fires the banner + haptic, grants a life back every 3rd stage, and starts
  /// a short breather so the player gets a beat to breathe.
  void _advanceStage() {
    _stageNumber += 1;
    _stageScore = 0;
    _stage = StageConfig.forStage(_stageNumber);
    _stageBannerLife = 0.0001; // arm the banner timer
    _breather = 1.1; // ~1s spawn pause
    HapticService.success();
    // Every 3rd stage hands a life back (capped at 5 so it can't snowball).
    if (_stage.grantsLifeBack && _lives < 5) {
      _lives += 1;
      _stageBannerText = 'STAGE $_stageNumber  •  +1 ❤';
    } else {
      _stageBannerText = 'STAGE $_stageNumber';
    }
    // Confetti to celebrate the clear.
    _particles.burst(
      x: _playSize.width / 2,
      y: _playSize.height * 0.4,
      count: 26,
      color: widget.accentColor,
      speed: 240,
      maxLife: 0.8,
      sizeMax: 6,
    );
  }

  /// Picks a randomised seconds-until-next-powerup within the configured band.
  double _randomPowerUpInterval() =>
      kPowerUpMinInterval +
      _rng.nextDouble() * (kPowerUpMaxInterval - kPowerUpMinInterval);

  bool _hasPowerUp(PowerUpKind kind) =>
      _activePowerUps.any((p) => p.kind == kind);

  void _spawnItem() {
    final w = _playSize.width;
    final isJunk = _rng.nextDouble() < _stage.junkChance;
    final emoji = isJunk
        ? _junk[_rng.nextInt(_junk.length)]
        : _healthy[_rng.nextInt(_healthy.length)];
    // Keep items fully on-screen accounting for their (size-scaled) radius.
    final radius = hitboxRadiusFor(emoji);
    final margin = radius + 8;
    _items.add(_FallingItem(
      x: margin + _rng.nextDouble() * math.max(1.0, w - margin * 2),
      y: -40,
      speed: 150 + _rng.nextDouble() * 90,
      emoji: emoji,
      healthy: !isJunk,
      isPowerUp: false,
      spin: 0,
      spinSpeed: (_rng.nextDouble() - 0.5) * 3.0,
    ));
  }

  /// Spawns the rare golden Zealova power-up item.
  void _spawnPowerUpItem() {
    final w = _playSize.width;
    final radius = hitboxRadiusFor(kPowerUpGlyph);
    final margin = radius + 8;
    _items.add(_FallingItem(
      x: margin + _rng.nextDouble() * math.max(1.0, w - margin * 2),
      y: -40,
      // Slightly slower than normal items so it is reachable.
      speed: 120 + _rng.nextDouble() * 50,
      emoji: kPowerUpGlyph,
      healthy: true, // treated as desirable (missing it is harmless)
      isPowerUp: true,
      spin: 0,
      spinSpeed: 1.6, // gentle, deliberate spin
    ));
  }

  void _onCatch(_FallingItem item, Offset at) {
    // ── Power-up pickup ──
    if (item.isPowerUp) {
      final kind = PowerUpKind.values[_rng.nextInt(PowerUpKind.values.length)];
      // Stack: refresh duration if already active, else add a new chip.
      final existing = _activePowerUps.where((p) => p.kind == kind).firstOrNull;
      if (existing != null) {
        existing.remaining = kPowerUpDuration;
      } else {
        _activePowerUps.add(ActivePowerUp(kind, kPowerUpDuration));
      }
      _powerUpBannerText = '${kind.label}!';
      _powerUpBannerIcon = kind.icon;
      _powerUpBannerColor = kind.color;
      _powerUpBannerLife = 0.0001;
      _powerFlash = 1.0; // bright pickup flash
      _particles.burst(
        x: at.dx,
        y: at.dy,
        count: 22,
        color: const Color(0xFFFFD54F),
        speed: 230,
        maxLife: 0.7,
        sizeMax: 6,
      );
      HapticService.success();
      return;
    }

    if (item.healthy) {
      _combo += 1;
      _bestCombo = math.max(_bestCombo, _combo);
      var gain = 10 + (_combo ~/ 3) * 5; // combo multiplier
      // 2× Score power-up doubles every healthy catch.
      final doubled = _hasPowerUp(PowerUpKind.doubleScore);
      if (doubled) gain *= 2;
      _score += gain;
      _stageScore += gain;
      _maybeFireNewBest();
      // Floating score pop — escalates its wording with the combo.
      final popText = _combo >= 6
          ? '+$gain  x$_combo!'
          : (doubled ? '+$gain  2×' : '+$gain');
      _pops.add(_Pop(at, popText, widget.accentColor, _combo));
      // Green spark burst — bigger with higher combo.
      _particles.burst(
        x: at.dx,
        y: at.dy,
        count: 8 + math.min(10, _combo),
        color: const Color(0xFF66E08A),
        speed: 150 + math.min(120, _combo * 12.0),
      );
      if (_combo > 0 && _combo % 5 == 0) {
        HapticService.success();
      } else {
        HapticService.light();
      }
    } else {
      // ── Junk hit ──
      if (_hasPowerUp(PowerUpKind.shield)) {
        // Shield absorbs this hit — consume the shield, lose no life.
        _activePowerUps.removeWhere((p) => p.kind == PowerUpKind.shield);
        _pops.add(_Pop(at, 'BLOCKED', const Color(0xFF66BB6A), 0));
        _particles.burst(
          x: at.dx,
          y: at.dy,
          count: 16,
          color: const Color(0xFF66BB6A),
          speed: 200,
        );
        HapticService.medium();
      } else {
        _lives -= 1;
        _combo = 0;
        _shake = 14; // screen shake on a real hit
        _pops.add(_Pop(at, '-1 ❤', const Color(0xFFFF5252), 0));
        _particles.burst(
          x: at.dx,
          y: at.dy,
          count: 18,
          color: const Color(0xFFFF5252),
          speed: 210,
        );
        HapticService.error();
      }
    }
  }

  /// Fires the one-shot celebratory "NEW BEST!" moment the instant the live
  /// score overtakes the best the player had when the run started.
  void _maybeFireNewBest() {
    if (_beatBestThisRun) return;
    final target = _bestBeforeRun;
    if (target == null || target <= 0) return; // nothing to beat
    if (_score > target) {
      _beatBestThisRun = true;
      _newBestCelebration = 1.6;
      _shake = 8;
      HapticService.success();
      // Gold confetti from the top-centre.
      _particles.burst(
        x: _playSize.width / 2,
        y: _playSize.height * 0.18,
        count: 34,
        color: const Color(0xFFFFC107),
        speed: 280,
        maxLife: 0.9,
        sizeMax: 6,
      );
    }
  }

  // ───────────────────────────────────────────────────────────── input ──

  void _onDrag(Offset localPos) {
    if (_phase != _GamePhase.playing || _playSize.width == 0) return;
    _catcherTargetX = (localPos.dx / _playSize.width).clamp(0.0, 1.0);
  }

  // ──────────────────────────────────────────────────────────── render ──

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Reserve room for the top HUD; the rest is the play field.
            const hudHeight = 64.0;
            final playSize = Size(
              constraints.maxWidth,
              math.max(220.0, constraints.maxHeight - hudHeight),
            );
            _playSize = playSize;
            // Build the ambient layer once we know the field exists.
            if (_ambient.isEmpty) {
              _ambient = AmbientShape.build(18, _rng);
            }

            return Column(
              children: [
                _buildHud(),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _onDrag(d.localPosition),
                    onPanUpdate: (d) => _onDrag(d.localPosition),
                    onTapDown: (d) => _onDrag(d.localPosition),
                    child: Stack(
                      children: [
                        // ── Game field ──
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GamePainter(
                              items: _items,
                              pops: _pops,
                              particles: _particles,
                              ambient: _ambient,
                              catcherX: _catcherX,
                              accent: widget.accentColor,
                              shake: _shake,
                              powerFlash: _powerFlash,
                              hasMagnet: _hasPowerUp(PowerUpKind.magnet),
                              hasShield: _hasPowerUp(PowerUpKind.shield),
                              hasSlowMo: _hasPowerUp(PowerUpKind.slowMo),
                              time: _elapsed,
                            ),
                          ),
                        ),
                        // ── In-field banners ──
                        if (_stageBannerLife > 0)
                          _buildStageBanner(),
                        if (_powerUpBannerLife > 0)
                          _buildPowerUpBanner(),
                        if (_newBestCelebration > 0)
                          _buildNewBestBanner(),
                        // ── Overlays ──
                        if (_phase == _GamePhase.intro)
                          _buildIntroOverlay(media),
                        if (_phase == _GamePhase.paused)
                          _buildPausedOverlay(),
                        if (_phase == _GamePhase.gameOver)
                          _buildGameOverOverlay(),
                      ],
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

  // ── HUD ───────────────────────────────────────────────────────────────

  Widget _buildHud() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      color: Colors.black.withValues(alpha: 0.42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Score
              _hudChip(
                icon: Icons.bolt_rounded,
                label: '$_score',
                color: widget.accentColor,
              ),
              const SizedBox(width: 6),
              // Stage
              _hudChip(
                icon: Icons.layers_rounded,
                label: 'S$_stageNumber',
                color: const Color(0xFF7E9CFF),
              ),
              const SizedBox(width: 6),
              // Combo (only once it's meaningful)
              if (_combo >= 2)
                _hudChip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'x$_combo',
                  color: Colors.orange,
                ),
              const Spacer(),
              // Lives as hearts (supports the up-to-5 life-back bonus).
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(math.max(3, _lives), (i) {
                  final filled = i < _lives;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Icon(
                      filled
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: filled
                          ? const Color(0xFFFF5252)
                          : Colors.white24,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 6),
              if (_phase == _GamePhase.playing || _phase == _GamePhase.paused)
                _iconButton(
                  icon: _phase == _GamePhase.paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  onTap: _togglePause,
                ),
              const SizedBox(width: 4),
              // Close — always available (dismissible at any time).
              _iconButton(icon: Icons.close_rounded, onTap: _exit),
            ],
          ),
          const SizedBox(height: 5),
          // Best-score progress bar + active power-up chips.
          Row(
            children: [
              Expanded(child: _buildBestProgressBar()),
              if (_activePowerUps.isNotEmpty) ...[
                const SizedBox(width: 8),
                ..._activePowerUps.map(_powerUpHudChip),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// A slim progress bar tracking the live score toward the personal best.
  /// Turns gold once the player has overtaken their best this run.
  Widget _buildBestProgressBar() {
    final best = _bestBeforeRun ?? _personalBest;
    final hasBest = best != null && best > 0;
    // 0..1 fill toward the best (clamped); full when there's no best yet.
    final frac = hasBest ? (_score / best).clamp(0.0, 1.0) : 1.0;
    final beaten = _beatBestThisRun || !hasBest;
    final fillColor =
        beaten ? const Color(0xFFFFC107) : widget.accentColor;
    final label = !hasBest
        ? 'No best yet — set one!'
        : (beaten ? 'NEW BEST! $_score' : 'Best $best');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              beaten ? Icons.emoji_events_rounded : Icons.flag_rounded,
              size: 11,
              color: fillColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fillColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 5,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              FractionallySizedBox(
                widthFactor: frac,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        fillColor.withValues(alpha: 0.7),
                        fillColor,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A small HUD chip for one active power-up, with a depleting timer ring.
  Widget _powerUpHudChip(ActivePowerUp pu) {
    final c = pu.kind.color;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Depleting ring shows time remaining.
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                value: pu.fraction,
                strokeWidth: 2.4,
                backgroundColor: c.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
            Icon(pu.kind.icon, size: 12, color: c),
          ],
        ),
      ),
    );
  }

  Widget _hudChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }

  // ── In-field banners ──────────────────────────────────────────────────

  /// Juicy slide+scale "STAGE N" banner shown briefly on a stage clear.
  Widget _buildStageBanner() {
    // Ease in for the first 0.3s, hold, then fade out the last 0.4s.
    final t = _stageBannerLife;
    final appear = (t / 0.3).clamp(0.0, 1.0);
    final disappear = t > 1.4 ? ((t - 1.4) / 0.4).clamp(0.0, 1.0) : 0.0;
    final scale = 0.7 + appear * 0.3;
    final opacity = (appear - disappear).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Transform.translate(
              offset: Offset(0, (1 - appear) * 30),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.4),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).nutrientRushGameStageClear,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stageBannerText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Brief banner shown on power-up pickup, sliding down from the top.
  Widget _buildPowerUpBanner() {
    final t = _powerUpBannerLife;
    final appear = (t / 0.25).clamp(0.0, 1.0);
    final disappear = t > 1.7 ? ((t - 1.7) / 0.5).clamp(0.0, 1.0) : 0.0;
    final opacity = (appear - disappear).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.55),
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - appear) * -24),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _powerUpBannerColor.withValues(alpha: 0.8),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _powerUpBannerColor.withValues(alpha: 0.45),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_powerUpBannerIcon,
                      color: _powerUpBannerColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _powerUpBannerText,
                    style: TextStyle(
                      color: _powerUpBannerColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The celebratory "NEW BEST!" moment that fires mid-run.
  Widget _buildNewBestBanner() {
    final t = (1.6 - _newBestCelebration); // counts up
    final appear = (t / 0.3).clamp(0.0, 1.0);
    final disappear = t > 1.2 ? ((t - 1.2) / 0.4).clamp(0.0, 1.0) : 0.0;
    final opacity = (appear - disappear).clamp(0.0, 1.0);
    final scale = 0.6 + appear * 0.5;
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.25),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFFC107),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66FFC107),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context).nutrientRushGameNewBest,
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Overlays ──────────────────────────────────────────────────────────

  Widget _buildIntroOverlay(MediaQueryData media) {
    return _centeredPanel(
      children: [
        const Text('🚀', style: TextStyle(fontSize: 50)),
        const SizedBox(height: 8),
        _title('NUTRIENT RUSH'),
        const SizedBox(height: 6),
        _body('Catch the good stuff, dodge the junk — clear stages and chase '
            'your best.'),
        const SizedBox(height: 16),
        // Legend with REAL in-game sizing so the player knows what to expect.
        _sizedLegendRow(_healthy, 'Catch — score points', widget.accentColor),
        const SizedBox(height: 8),
        _sizedLegendRow(_junk, 'Dodge — costs a life', const Color(0xFFFF5252)),
        const SizedBox(height: 10),
        // Power-up explainer.
        _powerUpLegend(),
        const SizedBox(height: 10),
        _body('Drag anywhere to steer your basket.', dim: true),
        if (_personalBest != null && _personalBest! > 0) ...[
          const SizedBox(height: 12),
          _bestPill(_personalBest!),
        ],
        const SizedBox(height: 18),
        _primaryButton('PLAY', _startGame),
        const SizedBox(height: 8),
        _textButton('Skip', _exit),
      ],
    );
  }

  /// Intro legend row that draws each emoji at its true in-game size.
  Widget _sizedLegendRow(List<String> emojis, String label, Color color) {
    return Row(
      children: [
        // Emoji shown at their relative sizes via a tiny custom paint.
        SizedBox(
          width: 118,
          height: 34,
          child: CustomPaint(
            painter: _LegendEmojiPainter(emojis: emojis),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  /// Intro callout explaining the rare golden Zealova power-up.
  Widget _powerUpLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC107).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The painted Zealova sparkle mark, mini.
              SizedBox(
                width: 30,
                height: 30,
                child: CustomPaint(
                  painter: _SparkleMarkPainter(
                    accent: widget.accentColor,
                    scale: 0.78,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).nutrientRushGameCatchTheGoldenZealova,
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // The four power-ups, two per row.
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: PowerUpKind.values.map((k) {
              return SizedBox(
                width: 132,
                child: Row(
                  children: [
                    Icon(k.icon, size: 13, color: k.color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        k.label,
                        style: TextStyle(
                          color: k.color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Prominent personal-best pill for the intro / game-over screens.
  Widget _bestPill(int best) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFC107).withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              size: 16, color: Color(0xFFFFD54F)),
          const SizedBox(width: 6),
          Text(
            'Your best: $best',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return _centeredPanel(
      children: [
        _title('PAUSED'),
        const SizedBox(height: 8),
        _body('Stage $_stageNumber  •  Score $_score', dim: true),
        const SizedBox(height: 16),
        _primaryButton('RESUME', _togglePause),
        const SizedBox(height: 8),
        _textButton('End bonus round', _exit),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    final bestValue = _personalBest ?? _score;
    final prev = _bestBeforeRun;
    // Delta vs the best the player STARTED with.
    final int? delta = (prev != null) ? _score - prev : null;
    return _centeredPanel(
      children: [
        Text(_isNewBest && _score > 0 ? '🏆' : '💪',
            style: const TextStyle(fontSize: 50)),
        const SizedBox(height: 8),
        _title(_isNewBest && _score > 0 ? 'NEW PERSONAL BEST!' : 'GOOD RUN!'),
        if (_isNewBest && _score > 0) ...[
          const SizedBox(height: 8),
          _newBestBadge(),
        ],
        const SizedBox(height: 14),
        _statRow('SCORE', '$_score'),
        const SizedBox(height: 6),
        _statRow('STAGE REACHED', '$_stageNumber'),
        const SizedBox(height: 6),
        _statRow('BEST COMBO', 'x$_bestCombo'),
        const SizedBox(height: 6),
        _statRow(
          'PERSONAL BEST',
          _submittingScore ? '…' : '$bestValue',
        ),
        // Score-vs-best delta line.
        if (delta != null && !_submittingScore) ...[
          const SizedBox(height: 8),
          _deltaLine(delta),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: widget.accentColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            widget.rewardEligible
                ? (_score > 0
                    ? '⚡ Bonus XP earned!'
                    : '✨ Bonus celebration unlocked')
                : '🎮 Practice run — freeplay only',
            style: TextStyle(
              color: widget.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _primaryButton('PLAY AGAIN', _startGame),
        const SizedBox(height: 8),
        if (widget.leaderboardService != null && widget.userId != null) ...[
          _textButton('🏆 High Scores', _showHighScores),
          const SizedBox(height: 2),
        ],
        _textButton('Done', _exit),
      ],
    );
  }

  /// Game-over line showing how the run compares to the previous best.
  Widget _deltaLine(int delta) {
    final beat = delta > 0;
    final color = beat ? const Color(0xFF66E08A) : Colors.white54;
    final text = beat
        ? '+$delta over your old best!'
        : (delta == 0
            ? 'Matched your best — so close!'
            : '${-delta} short of your best');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          beat ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  /// A "NEW PERSONAL BEST!" flourish for the game-over screen.
  Widget _newBestBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.6)),
      ),
      child: Text(
        AppLocalizations.of(context).nutrientRushGameNewPersonalBest,
        style: TextStyle(
          color: Color(0xFFFFC107),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  /// Opens the friends high-score view as a bottom sheet.
  void _showHighScores() {
    final service = widget.leaderboardService;
    final uid = widget.userId;
    if (service == null || uid == null) return;
    HapticService.light();
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        opaque: true,
        child: _HighScoresSheet(
          service: service,
          userId: uid,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  Widget _centeredPanel({required List<Widget> children}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xF21A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  Widget _title(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          decoration: TextDecoration.none,
        ),
      );

  Widget _body(String text, {bool dim = false}) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: dim ? 0.45 : 0.7),
          fontSize: 13,
          height: 1.35,
          decoration: TextDecoration.none,
        ),
      );

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _textButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

// =============================================================================
// Simulation entities
// =============================================================================

class _FallingItem {
  double x;
  double y;
  double speed;
  final String emoji;
  final bool healthy;

  /// True for the rare golden Zealova power-up item (painted, not an emoji).
  final bool isPowerUp;

  double spin;
  final double spinSpeed;
  bool resolved = false;

  /// Cached visual size + catch-hitbox radius, derived once from the real-life
  /// size-scale map so the loop + painter never recompute them per frame.
  final double visualSize;
  final double hitbox;
  final double halo;

  _FallingItem({
    required this.x,
    required this.y,
    required this.speed,
    required this.emoji,
    required this.healthy,
    required this.isPowerUp,
    required this.spin,
    required this.spinSpeed,
  })  : visualSize = visualSizeFor(emoji),
        hitbox = hitboxRadiusFor(emoji),
        halo = haloRadiusFor(emoji);
}

/// A short-lived score/feedback flourish at a catch point. [combo] drives the
/// escalating size/colour flair (0 = a non-combo event like a junk hit).
class _Pop {
  final Offset at;
  final String text;
  final Color color;
  final int combo;
  double life = 0;

  _Pop(this.at, this.text, this.color, this.combo);
}

// =============================================================================
// Renderer — a single CustomPainter draws the whole field.
// =============================================================================

class _GamePainter extends CustomPainter {
  final List<_FallingItem> items;
  final List<_Pop> pops;
  final ParticlePool particles;
  final List<AmbientShape> ambient;
  final double catcherX;
  final Color accent;
  final double shake;
  final double powerFlash;
  final bool hasMagnet;
  final bool hasShield;
  final bool hasSlowMo;
  final double time; // seconds — drives subtle animation (twinkle, thruster)

  _GamePainter({
    required this.items,
    required this.pops,
    required this.particles,
    required this.ambient,
    required this.catcherX,
    required this.accent,
    required this.shake,
    required this.powerFlash,
    required this.hasMagnet,
    required this.hasShield,
    required this.hasSlowMo,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Screen shake — offset the whole field on a junk hit ──
    if (shake > 0) {
      final rng = math.Random((time * 1000).toInt());
      canvas.translate(
        (rng.nextDouble() - 0.5) * shake,
        (rng.nextDouble() - 0.5) * shake,
      );
    }

    // ── Background gradient — a deep, slightly-vignetted dark field ──
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.35),
        radius: 1.25,
        colors: [Color(0xFF1C2236), Color(0xFF120D1C), Color(0xFF0A0710)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Ambient drifting shapes (depth) ──
    _drawAmbient(canvas, size);

    // Slow-Mo tint — a faint cyan wash so the effect reads even off the HUD.
    if (hasSlowMo) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF26C6DA).withValues(alpha: 0.06),
      );
    }

    // ── Falling items ──
    for (final item in items) {
      if (item.isPowerUp) {
        _drawPowerUp(canvas, item, size);
      } else {
        _drawFallingFood(canvas, item);
      }
    }

    // ── Particles (catch bursts / confetti) ──
    if (particles.anyAlive) {
      for (final p in particles.particles) {
        if (!p.alive) continue;
        final f = p.fraction;
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.size * (0.4 + f * 0.6),
          Paint()..color = p.color.withValues(alpha: f),
        );
      }
    }

    // ── Catcher ──
    final catcherY = size.height - 92.0;
    final cx = catcherX * size.width;
    _drawCatcher(canvas, Offset(cx, catcherY));

    // ── Score pops ──
    for (final p in pops) {
      _drawPop(canvas, p);
    }

    // ── Power-up pickup flash — a quick white veil ──
    if (powerFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.white.withValues(alpha: powerFlash * 0.28),
      );
    }
  }

  /// Slow-drifting ambient blobs + twinkling stars behind the field.
  void _drawAmbient(Canvas canvas, Size size) {
    for (final a in ambient) {
      final px = a.x * size.width;
      final py = a.y * size.height;
      if (a.isStar) {
        // Twinkle: brightness oscillates, desynced per-star.
        final tw = 0.25 + 0.55 * (0.5 + 0.5 * math.sin(time * 1.6 + a.twinklePhase));
        canvas.drawCircle(
          Offset(px, py),
          a.radius,
          Paint()..color = Colors.white.withValues(alpha: tw * 0.5),
        );
      } else {
        // Soft accent-tinted blob.
        canvas.drawCircle(
          Offset(px, py),
          a.radius,
          Paint()
            ..color = accent.withValues(alpha: 0.05)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
        );
      }
    }
  }

  /// Draws a normal falling food item with a size-scaled halo.
  void _drawFallingFood(Canvas canvas, _FallingItem item) {
    // Size-scaled soft halo: green-ish for healthy, red-ish for junk.
    final halo = Paint()
      ..color = (item.healthy ? accent : const Color(0xFFFF5252))
          .withValues(alpha: 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(Offset(item.x, item.y), item.halo, halo);
    // The emoji itself, sized to its real-life proportion.
    _drawEmoji(canvas, item.emoji, Offset(item.x, item.y), item.visualSize,
        item.spin);
  }

  /// Draws the rare golden Zealova power-up: a painted sparkle mark with a
  /// pulsing golden glow.
  void _drawPowerUp(Canvas canvas, _FallingItem item, Size size) {
    final c = Offset(item.x, item.y);
    // Pulsing golden glow.
    final pulse = 0.7 + 0.3 * math.sin(time * 6);
    canvas.drawCircle(
      c,
      item.halo + 8,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.30 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      c,
      item.halo,
      Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // The painted Zealova sparkle mark, spinning gently.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(item.spin * 0.5);
    _paintSparkleMark(
      canvas,
      Offset.zero,
      item.visualSize * 0.62,
      accent,
      golden: true,
    );
    canvas.restore();
  }

  /// A short-lived floating score pop. Higher-combo pops are bigger + bolder.
  void _drawPop(Canvas canvas, _Pop p) {
    final t = (p.life / 0.7).clamp(0.0, 1.0);
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    final dy = -42 * t;
    // Combo flair: pops scale up with the streak.
    final fontSize = 16.0 + math.min(12, p.combo) * 1.1;
    final tp = TextPainter(
      text: TextSpan(
        text: p.text,
        style: TextStyle(
          color: p.color.withValues(alpha: opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: opacity * 0.7),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, p.at + Offset(-tp.width / 2, dy));
  }

  /// The branded basket / hoverboard catcher: glowing body, white rim, animated
  /// thruster flames, and a shield ring when the Shield power-up is active.
  void _drawCatcher(Canvas canvas, Offset center) {
    const halfW = 46.0;
    final rect = Rect.fromCenter(center: center, width: halfW * 2, height: 26);

    // ── Outer glow ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(7), const Radius.circular(18)),
      Paint()
        ..color = accent.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
    );

    // ── Animated thruster flames (under the board) ──
    final flameFlicker = 0.6 + 0.4 * math.sin(time * 22);
    for (final dx in const [-26.0, 0.0, 26.0]) {
      final base = center + Offset(dx, 14);
      final len = 12.0 + flameFlicker * 9.0;
      final path = Path()
        ..moveTo(base.dx - 4, base.dy)
        ..lineTo(base.dx + 4, base.dy)
        ..lineTo(base.dx, base.dy + len)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.9),
              const Color(0xFF7E9CFF).withValues(alpha: 0.0),
            ],
          ).createShader(
              Rect.fromLTWH(base.dx - 4, base.dy, 8, len)),
      );
    }

    // ── Basket body ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(13)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(accent, Colors.white, 0.2) ?? accent,
            accent,
            Color.lerp(accent, Colors.black, 0.5) ?? accent,
          ],
        ).createShader(rect),
    );

    // ── Basket weave lines — read it as a basket, not a slab ──
    final weave = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.4;
    for (final dx in const [-26.0, -13.0, 0.0, 13.0, 26.0]) {
      canvas.drawLine(
        Offset(center.dx + dx, rect.top + 4),
        Offset(center.dx + dx, rect.bottom - 4),
        weave,
      );
    }

    // ── Highlight rim ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(13)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.6),
    );

    // ── Shield ring — visible while the Shield power-up is held ──
    if (hasShield) {
      canvas.drawArc(
        Rect.fromCenter(
            center: center, width: halfW * 2 + 22, height: 54),
        math.pi, // top half arc
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF66BB6A).withValues(alpha: 0.85),
      );
    }

    // ── Magnet aura — faint pulsing field while Magnet is held ──
    if (hasMagnet) {
      final mp = 0.4 + 0.3 * math.sin(time * 5);
      canvas.drawCircle(
        center,
        halfW + 14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF42A5F5).withValues(alpha: mp),
      );
    }
  }

  void _drawEmoji(
      Canvas canvas, String emoji, Offset center, double fontSize, double spin) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spin);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}

/// Draws the painted Zealova brand mark — a crisp 4-point sparkle/star — at
/// [center] with the given [armLength] (tip radius). Shared by the in-game
/// power-up item and the intro legend. When [golden] the mark is gold-tinted
/// for the power-up; otherwise it uses the accent purple.
void _paintSparkleMark(
  Canvas canvas,
  Offset center,
  double armLength,
  Color accent, {
  bool golden = false,
}) {
  final tip = golden ? const Color(0xFFFFE082) : accent;
  final core = golden ? const Color(0xFFFFC107) : accent;
  // A 4-point star: long arms on the axes, short waist between.
  final waist = armLength * 0.30;
  final path = Path();
  for (var i = 0; i < 4; i++) {
    final a = i * math.pi / 2;
    final na = a + math.pi / 4;
    final tx = center.dx + math.cos(a) * armLength;
    final ty = center.dy + math.sin(a) * armLength;
    final wx = center.dx + math.cos(na) * waist;
    final wy = center.dy + math.sin(na) * waist;
    if (i == 0) {
      path.moveTo(tx, ty);
    } else {
      path.lineTo(tx, ty);
    }
    path.lineTo(wx, wy);
  }
  path.close();
  // Soft glow under the mark.
  canvas.drawPath(
    path,
    Paint()
      ..color = tip.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  // Filled body with a radial sheen.
  canvas.drawPath(
    path,
    Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, tip, core],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
          Rect.fromCircle(center: center, radius: armLength)),
  );
  // Crisp outline.
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.85),
  );
  // Bright centre pip.
  canvas.drawCircle(
    center,
    armLength * 0.16,
    Paint()..color = Colors.white,
  );
}

/// Standalone painter for the Zealova sparkle mark — used in the intro legend.
class _SparkleMarkPainter extends CustomPainter {
  final Color accent;
  final double scale;
  _SparkleMarkPainter({required this.accent, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    _paintSparkleMark(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.shortestSide / 2 * scale,
      accent,
      golden: true,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkleMarkPainter old) =>
      old.accent != accent || old.scale != scale;
}

/// Intro-legend painter: draws a row of emoji at their TRUE relative in-game
/// sizes so the rules screen reflects how items actually appear.
class _LegendEmojiPainter extends CustomPainter {
  final List<String> emojis;
  _LegendEmojiPainter({required this.emojis});

  @override
  void paint(Canvas canvas, Size size) {
    if (emojis.isEmpty) return;
    // Lay the emoji out evenly across the width, each at its scaled size.
    final slot = size.width / emojis.length;
    for (var i = 0; i < emojis.length; i++) {
      final emoji = emojis[i];
      // Scale down a touch so even the biggest (🐟) fits the 34px-tall row.
      final fs = visualSizeFor(emoji) * 0.62;
      final tp = TextPainter(
        text: TextSpan(text: emoji, style: TextStyle(fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          slot * i + slot / 2 - tp.width / 2,
          size.height / 2 - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LegendEmojiPainter old) =>
      old.emojis != emojis;
}

// =============================================================================
// High-scores sheet — friends leaderboard for the Nutrient Rush mini-game.
//
// Reuses the existing leaderboard system (board id `nutrient_rush`, friends
// scope). Reachable from the game-over screen. Degrades gracefully: empty
// friend list, unranked viewer, or an unlock-gate 403 all render a friendly
// state instead of an error.
// =============================================================================

class _HighScoresSheet extends StatefulWidget {
  final LeaderboardService service;
  final String userId;
  final Color accentColor;

  const _HighScoresSheet({
    required this.service,
    required this.userId,
    required this.accentColor,
  });

  @override
  State<_HighScoresSheet> createState() => _HighScoresSheetState();
}

class _HighScoresSheetState extends State<_HighScoresSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.service.getLeaderboard(
        userId: widget.userId,
        leaderboardType: LeaderboardType.nutrientRush,
        filterType: LeaderboardFilter.friends,
        limit: 50,
      );
      final raw = (data['entries'] as List?) ?? const [];
      if (mounted) {
        setState(() {
          _entries =
              raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      // Unlock-gate 403, network error, etc. — show a friendly message.
      debugPrint('⚠️ [NutrientRush] high-scores load failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Could not load high scores right now.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).nutrientRushGameNutrientRushFriends,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: _buildBody(accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color accent) {
    if (_loading) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: accent, strokeWidth: 2.5),
        ),
      );
    }
    if (_error != null) {
      return _message('😕', _error!);
    }
    if (_entries.isEmpty) {
      // Friendly empty state: no friends ranked yet (or none have played).
      return _message(
        '👥',
        'No friends on the board yet.\nAdd friends and challenge them in Nutrient Rush!',
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _row(_entries[i], accent),
    );
  }

  Widget _message(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> entry, Color accent) {
    final rank = (entry['rank'] as num?)?.toInt() ?? 0;
    final name = entry['user_name'] as String? ?? 'User';
    final score = (entry['minigame_high_score'] as num?)?.toInt() ?? 0;
    final isMe = entry['is_current_user'] as bool? ?? false;
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? accent.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            isMe ? Border.all(color: accent.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              medal,
              style: TextStyle(
                color: Colors.white,
                fontSize: rank <= 3 ? 20 : 14,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isMe ? '$name (You)' : name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
