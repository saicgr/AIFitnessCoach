import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../data/services/haptic_service.dart';

// =============================================================================
// Nutrient Rush — a tiny, optional fitness-themed arcade mini-game.
//
// Self-contained: no game engine, no sound, no network. A `Ticker`-driven
// fixed-timestep loop renders via a single `CustomPainter`; a `GestureDetector`
// reads horizontal drag/tap to steer a catcher.
//
// Loop: healthy items (🥦🍎🥚💧) fall — catch them for points. Junk items
// (🍩🍔🍟🥤) fall too — catching one costs a life. Miss a healthy item and
// the combo resets. 3 lives, ~45s soft run, clear game-over.
//
// It is launched (optionally) from the level-up celebration. It is dismissible
// at any time and can be safely abandoned (the Ticker stops on dispose).
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
Future<int> showNutrientRushGame(
  BuildContext context,
  Color accentColor, {
  bool rewardEligible = false,
}) async {
  final result = await Navigator.of(context).push<int>(
    PageRouteBuilder<int>(
      opaque: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => NutrientRushGame(
        accentColor: accentColor,
        rewardEligible: rewardEligible,
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

  const NutrientRushGame({
    super.key,
    required this.accentColor,
    this.rewardEligible = false,
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

  // Catcher: position is a 0..1 fraction of the play width.
  double _catcherX = 0.5;
  double _catcherTargetX = 0.5;

  int _score = 0;
  int _lives = 3;
  int _combo = 0;
  int _bestCombo = 0;
  double _elapsed = 0; // seconds since play started
  double _spawnTimer = 0;
  double _difficulty = 1.0;

  // Play area is measured on first layout; the loop is a no-op until known.
  Size _playSize = Size.zero;

  static const double _runLength = 45.0; // soft cap — speeds up near the end

  // ── Item catalogue ──
  static const List<String> _healthy = ['🥦', '🍎', '🥚', '💧', '🥑', '🐟'];
  static const List<String> _junk = ['🍩', '🍔', '🍟', '🥤'];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
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
      _score = 0;
      _lives = 3;
      _combo = 0;
      _bestCombo = 0;
      _elapsed = 0;
      _spawnTimer = 0;
      _difficulty = 1.0;
      _catcherX = 0.5;
      _catcherTargetX = 0.5;
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
    _difficulty = 1.0 + _elapsed / 14.0; // ramps gradually

    // Smoothly chase the drag target so the catcher feels weighty.
    _catcherX += (_catcherTargetX - _catcherX) * math.min(1.0, dt * 14);

    // ── Spawn ──
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnItem();
      // Faster spawns as difficulty climbs; floor keeps it survivable.
      _spawnTimer = math.max(0.42, 1.05 - _difficulty * 0.13) +
          _rng.nextDouble() * 0.35;
    }

    final w = _playSize.width;
    final h = _playSize.height;
    final catcherPx = _catcherX * w;
    const catcherHalf = 46.0;
    final catcherY = h - 84.0;

    // ── Move + resolve items ──
    for (final item in _items) {
      item.y += item.speed * _difficulty * dt;
      item.spin += dt * item.spinSpeed;

      if (item.resolved) continue;

      // Catch test: item overlaps the catcher band.
      if (item.y >= catcherY - 26 && item.y <= catcherY + 30) {
        if ((item.x - catcherPx).abs() < catcherHalf + 20) {
          item.resolved = true;
          _onCatch(item, Offset(item.x, catcherY - 10));
          continue;
        }
      }

      // Missed: fell past the bottom.
      if (item.y > h + 40) {
        item.resolved = true;
        if (item.healthy) {
          _combo = 0; // miss a good item → combo break (no life lost)
          HapticService.selection();
        }
      }
    }
    // Drop resolved items immediately (caught items vanish into the catcher;
    // missed items have already fallen off-screen).
    _items.removeWhere((i) => i.resolved);

    // ── Pops (catch flourishes) ──
    for (final p in _pops) {
      p.life += dt;
    }
    _pops.removeWhere((p) => p.life > 0.6);

    // ── End conditions ──
    if (_lives <= 0) {
      _endGame();
      return;
    }
    if (_elapsed >= _runLength) {
      // Survived the full run — generous finish.
      _score += 25;
      _endGame();
    }
  }

  void _spawnItem() {
    final w = _playSize.width;
    // Junk share grows with difficulty but is capped so it stays fair.
    final junkChance = math.min(0.42, 0.22 + _difficulty * 0.05);
    final isJunk = _rng.nextDouble() < junkChance;
    final emoji = isJunk
        ? _junk[_rng.nextInt(_junk.length)]
        : _healthy[_rng.nextInt(_healthy.length)];
    _items.add(_FallingItem(
      x: 36 + _rng.nextDouble() * (math.max(1.0, w - 72)),
      y: -40,
      speed: 150 + _rng.nextDouble() * 90,
      emoji: emoji,
      healthy: !isJunk,
      spin: 0,
      spinSpeed: (_rng.nextDouble() - 0.5) * 3.0,
    ));
  }

  void _onCatch(_FallingItem item, Offset at) {
    if (item.healthy) {
      _combo += 1;
      _bestCombo = math.max(_bestCombo, _combo);
      final gain = 10 + (_combo ~/ 3) * 5; // combo multiplier
      _score += gain;
      _pops.add(_Pop(at, '+$gain', widget.accentColor, item.emoji));
      if (_combo > 0 && _combo % 5 == 0) {
        HapticService.success();
      } else {
        HapticService.light();
      }
    } else {
      _lives -= 1;
      _combo = 0;
      _pops.add(_Pop(at, '-1 ❤', const Color(0xFFFF5252), item.emoji));
      HapticService.error();
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
            const hudHeight = 56.0;
            final playSize = Size(
              constraints.maxWidth,
              math.max(200.0, constraints.maxHeight - hudHeight),
            );
            _playSize = playSize;

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
                              catcherX: _catcherX,
                              accent: widget.accentColor,
                              elapsed: _elapsed,
                              runLength: _runLength,
                            ),
                          ),
                        ),
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

  Widget _buildHud() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.black.withValues(alpha: 0.35),
      child: Row(
        children: [
          // Score
          _hudChip(
            icon: Icons.bolt_rounded,
            label: '$_score',
            color: widget.accentColor,
          ),
          const SizedBox(width: 8),
          // Combo
          if (_combo >= 2)
            _hudChip(
              icon: Icons.local_fire_department_rounded,
              label: 'x$_combo',
              color: Colors.orange,
            ),
          const Spacer(),
          // Lives
          Row(
            children: List.generate(3, (i) {
              final filled = i < _lives;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  filled
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: filled ? const Color(0xFFFF5252) : Colors.white24,
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          // Pause (only while playing/paused)
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
    );
  }

  Widget _hudChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, size: 19, color: Colors.white70),
      ),
    );
  }

  // ── Overlays ──────────────────────────────────────────────────────────

  Widget _buildIntroOverlay(MediaQueryData media) {
    return _centeredPanel(
      children: [
        const Text('🚀', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 10),
        _title('NUTRIENT RUSH'),
        const SizedBox(height: 6),
        _body('Bonus round! Catch the good stuff, dodge the junk.'),
        const SizedBox(height: 16),
        _legendRow('🥦🍎🥚💧', 'Catch — score points', widget.accentColor),
        const SizedBox(height: 6),
        _legendRow('🍩🍔🍟🥤', 'Dodge — costs a life', const Color(0xFFFF5252)),
        const SizedBox(height: 6),
        _body('Drag anywhere to steer.', dim: true),
        const SizedBox(height: 18),
        _primaryButton('PLAY', _startGame),
        const SizedBox(height: 8),
        _textButton('Skip', _exit),
      ],
    );
  }

  Widget _buildPausedOverlay() {
    return _centeredPanel(
      children: [
        _title('PAUSED'),
        const SizedBox(height: 16),
        _primaryButton('RESUME', _togglePause),
        const SizedBox(height: 8),
        _textButton('End bonus round', _exit),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    final survived = _elapsed >= _runLength;
    return _centeredPanel(
      children: [
        Text(survived ? '🏆' : '💪', style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 10),
        _title(survived ? 'SURVIVED THE RUSH!' : 'GOOD RUN!'),
        const SizedBox(height: 14),
        _statRow('SCORE', '$_score'),
        const SizedBox(height: 6),
        _statRow('BEST COMBO', 'x$_bestCombo'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.4)),
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
        _textButton('Done', _exit),
      ],
    );
  }

  Widget _centeredPanel({required List<Widget> children}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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

  Widget _legendRow(String emojis, String label, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emojis, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Flexible(
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
  double spin;
  final double spinSpeed;
  bool resolved = false;

  _FallingItem({
    required this.x,
    required this.y,
    required this.speed,
    required this.emoji,
    required this.healthy,
    required this.spin,
    required this.spinSpeed,
  });
}

/// A short-lived score/feedback flourish at a catch point.
class _Pop {
  final Offset at;
  final String text;
  final Color color;
  final String emoji;
  double life = 0;

  _Pop(this.at, this.text, this.color, this.emoji);
}

// =============================================================================
// Renderer — a single CustomPainter draws the whole field.
// =============================================================================

class _GamePainter extends CustomPainter {
  final List<_FallingItem> items;
  final List<_Pop> pops;
  final double catcherX;
  final Color accent;
  final double elapsed;
  final double runLength;

  _GamePainter({
    required this.items,
    required this.pops,
    required this.catcherX,
    required this.accent,
    required this.elapsed,
    required this.runLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background gradient ──
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF101522), Color(0xFF1B1320)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Run-progress bar across the very top ──
    final progress = (elapsed / runLength).clamp(0.0, 1.0);
    final trackPaint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 3), trackPaint);
    final fillPaint = Paint()..color = accent.withValues(alpha: 0.85);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * progress, 3), fillPaint);

    // ── Falling items ──
    for (final item in items) {
      _drawEmoji(canvas, item.emoji, Offset(item.x, item.y), 30, item.spin);
      // Soft halo: green-ish for healthy, red-ish for junk.
      final halo = Paint()
        ..color = (item.healthy ? accent : const Color(0xFFFF5252))
            .withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(item.x, item.y), 18, halo);
    }

    // ── Catcher (a glowing basket / hoverboard) ──
    final catcherY = size.height - 84.0;
    final cx = catcherX * size.width;
    _drawCatcher(canvas, Offset(cx, catcherY));

    // ── Score pops ──
    for (final p in pops) {
      final t = (p.life / 0.6).clamp(0.0, 1.0);
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final dy = -34 * t;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            color: p.color.withValues(alpha: opacity),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p.at + Offset(-tp.width / 2, dy));
    }
  }

  void _drawCatcher(Canvas canvas, Offset center) {
    const halfW = 46.0;
    final rect = Rect.fromCenter(
      center: center,
      width: halfW * 2,
      height: 24,
    );

    // Glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(16)),
      Paint()
        ..color = accent.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent,
            Color.lerp(accent, Colors.black, 0.45) ?? accent,
          ],
        ).createShader(rect),
    );

    // Highlight rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    // Thruster ticks under the board
    final tick = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final dx in const [-22.0, 0.0, 22.0]) {
      canvas.drawLine(
        center + Offset(dx, 16),
        center + Offset(dx, 24),
        tick,
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
