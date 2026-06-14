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

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/consistency.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/streak_freeze_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/leaderboard_service.dart';
import '../../widgets/design_system/zealova.dart';

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
    with TickerProviderStateMixin {
  late final TabController _boardTabController;
  late final AnimationController _blinkController;

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
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _boardTabController.removeListener(_onBoardTabChanged);
    _boardTabController.dispose();
    _blinkController.dispose();
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

  /// Trailing 7 days (oldest → today) marked completed, for the momentum dots.
  List<bool> _weekCompletion(CalendarHeatmapResponse? cal) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDays = <DateTime>{};
    if (cal != null) {
      for (final d in cal.data) {
        if (d.status.toLowerCase() != 'completed') continue;
        completedDays
            .add(DateTime(d.dateTime.year, d.dateTime.month, d.dateTime.day));
      }
    }
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return completedDays.contains(day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: ZealovaAppBar(
        title: 'Streaks',
        kicker: 'Momentum',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const SkeletonBox(width: 160, height: 96),
          const SizedBox(height: 14),
          const SkeletonBox(width: 110, height: 14),
          const SizedBox(height: 20),
          const SkeletonBox(width: 220, height: 28),
          const SizedBox(height: AppSpacing.md),
        ],
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
    final week = _weekCompletion(cal);

    if (current <= 0) {
      return _buildEmptyHero(c, freezeCount, week);
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Freeze chip, right-aligned above the hero numeral.
        Align(
          alignment: Alignment.centerRight,
          child: _buildFreezeChip(c, freezeCount),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text('🔥', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 4),
        Text(
          '$current',
          style: ZType.disp(108, color: c.accent, letterSpacing: 1, height: 0.9),
        ),
        const SizedBox(height: 6),
        Text(
          'WEEK STREAK',
          style: ZType.lbl(13, color: c.textSecondary, letterSpacing: 3),
        ),
        const SizedBox(height: 4),
        Text(
          completed > 0
              ? '$completed ${completed == 1 ? 'day' : 'days'} this week'
              : 'Keep it going this week',
          style: ZType.lbl(11, color: c.textMuted, letterSpacing: 1.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildMomentumDots(c, week),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildEmptyHero(ThemeColors c, int freezeCount, List<bool> week) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: _buildFreezeChip(c, freezeCount),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '🔥',
          style: TextStyle(
            fontSize: 48,
            color: c.textMuted.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'START YOUR STREAK',
          style: ZType.disp(34, color: c.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Finish a workout to light the flame. '
            'Train each scheduled day to grow your week streak.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildMomentumDots(c, week),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  /// 7 day-dots: completed = accent-filled rounded square, today = blinking
  /// accent outline, future/missed = hairline outline.
  Widget _buildMomentumDots(ThemeColors c, List<bool> week) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < week.length; i++) ...[
          if (i == week.length - 1)
            // Today — blinking accent outline (over a fill if completed).
            AnimatedBuilder(
              animation: _blinkController,
              builder: (context, _) {
                final t = 0.35 + 0.65 * _blinkController.value;
                return Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: week[i] ? c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: c.accent.withValues(alpha: t),
                      width: 2,
                    ),
                  ),
                );
              },
            )
          else
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: week[i] ? c.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: week[i]
                    ? null
                    : Border.all(color: AppColors.hairlineStrong),
              ),
            ),
          if (i != week.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildFreezeChip(ThemeColors c, int count) {
    // Cyan outline pill for streak-freeze.
    const cyan = Color(0xFF38BDF8);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/streak-freeze');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cyan.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ac_unit_rounded, size: 14, color: cyan),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: ZType.data(13, color: cyan),
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
      return Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: const [
                Expanded(child: SkeletonBox(width: 70, height: 34)),
                SizedBox(width: 16),
                Expanded(child: SkeletonBox(width: 70, height: 34)),
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

    Widget cell(String value, String label, {String? unit, bool accent = false}) {
      return Expanded(
        child: ZealovaStatTile(
          value: value,
          label: label,
          unit: unit,
          valueSize: 26,
          accentValue: accent,
        ),
      );
    }

    return Column(
      children: [
        const ZealovaRule(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell('$completed/$target', 'Workouts This Week', accent: true),
              const SizedBox(width: 16),
              cell('$bestStreak', 'Best Streak',
                  unit: bestStreak == 1 ? 'day' : 'days'),
            ],
          ),
        ),
        const ZealovaRule(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell('$consistencyStreak', 'Consistency Streak',
                  unit: consistencyStreak == 1 ? 'day' : 'days'),
              const SizedBox(width: 16),
              cell('$consistencyBest', 'Consistency Best',
                  unit: consistencyBest == 1 ? 'day' : 'days'),
            ],
          ),
        ),
        const ZealovaRule(),
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
    return AnimatedBuilder(
      animation: _boardTabController,
      builder: (context, _) => ZealovaTextTabs(
        tabs: const ['Current Streak', 'Workouts'],
        activeIndex: _boardTabController.index,
        onChanged: (i) {
          HapticService.light();
          _boardTabController.animateTo(i);
        },
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: isCurrentUser
            ? Border.all(color: c.accent, width: 1.5)
            : const Border(
                bottom: BorderSide(color: AppColors.hairline),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: ZType.disp(
                20,
                color: rank <= 3
                    ? (isCurrentUser ? c.accent : c.textPrimary)
                    : c.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser ? c.accent : AppColors.hairlineStrong,
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? c.accent : c.textSecondary,
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
            style: ZType.data(
              14,
              color: isCurrentUser ? c.accent : c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardEmpty(ThemeColors c, bool isStreakTab) {
    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
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

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        HapticService.light();
        context.push('/trophy-room');
      },
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TROPHIES',
                style: ZType.lbl(10, color: c.textMuted, letterSpacing: 2),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$earnedCount',
                    style: ZType.disp(30, color: c.accent),
                  ),
                  if (totalCount > 0) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/ $totalCount',
                        style: ZType.lbl(14, color: c.textSecondary,
                            letterSpacing: 1),
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
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.hairlineStrong),
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
    );
  }

  // ── shared ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(ThemeColors c, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: ZType.disp(22, color: c.textPrimary),
        ),
        const SizedBox(height: 3),
        ZealovaSectionKicker(subtitle),
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
