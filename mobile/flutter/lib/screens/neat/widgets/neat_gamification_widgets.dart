import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// NEAT Level enumeration with progression tiers.
///
/// Users progress through levels based on their NEAT score and consistency:
/// - Couch Potato: Starting level (0-999 XP)
/// - Casual Mover: Beginning to build habits (1000-2499 XP)
/// - Active Walker: Regular daily movement (2500-4999 XP)
/// - NEAT Enthusiast: Strong daily activity (5000-9999 XP)
/// - NEAT Champion: Elite daily movement (10000+ XP)
enum NeatLevel {
  couchPotato,
  casualMover,
  activeWalker,
  neatEnthusiast,
  neatChampion;

  String get displayName {
    switch (this) {
      case NeatLevel.couchPotato:
        return 'Couch Potato';
      case NeatLevel.casualMover:
        return 'Casual Mover';
      case NeatLevel.activeWalker:
        return 'Active Walker';
      case NeatLevel.neatEnthusiast:
        return 'NEAT Enthusiast';
      case NeatLevel.neatChampion:
        return 'NEAT Champion';
    }
  }

  String get emoji {
    switch (this) {
      case NeatLevel.couchPotato:
        return '\u{1F6CB}'; // Couch emoji
      case NeatLevel.casualMover:
        return '\u{1F6B6}'; // Walking person
      case NeatLevel.activeWalker:
        return '\u{1F3C3}'; // Running person
      case NeatLevel.neatEnthusiast:
        return '\u{1F525}'; // Fire
      case NeatLevel.neatChampion:
        return '\u{1F3C6}'; // Trophy
    }
  }

  Color get color {
    switch (this) {
      case NeatLevel.couchPotato:
        return AppColors.textMuted;
      case NeatLevel.casualMover:
        return AppColors.info;
      case NeatLevel.activeWalker:
        return AppColors.teal;
      case NeatLevel.neatEnthusiast:
        return AppColors.orange;
      case NeatLevel.neatChampion:
        return AppColors.yellow;
    }
  }

  int get minXP {
    switch (this) {
      case NeatLevel.couchPotato:
        return 0;
      case NeatLevel.casualMover:
        return 1000;
      case NeatLevel.activeWalker:
        return 2500;
      case NeatLevel.neatEnthusiast:
        return 5000;
      case NeatLevel.neatChampion:
        return 10000;
    }
  }

  int get maxXP {
    switch (this) {
      case NeatLevel.couchPotato:
        return 999;
      case NeatLevel.casualMover:
        return 2499;
      case NeatLevel.activeWalker:
        return 4999;
      case NeatLevel.neatEnthusiast:
        return 9999;
      case NeatLevel.neatChampion:
        return 99999; // Effectively no cap
    }
  }

  /// Get the next level, or null if at max
  NeatLevel? get nextLevel {
    final index = NeatLevel.values.indexOf(this);
    if (index < NeatLevel.values.length - 1) {
      return NeatLevel.values[index + 1];
    }
    return null;
  }

  /// Calculate level from XP
  static NeatLevel fromXP(int xp) {
    if (xp >= 10000) return NeatLevel.neatChampion;
    if (xp >= 5000) return NeatLevel.neatEnthusiast;
    if (xp >= 2500) return NeatLevel.activeWalker;
    if (xp >= 1000) return NeatLevel.casualMover;
    return NeatLevel.couchPotato;
  }
}

/// NEAT Level Badge widget - displays user's current NEAT level with visual flair.
///
/// Features:
/// - Animated glow effect for higher levels
/// - Emoji icon representing level
/// - Gradient background based on tier
/// - Tap callback for level details
class NeatLevelBadge extends StatefulWidget {
  final NeatLevel level;
  final bool showName;
  final double size;
  final VoidCallback? onTap;

  const NeatLevelBadge({
    super.key,
    required this.level,
    this.showName = true,
    this.size = 48,
    this.onTap,
  });

  @override
  State<NeatLevelBadge> createState() => _NeatLevelBadgeState();
}

