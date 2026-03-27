import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/level_reward.dart';
import '../data/models/user_xp.dart';
import '../data/services/haptic_service.dart';
import 'fitness_crate_dialog.dart';

// =============================================================================
// XP per level table (Migration 227)
// =============================================================================
const _kXpTable = [
  25, 30, 40, 50, 65, 80, 100, 120, 150, 180, // 1-10  Beginner
  200, 220, 250, 280, 300, 320, 350, 380, 400, 420, 450, 480, 500, 520, 550, // 11-25 Novice
  550, 600, 650, 700, 750, 800, 850, 900, 1000, 1100, 1200, 1300, 1400, 1500,
  1550, 1600, 1650, 1700, 1750, 1800, 1850, 1900, 1950, 2000, // 26-50 Apprentice
];

int _xpForLevelUp(int level) {
  if (level < 1) return 25;
  if (level <= _kXpTable.length) return _kXpTable[level - 1];
  if (level <= 75) return 1900 + (level - 50) * 100; // Athlete
  if (level <= 100) return 4800 + (level - 76) * 200; // Elite
  return 10000 + (level - 100) * 500; // Master+
}

XPTitle _titleForLevel(int level) {
  if (level <= 10) return XPTitle.beginner;
  if (level <= 25) return XPTitle.novice;
  if (level <= 50) return XPTitle.apprentice;
  if (level <= 75) return XPTitle.athlete;
  if (level <= 100) return XPTitle.elite;
  if (level <= 125) return XPTitle.master;
  if (level <= 150) return XPTitle.champion;
  if (level <= 175) return XPTitle.legend;
  if (level <= 200) return XPTitle.mythic;
  if (level <= 225) return XPTitle.immortal;
  return XPTitle.transcendent;
}

// =============================================================================
// Fitness & Diet tips per level tier
// =============================================================================
List<String> _fitnessTips(int level) {
  if (level <= 10) {
    return [
      'Build consistency — aim for 3 workouts this week',
      'Track your meals to start hitting your protein goal',
    ];
  } else if (level <= 25) {
    return [
      'Progressive overload — increase weights by 5% this week',
      'Try meal prepping for 2 days to stay on track',
    ];
  } else if (level <= 50) {
    return [
      'Focus on compound lifts for faster strength gains',
      'Dial in your macros — protein timing around workouts matters',
    ];
  } else if (level <= 75) {
    return [
      'Consider a deload week — listen to your body for recovery',
      'Optimize sleep 7-9h for muscle repair and hormone balance',
    ];
  } else {
    return [
      'Advanced periodization — vary intensity across your mesocycle',
      'Consider carb cycling to fine-tune body recomposition',
    ];
  }
}

// =============================================================================
// Battlefield-Style Level-Up Dialog (Full Screen, Non-Scrollable, Adaptive)
// =============================================================================

class LevelUpDialog extends ConsumerStatefulWidget {
  final LevelUpEvent event;
  final VoidCallback onDismiss;

