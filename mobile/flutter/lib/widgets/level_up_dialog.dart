import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/level_reward.dart';
import '../data/models/user_xp.dart';
import '../data/services/haptic_service.dart';
import 'fitness_crate_dialog.dart';

part 'level_up_dialog_part_accomplishment.dart';
part 'level_up_dialog_part_progress_bar.dart';


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
    const milestones = [5, 10, 25, 50, 75, 100, 150, 200, 250];
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
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: accentColor.withValues(alpha: 0.5),
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
    // Mirrors backend MERCH_TYPE_FOR_LEVEL + MILESTONE_REWARDS_DISPLAY.
    switch (level) {
      case 5: return '"Rising Star" animated badge + Premium Crate';
      case 10: return '"Iron Will" animated badge + Iron theme';
      case 25: return 'Bronze animated frame + "Dedicated" chat title';
      case 50: return 'Silver frame + FREE FitWiz Sticker Pack!';
      case 75: return 'Gold holographic frame + "Elite" animated nameplate';
      case 100: return 'Elite badge + FREE FitWiz T-Shirt!';
      case 150: return 'Champion badge + FREE FitWiz Hoodie!';
      case 200: return 'Mythic badge + FREE Full Merch Kit!';
      case 250: return 'Transcendent badge + FREE Signed Premium Kit!';
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
