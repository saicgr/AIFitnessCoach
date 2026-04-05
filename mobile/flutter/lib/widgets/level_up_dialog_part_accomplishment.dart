part of 'level_up_dialog.dart';


// =============================================================================
// Accomplishment data model
// =============================================================================

class _Accomplishment {
  final String icon;
  final String title;
  final String subtitle;
  final String xpText;
  final Color color;
  final bool isCrate;

  const _Accomplishment({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.xpText,
    required this.color,
    this.isCrate = false,
  });
}


// =============================================================================
// Accomplishments carousel — cards slide in from right, pause, then slide out
// =============================================================================

class _AccomplishmentCarousel extends StatelessWidget {
  final List<_Accomplishment> accomplishments;
  final int currentIndex;
  final VoidCallback onOpenCrate;
  final bool compact;

  const _AccomplishmentCarousel({
    required this.accomplishments,
    required this.currentIndex,
    required this.onOpenCrate,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section header
        Row(
          children: [
            Container(width: 20, height: 1, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(width: 8),
            Icon(Icons.military_tech_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              'ACCOMPLISHMENTS',
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 2,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
          ],
        ),
        const SizedBox(height: 10),

        // Card carousel area
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              // Slide in from right, slide out to left
              final isIncoming = child.key == ValueKey<int>(currentIndex);
              final slideIn = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation);
              final slideOut = Tween<Offset>(
                begin: const Offset(-0.5, 0.0),
                end: Offset.zero,
              ).animate(animation);

              return SlideTransition(
                position: isIncoming ? slideIn : slideOut,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _AccomplishmentCard(
              key: ValueKey<int>(currentIndex),
              accomplishment: accomplishments[currentIndex.clamp(0, accomplishments.length - 1)],
              onOpenCrate: onOpenCrate,
              compact: compact,
              index: currentIndex,
              total: accomplishments.length,
            ),
          ),
        ),

        // Dots indicator
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(accomplishments.length, (i) {
            final isActive = i == currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive
                    ? accomplishments[currentIndex].color
                    : Colors.white.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
      ],
    );
  }
}


// =============================================================================
// Single accomplishment card
// =============================================================================

class _AccomplishmentCard extends StatelessWidget {
  final _Accomplishment accomplishment;
  final VoidCallback onOpenCrate;
  final bool compact;
  final int index;
  final int total;

