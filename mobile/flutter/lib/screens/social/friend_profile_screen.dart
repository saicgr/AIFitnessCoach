import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/main_shell.dart';
import 'conversation_screen.dart';

class FriendProfileScreen extends ConsumerStatefulWidget {
  final String targetUserId;

  const FriendProfileScreen({super.key, required this.targetUserId});

  @override
  ConsumerState<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  String? _userId;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _socialSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        setState(() => _userId = userId);
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_userId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final socialService = ref.read(socialServiceProvider);
      final results = await Future.wait<Map<String, dynamic>>([
        socialService.getUserProfile(
          userId: _userId!,
          targetUserId: widget.targetUserId,
        ),
        socialService.getSocialSummary(
          userId: _userId!,
          targetUserId: widget.targetUserId,
        ),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0];
          _socialSummary = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load friend profile: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleMessage() async {
    if (_userId == null) return;
    HapticFeedback.lightImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      final conversation = await socialService.getOrCreateConversation(
        userId: _userId!,
        otherUserId: widget.targetUserId,
      );

      if (mounted) {
        Navigator.push(
          context,
          AppPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: conversation['id'] as String? ?? '',
              otherUserId: widget.targetUserId,
              otherUserName: _profile?['name'] as String? ?? 'User',
              otherUserAvatar: _profile?['avatar_url'] as String?,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to get/create conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open conversation')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Profile',
        actions: [
          PillAppBarAction(
            icon: Icons.more_vert,
            onTap: () async {
              final value = await showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                items: [
                  const PopupMenuItem(
                    value: 'block',
                    child: Text('Block User', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
              if (value == 'block') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Block User'),
                    content: const Text(
                      'This user will not be able to see your content or message you. You can unblock them later.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Block'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await ref.read(socialServiceProvider).blockUser(widget.targetUserId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User blocked')),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to block user: $e')),
                      );
                    }
                  }
                }
              }
            },
          ),
        ],
      ),
      body: _buildBody(context, isDark),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_isLoading) {
      return AppLoading.fullScreen();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            )),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final colors = ref.colors(context);
    final name = _profile?['name'] as String? ?? 'User';
    final avatarUrl = _profile?['avatar_url'] as String?;
    final bio = _profile?['bio'] as String?;
    final isFriend = _profile?['is_friend'] as bool? ?? false;
    final isFollowing = _profile?['is_following'] as bool? ?? false;

    final friendsCount = _socialSummary?['friends_count'] as int? ?? 0;
    final followersCount = _socialSummary?['followers_count'] as int? ?? 0;
    final followingCount = _socialSummary?['following_count'] as int? ?? 0;
    final workoutsCount = _profile?['total_workouts'] as int? ?? 0;
    final trophiesCount = _profile?['total_achievements'] as int? ?? 0;
    final streak = _profile?['current_streak'] as int? ?? 0;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header
            _buildHeader(context, isDark, colors, name, avatarUrl, bio, isFriend, isFollowing),
            const SizedBox(height: 24),
            // Stats Row
            _buildStatsRow(isDark, colors, workoutsCount, friendsCount, trophiesCount, streak),
            const SizedBox(height: 24),
            // Social counts
            _buildSocialCounts(isDark, colors, followersCount, followingCount, friendsCount),
            const SizedBox(height: 24),
            // Recent activity section
            _buildRecentActivity(isDark, colors),
            const SizedBox(height: 100), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ThemeColors colors,
      String name, String? avatarUrl, String? bio, bool isFriend, bool isFollowing) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 44,
            backgroundColor: colors.accent.withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              bio,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              // Message button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleMessage,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accent,
                    side: BorderSide(color: colors.accent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Relationship badge
              Expanded(
                child: _buildRelationshipButton(colors, isFriend, isFollowing),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipButton(ThemeColors colors, bool isFriend, bool isFollowing) {
    if (isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_rounded, size: 18, color: colors.accent),
            const SizedBox(width: 6),
            Text(
              'Friends',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _handleFollow(isFollowing),
      icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add, size: 18),
      label: Text(isFollowing ? 'Following' : 'Follow'),
      style: OutlinedButton.styleFrom(
        foregroundColor: isFollowing ? (AppColors.textMuted) : colors.accent,
        side: BorderSide(
          color: isFollowing
              ? AppColors.textMuted.withValues(alpha: 0.3)
              : colors.accent.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleFollow(bool isCurrentlyFollowing) async {
    if (_userId == null) return;
    HapticFeedback.mediumImpact();

    try {
      final socialService = ref.read(socialServiceProvider);
      if (isCurrentlyFollowing) {
        await socialService.unfollowUser(
          userId: _userId!,
          followingId: widget.targetUserId,
        );
      } else {
        await socialService.followUser(
          userId: _userId!,
          followingId: widget.targetUserId,
        );
      }
      // Refresh profile
      await _loadProfile();
      // Invalidate related providers
      ref.invalidate(friendsListProvider(_userId!));
      ref.invalidate(followersListProvider(_userId!));
      ref.invalidate(followingListProvider(_userId!));
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update follow status')),
        );
      }
    }
  }

  Widget _buildStatsRow(bool isDark, ThemeColors colors,
      int workouts, int friends, int trophies, int streak) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildStatItem(Icons.fitness_center_rounded, '$workouts', 'Workouts', AppColors.purple, textMuted),
          _buildStatDivider(cardBorder),
          _buildStatItem(Icons.people_rounded, '$friends', 'Friends', AppColors.cyan, textMuted),
          _buildStatDivider(cardBorder),
          _buildStatItem(Icons.emoji_events_rounded, '$trophies', 'Trophies', AppColors.orange, textMuted),
          _buildStatDivider(cardBorder),
          _buildStatItem(Icons.local_fire_department, '$streak', 'Streak', AppColors.pink, textMuted),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color, Color textMuted) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(Color borderColor) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: borderColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildSocialCounts(bool isDark, ThemeColors colors,
      int followers, int following, int friends) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('$followers', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary,
                )),
                const SizedBox(height: 2),
                Text('Followers', style: TextStyle(fontSize: 12, color: textMuted)),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: cardBorder.withValues(alpha: 0.3)),
          Expanded(
            child: Column(
              children: [
                Text('$following', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary,
                )),
                const SizedBox(height: 2),
                Text('Following', style: TextStyle(fontSize: 12, color: textMuted)),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: cardBorder.withValues(alpha: 0.3)),
          Expanded(
            child: Column(
              children: [
                Text('$friends', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary,
                )),
                const SizedBox(height: 2),
                Text('Friends', style: TextStyle(fontSize: 12, color: textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark, ThemeColors colors) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Member Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : AppColorsLight.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.person_outline_rounded, size: 40, color: textMuted),
              const SizedBox(height: 8),
              Text(
                'More details coming soon',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'Workout history, PRs, and trophies\nwill be shown here.',
                style: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
