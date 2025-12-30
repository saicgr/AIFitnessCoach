import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/saved_workouts_service.dart';
import '../../../data/services/api_client.dart';
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
  final String activityId; // Activity ID for saving/scheduling
  final String currentUserId; // Current logged-in user ID
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
  final List<Map<String, dynamic>>? badges; // Optional workout badges (TRENDING, HALL OF FAME, etc.)

  const ActivityCard({
    super.key,
    required this.activityId,
    required this.currentUserId,
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
    this.badges,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isExpanded = false;
  late final SavedWorkoutsService _savedWorkoutsService;

  @override
  void initState() {
    super.initState();
    final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _savedWorkoutsService = SavedWorkoutsService(ApiClient(storage));
  }

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
                  onPressed: () => _showPostOptionsMenu(context),
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

  /// Show post options menu (3-dot menu)
  void _showPostOptionsMenu(BuildContext context) {
    HapticFeedback.lightImpact();
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
        padding: const EdgeInsets.symmetric(vertical: 16),
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
            const SizedBox(height: 16),

            // Copy link option
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Share option
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Report option (only show if not own post)
            ListTile(
              leading: Icon(Icons.flag_rounded, color: AppColors.textMuted),
              title: Text('Report', style: TextStyle(color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                _showReportDialog(context);
              },
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Show report dialog
  void _showReportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: elevated,
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this post?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildReportOption(context, 'Spam or misleading'),
            _buildReportOption(context, 'Inappropriate content'),
            _buildReportOption(context, 'Harassment or bullying'),
            _buildReportOption(context, 'Other'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(BuildContext context, String reason) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted. Thank you for helping keep our community safe.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.radio_button_unchecked, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Text(reason, style: const TextStyle(fontSize: 14)),
          ],
        ),
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
      case 'challenge_victory':
        return _buildChallengeVictoryContent(context);
      case 'challenge_completed':
        return _buildChallengeCompletedContent(context);
      case 'manual_post':
        return _buildManualPostContent(context);
      default:
        return _buildGenericContent(context);
    }
  }

  Widget _buildManualPostContent(BuildContext context) {
    final caption = widget.activityData['caption'] as String? ?? '';
    final postType = widget.activityData['post_type'] as String?;
    final hasImage = widget.activityData['has_image'] as bool? ?? false;
    final imageUrl = widget.activityData['image_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post type badge if applicable
        if (postType != null && postType != 'progress') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPostTypeColor(postType).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPostTypeIcon(postType),
                  size: 14,
                  color: _getPostTypeColor(postType),
                ),
                const SizedBox(width: 4),
                Text(
                  _getPostTypeLabel(postType),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPostTypeColor(postType),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Caption text
        if (caption.isNotEmpty)
          Text(
            caption,
            style: const TextStyle(fontSize: 15),
          ),

        // Image if present
        if (hasImage && imageUrl != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Color _getPostTypeColor(String postType) {
    switch (postType) {
      case 'milestone':
        return AppColors.orange;
      case 'photo':
        return AppColors.purple;
      default:
        return AppColors.cyan;
    }
  }

  IconData _getPostTypeIcon(String postType) {
    switch (postType) {
      case 'milestone':
        return Icons.emoji_events_rounded;
      case 'photo':
        return Icons.photo_camera_rounded;
      default:
        return Icons.trending_up_rounded;
    }
  }

  String _getPostTypeLabel(String postType) {
    switch (postType) {
      case 'milestone':
        return 'Milestone';
      case 'photo':
        return 'Photo';
      default:
        return 'Progress Update';
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
        // Display badges if available
        if (widget.badges != null && widget.badges!.isNotEmpty) ...[
          _buildBadges(context, widget.badges!),
          const SizedBox(height: 8),
        ],

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

        // Challenge button - always visible and prominent
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showBeatWorkoutDialog(context);
            },
            icon: const Icon(Icons.emoji_events, size: 20),
            label: const Text(
              'Challenge',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 2,
            ),
          ),
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

          // Workout action buttons
          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // BEAT THIS button - prominent and viral
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showBeatWorkoutDialog(context);
                    },
                    icon: const Icon(Icons.emoji_events, size: 20),
                    label: const Text(
                      'BEAT THIS WORKOUT 💪',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary actions row
                Row(
                  children: [
                    // Save button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showSaveWorkoutDialog(context);
                        },
                        icon: const Icon(Icons.bookmark_outline, size: 16),
                        label: const Text('Save', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cyan,
                          side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Schedule button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showScheduleWorkoutDialog(context);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Schedule', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show save workout dialog
  void _showSaveWorkoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: elevated,
        title: const Text('Save Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save "${widget.activityData['workout_name']}" to your library?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'You can access it anytime from the Library tab.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saving workout...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              try {
                // Call API to save workout
                await _savedWorkoutsService.saveWorkoutFromActivity(
                  userId: widget.currentUserId,
                  activityId: widget.activityId,
                  folder: 'From Friends',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout saved to Library!'),
                      backgroundColor: AppColors.cyan,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error saving workout: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save workout: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show beat workout dialog with competitive messaging
  void _showBeatWorkoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final workoutName = widget.activityData['workout_name'] ?? 'this workout';
    final duration = widget.activityData['duration_minutes'] ?? 0;
    final totalVolume = widget.activityData['total_volume'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: elevated,
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.orange, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'BEAT THIS WORKOUT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '${widget.userName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' crushed '),
                  TextSpan(
                    text: workoutName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildChallengeStat('Time', '$duration min'),
                  if (totalVolume != null) ...[
                    const SizedBox(height: 8),
                    _buildChallengeStat('Total Volume', '${totalVolume.toStringAsFixed(0)} lbs'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Can you beat their performance? Start now!',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Today'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Accepting challenge...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              try {
                // Call API to accept challenge (tracks click, saves workout, returns session)
                final workoutSession = await _savedWorkoutsService.acceptChallenge(
                  userId: widget.currentUserId,
                  activityId: widget.activityId,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Challenge accepted! Starting workout...'),
                      backgroundColor: AppColors.orange,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // TODO: Navigate to ActiveWorkoutScreen with workoutSession data
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => ActiveWorkoutScreen(
                  //     workoutData: workoutSession,
                  //     isChallengeMode: true,
                  //   ),
                  // ));
                }
              } catch (e) {
                debugPrint('Error accepting challenge: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to start challenge: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'ACCEPT CHALLENGE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }

  /// Show schedule workout dialog
  void _showScheduleWorkoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      builder: (context) => _ScheduleWorkoutDialog(
        activityId: widget.activityId,
        currentUserId: widget.currentUserId,
        workoutName: widget.activityData['workout_name'] ?? 'this workout',
        savedWorkoutsService: _savedWorkoutsService,
        elevated: elevated,
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

  Widget _buildChallengeVictoryContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workoutName = widget.activityData['workout_name'] ?? 'a workout';
    final challengerName = widget.activityData['challenger_name'] ?? 'someone';
    final yourDuration = widget.activityData['your_duration'];
    final yourVolume = widget.activityData['your_volume'];
    final theirDuration = widget.activityData['their_duration'];
    final theirVolume = widget.activityData['their_volume'];
    final timeDifference = widget.activityData['time_difference'];
    final volumeDifference = widget.activityData['volume_difference'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Victory header with trophy
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow.withValues(alpha: 0.4),
                    Colors.orange.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VICTORY!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(text: 'beat '),
                        TextSpan(
                          text: '$challengerName\'s',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: workoutName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Comparison stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Time comparison
              if (yourDuration != null && theirDuration != null) ...[
                _buildVictoryComparison(
                  emoji: '⏱️',
                  label: 'Time',
                  yourValue: '$yourDuration min',
                  theirValue: '$theirDuration min',
                  improvement: timeDifference != null && timeDifference > 0
                      ? '${timeDifference.abs()} min faster'
                      : null,
                ),
                const SizedBox(height: 8),
              ],

              // Volume comparison
              if (yourVolume != null && theirVolume != null)
                _buildVictoryComparison(
                  emoji: '💪',
                  label: 'Volume',
                  yourValue: '${yourVolume.toStringAsFixed(0)} lbs',
                  theirValue: '${theirVolume.toStringAsFixed(0)} lbs',
                  improvement: volumeDifference != null && volumeDifference > 0
                      ? '+${volumeDifference.toStringAsFixed(0)} lbs'
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVictoryComparison({
    required String emoji,
    required String label,
    required String yourValue,
    required String theirValue,
    String? improvement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 24),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        yourValue,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Them',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        theirValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (improvement != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  improvement,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildChallengeCompletedContent(BuildContext context) {
    final workoutName = widget.activityData['workout_name'] ?? 'a workout';
    final challengerName = widget.activityData['challenger_name'] ?? 'someone';
    final yourDuration = widget.activityData['your_duration'];
    final yourVolume = widget.activityData['your_volume'];
    final theirDuration = widget.activityData['their_duration'];
    final theirVolume = widget.activityData['their_volume'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Challenge attempted header
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('💪', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHALLENGE ATTEMPTED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(text: 'challenged '),
                        TextSpan(
                          text: '$challengerName\'s',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: workoutName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Stats comparison
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Keep training! Every attempt makes you stronger',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats
              if (yourDuration != null && theirDuration != null) ...[
                _buildChallengeStatRow('Time', '$yourDuration min', '$theirDuration min'),
                const SizedBox(height: 8),
              ],
              if (yourVolume != null && theirVolume != null)
                _buildChallengeStatRow('Volume', '${yourVolume.toStringAsFixed(0)} lbs', '${theirVolume.toStringAsFixed(0)} lbs'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeStatRow(String label, String yourValue, String targetValue) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'You: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    yourValue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('|', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  Text(
                    'Target: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    targetValue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericContent(BuildContext context) {
    // Try to show caption if available for unknown activity types
    final caption = widget.activityData['caption'] as String?;
    if (caption != null && caption.isNotEmpty) {
      return Text(caption, style: const TextStyle(fontSize: 15));
    }
    return const Text('shared an update');
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

  /// Build badge chips (TRENDING, HALL OF FAME, BEAST MODE, etc.)
  Widget _buildBadges(BuildContext context, List<Map<String, dynamic>> badges) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges.map((badge) {
        final type = badge['type'] as String;
        final label = badge['label'] as String;
        final colorStr = badge['color'] as String;

        // Map color strings to actual colors
        Color badgeColor;
        switch (colorStr.toLowerCase()) {
          case 'orange':
            badgeColor = AppColors.orange;
            break;
          case 'gold':
            badgeColor = const Color(0xFFFFD700);
            break;
          case 'red':
            badgeColor = AppColors.red;
            break;
          case 'purple':
            badgeColor = AppColors.purple;
            break;
          default:
            badgeColor = AppColors.cyan;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
              letterSpacing: 0.3,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Schedule Workout Dialog - Stateful to handle date selection
class _ScheduleWorkoutDialog extends StatefulWidget {
  final String activityId;
  final String currentUserId;
  final String workoutName;
  final SavedWorkoutsService savedWorkoutsService;
  final Color elevated;

  const _ScheduleWorkoutDialog({
    required this.activityId,
    required this.currentUserId,
    required this.workoutName,
    required this.savedWorkoutsService,
    required this.elevated,
  });

  @override
  State<_ScheduleWorkoutDialog> createState() => _ScheduleWorkoutDialogState();
}

class _ScheduleWorkoutDialogState extends State<_ScheduleWorkoutDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.elevated,
      title: const Text('Schedule Workout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule "${widget.workoutName}" for:',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cyan,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);

            // Show loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Scheduling workout...'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );

            try {
              // Call API to schedule workout
              await widget.savedWorkoutsService.saveAndSchedule(
                userId: widget.currentUserId,
                activityId: widget.activityId,
                scheduledDate: _selectedDate,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Workout scheduled for ${_selectedDate.month}/${_selectedDate.day}!',
                    ),
                    backgroundColor: AppColors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error scheduling workout: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to schedule workout: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
          ),
          child: const Text('Schedule'),
        ),
      ],
    );
  }
}
