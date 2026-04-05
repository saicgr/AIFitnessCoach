part of 'neat_gamification_widgets.dart';



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

