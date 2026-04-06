import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/challenges_service.dart';
import '../../../data/services/saved_workouts_service.dart';
import '../../../data/services/social_service.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/social_video_player.dart';
import '../hashtag_feed_screen.dart';
import '../friend_profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;


part 'activity_card_part_reaction_type.dart';
part 'activity_card_part_challenge_leaderboard.dart';

part 'activity_card_ui.dart';


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
                Clipboard.setData(const ClipboardData(text: 'https://fitwiz.us'));
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

  /// Show report dialog (F9 - full report with reason selection and description)
  void _showReportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    String? selectedReason;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final reasons = ['spam', 'inappropriate', 'harassment', 'other'];
          final reasonLabels = {
            'spam': 'Spam or misleading',
            'inappropriate': 'Inappropriate content',
            'harassment': 'Harassment or bullying',
            'other': 'Other',
          };

          return AlertDialog(
            backgroundColor: elevated,
            title: const Text('Report Post'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why are you reporting this post?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ...reasons.map((reason) {
                    final isSelected = selectedReason == reason;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setDialogState(() => selectedReason = reason);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 20,
                              color: isSelected
                                  ? Theme.of(dialogContext).colorScheme.primary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              reasonLabels[reason] ?? reason,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Additional details (optional)',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.pureBlack.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedReason == null
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        HapticFeedback.lightImpact();
                        await _submitReport(
                          selectedReason!,
                          descriptionController.text.trim(),
                        );
                      },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      descriptionController.dispose();
    });
  }

  /// Submit report to backend
  Future<void> _submitReport(String reason, String description) async {
    try {
      final storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
      final socialService = SocialService(ApiClient(storage));
      await socialService.reportContent(
        contentType: 'post',
        contentId: widget.activityId,
        reportedUserId: widget.postUserId,
        reason: reason,
        description: description.isNotEmpty ? description : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Report submitted. Thank you for helping keep our community safe.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

  void _navigateToMentionedUser(BuildContext context, String username) async {
    try {
      final storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
      final socialService = SocialService(ApiClient(storage));
      final result = await socialService.searchUsers(
        userId: widget.currentUserId,
        query: username,
        limit: 1,
      );

      final users = result['results'] as List<dynamic>?;
      if (users != null && users.isNotEmpty) {
        final user = users[0] as Map<String, dynamic>;
        final userId = user['id'] as String?;
        if (userId != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendProfileScreen(targetUserId: userId),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Error navigating to mentioned user: $e');
    }
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

  Widget _buildGenericContent(BuildContext context) {
    // Try to show caption if available for unknown activity types
    final caption = widget.activityData['caption'] as String?;
    if (caption != null && caption.isNotEmpty) {
      return Text(caption, style: const TextStyle(fontSize: 15));
    }
    return const Text('shared an update');
  }
}
