import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/user_xp.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/xp_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/leaderboard_service.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';

/// Leaderboard screen with XP, Streaks, and Workouts boards.
///
/// B10 — surfaces the streaks + workouts tabs (in addition to the original XP
/// board) and renders a friend STRENGTH-SCORE badge per entry. The XP tab is
/// the original cached SWR implementation; the streaks/workouts tabs pull from
/// the `/leaderboard/` service (friend-scoped, with `strength_score` per row).
class XPLeaderboardScreen extends ConsumerStatefulWidget {
  const XPLeaderboardScreen({super.key});

  @override
  ConsumerState<XPLeaderboardScreen> createState() =>
      _XPLeaderboardScreenState();
}

class _XPLeaderboardScreenState extends ConsumerState<XPLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ---- XP board state --------------------------------------------------
  List<XPLeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _currentUserId;
  int? _currentUserRank;

  // ---- Streaks / Workouts board state ----------------------------------
  // Raw entry maps from /leaderboard/ keyed by board.
  final Map<LeaderboardType, List<Map<String, dynamic>>> _boardEntries = {};
  final Map<LeaderboardType, bool> _boardLoading = {};
  LeaderboardService? _lbService;

  // ---- Disk SWR cache (XP board) ---------------------------------------
  static const String _cacheKey = 'xp_leaderboard_swr::v1';
  static const Duration _cacheTtl = Duration(hours: 12);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      ref.read(posthogServiceProvider).capture(eventName: 'leaderboard_viewed');
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final idx = _tabController.index;
    if (idx == 1) {
      _loadBoard(LeaderboardType.streaks);
    } else if (idx == 2) {
      _loadBoard(LeaderboardType.volumeKings);
    }
  }

  // ======================================================================
  // XP BOARD (original SWR)
  // ======================================================================

  void _applyEntries(List<XPLeaderboardEntry> entries) {
    _entries = entries;
    _currentUserRank = null;
    if (_currentUserId != null) {
      final index = entries.indexWhere((e) => e.userId == _currentUserId);
      if (index >= 0) _currentUserRank = index + 1;
    }
  }

  Future<List<XPLeaderboardEntry>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final env = jsonDecode(raw);
      if (env is! Map<String, dynamic>) return null;
      final cachedAt = env['cachedAt'];
      if (cachedAt is! int) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      if (age < 0 || age >= _cacheTtl.inMilliseconds) return null;
      final list = env['data'];
      if (list is! List) return null;
      return list
          .map((e) => XPLeaderboardEntry.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('💾 [XPLeaderboardSWR] read failed: $e');
      return null;
    }
  }

  Future<void> _writeCache(List<XPLeaderboardEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode({
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'data': entries.map((e) => e.toJson()).toList(),
      }));
    } catch (e) {
      debugPrint('💾 [XPLeaderboardSWR] write failed: $e');
    }
  }

  Future<void> _loadData() async {
    final authState = ref.read(authStateProvider);
    _currentUserId = authState.user?.id;

    final cached = await _readCache();
    if (cached != null && mounted) {
      setState(() {
        _applyEntries(cached);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final repository = XPRepository(ref.read(apiClientProvider));
      final entries = await repository.getXPLeaderboard(limit: 100);
      await _writeCache(entries);

      if (mounted) {
        setState(() {
          _applyEntries(entries);
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

  // ======================================================================
  // STREAKS / WORKOUTS BOARDS (/leaderboard/ service)
  // ======================================================================

  Future<void> _loadBoard(LeaderboardType type, {bool force = false}) async {
    if (!force && _boardEntries.containsKey(type)) return; // already loaded
    final userId = _currentUserId ?? ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    setState(() => _boardLoading[type] = true);
    _lbService ??= LeaderboardService(ref.read(apiClientProvider));

    // Friend-scoped board (the strength-score badge is most meaningful among
    // friends). Friends scope unlocks at 1 workout.
    try {
      final data = await _lbService!.getLeaderboard(
        userId: userId,
        leaderboardType: type,
        filterType: LeaderboardFilter.friends,
        limit: 100,
      );
      final entries = ((data['entries'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) {
        setState(() {
          _boardEntries[type] = entries;
          _boardLoading[type] = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ${type.value} leaderboard: $e');
      if (mounted) {
        setState(() {
          _boardEntries[type] = [];
          _boardLoading[type] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColorsLight.background;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).xpLeaderboardXpLeaderboard,
      ),
      body: Column(
        children: [
          _buildTabBar(isDark, accentColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildXpTab(isDark),
                _buildStreaksTab(isDark),
                _buildWorkoutsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark, Color accentColor) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
        ),
        labelColor: accentColor,
        unselectedLabelColor: textMuted,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '⚡ XP'),
          Tab(text: '🔥 Streaks'),
          Tab(text: '🏋️ Workouts'),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // XP TAB
  // ----------------------------------------------------------------------

  Widget _buildXpTab(bool isDark) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final userXp = ref.watch(xpProvider).userXp;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
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
          if (_isLoading && _entries.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SkeletonList(
                  itemCount: 10,
                  spacing: 8,
                  itemBuilder: (context, index) => const SkeletonCard(
                    height: 64,
                    leadingSize: 40,
                    lines: 2,
                  ),
                ),
              ),
            ),
          if (!_isLoading && _entries.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState(textMuted)),
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
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // STREAKS TAB
  // ----------------------------------------------------------------------

  Widget _buildStreaksTab(bool isDark) {
    return _buildServiceBoard(
      isDark: isDark,
      type: LeaderboardType.streaks,
      metricLabel: 'day streak',
      metricBuilder: (e) {
        final cur = (e['current_streak'] as num?)?.toInt() ?? 0;
        final best = (e['best_streak'] as num?)?.toInt() ?? 0;
        final v = cur > 0 ? cur : best;
        return '$v 🔥';
      },
      emptyMessage:
          'Add friends and keep your streak to climb the streak board.',
    );
  }

  // ----------------------------------------------------------------------
  // WORKOUTS TAB
  // ----------------------------------------------------------------------

  Widget _buildWorkoutsTab(bool isDark) {
    return _buildServiceBoard(
      isDark: isDark,
      type: LeaderboardType.volumeKings,
      metricLabel: 'workouts',
      metricBuilder: (e) {
        final workouts = (e['total_workouts'] as num?)?.toInt() ?? 0;
        return '$workouts';
      },
      emptyMessage:
          'Add friends and log workouts to rank on the workouts board.',
    );
  }

  /// Shared renderer for the streaks/workouts boards.
  Widget _buildServiceBoard({
    required bool isDark,
    required LeaderboardType type,
    required String metricLabel,
    required String Function(Map<String, dynamic>) metricBuilder,
    required String emptyMessage,
  }) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    final loading = _boardLoading[type] ?? false;
    final entries = _boardEntries[type];

    return RefreshIndicator(
      onRefresh: () => _loadBoard(type, force: true),
      child: CustomScrollView(
        slivers: [
          if (loading && (entries == null || entries.isEmpty))
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SkeletonList(
                  itemCount: 8,
                  spacing: 8,
                  itemBuilder: (context, index) => const SkeletonCard(
                    height: 64,
                    leadingSize: 40,
                    lines: 2,
                  ),
                ),
              ),
            ),
          if (!loading && (entries == null || entries.isEmpty))
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(textMuted, message: emptyMessage),
            ),
          if (entries != null && entries.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final e = entries[index];
                    final rank = (e['rank'] as num?)?.toInt() ?? (index + 1);
                    final isCurrentUser = e['is_current_user'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildServiceEntry(
                        e,
                        rank,
                        isCurrentUser,
                        metricBuilder(e),
                        metricLabel,
                        textColor,
                        textMuted,
                        elevatedColor,
                        cardBorder,
                        accentColor,
                      ),
                    );
                  },
                  childCount: entries.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildServiceEntry(
    Map<String, dynamic> e,
    int rank,
    bool isCurrentUser,
    String metricValue,
    String metricLabel,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
  ) {
    final name = (e['user_name'] as String?) ?? 'Anonymous';
    final strengthScore = (e['strength_score'] as num?)?.toInt();
    final isFriend = e['is_friend'] == true;

    Color? rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser ? accentColor : textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFriend && !isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.people_alt_rounded,
                          size: 13, color: textMuted),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                // Friend STRENGTH-SCORE badge (B10).
                if (strengthScore != null && strengthScore > 0)
                  _buildStrengthBadge(strengthScore)
                else
                  Text(
                    metricLabel,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            metricValue,
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

  /// Small strength-score chip (B10). Color ramps with the score tier.
  Widget _buildStrengthBadge(int score) {
    Color color;
    String tier;
    if (score >= 90) {
      color = const Color(0xFFFFD700);
      tier = 'Elite';
    } else if (score >= 70) {
      color = const Color(0xFF9C27B0);
      tier = 'Advanced';
    } else if (score >= 50) {
      color = const Color(0xFF2196F3);
      tier = 'Intermediate';
    } else if (score >= 25) {
      color = const Color(0xFF4CAF50);
      tier = 'Novice';
    } else {
      color = const Color(0xFF9E9E9E);
      tier = 'Beginner';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            'STR $score · $tier',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // SHARED: current-user card + XP entry + empty state
  // ----------------------------------------------------------------------

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).xpLeaderboardYourRank,
                  style: TextStyle(fontSize: 12, color: textMuted),
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
                AppLocalizations.of(context).xpLeaderboardTotalXp,
                style: TextStyle(fontSize: 11, color: textMuted),
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
    final titleColor = _getTitleColorForLevel(entry.currentLevel);

    Color? rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
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
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Widget _buildEmptyState(Color textMuted, {String? message}) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message ??
                AppLocalizations.of(context).xpLeaderboardNoLeaderboardDataYet,
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
    if (level <= 10) return const Color(0xFF9E9E9E);
    if (level <= 25) return const Color(0xFF8BC34A);
    if (level <= 50) return const Color(0xFF4CAF50);
    if (level <= 75) return const Color(0xFF2196F3);
    if (level <= 100) return const Color(0xFF9C27B0);
    if (level <= 125) return const Color(0xFFFF9800);
    if (level <= 150) return const Color(0xFFFF5722);
    if (level <= 175) return const Color(0xFFFFD700);
    if (level <= 200) return const Color(0xFFE040FB);
    if (level <= 225) return const Color(0xFF00E5FF);
    return const Color(0xFFFF1744);
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
