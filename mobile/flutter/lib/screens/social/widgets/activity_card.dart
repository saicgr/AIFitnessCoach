import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Reaction type enum matching backend
enum ReactionType {
  cheer('cheer', '🎉', 'Cheer', AppColors.orange),
  fire('fire', '🔥', 'Fire', AppColors.red),
  strong('strong', '💪', 'Strong', AppColors.purple),
  clap('clap', '👏', 'Clap', AppColors.cyan),
  heart('heart', '❤️', 'Heart', AppColors.pink);

  final String value;
  final String emoji;
  final String label;
  final Color color;

  const ReactionType(this.value, this.emoji, this.label, this.color);
}

/// Activity Card - Displays a single activity feed item with expandable workout details
class ActivityCard extends StatefulWidget {
  final String userName;
  final String? userAvatar;
  final String activityType;
  final Map<String, dynamic> activityData;
  final DateTime timestamp;
  final int reactionCount;
  final int commentCount;
  final bool hasUserReacted;
  final String? userReactionType; // Type of user's reaction (if any)
  final Function(String reactionType) onReact; // Changed to accept reaction type
  final VoidCallback onComment;

  const ActivityCard({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.activityType,
    required this.activityData,
    required this.timestamp,
    required this.reactionCount,
    required this.commentCount,
    required this.hasUserReacted,
    this.userReactionType,
    required this.onReact,
    required this.onComment,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (User info + timestamp)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                  backgroundImage: widget.userAvatar != null ? NetworkImage(widget.userAvatar!) : null,
                  child: widget.userAvatar == null
                      ? Text(
                          widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeago.format(widget.timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () {
                    // TODO: Show options menu
                  },
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Activity content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActivityContent(context),
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(
            height: 1,
            color: cardBorder.withValues(alpha: 0.3),
          ),

          // Actions (Reactions & Comments)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // React button with long-press support
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Quick tap - toggle default reaction (heart)
                      HapticFeedback.lightImpact();
                      widget.onReact(widget.hasUserReacted ? 'remove' : 'heart');
                    },
                    onLongPress: () {
                      // Long press - show emoji picker
                      HapticFeedback.mediumImpact();
                      _showReactionPicker(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Show emoji if user has reacted, otherwise heart icon
                          if (widget.hasUserReacted && widget.userReactionType != null)
                            Text(
                              _getReactionEmoji(widget.userReactionType!),
                              style: const TextStyle(fontSize: 20),
                            )
                          else
                            Icon(
                              widget.hasUserReacted ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: widget.hasUserReacted ? AppColors.pink : AppColors.textMuted,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            widget.reactionCount > 0 ? '${widget.reactionCount}' : 'React',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.hasUserReacted ? _getReactionColor(widget.userReactionType) : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Divider
                Container(
                  height: 24,
                  width: 1,
                  color: cardBorder.withValues(alpha: 0.3),
                ),

                // Comment button
                Expanded(
                  child: InkWell(
                    onTap: widget.onComment,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.commentCount > 0 ? '${widget.commentCount}' : 'Comment',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show reaction picker bottom sheet
  void _showReactionPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'React to this post',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Reaction options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ReactionType.values.map((reaction) {
                final isSelected = widget.userReactionType == reaction.value;
                return _buildReactionButton(
                  context,
                  reaction: reaction,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                    widget.onReact(reaction.value);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Remove reaction button (if user has reacted)
            if (widget.hasUserReacted)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  widget.onReact('remove');
                },
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove Reaction'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(
    BuildContext context, {
    required ReactionType reaction,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? reaction.color.withValues(alpha: 0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? reaction.color
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reaction.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              reaction.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? reaction.color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getReactionEmoji(String reactionType) {
    try {
      return ReactionType.values
          .firstWhere((r) => r.value == reactionType)
          .emoji;
    } catch (_) {
      return '❤️';
    }
  }

  Color _getReactionColor(String? reactionType) {
    if (reactionType == null) return AppColors.pink;
    try {
      return ReactionType.values
          .firstWhere((r) => r.value == reactionType)
          .color;
    } catch (_) {
      return AppColors.pink;
    }
  }

  Widget _buildActivityContent(BuildContext context) {
    switch (widget.activityType) {
      case 'workout_completed':
        return _buildWorkoutContent(context);
      case 'achievement_earned':
        return _buildAchievementContent(context);
      case 'personal_record':
        return _buildPRContent(context);
      case 'weight_milestone':
        return _buildWeightMilestoneContent(context);
      case 'streak_milestone':
        return _buildStreakContent(context);
      default:
        return _buildGenericContent(context);
    }
  }

  Widget _buildWorkoutContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workoutName = widget.activityData['workout_name'] ?? 'a workout';
    final duration = widget.activityData['duration_minutes'] ?? 0;
    final exercises = widget.activityData['exercises_count'] ?? 0;
    final totalVolume = widget.activityData['total_volume'];
    final exercisesList = widget.activityData['exercises_performance'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(text: 'completed '),
              TextSpan(
                text: workoutName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStat(Icons.timer_outlined, '$duration min'),
            _buildStat(Icons.fitness_center_outlined, '$exercises exercises'),
            if (totalVolume != null)
              _buildStat(Icons.trending_up_outlined, '${totalVolume.toStringAsFixed(0)} lbs'),
          ],
        ),

        // Show exercises button if exercise data is available
        if (exercisesList != null && exercisesList.isNotEmpty) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isExpanded ? 'Hide workout details' : 'Show workout details',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded exercise details
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            _buildExerciseDetails(context, exercisesList, isDark),
          ],
        ],
      ],
    );
  }

  Widget _buildExerciseDetails(BuildContext context, List<dynamic> exercises, bool isDark) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 8),
                Text(
                  'Workout Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3)),

          // Exercise list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: exercises.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exercise = exercises[index] as Map<String, dynamic>;
              final name = exercise['name'] ?? 'Exercise ${index + 1}';
              final sets = exercise['sets'] ?? 0;
              final reps = exercise['reps'] ?? 0;
              final weightKg = exercise['weight_kg'] ?? 0.0;
              final weightLbs = (weightKg * 2.20462).toStringAsFixed(0);

              return Row(
                children: [
                  // Exercise number
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Exercise info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sets sets × $reps reps @ $weightLbs lbs',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Copy workout button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  // TODO: Implement copy workout feature
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copy Workout feature coming soon!'),
                      backgroundColor: AppColors.cyan,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copy This Workout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementContent(BuildContext context) {
    final achievementName = widget.activityData['achievement_name'] ?? 'an achievement';
    final achievementIcon = widget.activityData['achievement_icon'] ?? '🏆';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.orange.withValues(alpha: 0.3),
                AppColors.pink.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              achievementIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'earned an achievement',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                achievementName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPRContent(BuildContext context) {
    final exercise = widget.activityData['exercise_name'] ?? 'an exercise';
    final value = widget.activityData['record_value'] ?? 0;
    final unit = widget.activityData['record_unit'] ?? '';

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          const TextSpan(text: 'set a new PR in '),
          TextSpan(
            text: exercise,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ': '),
          TextSpan(
            text: '$value $unit',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightMilestoneContent(BuildContext context) {
    final weightChange = widget.activityData['weight_change'] ?? 0;
    final direction = weightChange < 0 ? 'lost' : 'gained';

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: '$direction '),
          TextSpan(
            text: '${weightChange.abs()} lbs',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakContent(BuildContext context) {
    final days = widget.activityData['streak_days'] ?? 0;

    return Row(
      children: [
        const Icon(
          Icons.local_fire_department,
          color: AppColors.orange,
          size: 24,
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(text: 'reached a '),
              TextSpan(
                text: '$days-day streak',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
              const TextSpan(text: '!'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericContent(BuildContext context) {
    return const Text('was active');
  }

  Widget _buildStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
