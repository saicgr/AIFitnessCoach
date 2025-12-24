import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/leaderboard_service.dart';
import '../../../data/services/challenges_service.dart';
import '../../../data/services/api_client.dart';
import '../widgets/empty_state.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Leaderboard Tab - Global, country, and friends rankings
class LeaderboardTab extends ConsumerStatefulWidget {
  const LeaderboardTab({super.key});

  @override
  ConsumerState<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<LeaderboardTab>
    with SingleTickerProviderStateMixin {
  late TabController _typeTabController;
  late LeaderboardService _leaderboardService;
  late ChallengesService _challengesService;

  // State
  String? _userId;
  bool _isLoading = true;
  bool _isUnlocked = false;
  Map<String, dynamic>? _unlockStatus;
  Map<String, dynamic>? _leaderboardData;

  // Filters
  LeaderboardType _selectedType = LeaderboardType.challengeMasters;
  LeaderboardFilter _selectedFilter = LeaderboardFilter.global;
  String? _userCountryCode;

  @override
  void initState() {
    super.initState();
    _typeTabController = TabController(length: 4, vsync: this);
    _typeTabController.addListener(_onTypeTabChanged);

    _leaderboardService = LeaderboardService(ref.read(apiClientProvider));
    _challengesService = ChallengesService(ref.read(apiClientProvider));

    _loadUserId();
  }

  @override
  void dispose() {
    _typeTabController.removeListener(_onTypeTabChanged);
    _typeTabController.dispose();
    super.dispose();
  }

  void _onTypeTabChanged() {
    if (!_typeTabController.indexIsChanging) {
      setState(() {
        _selectedType = LeaderboardType.values[_typeTabController.index];
      });
      _loadLeaderboard();
    }
  }

  Future<void> _loadUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted) {
      setState(() {
        _userId = userId;
      });
      _loadUnlockStatus();
    }
  }

  Future<void> _loadUnlockStatus() async {
    if (_userId == null) return;

    try {
      final status = await _leaderboardService.getUnlockStatus(userId: _userId!);

      if (mounted) {
        setState(() {
          _unlockStatus = status;
          _isUnlocked = status['is_unlocked'] ?? false;
        });

        // Load leaderboard if unlocked
        if (_isUnlocked || _selectedFilter == LeaderboardFilter.friends) {
          _loadLeaderboard();
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading unlock status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _leaderboardService.getLeaderboard(
        userId: _userId!,
        leaderboardType: _selectedType,
        filterType: _selectedFilter,
        countryCode: _selectedFilter == LeaderboardFilter.country ? _userCountryCode : null,
        limit: 100,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _leaderboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading leaderboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show locked state if global leaderboard not unlocked
    if (!_isUnlocked && _selectedFilter == LeaderboardFilter.global) {
      return _buildLockedState(context, isDark);
    }

    return Column(
      children: [
        // Leaderboard Type Tabs
        Container(
          color: backgroundColor,
          child: TabBar(
            controller: _typeTabController,
            indicatorColor: AppColors.orange,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: AppColors.textMuted,
            isScrollable: true,
            tabs: [
              _buildTypeTab('🏆', 'Masters'),
              _buildTypeTab('🏋️', 'Volume'),
              _buildTypeTab('🔥', 'Streaks'),
              _buildTypeTab('⚡', 'This Week'),
            ],
          ),
        ),

        // Filter Chips
        _buildFilterChips(isDark),

        // Leaderboard Content
        Expanded(
          child: _leaderboardData == null
              ? _buildEmptyState(context, isDark)
              : _buildLeaderboardList(context, isDark),
        ),
      ],
    );
  }

  Widget _buildTypeTab(String emoji, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              '🌍 Global',
              LeaderboardFilter.global,
              isDark,
              enabled: _isUnlocked,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              '${_userCountryCode != null ? _leaderboardService.getCountryFlag(_userCountryCode!) : '🌍'} Country',
              LeaderboardFilter.country,
              isDark,
              enabled: _isUnlocked && _userCountryCode != null,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              '👥 Friends',
              LeaderboardFilter.friends,
              isDark,
              enabled: true, // Always enabled
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, LeaderboardFilter filter, bool isDark, {bool enabled = true}) {
    final isSelected = _selectedFilter == filter;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: enabled ? (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
          _loadLeaderboard();
        }
      } : null,
      selectedColor: AppColors.orange.withValues(alpha: 0.2),
      checkmarkColor: AppColors.orange,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      labelStyle: TextStyle(
        color: enabled
            ? (isSelected ? AppColors.orange : (isDark ? Colors.white : Colors.black))
            : AppColors.textMuted,
      ),
    );
  }

  Widget _buildLockedState(BuildContext context, bool isDark) {
    final workoutsCompleted = _unlockStatus?['workouts_completed'] ?? 0;
    final workoutsNeeded = _unlockStatus?['workouts_needed'] ?? 10;
    final progress = _unlockStatus?['progress_percentage'] ?? 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 50,
                  color: AppColors.orange,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Global Leaderboard Locked',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              _unlockStatus?['unlock_message'] ?? 'Complete more workouts to unlock!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Progress Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '$workoutsCompleted / 10 workouts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Friends Leaderboard Button
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = LeaderboardFilter.friends;
                });
                _loadLeaderboard();
              },
              icon: const Icon(Icons.people_outline),
              label: const Text('View Friends Leaderboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.cyan),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return SocialEmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'No Rankings Yet',
      description: _selectedFilter == LeaderboardFilter.friends
          ? 'Add friends to see their rankings!'
          : 'Complete challenges to appear on the leaderboard!',
      actionLabel: null,
      onAction: null,
    );
  }

  Widget _buildLeaderboardList(BuildContext context, bool isDark) {
    final entries = (_leaderboardData?['entries'] as List?) ?? [];
    final userRank = _leaderboardData?['user_rank'] as Map<String, dynamic>?;
    final lastUpdated = _leaderboardData?['last_updated'] as String?;
    final refreshesIn = _leaderboardData?['refreshes_in'] as String?;

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: CustomScrollView(
        slivers: [
          // User's Rank Card (Sticky)
          if (userRank != null)
            SliverToBoxAdapter(
              child: _buildUserRankCard(context, isDark, userRank),
            ),

          // Last Updated Info
          if (lastUpdated != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Updates in ${refreshesIn ?? "soon"} • Updated ${_formatTimestamp(lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Leaderboard Entries
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = entries[index] as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLeaderboardEntry(context, isDark, entry),
                  );
                },
                childCount: entries.length,
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard(BuildContext context, bool isDark, Map<String, dynamic> userRank) {
    final rank = userRank['rank'] as int;
    final totalUsers = userRank['total_users'] as int;
    final percentile = userRank['percentile'] as num;
    final userStats = userRank['user_stats'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.2),
            AppColors.cyan.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.orange, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR RANK',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '#$rank',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'of $totalUsers',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Top ${percentile.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // User's stats
          if (userStats != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildStatsRow(context, userStats),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(BuildContext context, bool isDark, Map<String, dynamic> entry) {
    final rank = entry['rank'] as int;
    final userName = entry['user_name'] as String? ?? 'User';
    final avatarUrl = entry['avatar_url'] as String?;
    final countryCode = entry['country_code'] as String?;
    final isFriend = entry['is_friend'] as bool? ?? false;
    final isCurrentUser = entry['is_current_user'] as bool? ?? false;

    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final highlightColor = isCurrentUser
        ? AppColors.cyan.withValues(alpha: 0.1)
        : (isFriend ? AppColors.green.withValues(alpha: 0.05) : cardColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlightColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.cyan.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank/Medal
          SizedBox(
            width: 50,
            child: Text(
              rank <= 3 ? _leaderboardService.getMedalEmoji(rank) : '#$rank',
              style: TextStyle(
                fontSize: rank <= 3 ? 28 : 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? const Icon(Icons.person) : null,
          ),

          const SizedBox(width: 12),

          // Name and Country
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (countryCode != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _leaderboardService.getCountryFlag(countryCode),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                    if (isFriend && !isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '✓ Friend',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _buildStatsRow(context, entry),
              ],
            ),
          ),

          // Challenge Button
          if (!isCurrentUser)
            IconButton(
              onPressed: () => _showChallengeOptions(context, entry),
              icon: Icon(
                isFriend ? Icons.emoji_events : Icons.flash_on,
                color: isFriend ? AppColors.orange : AppColors.cyan,
              ),
              tooltip: isFriend ? 'Challenge Friend' : 'Beat Their Best',
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic> entry) {
    final List<Widget> stats = [];

    // Challenge Masters stats
    if (_selectedType == LeaderboardType.challengeMasters) {
      final wins = entry['first_wins'] ?? 0;
      final winRate = entry['win_rate'] ?? 0.0;
      stats.addAll([
        _buildStatItem('🏆', '$wins wins'),
        _buildStatItem('📊', '${winRate.toStringAsFixed(1)}%'),
      ]);
    }
    // Volume Kings stats
    else if (_selectedType == LeaderboardType.volumeKings) {
      final volume = entry['total_volume_lbs'] ?? 0.0;
      final workouts = entry['total_workouts'] ?? 0;
      stats.addAll([
        _buildStatItem('🏋️', '${(volume / 1000).toStringAsFixed(1)}K lbs'),
        _buildStatItem('💪', '$workouts workouts'),
      ]);
    }
    // Streaks stats
    else if (_selectedType == LeaderboardType.streaks) {
      final currentStreak = entry['current_streak'] ?? 0;
      final bestStreak = entry['best_streak'] ?? 0;
      stats.addAll([
        _buildStatItem('🔥', '$currentStreak days'),
        _buildStatItem('⭐', 'Best: $bestStreak'),
      ]);
    }
    // Weekly stats
    else if (_selectedType == LeaderboardType.weeklyChallenges) {
      final weeklyWins = entry['weekly_wins'] ?? 0;
      final weeklyRate = entry['weekly_win_rate'] ?? 0.0;
      stats.addAll([
        _buildStatItem('⚡', '$weeklyWins wins'),
        _buildStatItem('📊', '${weeklyRate.toStringAsFixed(1)}%'),
      ]);
    }

    return Row(
      children: stats.expand((w) => [w, const SizedBox(width: 12)]).take(stats.length * 2 - 1).toList(),
    );
  }

  Widget _buildStatItem(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  void _showChallengeOptions(BuildContext context, Map<String, dynamic> entry) {
    final isFriend = entry['is_friend'] as bool? ?? false;
    final userName = entry['user_name'] as String? ?? 'User';
    final userId = entry['user_id'] as String;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Challenge $userName',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            if (isFriend) ...[
              // Direct challenge for friends
              ListTile(
                leading: const Icon(Icons.emoji_events, color: AppColors.orange),
                title: const Text('Challenge Directly'),
                subtitle: const Text('Send a direct challenge notification'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show ChallengeFriendsDialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
              const Divider(),
            ],

            // Async challenge (Beat Their Best)
            ListTile(
              leading: const Icon(Icons.flash_on, color: AppColors.cyan),
              title: const Text('Beat Their Best'),
              subtitle: Text(
                isFriend
                    ? 'Challenge without notification (async)'
                    : 'Try to beat their record!',
              ),
              onTap: () async {
                Navigator.pop(context);
                await _createAsyncChallenge(userId, userName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAsyncChallenge(String targetUserId, String targetUserName) async {
    if (_userId == null) return;

    try {
      await _leaderboardService.createAsyncChallenge(
        userId: _userId!,
        targetUserId: targetUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge created! Beat $targetUserName\'s record!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create challenge: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return timeago.format(dt);
    } catch (e) {
      return 'recently';
    }
  }
}
