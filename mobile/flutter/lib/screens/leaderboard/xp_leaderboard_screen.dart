import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/user_xp.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/xp_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';

/// XP Leaderboard screen showing top users by level and XP
class XPLeaderboardScreen extends ConsumerStatefulWidget {
  const XPLeaderboardScreen({super.key});

  @override
  ConsumerState<XPLeaderboardScreen> createState() => _XPLeaderboardScreenState();
}

class _XPLeaderboardScreenState extends ConsumerState<XPLeaderboardScreen> {
  List<XPLeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _currentUserId;
  int? _currentUserRank;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authStateProvider);
      _currentUserId = authState.user?.id;

      final repository = XPRepository(ref.read(apiClientProvider));
      final entries = await repository.getXPLeaderboard(limit: 100);

      // Find current user's rank
      if (_currentUserId != null) {
        final index = entries.indexWhere((e) => e.userId == _currentUserId);
        if (index >= 0) {
          _currentUserRank = index + 1;
        }
      }

      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading XP leaderboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColorsLight.background;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    final userXp = ref.watch(xpProvider).userXp;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard, color: accentColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'XP Leaderboard',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Current user rank card
            if (userXp != null && _currentUserRank != null)
              SliverToBoxAdapter(
                child: _buildCurrentUserCard(
                  userXp,
                  _currentUserRank!,
                  isDark,
                  textColor,
                  textMuted,
                  elevatedColor,
                  cardBorder,
                  accentColor,
                ),
              ),

            // Loading indicator
            if (_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: accentColor),
                  ),
                ),
              ),

            // Empty state
            if (!_isLoading && _entries.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(textMuted),
              ),

            // Leaderboard entries
            if (!_isLoading && _entries.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = _entries[index];
                      final rank = index + 1;
                      final isCurrentUser = entry.userId == _currentUserId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildLeaderboardEntry(
                          entry,
                          rank,
                          isCurrentUser,
                          isDark,
                          textColor,
                          textMuted,
                          elevatedColor,
                          cardBorder,
                          accentColor,
                        ),
                      );
                    },
                    childCount: _entries.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard(
    UserXP userXp,
    int rank,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
  ) {
    final titleColor = Color(userXp.xpTitle.colorValue);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Level ${userXp.currentLevel}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: titleColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userXp.xpTitle.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                userXp.formattedTotalXp,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              Text(
                'Total XP',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(
    XPLeaderboardEntry entry,
    int rank,
    bool isCurrentUser,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
  ) {
    // Get title color based on level
    final titleColor = _getTitleColorForLevel(entry.currentLevel);

    // Rank colors for top 3
    Color? rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankIcon = Icons.emoji_events;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? accentColor.withValues(alpha: 0.1)
            : elevatedColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? accentColor.withValues(alpha: 0.4)
              : cardBorder,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 24)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: titleColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.currentLevel.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser ? accentColor : textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: titleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lvl ${entry.currentLevel}',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // XP
          Text(
            _formatXP(entry.totalXp),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? accentColor : textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No leaderboard data yet.\nStart earning XP to climb the ranks!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTitleColorForLevel(int level) {
    if (level <= 10) return const Color(0xFF9E9E9E); // Gray - Beginner
    if (level <= 25) return const Color(0xFF8BC34A); // Light Green - Novice
    if (level <= 50) return const Color(0xFF4CAF50); // Green - Apprentice
    if (level <= 75) return const Color(0xFF2196F3); // Blue - Athlete
    if (level <= 100) return const Color(0xFF9C27B0); // Purple - Elite
    if (level <= 125) return const Color(0xFFFF9800); // Orange - Master
    if (level <= 150) return const Color(0xFFFF5722); // Deep Orange - Champion
    if (level <= 175) return const Color(0xFFFFD700); // Gold - Legend
    if (level <= 200) return const Color(0xFFE040FB); // Pink - Mythic
    if (level <= 225) return const Color(0xFF00E5FF); // Cyan - Immortal
    return const Color(0xFFFF1744); // Red - Transcendent
  }

  String _formatXP(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }
}