  const _AccomplishmentCard({
    super.key,
    required this.accomplishment,
    required this.onOpenCrate,
    required this.compact,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final color = accomplishment.color;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // XP text label (top, like "3,822 XP GAINED")
          Text(
            accomplishment.xpText,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 2,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),

          // Icon
          Text(
            accomplishment.icon,
            style: TextStyle(fontSize: compact ? 36 : 44),
          ),
          SizedBox(height: compact ? 8 : 12),

          // Title
          Text(
            accomplishment.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            accomplishment.subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: Colors.white60,
              decoration: TextDecoration.none,
              height: 1.3,
            ),
          ),

          // Progress bar (mastery style)
          SizedBox(height: compact ? 10 : 14),
          SizedBox(
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: 1.0,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.6)),
              ),
            ),
          ),

          // Open crate button (if applicable)
          if (accomplishment.isCrate) ...[
            SizedBox(height: compact ? 10 : 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenCrate,
                icon: const Icon(Icons.lock_open_rounded, size: 14),
                label: const Text(
                  'OPEN CRATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// =============================================================================
// Particle system for atmospheric background
// =============================================================================

class _Particle {
  double x, y, speed, size, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });

  factory _Particle.random(math.Random r) => _Particle(
        x: r.nextDouble(),
        y: r.nextDouble(),
        speed: 0.02 + r.nextDouble() * 0.06,
        size: 1.0 + r.nextDouble() * 2.5,
        opacity: 0.05 + r.nextDouble() * 0.2,
      );
}


class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final Color color;
  _ParticlePainter({required this.particles, required this.time, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - time * p.speed) % 1.0;
      final x = p.x + math.sin(time * 6.28 + p.y * 10) * 0.02;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        Paint()..color = color.withValues(alpha: p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}


// =============================================================================
// Military rank emblem (CustomPainter)
// =============================================================================

class _RankEmblemPainter extends CustomPainter {
  final int level;
  final Color glowColor;
  _RankEmblemPainter({required this.level, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy),
      r + 12,
      Paint()
        ..color = glowColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Shield shape (hexagon)
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glowColor.withValues(alpha: 0.4),
            glowColor.withValues(alpha: 0.15),
          ],
        ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2)),
    );

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = glowColor.withValues(alpha: 0.8),
    );

    // Inner border
    final innerPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final ir = r * 0.78;
      final px = cx + ir * math.cos(angle);
      final py = cy + ir * math.sin(angle);
      if (i == 0) {
        innerPath.moveTo(px, py);
      } else {
        innerPath.lineTo(px, py);
      }
    }
    innerPath.close();
    canvas.drawPath(
      innerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = glowColor.withValues(alpha: 0.3),
    );

    // Wings (decorative lines)
    final wingPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Left wing
    canvas.drawLine(Offset(cx - r - 6, cy), Offset(cx - r - 18, cy - 8), wingPaint);
    canvas.drawLine(Offset(cx - r - 6, cy), Offset(cx - r - 18, cy + 8), wingPaint);
    // Right wing
    canvas.drawLine(Offset(cx + r + 6, cy), Offset(cx + r + 18, cy - 8), wingPaint);
    canvas.drawLine(Offset(cx + r + 6, cy), Offset(cx + r + 18, cy + 8), wingPaint);

    // Level number
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$level',
        style: TextStyle(
          fontSize: r * 0.8,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontFamily: 'monospace',
          shadows: [
            Shadow(color: glowColor.withValues(alpha: 0.8), blurRadius: 8),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RankEmblemPainter old) =>
      level != old.level || glowColor != old.glowColor;
}


// =============================================================================
// Chevron-segmented progress bar (CustomPainter)
// =============================================================================

class _ChevronBarPainter extends CustomPainter {
  final double progress;
  final Color fillColor;
  _ChevronBarPainter({required this.progress, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 20;
    final segW = size.width / segments;
    final gap = 2.0;
    final skew = 4.0;

    for (int i = 0; i < segments; i++) {
      final x = i * segW;
      final filled = (i + 1) / segments <= progress + 0.001;

      final path = Path()
        ..moveTo(x + skew, 0)
        ..lineTo(x + segW - gap + skew, 0)
        ..lineTo(x + segW - gap, size.height)
        ..lineTo(x, size.height)
        ..close();

      if (filled) {
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.green.shade700,
                Colors.green.shade400,
              ],
            ).createShader(Rect.fromLTWH(x, 0, segW, size.height)),
        );

        // Edge glow on the last filled segment
        if ((i + 1) / segments > progress - 1 / segments) {
          canvas.drawPath(
            path,
            Paint()
              ..color = Colors.cyan.withValues(alpha: 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
        }
      } else {
        canvas.drawPath(
          path,
          Paint()..color = Colors.white.withValues(alpha: 0.06),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChevronBarPainter old) =>
      progress != old.progress;
}


/// Battlefield-style progression screen.
/// Shows level badges, animated XP progress bar, XP counter, and rewards.
class _CascadingLevelOverlay extends StatefulWidget {
  final int oldLevel;
  final int newLevel;
  final VoidCallback onComplete;

  const _CascadingLevelOverlay({
    required this.oldLevel,
    required this.newLevel,
    required this.onComplete,
  });

  @override
  State<_CascadingLevelOverlay> createState() => _CascadingLevelOverlayState();
}


class _CascadingLevelOverlayState extends State<_CascadingLevelOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _barController;
  late ConfettiController _confettiController;

  int _currentFromLevel = 0;
  int _currentToLevel = 0;
  int _cumulativeXp = 0;
  bool _showLevelUpFlash = false;
  bool _skipped = false;
  final List<String> _unlockedRewards = [];

  @override
  void initState() {
    super.initState();
    _currentFromLevel = widget.oldLevel;
    _currentToLevel = widget.oldLevel + 1;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0,
    );

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 600),
    );

