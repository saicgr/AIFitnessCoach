import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../tabs/feed_tab.dart' show storiesAutoScrollProvider;
import '../story_create_screen.dart';
import '../story_viewer_screen.dart';

/// Stories ring widget (F11) - Shows friends' stories in a horizontal scrollable row
/// Displays above the segmented tab bar on the Social screen.
/// First item is "Your Story" with + icon overlay.
class StoriesRing extends ConsumerStatefulWidget {
  const StoriesRing({super.key});

  @override
  ConsumerState<StoriesRing> createState() => _StoriesRingState();
}

class _StoriesRingState extends ConsumerState<StoriesRing> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _disposed = false;

  void _startAutoScroll() {
    _stopAutoScroll();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_disposed || !_scrollController.hasClients) return;
      final current = _scrollController.offset;
      final max = _scrollController.position.maxScrollExtent;
      if (current >= max) {
        // Loop back to start
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.animateTo(
          (current + 56).clamp(0.0, max),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storiesAsync = ref.watch(storiesFeedProvider);
    final colors = ref.colors(context);

    // Start/stop auto-scroll when provider changes
    ref.listen<bool>(storiesAutoScrollProvider, (prev, next) {
      if (next) {
        _startAutoScroll();
      } else {
        _stopAutoScroll();
      }
    });

    return storiesAsync.when(
      loading: () => _buildShimmerRow(isDark),
      error: (_, __) => _buildRowWithYourStory(context, isDark, colors, {}),
      data: (stories) {
        // Group stories by user
        final Map<String, List<Map<String, dynamic>>> storiesByUser = {};
        for (final story in stories) {
          final userId = story['user_id'] as String? ?? '';
          storiesByUser.putIfAbsent(userId, () => []).add(story);
        }

        return _buildRowWithYourStory(context, isDark, colors, storiesByUser);
      },
    );
  }

  Widget _buildRowWithYourStory(
    BuildContext context,
    bool isDark,
    ThemeColors colors,
    Map<String, List<Map<String, dynamic>>> storiesByUser,
  ) {
    // Total items: 1 (Your Story) + number of users with stories
    final totalItems = 1 + storiesByUser.length;

    return SizedBox(
      height: 80,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // User-initiated drag → disable stories auto-scroll
          if (notification is UserScrollNotification &&
              notification.direction != ScrollDirection.idle) {
            if (ref.read(storiesAutoScrollProvider)) {
              ref.read(storiesAutoScrollProvider.notifier).state = false;
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildYourStoryItem(context, isDark, colors);
            }

            final userIndex = index - 1;
            final userId = storiesByUser.keys.elementAt(userIndex);
            final userStories = storiesByUser[userId]!;
            final firstStory = userStories.first;
            final userName = firstStory['user_name'] as String? ?? 'User';
            final userAvatar = firstStory['user_avatar'] as String?;
            final hasUnviewed = userStories.any(
              (s) => !(s['viewed'] as bool? ?? false),
            );

            return _buildStoryItem(
              context: context,
              isDark: isDark,
              colors: colors,
              userName: userName,
              userAvatar: userAvatar,
              hasUnviewed: hasUnviewed,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => StoryViewerScreen(
                      storiesByUser: storiesByUser,
                      initialUserIndex: userIndex,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildYourStoryItem(BuildContext context, bool isDark, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => const StoryCreateScreen(),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                    child: Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                ),
                // + icon overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 12,
                      color: colors.accentContrast,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 52,
              child: Text(
                'Your Story',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem({
    required BuildContext context,
    required bool isDark,
    required ThemeColors colors,
    required String userName,
    required String? userAvatar,
    required bool hasUnviewed,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with gradient ring
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? LinearGradient(
                        colors: [
                          colors.accent,
                          colors.accent.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasUnviewed
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.cardBorder
                            : AppColorsLight.cardBorder,
                        width: 2,
                      ),
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 20,
                backgroundColor:
                    isDark ? AppColors.elevated : AppColorsLight.elevated,
                backgroundImage:
                    userAvatar != null ? NetworkImage(userAvatar) : null,
                child: userAvatar == null
                    ? Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            // User name
            SizedBox(
              width: 52,
              child: Text(
                userName.length > 8
                    ? '${userName.substring(0, 8)}...'
                    : userName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: hasUnviewed
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColorsLight.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer loading placeholder for stories
  Widget _buildShimmerRow(bool isDark) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.elevated
                        : AppColorsLight.elevated,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isDark
                        ? AppColors.elevated
                        : AppColorsLight.elevated,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
