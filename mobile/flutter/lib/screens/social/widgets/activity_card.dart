import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/challenges_service.dart';
import '../../../data/services/saved_workouts_service.dart';
import '../../../widgets/glass_sheet.dart';
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
  final String postUserId; // Post author's user ID
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
  final VoidCallback? onDelete; // Callback to delete the post (own only)
  final VoidCallback? onEdit; // Callback to edit the post (own only)
  final VoidCallback? onShare; // Callback to share the post
  final List<Map<String, dynamic>>? badges; // Optional workout badges (TRENDING, HALL OF FAME, etc.)
  final bool isPinned; // Whether this post is pinned to top of feed
  final bool isCurrentUserAdmin; // Whether current user is admin (can pin/unpin)
  final VoidCallback? onPin; // Callback to pin/unpin the post (admin only)

  const ActivityCard({
    super.key,
    required this.activityId,
    required this.currentUserId,
    required this.postUserId,
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
    this.onDelete,
    this.onEdit,
    this.onShare,
    this.badges,
    this.isPinned = false,
    this.isCurrentUserAdmin = false,
    this.onPin,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> with SingleTickerProviderStateMixin {
  late final SavedWorkoutsService _savedWorkoutsService;
  final _reactButtonKey = GlobalKey();
  OverlayEntry? _reactionOverlay;
  late AnimationController _reactionAnimController;
  late Animation<double> _reactionScaleAnim;

  @override
  void initState() {
    super.initState();
    final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _savedWorkoutsService = SavedWorkoutsService(ApiClient(storage));
    _reactionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _reactionScaleAnim = CurvedAnimation(
      parent: _reactionAnimController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _dismissReactionOverlay();
    _reactionAnimController.dispose();
    super.dispose();
  }

  void _dismissReactionOverlay() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
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
        border: Border.all(color: cardBorder.withValues(alpha: isDark ? 0.3 : 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned badge (if pinned)
          if (widget.isPinned)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pinned Post',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),

          // Header (User info + timestamp)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _flairCyan.withValues(alpha: 0.2),
                  backgroundImage: widget.userAvatar != null ? NetworkImage(widget.userAvatar!) : null,
                  child: widget.userAvatar == null
                      ? Text(
                          widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _flairCyan,
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

          // Actions (React, Comment, Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // React button with long-press support
                Expanded(
                  key: _reactButtonKey,
                  child: GestureDetector(
                    onTap: () {
                      // Quick tap - toggle default reaction (heart)
                      HapticFeedback.lightImpact();
                      widget.onReact(widget.hasUserReacted ? 'remove' : 'heart');
                    },
                    onLongPress: () {
                      // Long press - show inline emoji picker above button
                      HapticFeedback.mediumImpact();
                      _showInlineReactionPicker();
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
                              style: const TextStyle(fontSize: 18),
                            )
                          else
                            Icon(
                              widget.hasUserReacted ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: widget.hasUserReacted ? AppColors.pink : AppColors.textMuted,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            widget.reactionCount > 0 ? '${widget.reactionCount}' : 'React',
                            style: TextStyle(
                              fontSize: 13,
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
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.commentCount > 0 ? '${widget.commentCount}' : 'Comment',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
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

                // Share button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onShare?.call();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 13,
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

  /// Whether the current user owns this post
  bool get _isOwnPost => widget.currentUserId == widget.postUserId;

  /// Show post options menu (3-dot menu)
  void _showPostOptionsMenu(BuildContext context) {
    HapticFeedback.lightImpact();

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === OWN POST OPTIONS ===
            if (_isOwnPost) ...[
              // Edit option (own post only, manual_post type)
              if (widget.activityType == 'manual_post' && widget.onEdit != null)
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    widget.onEdit!();
                  },
                ),

              // Delete option (own post only)
              if (widget.onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                  title: const Text('Delete Post', style: TextStyle(color: AppColors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(context);
                  },
                ),
            ],

            // === SHARED OPTIONS (both own and others) ===

            // Share option
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                widget.onShare?.call();
              },
            ),

            // Copy link option
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                Clipboard.setData(const ClipboardData(text: 'https://fitwiz.app/post'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Pin/Unpin option (admin only)
            if (widget.isCurrentUserAdmin && widget.onPin != null)
              ListTile(
                leading: Icon(
                  widget.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: AppColors.orange,
                ),
                title: Text(
                  widget.isPinned ? 'Unpin Post' : 'Pin to Top',
                  style: const TextStyle(color: AppColors.orange),
                ),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  widget.onPin!();
                },
              ),

            // === OTHERS' POST OPTIONS ===
            if (!_isOwnPost)
              ListTile(
                leading: Icon(Icons.flag_rounded, color: AppColors.textMuted),
                title: Text('Report', style: TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _showReportDialog(context);
                },
              ),

            // Bottom padding for safe area + floating nav bar (80px nav + 16px extra)
            SizedBox(height: MediaQuery.of(context).padding.bottom + 96),
          ],
        ),
      ),
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: elevated,
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
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

  /// Show inline reaction picker floating above the react button
  void _showInlineReactionPicker() {
    _dismissReactionOverlay();

    final renderBox = _reactButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _reactionOverlay = OverlayEntry(
      builder: (context) {
        // Pill width for 5 emojis
        const pillWidth = 280.0;
        const pillHeight = 52.0;
        // Center pill horizontally over the button, clamp to screen
        final screenWidth = MediaQuery.of(context).size.width;
        double left = buttonPos.dx + (buttonSize.width / 2) - (pillWidth / 2);
        if (left < 12) left = 12;
        if (left + pillWidth > screenWidth - 12) left = screenWidth - pillWidth - 12;
        // Position above the button
        final top = buttonPos.dy - pillHeight - 12;

        return Stack(
          children: [
            // Tap-away barrier
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _reactionAnimController.reverse().then((_) => _dismissReactionOverlay());
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // Reaction pill
            Positioned(
              left: left,
              top: top,
              child: ScaleTransition(
                scale: _reactionScaleAnim,
                alignment: Alignment.bottomCenter,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black45,
                  borderRadius: BorderRadius.circular(28),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: Container(
                    width: pillWidth,
                    height: pillHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ReactionType.values.map((reaction) {
                        final isSelected = widget.userReactionType == reaction.value;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _reactionAnimController.reverse().then((_) {
                              _dismissReactionOverlay();
                              widget.onReact(reaction.value);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? reaction.color.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                reaction.emoji,
                                style: TextStyle(fontSize: isSelected ? 26 : 24),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_reactionOverlay!);
    _reactionAnimController.forward(from: 0);
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
      case 'workout_shared':
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
    final flairs = (widget.activityData['flairs'] as List<dynamic>?)?.cast<String>() ?? [];
    final hasImage = widget.activityData['has_image'] as bool? ?? false;
    final imageUrl = widget.activityData['image_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Flair tags
        if (flairs.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: flairs.map((flair) {
              final color = _getFlairColor(flair);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getFlairIcon(flair), size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      _getFlairLabel(flair),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
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

  /// Vibrant flair colors — always colorful regardless of monochrome theme
  static const Color _flairCyan = Color(0xFF06B6D4);
  static const Color _flairGreen = Color(0xFF22C55E);
  static const Color _flairOrange = Color(0xFFF97316);
  static const Color _flairPurple = Color(0xFFA855F7);
  static const Color _flairYellow = Color(0xFFEAB308);
  static const Color _flairBlue = Color(0xFF3B82F6);

  Color _getFlairColor(String flair) {
    switch (flair) {
      case 'fitness':
        return _flairCyan;
      case 'progress':
        return _flairGreen;
      case 'milestone':
        return _flairOrange;
      case 'nutrition':
        return _flairPurple;
      case 'motivation':
        return _flairYellow;
      case 'question':
        return _flairBlue;
      default:
        return _flairCyan;
    }
  }

  IconData _getFlairIcon(String flair) {
    switch (flair) {
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'progress':
        return Icons.trending_up_rounded;
      case 'milestone':
        return Icons.emoji_events_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      case 'motivation':
        return Icons.bolt_rounded;
      case 'question':
        return Icons.help_outline_rounded;
      default:
        return Icons.tag_rounded;
    }
  }

  String _getFlairLabel(String flair) {
    switch (flair) {
      case 'fitness':
        return 'Fitness';
      case 'progress':
        return 'Progress';
      case 'milestone':
        return 'Milestone';
      case 'nutrition':
        return 'Nutrition';
      case 'motivation':
        return 'Motivation';
      case 'question':
        return 'Question';
      default:
        return flair[0].toUpperCase() + flair.substring(1);
    }
  }

  Widget _buildWorkoutContent(BuildContext context) {
    final workoutName = widget.activityData['workout_name'] ?? 'a workout';
    final duration = widget.activityData['duration_minutes'] ?? 0;
    final exercises = widget.activityData['exercises_count'] ?? 0;
    final totalVolume = widget.activityData['total_volume'];

    final verb = widget.activityType == 'workout_shared' ? 'shared' : 'completed';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/shared-workout', extra: {
          'activityId': widget.activityId,
          'currentUserId': widget.currentUserId,
          'posterName': widget.userName,
          'posterAvatar': widget.userAvatar,
          'activityType': widget.activityType,
          'activityData': widget.activityData,
          'savedWorkoutsService': _savedWorkoutsService,
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display badges if available
          if (widget.badges != null && widget.badges!.isNotEmpty) ...[
            _buildBadges(context, widget.badges!),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(text: '$verb '),
                      TextSpan(
                        text: workoutName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textMuted,
              ),
            ],
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

        // Mini leaderboard
        _ChallengeLeaderboard(activityId: widget.activityId),
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

        // Mini leaderboard
        _ChallengeLeaderboard(activityId: widget.activityId),
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

/// Mini leaderboard widget shown on challenge_victory / challenge_completed activity cards.
/// Fetches data lazily and only shows if there are 2+ entries.
class _ChallengeLeaderboard extends StatefulWidget {
  final String activityId;

  const _ChallengeLeaderboard({required this.activityId});

  @override
  State<_ChallengeLeaderboard> createState() => _ChallengeLeaderboardState();
}

class _ChallengeLeaderboardState extends State<_ChallengeLeaderboard> {
  List<Map<String, dynamic>>? _entries;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
      final service = ChallengesService(ApiClient(storage));
      final entries = await service.getActivityLeaderboard(activityId: widget.activityId);
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [ChallengeLeaderboard] Error: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_error || _entries == null || _entries!.length < 2) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard_rounded, size: 16, color: AppColors.orange),
                const SizedBox(width: 6),
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._entries!.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final name = data['user_name'] as String? ?? 'Unknown';
              final didBeat = data['did_beat'] as bool? ?? false;
              final duration = data['duration_minutes'];
              final volume = data['total_volume'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Position
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: index == 0 ? const Color(0xFFFFD700) : AppColors.textMuted,
                        ),
                      ),
                    ),
                    // Name
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Beat indicator
                    if (didBeat)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                      ),
                    // Stats
                    if (duration != null)
                      Text(
                        '${duration}m',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (duration != null && volume != null)
                      Text(
                        ' | ',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    if (volume != null)
                      Text(
                        '${volume is double ? volume.toStringAsFixed(0) : volume} lbs',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