  const LevelUpDialog({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  ConsumerState<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends ConsumerState<LevelUpDialog>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  late AnimationController _badgeController;
  late AnimationController _barController;
  late AnimationController _contentController;
  late AnimationController _particleController;

  // Accomplishments carousel
  late List<_Accomplishment> _accomplishments;
  int _currentAccomplishmentIndex = -1;
  bool _carouselDone = false;

  // Particles
  late List<_Particle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Init particles
    _particles = List.generate(50, (_) => _Particle.random(_random));

    // Build accomplishment cards
    _accomplishments = _buildAccomplishments();

    _startSequence();
  }

  List<_Accomplishment> _buildAccomplishments() {
    final items = <_Accomplishment>[];
    final level = widget.event.newLevel;
    final titleXP = _titleForLevel(level);

    // 1. Level reward
    final reward = LevelRewards.getRewardForLevel(level);
    items.add(_Accomplishment(
      icon: reward.icon ?? '🎁',
      title: reward.name,
      subtitle: reward.description,
      xpText: '+${widget.event.xpEarned} XP EARNED',
      color: Color(titleXP.colorValue),
      isCrate: reward.type == LevelRewardType.crate,
    ));

    // 2. Title change
    if (widget.event.hasNewTitle) {
      items.add(_Accomplishment(
        icon: '⭐',
        title: 'NEW RANK: ${titleXP.displayName.toUpperCase()}',
        subtitle: 'Levels ${titleXP.levelRange}',
        xpText: 'RANK ACHIEVED',
        color: Color(titleXP.colorValue),
      ));
    }

    // 3. Backend rewards (if any)
    if (widget.event.hasRewards) {
      for (final r in widget.event.rewards!.take(2)) {
        items.add(_Accomplishment(
          icon: r.icon,
          title: '${r.displayName} x${r.quantity}',
          subtitle: r.description,
          xpText: 'LEVEL ${r.level} REWARD',
          color: _rewardColor(r.type),
        ));
      }
    }

    // 4. Fitness tip
    final tips = _fitnessTips(level);
    if (tips.isNotEmpty) {
      items.add(_Accomplishment(
        icon: '💪',
        title: "WHAT'S NEXT",
        subtitle: tips.first,
        xpText: '${titleXP.displayName.toUpperCase()} TIER',
        color: Colors.green.shade400,
      ));
    }

    // 5. Next milestone (if any)
    const milestones = [5, 10, 15, 25, 35, 50, 75, 100];
    for (final m in milestones) {
      if (level < m) {
        final unlock = _getLevelUnlock(m);
        if (unlock != null) {
          items.add(_Accomplishment(
            icon: '🏆',
            title: 'NEXT MILESTONE: LEVEL $m',
            subtitle: unlock,
            xpText: '${m - level} LEVELS TO GO',
            color: Colors.amber,
          ));
          break;
        }
      }
    }

    return items;
  }

  Color _rewardColor(String type) {
    switch (type) {
      case 'fitness_crate': return Colors.orange;
      case 'premium_crate': return Colors.purple;
      case 'streak_shield': return Colors.blue;
      case 'xp_token_2x': return Colors.amber;
      default: return Colors.white54;
    }
  }

  Future<void> _startSequence() async {
    // 0ms — fade in background
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 200ms — rank badge scales in + haptic
    HapticService.heavy();
    _badgeController.forward();
    _confettiController.play();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // 800ms — progress bar fills
    _barController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // 1400ms — start accomplishments carousel
    HapticService.success();
    _runCarousel();
  }

  Future<void> _runCarousel() async {
    for (int i = 0; i < _accomplishments.length; i++) {
      if (!mounted) return;
      setState(() => _currentAccomplishmentIndex = i);
      HapticService.light();

      // Hold each card for 1.8s (shorter for more items)
      final holdTime = _accomplishments.length > 3 ? 1400 : 1800;
      await Future.delayed(Duration(milliseconds: holdTime));
    }

    if (!mounted) return;

    // After carousel, show the continue button
    setState(() => _carouselDone = true);
    _contentController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    _badgeController.dispose();
    _barController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _dismiss() {
    HapticService.light();
    widget.onDismiss();
  }

  void _openCrate() {
    final tier = CrateTierExtension.forLevel(widget.event.newLevel);
    // Dismiss level-up first, then show crate
    Navigator.of(context).pop();
    showFitnessCrateDialog(
      context,
      tier,
      widget.onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentEnum = ref.watch(accentColorProvider);
    final titleXP = _titleForLevel(widget.event.newLevel);
    final titleColor = Color(titleXP.colorValue);
    final accentColor = accentEnum.getColor(true); // always dark context
    final screenH = MediaQuery.of(context).size.height;
    final compact = screenH < 700;
    final vGap = compact ? 8.0 : 14.0;

    return FadeTransition(
      opacity: _fadeController,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Dark background + particles ──
            Container(color: const Color(0xF0000000)),
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    time: _particleController.value,
                    color: titleColor,
                  ),
                );
              },
            ),

            // ── Confetti ──
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
                colors: [titleColor, accentColor, Colors.amber, Colors.white],
              ),
            ),

            // ── Skip button ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: _dismiss,
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

            // ── Main content (non-scrollable, adaptive) ──
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: compact ? 8 : 16,
                ),
                child: Column(
                  children: [
                    SizedBox(height: compact ? 24 : 40),

                    // ── "LEVEL UP!" header ──
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _badgeController,
                        curve: Curves.elasticOut,
                      ),
                      child: Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          fontSize: compact ? 22 : 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 4,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(color: Colors.amber.withValues(alpha: 0.6), blurRadius: 20),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: vGap),

                    // ── Military rank emblem ──
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _badgeController,
                        curve: Curves.elasticOut,
                      ),
                      child: CustomPaint(
                        size: Size(compact ? 80 : 100, compact ? 90 : 110),
                        painter: _RankEmblemPainter(
                          level: widget.event.newLevel,
                          glowColor: titleColor,
                        ),
                      ),
                    ),

                    // ── Title badge ──
                    if (widget.event.hasNewTitle) ...[
                      SizedBox(height: vGap * 0.5),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _badgeController,
                          curve: const Interval(0.5, 1.0),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: titleColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: titleColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'RANK: ${titleXP.displayName.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: 2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: vGap),

                    // ── XP counter ──
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _badgeController,
                        curve: const Interval(0.4, 1.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          // Leading zeros in dim
                          Text(
                            widget.event.totalXp.toString().padLeft(7, '0').substring(
                                0,
                                7 - widget.event.totalXp.toString().length),
                            style: TextStyle(
                              fontSize: compact ? 28 : 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.2),
                              fontFamily: 'monospace',
                              letterSpacing: 3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            '${widget.event.totalXp}',
                            style: TextStyle(
                              fontSize: compact ? 28 : 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'monospace',
                              letterSpacing: 3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'XP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.5),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: vGap),

                    // ── Chevron progress bar ──
                    AnimatedBuilder(
                      animation: _barController,
                      builder: (context, _) {
                        final xpNeeded = _xpForLevelUp(widget.event.newLevel);
                        final xpInLevel = widget.event.totalXp -
                            _cumulativeXpForLevel(widget.event.newLevel);
                        final progress = (xpInLevel / xpNeeded).clamp(0.0, 1.0) *
                            _barController.value;
                        final xpToNext = xpNeeded - xpInLevel;

                        return Column(
                          children: [
                            SizedBox(
                              height: 16,
                              child: CustomPaint(
                                size: const Size(double.infinity, 16),
                                painter: _ChevronBarPainter(
                                  progress: progress,
                                  fillColor: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'NEXT REWARD IN ${xpToNext > 0 ? _formatNum(xpToNext) : 0} XP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.4),
                                letterSpacing: 2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: vGap),

                    // ── Accomplishments carousel (Battlefield-style) ──
                    Expanded(
                      child: _currentAccomplishmentIndex >= 0
                          ? _AccomplishmentCarousel(
                              accomplishments: _accomplishments,
                              currentIndex: _currentAccomplishmentIndex,
                              onOpenCrate: _openCrate,
                              compact: compact,
                            )
                          : const SizedBox.shrink(),
                    ),

                    // ── Continue button (appears after carousel finishes) ──
                    SizedBox(height: vGap * 0.5),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _carouselDone ? 1.0 : 0.0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 400),
                        offset: _carouselDone ? Offset.zero : const Offset(0, 0.3),
                        curve: Curves.easeOut,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _carouselDone ? _dismiss : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: titleColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: titleColor.withValues(alpha: 0.5),
                            ),
                            child: const Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getLevelUnlock(int level) {
    switch (level) {
      case 5: return '"Rising Star" profile badge';
      case 10: return 'Custom profile frame unlock';
      case 15: return 'Exclusive theme color options';
      case 25: return '"Dedicated" animated badge';
      case 35: return 'Animated profile effects';
      case 50: return '"Veteran" badge + FREE FitWiz T-Shirt!';
      case 75: return '"Elite" holographic badge + FREE Shaker Bottle!';
      case 100: return '"Legend" animated badge + FREE FitWiz Hoodie!';
      default: return null;
    }
  }

  int _cumulativeXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += _xpForLevelUp(i);
    }
    return total;
  }

  static String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return n.toString();
  }
}

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

/// Shows the level-up dialog.
/// For multi-level jumps (e.g. welcome bonus 1→3), shows a Battlefield-style
/// cascading animation stepping through each level before the final dialog.
/// Set [showProgression] to false to skip the cascade overlay.
Future<void> showLevelUpDialog(
  BuildContext context,
  LevelUpEvent event,
  VoidCallback onDismiss, {
  bool showProgression = true,
}) async {
  // Multi-level cascade: show rapid level ticks before the standard dialog
  if (event.levelsGained > 1 && showProgression) {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _CascadingLevelOverlay(
          oldLevel: event.oldLevel,
          newLevel: event.newLevel,
          onComplete: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
    if (!context.mounted) return;
  }

  // Show standard dialog for the final level
  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return LevelUpDialog(
        event: event,
        onDismiss: () {
          Navigator.of(dialogContext).pop();
          onDismiss();
        },
      );
    },
  );
}

/// XP required per level (from backend _XP_TABLE, levels 1-10)
const _kXpPerLevel = [25, 30, 40, 50, 65, 80, 100, 120, 150, 180];

int _xpForLevel(int level) {
  if (level < 1) return 25;
  if (level <= _kXpPerLevel.length) return _kXpPerLevel[level - 1];
  return 200; // fallback for levels > 10
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

/// Animated progress bar between level badges
class _ProgressBar extends StatelessWidget {
  final double progress;
  final double barWidth;

  const _ProgressBar({
    required this.progress,
    required this.barWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // Green filled portion
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade600,
                      Colors.green.shade400,
                    ],
                  ),
                ),
              ),
            ),
            // Blue marker at the edge
            if (progress > 0.02 && progress < 0.98)
              Positioned(
                left: (progress * (barWidth - 4)).clamp(0.0, barWidth - 4),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade300,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            // Chevron arrows (decorative, like Battlefield)
            if (progress > 0.1)
              ...List.generate(
                (progress * 8).floor().clamp(0, 6),
                (i) => Positioned(
                  left: (i + 1) * (barWidth / 8),
                  top: 2,
                  bottom: 2,
                  child: Icon(
                    Icons.chevron_right,
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
