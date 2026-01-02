import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Represents different streak milestones with their properties
enum StreakMilestone {
  bronze(3, 6, 'Getting Started'),
  silver(7, 13, 'Building Momentum'),
  gold(14, 29, 'On Fire'),
  platinum(30, 59, 'Unstoppable'),
  diamond(60, 89, 'Legend'),
  master(90, 999, 'Master');

  final int minDays;
  final int maxDays;
  final String title;

  const StreakMilestone(this.minDays, this.maxDays, this.title);

  static StreakMilestone? fromStreak(int days) {
    if (days >= 90) return master;
    if (days >= 60) return diamond;
    if (days >= 30) return platinum;
    if (days >= 14) return gold;
    if (days >= 7) return silver;
    if (days >= 3) return bronze;
    return null;
  }

  Color get color {
    switch (this) {
      case bronze:
        return const Color(0xFFCD7F32);
      case silver:
        return const Color(0xFFC0C0C0);
      case gold:
        return const Color(0xFFFFD700);
      case platinum:
        return const Color(0xFFE5E4E2);
      case diamond:
        return const Color(0xFFB9F2FF);
      case master:
        return AppColors.purple;
    }
  }

  Color get glowColor {
    switch (this) {
      case bronze:
        return const Color(0xFFCD7F32);
      case silver:
        return const Color(0xFFC0C0C0);
      case gold:
        return const Color(0xFFFFD700);
      case platinum:
        return const Color(0xFF3B82F6);
      case diamond:
        return const Color(0xFF00CED1);
      case master:
        return AppColors.purple;
    }
  }
}

/// A widget displaying streak badges with animations.
///
/// Features:
/// - Row of streak badges
/// - Fire icon with streak count
/// - Different colors for different streak lengths
/// - Shake animation on milestone days
/// - "Personal Best!" badge when exceeding longest streak
class StreakBadges extends StatefulWidget {
  /// Current streak in days
  final int currentStreak;

  /// Longest streak ever achieved
  final int longestStreak;

  /// Whether today's goal has been achieved
  final bool goalAchievedToday;

  /// Whether this is a milestone day (triggers shake animation)
  final bool isMilestoneDay;

  /// Whether to use dark theme
  final bool isDark;

  /// Callback when streak badge is tapped
  final VoidCallback? onTap;

  const StreakBadges({
    super.key,
    required this.currentStreak,
    this.longestStreak = 0,
    this.goalAchievedToday = false,
    this.isMilestoneDay = false,
    this.isDark = true,
    this.onTap,
  });

  @override
  State<StreakBadges> createState() => _StreakBadgesState();
}

class _StreakBadgesState extends State<StreakBadges>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Shake animation for milestone days
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    // Pulse animation for active streak
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    if (widget.isMilestoneDay) {
      _shakeController.repeat(reverse: true);
      HapticFeedback.heavyImpact();
    }

    if (widget.currentStreak > 0) {
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreakBadges oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isMilestoneDay != oldWidget.isMilestoneDay) {
      if (widget.isMilestoneDay) {
        _shakeController.repeat(reverse: true);
        HapticFeedback.heavyImpact();
      } else {
        _shakeController.stop();
        _shakeController.reset();
      }
    }

    if (widget.currentStreak != oldWidget.currentStreak) {
      if (widget.currentStreak > 0) {
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _glowController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  bool get _isPersonalBest =>
      widget.currentStreak > 0 && widget.currentStreak >= widget.longestStreak;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final milestone = StreakMilestone.fromStreak(widget.currentStreak);

    return Semantics(
      label: _buildAccessibilityLabel(),
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(20),
            border: milestone != null
                ? Border.all(
                    color: milestone.color.withOpacity(0.4),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Main streak badge
              AnimatedBuilder(
                animation: Listenable.merge([
                  _shakeAnimation,
                  _pulseAnimation,
                  _glowAnimation,
                ]),
                builder: (context, child) {
                  final shakeOffset = widget.isMilestoneDay
                      ? math.sin(_shakeAnimation.value * math.pi * 4) * 4
                      : 0.0;
                  final scale = _pulseAnimation.value;

                  return Transform.translate(
                    offset: Offset(shakeOffset, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: _StreakBadge(
                        streak: widget.currentStreak,
                        milestone: milestone,
                        glowOpacity: _glowAnimation.value,
                        goalAchievedToday: widget.goalAchievedToday,
                        isDark: isDark,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 16),

              // Streak info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${widget.currentStreak} Day Streak',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (_isPersonalBest) ...[
                          const SizedBox(width: 8),
                          _PersonalBestBadge(isDark: isDark),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (milestone != null)
                      Text(
                        milestone.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: milestone.color,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (widget.currentStreak > 0)
                      Text(
                        '${3 - widget.currentStreak} more days to Bronze!',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      )
                    else
                      Text(
                        'Hit your goal to start a streak!',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    if (widget.longestStreak > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 14,
                            color: textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Best: ${widget.longestStreak} days',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Milestone badges row
              if (milestone != null)
                _MilestoneBadgesRow(
                  currentMilestone: milestone,
                  isDark: isDark,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildAccessibilityLabel() {
    final parts = <String>[];
    parts.add('${widget.currentStreak} day streak');

    final milestone = StreakMilestone.fromStreak(widget.currentStreak);
    if (milestone != null) {
      parts.add(milestone.title);
    }

    if (_isPersonalBest) {
      parts.add('Personal best');
    }

    if (widget.longestStreak > 0) {
      parts.add('Best streak: ${widget.longestStreak} days');
    }

    return parts.join(', ');
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  final StreakMilestone? milestone;
  final double glowOpacity;
  final bool goalAchievedToday;
  final bool isDark;

  const _StreakBadge({
    required this.streak,
    this.milestone,
    this.glowOpacity = 0.5,
    required this.goalAchievedToday,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = milestone?.color ?? AppColors.orange;
    final glowColor = milestone?.glowColor ?? AppColors.orange;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: streak > 0
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(glowOpacity * 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              streak > 0
                  ? (goalAchievedToday ? Icons.local_fire_department : Icons.local_fire_department_outlined)
                  : Icons.local_fire_department_outlined,
              size: 28,
              color: streak > 0 ? color : glassSurface,
            ),
            if (streak > 0)
              Text(
                streak.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonalBestBadge extends StatefulWidget {
  final bool isDark;

  const _PersonalBestBadge({required this.isDark});

  @override
  State<_PersonalBestBadge> createState() => _PersonalBestBadgeState();
}

class _PersonalBestBadgeState extends State<_PersonalBestBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  'NEW BEST!',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MilestoneBadgesRow extends StatelessWidget {
  final StreakMilestone currentMilestone;
  final bool isDark;

  const _MilestoneBadgesRow({
    required this.currentMilestone,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = StreakMilestone.values;
    final currentIndex = milestones.indexOf(currentMilestone);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        (currentIndex + 2).clamp(0, milestones.length),
        (index) {
          final milestone = milestones[index];
          final isAchieved = index <= currentIndex;
          final isCurrent = index == currentIndex;

          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Semantics(
              label: '${milestone.title} badge${isAchieved ? ", achieved" : ", locked"}',
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAchieved
                      ? milestone.color.withOpacity(0.3)
                      : AppColors.glassSurface,
                  border: Border.all(
                    color: isAchieved
                        ? milestone.color
                        : AppColors.textMuted.withOpacity(0.3),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isAchieved
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: milestone.color,
                        )
                      : Icon(
                          Icons.lock,
                          size: 10,
                          color: AppColors.textMuted,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
