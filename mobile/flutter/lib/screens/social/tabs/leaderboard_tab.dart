import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/leaderboard_service.dart';
import '../../../data/services/challenges_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/leaderboard_locked_state.dart';
import '../widgets/leaderboard_rank_card.dart';
import '../widgets/leaderboard_entry_card.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../l10n/generated/app_localizations.dart';
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

  // ---- Disk SWR cache --------------------------------------------------
  // The leaderboard board + unlock status are persisted to SharedPreferences
  // so a cold restart renders the last-seen board INSTANTLY while a silent
  // network refresh runs. Blobs carry a schema version + 12h freshness window.
  static const String _cachePrefix = 'leaderboard_swr';
  static const int _cacheSchema = 1;
  static const Duration _cacheTtl = Duration(hours: 12);

  /// Cache slot for the unlock status (per user).
  String _unlockCacheKey() =>
      '$_cachePrefix::unlock::v$_cacheSchema::${_userId ?? '_global'}';

  /// Cache slot for a leaderboard board — keyed by user + type + filter +
  /// country so switching tabs/filters never serves the wrong board.
  String _boardCacheKey() =>
      '$_cachePrefix::board::v$_cacheSchema::${_userId ?? '_global'}::'
      '${_selectedType.name}::${_selectedFilter.name}::${_userCountryCode ?? '-'}';

  /// Read a JSON-map blob from disk; null on miss, corruption, schema
  /// mismatch, clock skew, or staleness beyond [_cacheTtl].
  Future<Map<String, dynamic>?> _readCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final env = jsonDecode(raw);
      if (env is! Map<String, dynamic>) return null;
      if (env['sv'] != _cacheSchema) return null;
      final cachedAt = env['cachedAt'];
      if (cachedAt is! int) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      if (age < 0 || age >= _cacheTtl.inMilliseconds) return null;
      final data = env['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('💾 [LeaderboardSWR] read failed: $e');
      return null;
    }
  }

  /// Persist a JSON-map blob in a versioned TTL envelope. Best-effort.
  Future<void> _writeCache(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode({
        'sv': _cacheSchema,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
    } catch (e) {
      debugPrint('💾 [LeaderboardSWR] write failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _typeTabController = TabController(length: 5, vsync: this);
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

    // Cache-first: render the last-seen unlock status instantly if present.
    final cached = await _readCache(_unlockCacheKey());
    if (cached != null && mounted) {
      setState(() {
        _unlockStatus = cached;
        _isUnlocked = cached['is_unlocked'] ?? false;
      });
    }

    try {
      final status = await _leaderboardService.getUnlockStatus(userId: _userId!);
      await _writeCache(_unlockCacheKey(), status);

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
        // A cached status keeps the screen usable; only the spinner clears.
        setState(() {
          _isLoading = false;
        });
        if (cached != null &&
            (_isUnlocked || _selectedFilter == LeaderboardFilter.friends)) {
          _loadLeaderboard();
        }
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_userId == null) return;

    // Cache-first: paint the cached board instantly, then revalidate silently.
    // Only show the skeleton when there is genuinely nothing cached.
    final cached = await _readCache(_boardCacheKey());
    if (cached != null && mounted) {
      setState(() {
        _leaderboardData = cached;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final data = await _leaderboardService.getLeaderboard(
        userId: _userId!,
        leaderboardType: _selectedType,
        filterType: _selectedFilter,
        countryCode: _selectedFilter == LeaderboardFilter.country ? _userCountryCode : null,
        limit: 100,
        offset: 0,
      );
      await _writeCache(_boardCacheKey(), data);

      if (mounted) {
        setState(() {
          _leaderboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading leaderboard: $e');
      if (mounted) {
        // Keep any cached board on screen; just clear the loading flag.
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

    // First-ever / cold cache: a layout-matched skeleton of ranking rows
    // instead of a blocking spinner.
    if (_isLoading) {
      return const _LeaderboardSkeleton();
    }

    // Show locked state if global leaderboard not unlocked
    if (!_isUnlocked && _selectedFilter == LeaderboardFilter.global) {
      return _buildLockedState(context, isDark);
    }

    return Column(
      children: [
        // Leaderboard Type Tabs
        SegmentedTabBar(
          controller: _typeTabController,
          showIcons: false,
          tabs: [
            SegmentedTabItem(label: AppLocalizations.of(context).leaderboardMasters),
            SegmentedTabItem(label: AppLocalizations.of(context).leaderboardVolume),
            SegmentedTabItem(label: AppLocalizations.of(context).leaderboardStreaks),
            SegmentedTabItem(label: AppLocalizations.of(context).leaderboardWeek),
            SegmentedTabItem(label: AppLocalizations.of(context).leaderboardRush),
          ],
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
    final accentColor = ref.colors(context).accent;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

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
      selectedColor: accentColor.withValues(alpha: 0.15),
      checkmarkColor: accentColor,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      labelStyle: TextStyle(
        color: enabled
            ? (isSelected ? accentColor : (isDark ? Colors.white : Colors.black))
            : textMuted,
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
    final isRush = _selectedType == LeaderboardType.nutrientRush;
    final String description;
    if (_selectedFilter == LeaderboardFilter.friends) {
      description = isRush
          ? 'Add friends and challenge them in Nutrient Rush!'
          : 'Add friends to see their rankings!';
    } else {
      description = isRush
          ? 'Play Nutrient Rush to set a high score and appear here!'
          : 'Complete challenges to appear on the leaderboard!';
    }
    return SocialEmptyState(
      icon: isRush ? Icons.sports_esports_outlined : Icons.emoji_events_outlined,
      title: AppLocalizations.of(context).leaderboardNoRankingsYet,
      description: description,
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
                      // The workout-based async challenge does not apply to
                      // the Nutrient Rush mini-game board.
                      showChallengeButton:
                          _selectedType != LeaderboardType.nutrientRush,
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

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final accentColor = sheetContext.colors.accent;

        return GlassSheet(
          child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Challenge $userName',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),


              // Async challenge (Beat Their Best)
              ListTile(
                leading: Icon(Icons.flash_on, color: accentColor),
                title: Text(AppLocalizations.of(context).leaderboardEntryCardBeatTheirBest),
                subtitle: Text(
                  isFriend
                      ? AppLocalizations.of(context).leaderboardChallengeWithoutNotification
                      : 'Try to beat their record!',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _createAsyncChallenge(userId, userName);
                },
              ),
            ],
          ),
        ),
        );
      },
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
        AppSnackBar.success(context, 'Challenge created! Beat $targetUserName\'s record!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to create challenge: $e');
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

/// Layout-matched skeleton for the leaderboard — a tall "your rank" card
/// placeholder followed by a column of ranking-row placeholders, mirroring
/// [LeaderboardRankCard] + [LeaderboardEntryCard]. Shown only on a cold cache.
class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // "Your rank" hero card placeholder.
        const SkeletonBox(height: 88, radius: 16),
        const SizedBox(height: 16),
        // Ranking row placeholders — avatar + name/title text per row.
        SkeletonList(
          itemCount: 8,
          spacing: 12,
          itemBuilder: (context, index) => const SkeletonCard(
            height: 64,
            leadingSize: 36,
            lines: 2,
          ),
        ),
      ],
    );
  }
}
