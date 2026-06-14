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
import '../../widgets/design_system/zealova.dart';

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
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).xpLeaderboardXpLeaderboard,
        kicker: 'XP & friends',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (_, __) => ZealovaTextTabs(
            tabs: const ['XP', 'Streaks', 'Workouts'],
            activeIndex: _tabController.index,
            onChanged: (i) => _tabController.animateTo(i),
          ),
        ),
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
                        isDark,
                        metricBuilder(e),
                        metricLabel,
                        textColor,
                        textMuted,
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
    bool isDark,
    String metricValue,
    String metricLabel,
    Color textColor,
    Color textMuted,
    Color cardBorder,
    Color accentColor,
  ) {
    final name = (e['user_name'] as String?) ?? 'Anonymous';
    final strengthScore = (e['strength_score'] as num?)?.toInt();
    final isFriend = e['is_friend'] == true;

    final surfaceColor = isDark ? AppColors.surface : AppColorsLight.surface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? surfaceColor : null,
        border: Border(
          bottom: BorderSide(
            color: isCurrentUser
                ? AppColors.hairlineStrong
                : AppColors.hairline,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildRankCell(rank, textMuted),
          const SizedBox(width: 12),
          _buildAvatar(
            label: name.isNotEmpty ? name[0].toUpperCase() : '?',
            cardBorder: cardBorder,
            surfaceColor: surfaceColor,
            textColor: textColor,
            useDisp: false,
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
                const SizedBox(height: 4),
                // Friend STRENGTH-SCORE badge (B10).
                if (strengthScore != null && strengthScore > 0)
                  _buildStrengthBadge(strengthScore)
                else
                  Text(
                    metricLabel.toUpperCase(),
                    style: ZType.lbl(9, color: textMuted, letterSpacing: 1.3),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            metricValue,
            style: ZType.data(
              14,
              color: isCurrentUser ? accentColor : textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Rank cell — gold/silver/bronze medal for the podium, Space Mono '#N' below.
  Widget _buildRankCell(int rank, Color textMuted) {
    Color? rankColor;
    if (rank == 1) {
      rankColor = AppColors.rarityGold;
    } else if (rank == 2) {
      rankColor = AppColors.raritySilver;
    } else if (rank == 3) {
      rankColor = AppColors.rarityBronze;
    }
    return SizedBox(
      width: 36,
      child: Center(
        child: rankColor != null
            ? Icon(Icons.emoji_events, color: rankColor, size: 22)
            : Text('#$rank', style: ZType.data(13, color: textMuted)),
      ),
    );
  }

  /// Hairline-bordered avatar circle (level number or name initial).
  Widget _buildAvatar({
    required String label,
    required Color cardBorder,
    required Color surfaceColor,
    required Color textColor,
    required bool useDisp,
  }) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: cardBorder),
      ),
      child: Text(
        label,
        style: useDisp
            ? ZType.disp(15, color: textColor)
            : ZType.data(14, color: textColor),
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            'STR $score · $tier'.toUpperCase(),
            style: ZType.lbl(9, color: color, letterSpacing: 1.2),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            children: [
              // Rank badge — gold rarity ring, no solid fill.
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0x38FBBF24), Colors.transparent],
                    stops: [0.0, 0.7],
                    center: Alignment(-0.3, -0.4),
                  ),
                  border: Border.all(
                    color: AppColors.gamGold.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '#$rank',
                  style: ZType.disp(18, color: AppColors.gamGold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .xpLeaderboardYourRank
                          .toUpperCase(),
                      style: ZType.lbl(10, color: textMuted, letterSpacing: 2),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Level ${userXp.currentLevel}'.toUpperCase(),
                          style: ZType.disp(19, color: textColor, height: 0.96),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: titleColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            userXp.xpTitle.displayName.toUpperCase(),
                            style: ZType.lbl(9,
                                color: titleColor, letterSpacing: 1.2),
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
                    style: ZType.data(18, color: accentColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)
                        .xpLeaderboardTotalXp
                        .toUpperCase(),
                    style: ZType.lbl(9, color: textMuted, letterSpacing: 1.3),
                  ),
                ],
              ),
            ],
          ),
        ),
        const ZealovaRule(margin: EdgeInsets.symmetric(horizontal: 20)),
      ],
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
    final surfaceColor = isDark ? AppColors.surface : AppColorsLight.surface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? surfaceColor : null,
        border: Border(
          bottom: BorderSide(
            color: isCurrentUser
                ? AppColors.hairlineStrong
                : AppColors.hairline,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildRankCell(rank, textMuted),
          const SizedBox(width: 12),
          _buildAvatar(
            label: entry.currentLevel.toString(),
            cardBorder: cardBorder,
            surfaceColor: surfaceColor,
            textColor: textColor,
            useDisp: true,
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: titleColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        entry.title.toUpperCase(),
                        style: ZType.lbl(9,
                            color: titleColor, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lvl ${entry.currentLevel}'.toUpperCase(),
                      style: ZType.lbl(9, color: textMuted, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _formatXP(entry.totalXp),
            style: ZType.data(
              14,
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
            size: 56,
            color: textMuted.withValues(alpha: 0.4),
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
