import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/app_snackbar.dart';

/// Comments Sheet - Bottom sheet showing comments for an activity
class CommentsSheet extends ConsumerStatefulWidget {
  final String activityId;

  const CommentsSheet({super.key, required this.activityId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  int _totalCount = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      _userId = authState.user?.id;
      _loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final socialService = ref.read(socialServiceProvider);
      final result = await socialService.getComments(
        activityId: widget.activityId,
      );

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(result['comments'] ?? []);
          _totalCount = result['total_count'] as int? ?? _comments.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _userId == null || _isSending) return;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      final newComment = await socialService.addComment(
        userId: _userId!,
        activityId: widget.activityId,
        text: text,
      );

      if (mounted) {
        _commentController.clear();
        // Add optimistically at the top (comments are desc by created_at)
        setState(() {
          _comments.insert(0, newComment);
          _totalCount++;
          _isSending = false;
        });

        // Invalidate feed to update comment counts
        ref.invalidate(activityFeedProvider(_userId!));
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (mounted) {
        setState(() => _isSending = false);
        AppSnackBar.error(context, 'Failed to add comment');
      }
    }
  }

  Future<void> _deleteComment(String commentId, int index) async {
    if (_userId == null) return;
    HapticFeedback.mediumImpact();

    // Remove optimistically
    final removed = _comments[index];
    setState(() {
      _comments.removeAt(index);
      _totalCount--;
    });

    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.deleteComment(
        userId: _userId!,
        commentId: commentId,
      );

      // Invalidate feed to update comment counts
      ref.invalidate(activityFeedProvider(_userId!));
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      if (mounted) {
        // Restore on failure
        setState(() {
          _comments.insert(index, removed);
          _totalCount++;
        });
        AppSnackBar.error(context, 'Failed to delete comment');
      }
    }
  }

  void _showDeleteConfirmation(String commentId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId, index);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text(
                      'Comments${_totalCount > 0 ? ' ($_totalCount)' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      iconSize: 24,
                    ),
                  ],
                ),
              ),

              Divider(color: cardBorder.withValues(alpha: 0.3), height: 1),

              // Comments list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Be the first to comment!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textMuted.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: _comments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return _buildCommentTile(comment, index, isDark);
                            },
                          ),
              ),

              // Input area
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 12,
                  bottom: bottomInset > 0 ? 12 : MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: cardBorder.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.pureBlack.withValues(alpha: 0.5)
                              : AppColorsLight.pureWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: cardBorder.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: cardBorder.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: ref.colors(context).accent,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSending ? null : _addComment,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: ref.colors(context).accent,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentTile(
    Map<String, dynamic> comment,
    int index,
    bool isDark,
  ) {
    final commentId = comment['id'] as String? ?? '';
    final userName = comment['user_name'] as String? ?? 'User';
    final userAvatar = comment['user_avatar'] as String?;
    final text = comment['comment_text'] as String? ?? '';
    final createdAt = _parseTimestamp(comment['created_at']);
    final commentUserId = comment['user_id'] as String? ?? '';
    final isOwn = commentUserId == _userId;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showCommentActions(commentId, text, index, isOwn);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
            backgroundImage:
                userAvatar != null ? NetworkImage(userAvatar) : null,
            child: userAvatar == null
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.cyan,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          // Delete icon for own comments
          if (isOwn)
            IconButton(
              onPressed: () => _showDeleteConfirmation(commentId, index),
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  void _showCommentActions(
    String commentId,
    String text,
    int index,
    bool isOwn,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: text));
                AppSnackBar.info(this.context, 'Comment copied');
              },
            ),
            if (isOwn)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.red),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(commentId, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
