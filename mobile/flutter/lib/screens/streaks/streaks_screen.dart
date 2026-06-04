/// Streaks hub — Surface 3 of the Gravl-parity DISPLAY UPGRADE.
///
/// A dedicated home for everything streak-related, displayed as well as Gravl
/// does it (a huge hero number, scannable 2×2 grid, ranked leaderboard) while
/// keeping OUR design system (ThemeColors accent, GlassSurface, hexagon/metric
/// foundation widgets — no volt/lime recolor).
///
/// Layout (top → bottom):
///   1. HERO — flame + giant streak number (AnimatedStatNumber), "Week Streak"
///      subtitle, "X days / week" cadence, and a freeze chip (top-right) that
///      taps to /streak-freeze.
///   2. 2×2 stat grid (MetricGrid) — workouts-this-week, best streak,
///      consistency streak, consistency best.
///   3. Leaderboard — two tabs (Current Streak / Workouts) over the
///      friend-scoped /leaderboard/ service (same provider + row styling as
///      xp_leaderboard_screen.dart).
///   4. Trophies summary strip (earned / total + recent icons) → /trophy-room.
///
/// Data sources:
///   • Streaks hero + best: GET /achievements/user/{id}/streaks
///       (fields: streak_type, current_streak, longest_streak; the `workout`
///        streak is the hero number).
///   • Weekly momentum: consistencyProvider calendar (CalendarHeatmapData →
///       status / date). Days with status=='completed' in the trailing 7 days.
///       Weekly target = User.workoutsPerWeek (defaults to 4 — see assumption).
///   • Consistency streak / best: consistencyProvider insights
///       (current_streak / longest_streak).
///   • Leaderboard rows: LeaderboardService.getLeaderboard (friends scope).
///   • Trophies: trophySummaryProvider + earnedTrophiesProvider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/stat_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/consistency.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/streak_freeze_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/leaderboard_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/metric_grid.dart';

/// Default weekly workout target when the user has no `workouts_per_week`
/// preference set. Documented assumption (Gravl shows "4 days/week" by default).
const int _kDefaultWeeklyTarget = 4;

/// One row of the `/achievements/user/{id}/streaks` payload, normalized.
class _StreakRecord {
  final String type;
  final int current;
  final int longest;

  const _StreakRecord({
    required this.type,
    required this.current,
    required this.longest,
  });
}

class StreaksScreen extends ConsumerStatefulWidget {
  const StreaksScreen({super.key});

  @override
  ConsumerState<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends ConsumerState<StreaksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _boardTabController;

  // ── Streak records (/achievements/user/{id}/streaks) ────────────────────
  List<_StreakRecord>? _streaks;
  bool _loadingStreaks = true;

  // ── Friend-scoped leaderboard boards (/leaderboard/ service) ────────────
  final Map<LeaderboardType, List<Map<String, dynamic>>> _boardEntries = {};
  final Map<LeaderboardType, bool> _boardLoading = {};
  LeaderboardService? _lbService;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _boardTabController = TabController(length: 2, vsync: this);
    _boardTabController.addListener(_onBoardTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _boardTabController.removeListener(_onBoardTabChanged);
    _boardTabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final api = ref.read(apiClientProvider);
    _userId = await api.getUserId();

    // Ensure the consistency calendar + insights are loaded (cache-first; the
    // provider silently revalidates). Drives the weekly cadence + grid.
    if (_userId != null) {
      final notifier = ref.read(consistencyProvider.notifier);
      notifier.setUserId(_userId!);
      // loadAll = insights + 4-week calendar. Cheap & cached.
      notifier.loadAll(userId: _userId!);
    }

    // Trophy summary + earned trophies for the bottom strip.
    ref.read(xpProvider.notifier).loadTrophySummary();
    ref.read(xpProvider.notifier).loadTrophies();

    await _loadStreaks();
    // Eagerly load the first leaderboard tab (Current Streak).
    _loadBoard(LeaderboardType.streaks);
  }

