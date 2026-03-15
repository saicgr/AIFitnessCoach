import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/pill_app_bar.dart';
import 'widgets/activity_card.dart';
import 'widgets/comments_sheet.dart';
import '../../widgets/glass_sheet.dart';

/// Screen that shows all public posts with a specific hashtag.
/// Supports pagination via infinite scroll.
class HashtagFeedScreen extends ConsumerStatefulWidget {
  final String hashtagName;

  const HashtagFeedScreen({super.key, required this.hashtagName});

  @override
  ConsumerState<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends ConsumerState<HashtagFeedScreen> {
  final List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
      _error = null;
    });
    try {
      final socialService = ref.read(socialServiceProvider);
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id ?? '';
      final result = await socialService.getPostsByHashtag(
        widget.hashtagName,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(
              List<Map<String, dynamic>>.from(result['posts'] ?? result['items'] ?? []));
          _hasMore = result['has_more'] as bool? ?? false;
          _offset = _posts.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hashtag posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load posts';
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final socialService = ref.read(socialServiceProvider);
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id ?? '';
      final result = await socialService.getPostsByHashtag(
        widget.hashtagName,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _posts.addAll(
              List<Map<String, dynamic>>.from(result['posts'] ?? result['items'] ?? []));
          _hasMore = result['has_more'] as bool? ?? false;
          _offset = _posts.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more hashtag posts: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Future<void> _handleReaction(
      String activityId, String reactionType, String userId) async {
    HapticFeedback.lightImpact();
    try {
      final socialService = ref.read(socialServiceProvider);
      if (reactionType == 'remove') {
        await socialService.removeReaction(
            userId: userId, activityId: activityId);
      } else {
        await socialService.addReaction(
            userId: userId,
            activityId: activityId,
            reactionType: reactionType);
      }
      // Reload to refresh reaction counts
      await _loadPosts();
    } catch (e) {
      debugPrint('Error handling reaction: $e');
    }
  }

  void _handleComment(String activityId) {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => CommentsSheet(activityId: activityId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(title: '#${widget.hashtagName}'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _loadPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 48,
                            color:
                                AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No posts with #${widget.hashtagName}',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final activity = _posts[index];
                          final activityId =
                              activity['id'] as String? ?? '';
                          final postUserId =
                              activity['user_id'] as String? ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ActivityCard(
                              activityId: activityId,
                              currentUserId: userId,
                              postUserId: postUserId,
                              userName: activity['user_name']
                                      as String? ??
                                  'User',
                              userAvatar:
                                  activity['user_avatar'] as String?,
                              activityType: activity['activity_type']
                                      as String? ??
                                  'manual_post',
                              activityData:
                                  activity['activity_data']
                                          as Map<String, dynamic>? ??
                                      {},
                              timestamp: _parseTimestamp(
                                  activity['created_at']),
                              reactionCount:
                                  activity['reaction_count'] as int? ??
                                      0,
                              commentCount:
                                  activity['comment_count'] as int? ?? 0,
                              hasUserReacted:
                                  activity['user_has_reacted']
                                          as bool? ??
                                      false,
                              userReactionType:
                                  activity['user_reaction_type']
                                      as String?,
                              onReact: (reactionType) =>
                                  _handleReaction(
                                      activityId, reactionType, userId),
                              onComment: () =>
                                  _handleComment(activityId),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
