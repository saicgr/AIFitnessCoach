import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/leaderboard_service.dart';
import '../../../data/services/challenges_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/repositories/auth_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/leaderboard_locked_state.dart';
import '../widgets/leaderboard_rank_card.dart';
import '../widgets/leaderboard_entry_card.dart';
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

    // Get userId from authStateProvider (consistent with rest of app)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (mounted && userId != null) {
        setState(() {
          _userId = userId;
        });
        _loadUnlockStatus();
      }
    });
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
    return LeaderboardLockedState(
      unlockStatus: _unlockStatus,
      isDark: isDark,
      onViewFriendsLeaderboard: () {
        setState(() {
          _selectedFilter = LeaderboardFilter.friends;
        });
        _loadLeaderboard();
      },
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
              child: LeaderboardRankCard(
                userRank: userRank,
                selectedType: _selectedType,
                isDark: isDark,
              ),
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
                    child: LeaderboardEntryCard(
                      entry: entry,
                      selectedType: _selectedType,
                      leaderboardService: _leaderboardService,
                      isDark: isDark,
                      onChallengeTap: () => _showChallengeOptions(context, entry),
                    ),
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