    _fadeController.forward();
    _startProgression();
  }

  Future<void> _startProgression() async {
    await Future.delayed(const Duration(milliseconds: 500));

    for (int level = widget.oldLevel + 1; level <= widget.newLevel; level++) {
      if (!mounted || _skipped) return;

      setState(() {
        _currentFromLevel = level - 1;
        _currentToLevel = level;
        _showLevelUpFlash = false;
      });

      // Animate the progress bar filling 0 → 100%
      _barController.reset();
      await _barController.forward().orCancel.catchError((_) {});
      if (!mounted || _skipped) return;

      // Level completed — add XP, flash, haptic, confetti
      final xpGained = _xpForLevel(level - 1);
      _cumulativeXp += xpGained;
      _confettiController.play();

      final isLast = level == widget.newLevel;
      if (isLast) {
        HapticService.heavy();
      } else {
        HapticService.medium();
      }

      setState(() => _showLevelUpFlash = true);

      // Hold "LEVEL UP!" flash
      await Future.delayed(Duration(milliseconds: isLast ? 1200 : 700));
      if (!mounted || _skipped) return;
    }

    // Auto-dismiss after final hold
    await Future.delayed(const Duration(milliseconds: 500));
    _dismiss();
  }

  void _skip() {
    _skipped = true;
    _dismiss();
  }

  void _dismiss() {
    if (!mounted) return;
    _fadeController.reverse().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _barController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = screenWidth - 160; // 80px per badge side

    return FadeTransition(
      opacity: _fadeController,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark blurred overlay
            Container(color: Colors.black.withValues(alpha: 0.9)),

            // Confetti at top
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 20,
                maxBlastForce: 18,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                gravity: 0.2,
                colors: const [
                  Colors.amber,
                  Colors.orange,
                  Colors.cyan,
                  Colors.purple,
                  Colors.white,
                ],
              ),
            ),

            // Skip button (top-right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: GestureDetector(
                onTap: _skip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'SKIP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),

            // Main content centered
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "LEVEL UP!" flash
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showLevelUpFlash ? 1.0 : 0.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: _showLevelUpFlash ? 1.0 : 0.7,
                        curve: Curves.elasticOut,
                        child: const Text(
                          'LEVEL UP!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                            letterSpacing: 4,
                            decoration: TextDecoration.none,
                            shadows: [
                              Shadow(color: Colors.amber, blurRadius: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Level badges + progress bar row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left badge (current level)
                        _LevelBadge(
                          level: _currentFromLevel,
                          isActive: true,
                        ),

                        const SizedBox(width: 12),

                        // Progress bar
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _barController,
                            builder: (context, _) {
                              return _ProgressBar(
                                progress: _barController.value,
                                barWidth: barWidth,
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Right badge (next level)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _LevelBadge(
                            key: ValueKey(_currentToLevel),
                            level: _currentToLevel,
                            isActive: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // XP counter
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_cumulativeXp),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_cumulativeXp',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'XP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.6),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Next reward info
                    Text(
                      'NEXT REWARD AT LEVEL ${widget.newLevel + 2}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Circular level badge for the progression screen
class _LevelBadge extends StatelessWidget {
  final int level;
  final bool isActive;

  const _LevelBadge({
    super.key,
    required this.level,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.amber : Colors.grey.shade600;
    final size = isActive ? 64.0 : 56.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.grey.shade800,
        border: Border.all(
          color: color.withValues(alpha: isActive ? 1.0 : 0.4),
          width: isActive ? 3 : 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: isActive ? 24 : 20,
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.white : Colors.grey.shade400,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