  Future<void> _loadStreaks() async {
    final api = ref.read(apiClientProvider);
    final uid = _userId ?? await api.getUserId();
    if (uid == null) {
      if (mounted) setState(() => _loadingStreaks = false);
      return;
    }
    try {
      final resp = await api.get('/achievements/user/$uid/streaks');
      final data = resp.data;
      List<dynamic> rows;
      if (data is List) {
        rows = data;
      } else if (data is Map && data['streaks'] is List) {
        rows = data['streaks'] as List;
      } else {
        rows = const [];
      }
      final parsed = rows.whereType<Map>().map((m) {
        final map = Map<String, dynamic>.from(m);
        return _StreakRecord(
          type: (map['streak_type'] as String?) ?? 'streak',
          current: (map['current_streak'] as num?)?.toInt() ?? 0,
          longest: (map['longest_streak'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _streaks = parsed;
          _loadingStreaks = false;
        });
      }
    } catch (e) {
      debugPrint('🔥 [Streaks] streaks fetch failed: $e');
      if (mounted) {
        setState(() {
          _streaks = const [];
          _loadingStreaks = false;
        });
      }
    }
  }

  void _onBoardTabChanged() {
    if (_boardTabController.indexIsChanging) return;
    _loadBoard(_boardTabController.index == 0
        ? LeaderboardType.streaks
        : LeaderboardType.volumeKings);
  }

  Future<void> _loadBoard(LeaderboardType type, {bool force = false}) async {
    if (!force && _boardEntries.containsKey(type)) return;
    final uid = _userId ?? await ref.read(apiClientProvider).getUserId();
    if (uid == null) return;
    _userId = uid;

    if (mounted) setState(() => _boardLoading[type] = true);
    _lbService ??= LeaderboardService(ref.read(apiClientProvider));

    try {
      final data = await _lbService!.getLeaderboard(
        userId: uid,
        leaderboardType: type,
        // Friends scope mirrors xp_leaderboard_screen.dart — the streak/workout
        // boards are most meaningful among friends.
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
      debugPrint('🔥 [Streaks] ${type.value} board failed: $e');
      if (mounted) {
        setState(() {
          _boardEntries[type] = [];
          _boardLoading[type] = false;
        });
      }
    }
  }

  // ── Derived values ──────────────────────────────────────────────────────

  /// The hero "workout" streak record (falls back to whichever record carries
  /// the highest current streak so the hero is never blank when a non-workout
  /// streak exists).
  _StreakRecord? get _workoutStreak {
    final list = _streaks;
    if (list == null || list.isEmpty) return null;
    for (final s in list) {
      if (s.type == 'workout') return s;
    }
    // No explicit workout streak — surface the strongest active one.
    list.sort((a, b) => b.current.compareTo(a.current));
    return list.first;
  }

  /// Days with a completed workout in the trailing 7 days (inclusive of today),
  /// from the consistency calendar heatmap.
  int _completedThisWeek(CalendarHeatmapResponse? cal) {
    if (cal == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 6));
    var count = 0;
    for (final d in cal.data) {
      if (d.status.toLowerCase() != 'completed') continue;
      final dt = DateTime(d.dateTime.year, d.dateTime.month, d.dateTime.day);
      if (!dt.isBefore(weekAgo) && !dt.isAfter(today)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Streaks',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: c.accent,
        onRefresh: () async {
          await _loadStreaks();
          if (_userId != null) {
            ref.read(consistencyProvider.notifier).loadAll(userId: _userId!);
          }
          _loadBoard(
            _boardTabController.index == 0
                ? LeaderboardType.streaks
                : LeaderboardType.volumeKings,
            force: true,
          );
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            MediaQuery.of(context).viewPadding.bottom + AppSpacing.xxl,
          ),
          children: [
            _buildHero(c),
            const SizedBox(height: AppSpacing.md),
            _buildStatGrid(c),
            const SizedBox(height: AppSpacing.lg),
            _buildLeaderboardSection(c),
            const SizedBox(height: AppSpacing.lg),
            _buildTrophyStrip(c),
          ],
        ),
      ),
    );
  }

  // ── 1. HERO ─────────────────────────────────────────────────────────────

  Widget _buildHero(ThemeColors c) {
    if (_loadingStreaks && _streaks == null) {
      return GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppRadius.xl,
        child: Row(
          children: [
            const SkeletonCircle(size: 56),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 120, height: 48),
                  SizedBox(height: 10),
                  SkeletonBox(width: 90, height: 14),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final streak = _workoutStreak;
    final current = streak?.current ?? 0;

    // Freeze chip data (independent provider; degrades gracefully).
    final freezeAsync = ref.watch(streakFreezeStatusProvider);
    final freezeCount = freezeAsync.maybeWhen(
      data: (s) => s.freezesAvailable,
      orElse: () => 0,
    );

    // Weekly cadence subtitle — "X days / week" from completed days this week.
    final cal = ref.watch(consistencyProvider.select((s) => s.calendarData));
    final completed = _completedThisWeek(cal);

    if (current <= 0) {
      return _buildEmptyHero(c, freezeCount);
    }

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 44)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedStatNumber(
                      value: current.toDouble(),
                      format: (v) => v.round().toString(),
                      size: 68,
                      color: c.accent,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Week Streak',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      completed > 0
                          ? '$completed ${completed == 1 ? 'day' : 'days'} / week'
                          : 'Keep it going this week',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildFreezeChip(c, freezeCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHero(ThemeColors c, int freezeCount) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🔥',
                      style: TextStyle(
                        fontSize: 40,
                        color: c.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Start your streak today',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Finish a workout to light the flame. '
                      'Train each scheduled day to grow your week streak.',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _buildFreezeChip(c, freezeCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeChip(ThemeColors c, int count) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/streak-freeze');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ac_unit_rounded, size: 15, color: c.accent),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                color: c.accent,
                fontSize: StatType.badge,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. 2×2 STAT GRID ────────────────────────────────────────────────────

  Widget _buildStatGrid(ThemeColors c) {
    final loadingGrid = _loadingStreaks && _streaks == null;
    if (loadingGrid) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
        children: List.generate(
          4,
          (_) => GlassSurface(
            borderRadius: AppRadius.lg,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonBox(width: 70, height: 11),
                SizedBox(height: 8),
                SkeletonBox(width: 50, height: 22),
              ],
            ),
          ),
        ),
      );
    }

    // Weekly target from training preferences, default 4 (documented).
    final target = ref.watch(
          currentUserProviderForTarget,
        ) ??
        _kDefaultWeeklyTarget;
    final cal = ref.watch(consistencyProvider.select((s) => s.calendarData));
    final completed = _completedThisWeek(cal);

    // Consistency streak/best come from the consistency insights (separate from
    // the achievements `workout` streak — this is the calendar-day consistency).
    final consistency = ref.watch(consistencyProvider);
    final consistencyStreak = consistency.currentStreak;
    final consistencyBest = consistency.longestStreak;

    final bestStreak = _workoutStreak?.longest ?? 0;

    return MetricGrid(
      columns: 2,
      numberSize: StatType.secondary,
      items: [
        MetricCell(
          label: 'Workouts This Week',
          value: '$completed/$target',
          icon: Icons.fitness_center_rounded,
          accent: c.accent,
        ),
        MetricCell(
          label: 'Best Streak',
          value: '$bestStreak',
          unit: bestStreak == 1 ? 'day' : 'days',
          icon: Icons.local_fire_department_rounded,
          accent: c.textPrimary,
        ),
        MetricCell(
          label: 'Consistency Streak',
          value: '$consistencyStreak',
          unit: consistencyStreak == 1 ? 'day' : 'days',
          icon: Icons.bolt_rounded,
          accent: c.textPrimary,
        ),
        MetricCell(
          label: 'Consistency Best',
          value: '$consistencyBest',
          unit: consistencyBest == 1 ? 'day' : 'days',
          icon: Icons.workspace_premium_rounded,
          accent: c.textPrimary,
        ),
      ],
    );
  }

  // ── 3. LEADERBOARD ──────────────────────────────────────────────────────

  Widget _buildLeaderboardSection(ThemeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(c, 'Leaderboard', 'Among your friends'),
        const SizedBox(height: AppSpacing.sm),
        _buildBoardTabBar(c),
        const SizedBox(height: AppSpacing.sm),
        AnimatedBuilder(
          animation: _boardTabController,
          builder: (context, _) {
            final isStreakTab = _boardTabController.index == 0;
            final type = isStreakTab
                ? LeaderboardType.streaks
                : LeaderboardType.volumeKings;
            return _buildBoard(c, type, isStreakTab);
          },
        ),
      ],
    );
  }

  Widget _buildBoardTabBar(ThemeColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.cardBorder),
      ),
      child: TabBar(
        controller: _boardTabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          color: c.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: c.accent.withValues(alpha: 0.4)),
        ),
        labelColor: c.accent,
        unselectedLabelColor: c.textMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        tabs: const [
          Tab(text: '🔥 Current Streak'),
          Tab(text: '🏋️ Workouts'),
        ],
      ),
    );
  }

  Widget _buildBoard(ThemeColors c, LeaderboardType type, bool isStreakTab) {
    final loading = _boardLoading[type] ?? false;
    final entries = _boardEntries[type];

    if (loading && (entries == null || entries.isEmpty)) {
      return SkeletonList(
        itemCount: 5,
        spacing: 8,
        itemBuilder: (context, index) => const SkeletonCard(
          height: 60,
          leadingSize: 40,
          lines: 2,
        ),
      );
    }

    if (entries == null || entries.isEmpty) {
      return _buildBoardEmpty(c, isStreakTab);
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildBoardRow(
              c,
              entries[i],
              (entries[i]['rank'] as num?)?.toInt() ?? (i + 1),
              isStreakTab,
            ),
          ),
      ],
    );
  }

  Widget _buildBoardRow(
    ThemeColors c,
    Map<String, dynamic> e,
    int rank,
    bool isStreakTab,
  ) {
    final name = (e['user_name'] as String?) ?? 'Anonymous';
    final isCurrentUser = e['is_current_user'] == true;

    final String metricValue;
    if (isStreakTab) {
      final cur = (e['current_streak'] as num?)?.toInt() ?? 0;
      final best = (e['best_streak'] as num?)?.toInt() ?? 0;
      metricValue = '${cur > 0 ? cur : best} 🔥';
    } else {
      metricValue = '${(e['total_workouts'] as num?)?.toInt() ?? 0}';
    }

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
        color: isCurrentUser ? c.accent.withValues(alpha: 0.1) : c.elevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCurrentUser
              ? c.accent.withValues(alpha: 0.4)
              : c.cardBorder,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 22)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: c.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCurrentUser ? c.accent : c.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            metricValue,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? c.accent : c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardEmpty(ThemeColors c, bool isStreakTab) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_outlined,
            size: 44,
            color: c.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isStreakTab
                ? 'Add friends and keep your streak to climb the board.'
                : 'Add friends and log workouts to rank here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. TROPHIES STRIP ───────────────────────────────────────────────────

  Widget _buildTrophyStrip(ThemeColors c) {
    final summary = ref.watch(trophySummaryProvider);
    final earned = ref.watch(earnedTrophiesProvider);

    final earnedCount = summary?.earnedTrophies ?? earned.length;
    final totalCount = summary?.totalTrophies ?? 0;

    // Up to 5 most-recently-earned trophy icons (earnedAt desc).
    final recent = [...earned]
      ..sort((a, b) {
        final ad = a.earnedAt;
        final bd = b.earnedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    final icons = recent.take(5).map((t) => t.displayIcon).toList();

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/trophy-room');
      },
      child: GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.lg,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TROPHIES',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: StatType.labelSm,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatNumber(
                      value: '$earnedCount',
                      size: StatType.primary,
                      color: c.accent,
                    ),
                    if (totalCount > 0) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '/ $totalCount',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: icons.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No trophies yet',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final icon in icons)
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: c.accent.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: c.textMuted.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  // ── shared ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(ThemeColors c, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: c.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Weekly workout-days target from the user's training preferences
/// (`workouts_per_week`, falling back to the count of selected workout_days).
/// Returns null when unset so the screen can apply the documented default (4).
final currentUserProviderForTarget = Provider<int?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.valueOrNull?.workoutsPerWeek;
});