class _NeatLevelBadgeState extends State<NeatLevelBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Only animate for higher levels
    if (widget.level.index >= NeatLevel.neatEnthusiast.index) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHighLevel = widget.level.index >= NeatLevel.neatEnthusiast.index;

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          HapticService.light();
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: widget.showName
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                : EdgeInsets.all(widget.size * 0.2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.level.color.withOpacity(0.2),
                  widget.level.color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.showName ? 24 : 16),
              border: Border.all(
                color: widget.level.color.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: isHighLevel
                  ? [
                      BoxShadow(
                        color: widget.level.color
                            .withOpacity(0.2 + _pulseController.value * 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Level emoji with potential glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isHighLevel)
                      Container(
                        width: widget.size * 0.6,
                        height: widget.size * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.level.color
                                  .withOpacity(0.3 + _pulseController.value * 0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    Text(
                      widget.level.emoji,
                      style: TextStyle(fontSize: widget.size * 0.5),
                    ),
                  ],
                ),
                if (widget.showName) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.level.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.level.color,
                        ),
                      ),
                      Text(
                        'Level ${widget.level.index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

/// NEAT Progress Bar - XP-style progress indicator to next level.
///
/// Features:
/// - Animated fill progress
/// - Current XP and XP needed display
/// - Level milestone markers
/// - Gradient fill matching level color
class NeatProgressBar extends StatefulWidget {
  final int currentXP;
  final NeatLevel currentLevel;
  final bool showLabels;
  final double height;

  const NeatProgressBar({
    super.key,
    required this.currentXP,
    required this.currentLevel,
    this.showLabels = true,
    this.height = 12,
  });

  @override
  State<NeatProgressBar> createState() => _NeatProgressBarState();
}

class _NeatProgressBarState extends State<NeatProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _updateProgress();
    _animController.forward();
  }

  @override
  void didUpdateWidget(NeatProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXP != widget.currentXP) {
      _updateProgress();
      _animController.forward(from: 0);
    }
  }

  void _updateProgress() {
    final nextLevel = widget.currentLevel.nextLevel;
    double progress;

    if (nextLevel == null) {
      // At max level, show full bar
      progress = 1.0;
    } else {
      final levelMinXP = widget.currentLevel.minXP;
      final levelMaxXP = nextLevel.minXP;
      final xpInLevel = widget.currentXP - levelMinXP;
      final xpNeeded = levelMaxXP - levelMinXP;
      progress = (xpInLevel / xpNeeded).clamp(0.0, 1.0);
    }

    _progressAnim = Tween<double>(
      begin: 0,
      end: progress,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextLevel = widget.currentLevel.nextLevel;
    final xpToNext = nextLevel != null
        ? nextLevel.minXP - widget.currentXP
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.currentXP} XP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (nextLevel != null)
                Text(
                  '$xpToNext XP to ${nextLevel.displayName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  'Max Level!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.yellow,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // Progress bar container
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, child) {
              return Stack(
                children: [
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: _progressAnim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.currentLevel.color,
                            widget.currentLevel.color.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.currentLevel.color.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Shimmer effect
                  if (_progressAnim.value > 0.1)
                    FractionallySizedBox(
                      widthFactor: _progressAnim.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.height / 2),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// NEAT Leaderboard Card - Weekly NEAT score rankings.
///
/// Displays top users by NEAT score with rank badges,
/// user avatars, and score comparisons.
class NeatLeaderboardCard extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;
  final VoidCallback? onViewAll;

  const NeatLeaderboardCard({
    super.key,
    required this.entries,
    this.currentUserId,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '\u{1F3C6}', // Trophy
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Weekly Leaderboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    onViewAll!();
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Entries
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No rankings yet this week',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...entries.take(5).map((entry) {
              final isCurrentUser = entry.userId == currentUserId;
              return _LeaderboardRow(
                entry: entry,
                isCurrentUser: isCurrentUser,
              );
            }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

/// Individual leaderboard row
class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.cyan.withOpacity(0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.cyan.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          _RankBadge(rank: entry.rank),
          const SizedBox(width: 12),

          // Avatar/initial
          CircleAvatar(
            radius: 18,
            backgroundColor: entry.level.color.withOpacity(0.2),
            child: Text(
              entry.displayName.isNotEmpty
                  ? entry.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: entry.level.color,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.displayName,
                      style: TextStyle(
                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (isCurrentUser)
                      Text(
                        ' (You)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cyan,
                        ),
                      ),
                  ],
                ),
                Text(
                  entry.level.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: entry.level.color,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.weeklyScore}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'NEAT pts',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rank badge widget for leaderboard positions
class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String? medal;

    switch (rank) {
      case 1:
        badgeColor = AppColors.yellow;
        medal = '\u{1F947}'; // Gold medal
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Silver
        medal = '\u{1F948}'; // Silver medal
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        medal = '\u{1F949}'; // Bronze medal
        break;
      default:
        badgeColor = AppColors.textMuted;
        medal = null;
    }

    if (medal != null) {
      return Text(
        medal,
        style: const TextStyle(fontSize: 24),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: badgeColor,
          ),
        ),
      ),
    );
  }
}

/// Leaderboard entry data model
class LeaderboardEntry {
  final String rankStr;
  final String userId;
  final String displayName;
  final int weeklyScore;
  final NeatLevel level;

  const LeaderboardEntry({
    required String rank,
    required this.userId,
    required this.displayName,
    required this.weeklyScore,
    required this.level,
  }) : rankStr = rank;

  int get rank => int.tryParse(rankStr) ?? 0;
}

/// Daily Challenge Card - Random daily NEAT challenge.
///
/// Features:
/// - Daily rotating challenges
/// - Progress tracking
/// - Reward display
/// - Countdown timer
class DailyChallenge extends StatefulWidget {
  final String challengeId;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final int xpReward;
  final String unit;
  final DateTime expiresAt;
  final VoidCallback? onAccept;
  final VoidCallback? onComplete;

  const DailyChallenge({
    super.key,
    required this.challengeId,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.xpReward,
    this.unit = 'steps',
    required this.expiresAt,
    this.onAccept,
    this.onComplete,
  });

  @override
  State<DailyChallenge> createState() => _DailyChallengeState();
}

class _DailyChallengeState extends State<DailyChallenge>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String _formatTimeRemaining() {
    final now = DateTime.now();
    final diff = widget.expiresAt.difference(now);

    if (diff.isNegative) return 'Expired';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    }
    return '${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (widget.currentValue / widget.targetValue).clamp(0.0, 1.0);
    final isCompleted = widget.currentValue >= widget.targetValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [
                  AppColors.green.withOpacity(0.2),
                  AppColors.teal.withOpacity(0.1),
                ]
              : [
                  AppColors.purple.withOpacity(0.15),
                  AppColors.cyan.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.green.withOpacity(0.3)
              : AppColors.purple.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.green.withOpacity(0.2)
                      : AppColors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isCompleted ? '\u{2705}' : '\u{26A1}', // Checkmark or lightning
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Challenge',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? AppColors.green : AppColors.purple,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRemaining(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.currentValue} / ${widget.targetValue} ${widget.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? AppColors.green : AppColors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted
                                ? [AppColors.green, AppColors.teal]
                                : [AppColors.purple, AppColors.cyan],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reward and action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // XP Reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.yellow.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '\u{2B50}', // Star
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${widget.xpReward} XP',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.yellow,
                      ),
                    ),
                  ],
                ),
              ),

              // Action button
              if (isCompleted && widget.onComplete != null)
                ElevatedButton(
                  onPressed: () {
                    HapticService.success();
                    widget.onComplete!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Claim Reward',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              else if (widget.onAccept != null && widget.currentValue == 0)
                OutlinedButton(
                  onPressed: () {
                    HapticService.medium();
                    widget.onAccept!();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purple,
                    side: BorderSide(color: AppColors.purple),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

/// NEAT Milestone Popup - Full-screen celebration for major achievements.
///
/// Features:
/// - Confetti animation
/// - Glowing badge display
/// - Share functionality
/// - Level up celebration
class NeatMilestonePopup extends StatefulWidget {
  final String title;
  final String description;
  final NeatLevel? newLevel;
  final int xpEarned;
  final String? achievementEmoji;
  final VoidCallback onDismiss;
  final VoidCallback? onShare;

  const NeatMilestonePopup({
    super.key,
    required this.title,
    required this.description,
    this.newLevel,
    required this.xpEarned,
    this.achievementEmoji,
    required this.onDismiss,
    this.onShare,
  });

  @override
  State<NeatMilestonePopup> createState() => _NeatMilestonePopupState();
}

class _NeatMilestonePopupState extends State<NeatMilestonePopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Badge scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeIn,
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addListener(() {
        _updateParticles();
      });

    // Start animations
    _scaleController.forward();
    _generateConfetti();
    _confettiController.forward();

    // Haptic feedback
    HapticService.success();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateConfetti() {
    _particles.clear();
    final colors = [
      AppColors.purple,
      AppColors.cyan,
      AppColors.orange,
      AppColors.yellow,
      AppColors.coral,
      AppColors.green,
    ];

    for (int i = 0; i < 100; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.3,
        size: 4 + _random.nextDouble() * 8,
        color: colors[_random.nextInt(colors.length)],
        velocity: 0.3 + _random.nextDouble() * 0.4,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: _random.nextDouble() * 5 - 2.5,
        swayAmplitude: 0.02 + _random.nextDouble() * 0.04,
        swayPhase: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.y += particle.velocity * 0.02;
        particle.x +=
            math.sin(particle.swayPhase + _confettiController.value * 10) *
                particle.swayAmplitude;
        particle.rotation += particle.rotationSpeed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.newLevel?.color ?? AppColors.cyan;
    final emoji = widget.achievementEmoji ?? widget.newLevel?.emoji ?? '\u{1F389}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.85),
          ),

          // Confetti
          CustomPaint(
            painter: _ConfettiPainter(_particles),
            size: Size.infinite,
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Celebration text
                  if (widget.newLevel != null)
                    Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.yellow,
                        letterSpacing: 4,
                      ),
                    )
                  else
                    Text(
                      'ACHIEVEMENT UNLOCKED!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        letterSpacing: 4,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Badge with glow
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.4),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        // Badge
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                accentColor.withOpacity(0.3),
                                accentColor.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: accentColor,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // XP earned badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.yellow),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '\u{2B50}', // Star
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.xpEarned} XP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        if (widget.onShare != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ShareButton(
                                icon: Icons.share,
                                label: 'Share',
                                onTap: widget.onShare!,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticService.light();
                              widget.onDismiss();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Share button widget
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confetti particle data
class _ConfettiParticle {
  double x;
  double y;
  final double size;
  final Color color;
  final double velocity;
  double rotation;
  final double rotationSpeed;
  final double swayAmplitude;
  final double swayPhase;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.swayPhase,
  });
}

/// Custom painter for confetti animation
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      if (particle.y > 1.2) continue;

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        particle.x * size.width,
        particle.y * size.height,
      );
      canvas.rotate(particle.rotation * math.pi / 180);

      // Draw rectangle confetti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/// Compact NEAT Stats Card - shows key NEAT metrics in a compact format.
///
/// Useful for home screen or dashboard display.
class CompactNeatStatsCard extends StatelessWidget {
  final int todaySteps;
  final int stepGoal;
  final int neatScore;
  final int activeHours;
  final int targetActiveHours;
  final VoidCallback? onTap;

  const CompactNeatStatsCard({
    super.key,
    required this.todaySteps,
    required this.stepGoal,
    required this.neatScore,
    required this.activeHours,
    this.targetActiveHours = 10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stepProgress = (todaySteps / stepGoal).clamp(0.0, 1.0);
    final activeProgress = (activeHours / targetActiveHours).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticService.light();
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Steps progress
            Expanded(
              child: _CompactStatItem(
                icon: '\u{1F6B6}', // Walking person
                label: 'Steps',
                value: '$todaySteps',
                subValue: '/ $stepGoal',
                progress: stepProgress,
                progressColor: AppColors.cyan,
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: colorScheme.outline.withOpacity(0.2),
            ),
            // Active hours
            Expanded(
              child: _CompactStatItem(
                icon: '\u{23F0}', // Alarm clock
                label: 'Active',
                value: '$activeHours',
                subValue: '/ $targetActiveHours hrs',
                progress: activeProgress,
                progressColor: AppColors.teal,
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: colorScheme.outline.withOpacity(0.2),
            ),
            // NEAT score
            Expanded(
              child: _CompactStatItem(
                icon: '\u{26A1}', // Lightning
                label: 'NEAT',
                value: '$neatScore',
                subValue: 'score',
                progress: (neatScore / 100).clamp(0.0, 1.0),
                progressColor: AppColors.orange,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _CompactStatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String subValue;
  final double progress;
  final Color progressColor;

  const _CompactStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                subValue,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Mini progress bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
