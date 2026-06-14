import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_first_mixin.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/goal_unit.dart';
import '../../../core/constants/stat_typography.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/services/personal_goals_service.dart';
import '../../../data/models/consistency.dart';
import '../../../data/models/milestone.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/providers/milestones_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/repositories/consistency_repository.dart';
import '../../../data/repositories/milestones_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/data_cache_service.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/activity_heatmap.dart';
import '../../../widgets/exercise_search_results.dart';
import '../../../widgets/workout_day_detail_sheet.dart';
import '../../workouts/widgets/workout_stats/workout_stats_section.dart'
    show WorkoutStatsDeepDive;
// Gravl-parity scannable score/activity cards (Surface 5). These are
// self-contained const ConsumerWidgets that own their own data fetching — they
// are dropped into the 2-up rows below. (Created concurrently by a sibling
// agent; imports may resolve late during a parallel build.)
import 'overview/strength_score_card.dart';
import 'overview/weekly_score_card.dart';
import 'overview/activity_streak_card.dart';
import 'overview/month_highlight_card.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Disk-cached snapshots for the Overview tab.
///
/// The Overview-tab providers (`milestonesProvider`, `consistencyProvider`)
/// are plain `StateNotifier`s with only a *process-lifetime* in-memory cache —
/// nothing survives a cold app restart, so the first open after a restart
/// always blocked on a spinner while the network fetch ran.
///
/// This holder gives those two providers a disk tier. It is owned entirely by
/// `overview_tab.dart` (the provider files themselves must not be edited), so
/// the disk warm runs from the tab's `State`: on `initState` it reads the
/// last-known `MilestonesResponse` / `CalendarHeatmapResponse` off disk and
/// renders them as a fallback while the provider's live fetch is in flight.
/// The fresh value is written back through after every successful load.
///
/// `MilestonesResponse` and `CalendarHeatmapResponse` are both
/// `json_serializable` models (they expose `toJson`/`fromJson`), which is what
/// makes a disk round-trip safe here. `ScoresOverview` is intentionally NOT
/// cached: that model has no `toJson`, so it can only be skeletonised.
class _OverviewDiskCache with CacheFirstMixin {
  // Plain disk-cache helper (no lifecycle) — always "mounted".
  @override
  bool get mounted => true;

  /// Bump when the cached model shapes change so stale blobs are dropped.
  static const int _schemaVersion = 1;

  /// Milestones survive 12h on disk — achievements change slowly.
  static const Duration _milestonesTtl = Duration(hours: 12);

  /// The activity calendar survives 6h — it rolls as workouts complete.
  static const Duration _calendarTtl = Duration(hours: 6);

  /// Read the cached milestones blob, then fetch fresh via [fetch].
  Future<void> warmMilestones({
    required String userId,
    required Future<MilestonesResponse> Function() fetch,
    required void Function(MilestonesResponse, {required bool fromCache}) emit,
  }) {
    return loadCacheFirst<MilestonesResponse>(
      cacheKey: 'stats_overview_milestones',
      userId: userId,
      ttl: _milestonesTtl,
      schemaVersion: _schemaVersion,
      fetch: fetch,
      decode: MilestonesResponse.fromJson,
      encode: (m) => m.toJson(),
      emit: emit,
    );
  }

  /// Read the cached 52-week calendar blob, then fetch fresh via [fetch].
  Future<void> warmCalendar({
    required String userId,
    required Future<CalendarHeatmapResponse> Function() fetch,
    required void Function(CalendarHeatmapResponse, {required bool fromCache})
        emit,
  }) {
    return loadCacheFirst<CalendarHeatmapResponse>(
      cacheKey: 'stats_overview_calendar_52w',
      userId: userId,
      ttl: _calendarTtl,
      schemaVersion: _schemaVersion,
      fetch: fetch,
      decode: CalendarHeatmapResponse.fromJson,
      encode: (c) => c.toJson(),
      emit: emit,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// OVERVIEW TAB - Summary stats, recent achievements, weekly progress
// ═══════════════════════════════════════════════════════════════════

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  Set<String> _highlightedDates = {};
  bool _showSearch = false;

  /// Disk-cache host for the milestones + calendar providers (see
  /// [_OverviewDiskCache]). Created once per tab lifetime.
  final _OverviewDiskCache _diskCache = _OverviewDiskCache();

  /// Last-known calendar read off disk. Used ONLY as a fallback for the
  /// compact stats row while `consistencyProvider` has no live data yet —
  /// once the provider resolves, its value always wins.
  CalendarHeatmapResponse? _diskCalendar;

  /// Last-known milestones read off disk. Fallback for `_AchievementsPreview`
  /// during the provider's first (post-cold-start) fetch.
  MilestonesResponse? _diskMilestones;

  @override
  void initState() {
    super.initState();
    // Warm the disk tier off the main build path. The provider network
    // fetches are kicked off separately by ComprehensiveStatsScreen's
    // `_loadTabData(0)`; this only fills the cold-start gap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmDiskCache());
  }

  /// Read both Overview disk caches and (best-effort) refresh them. Never
  /// throws — a miss simply leaves the skeleton/provider path in charge.
  Future<void> _warmDiskCache() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || !mounted) return;

    final consistencyRepo = ref.read(consistencyRepositoryProvider);
    final milestonesRepo = ref.read(milestonesRepositoryProvider);

    // Both warms run independently; a failure in one must not block the other.
    await Future.wait<void>([
      _diskCache.warmCalendar(
        userId: userId,
        // 52 weeks mirrors ComprehensiveStatsScreen's `loadCalendar(weeks: 52)`.
        fetch: () => consistencyRepo.getCalendarHeatmap(userId: userId, weeks: 52),
        emit: (data, {required bool fromCache}) {
          if (!mounted) return;
          // Only the cached value needs to flow into local state — the fresh
          // value is already being delivered through `consistencyProvider`.
          if (fromCache) setState(() => _diskCalendar = data);
        },
      ),
      _diskCache.warmMilestones(
        userId: userId,
        fetch: () => milestonesRepo.getMilestoneProgress(userId),
        emit: (data, {required bool fromCache}) {
          if (!mounted) return;
          if (fromCache) setState(() => _diskMilestones = data);
        },
      ),
    ]);
  }

  /// Whether an ROI-metrics load has already been requested this tab lifetime,
  /// so the post-frame callback in build() doesn't spam the endpoint.
  bool _roiRequested = false;

  /// Prime the real ROI metrics (total recorded workout time) once. These are
  /// not loaded by ComprehensiveStatsScreen, so the "Total Duration" stat needs
  /// to request them itself rather than estimating from completed-workout count.
  Future<void> _ensureRoiLoaded() async {
    if (_roiRequested || !mounted) return;
    _roiRequested = true;
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || !mounted) return;
    ref.read(milestonesProvider.notifier).loadROIMetrics(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final consistencyState = ref.watch(consistencyProvider);
    final currentStreak = consistencyState.currentStreak;

    // Stats from heatmap data (this endpoint always works)
    int completedCount = 0;
    int thisWeekCompleted = 0;
    int thisWeekTotal = 0;
    String totalDurationStr = '0m';

    // Read heatmap data synchronously via FutureBuilder in the widget tree
    // For now, compute from the consistency calendar data. Fall back to the
    // disk-cached calendar so a cold start shows real numbers (not zeros)
    // before `consistencyProvider`'s network fetch resolves.
    final calData = consistencyState.calendarData ?? _diskCalendar;
    if (calData != null) {
      completedCount = calData.totalCompleted;
      // Weekly: count completed/total this week from calendar data
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      for (final day in calData.data) {
        final dayDate = DateTime.tryParse(day.date);
        if (dayDate != null && !dayDate.isBefore(weekStart) && !dayDate.isAfter(now)) {
          if (day.status == 'completed') thisWeekCompleted++;
          if (day.status == 'completed' || day.status == 'missed') thisWeekTotal++;
        }
      }
    }

    // Total Duration: use REAL recorded workout time from ROI metrics, not a
    // fabricated `completedCount * 45` estimate. ROI metrics are not loaded by
    // ComprehensiveStatsScreen (it only calls loadMilestoneProgress), so prime
    // them once here. If the real value isn't available yet, show "--" rather
    // than a fake number (per the no-fabricated-data rule).
    final roi = ref.watch(milestonesProvider.select((s) => s.roiMetrics));
    if (roi == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRoiLoaded());
      totalDurationStr = '--';
    } else {
      final hours = roi.totalWorkoutTimeHours;
      if (hours <= 0) {
        totalDurationStr = '0m';
      } else {
        final totalMin = (hours * 60).round();
        totalDurationStr = totalMin >= 60
            ? '${(totalMin / 60).toStringAsFixed(1)}h'
            : '${totalMin}m';
      }
    }

    // Update highlighted dates when search query changes
    _updateHighlightedDates(searchQuery);

    return RefreshIndicator(
      onRefresh: () async {
        final uid = await ref.read(apiClientProvider).getUserId();
        if (uid == null) return;

        // Refresh all data
        final timeRange = ref.read(heatmapTimeRangeProvider);
        ref.invalidate(activityHeatmapProvider((userId: uid, weeks: timeRange.weeks, startDate: null, endDate: null)));
        await ref.read(consistencyProvider.notifier).loadCalendar(userId: uid, weeks: 52);
        ref.read(milestonesProvider.notifier).loadMilestoneProgress(userId: uid);
        ref.read(scoresProvider.notifier).loadScoresOverview(userId: uid);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. TOP SCORE ROW (2-up) ──────────────────────────────────
            // The two headline scores — Strength + Weekly — sit side-by-side
            // at the very top so the eye lands on "how am I doing" first.
            // Both cards self-fetch their data (sibling-owned widgets).
            // IntrinsicHeight bounds the Row's height to the taller card so
            // `stretch` can equalize both. Without it, the parent vertical
            // SingleChildScrollView passes an unbounded height into the Row and
            // `stretch` forces an infinite-height constraint on the Expanded
            // children → "BoxConstraints forces an infinite height" crash.
            const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: StrengthScoreCard()),
                  SizedBox(width: 12),
                  Expanded(child: WeeklyScoreCard()),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── 2. ACTIVITY ROW (2-up) ───────────────────────────────────
            const _OverviewSectionLabel(label: 'Activity'),
            const SizedBox(height: AppSpacing.sm),
            const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ActivityStreakCard()),
                  SizedBox(width: 12),
                  Expanded(child: MonthHighlightCard()),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── 3. HEATMAP ───────────────────────────────────────────────
            // The blue volume heatmap, presented prominently in its own card.
            // It renders its own header + legend, so this surface just frames
            // it and hosts the expandable exercise search.
            ZealovaCard(
              variant: ZealovaCardVariant.outlined,
              radius: AppRadius.lg,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  ActivityHeatmap(
                    highlightedDates: _highlightedDates,
                    isSearchActive: _showSearch ||
                        (searchQuery != null && searchQuery.isNotEmpty),
                    onSearchTapped: () {
                      HapticService.light();
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          // Clear search when closing
                          ref.read(exerciseSearchQueryProvider.notifier).state =
                              null;
                          _highlightedDates = {};
                        }
                      });
                    },
                    onDayTapped: (date) {
                      HapticService.light();
                      WorkoutDayDetailSheet.show(context, date);
                    },
                  ),
                  // Expandable Search Bar
                  if (_showSearch) ...[
                    const SizedBox(height: 12),
                    ExerciseSearchBar(
                      onSearch: (exerciseName) {
                        // Search results will automatically update via provider
                      },
                      onClear: () {
                        setState(() {
                          _highlightedDates = {};
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Search Results (shown when search is active)
            if (searchQuery != null && searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExerciseSearchResults(
                exerciseName: searchQuery,
                onResultTapped: (date) {
                  // Optionally highlight the tapped date
                },
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Compact at-a-glance stats strip (total / week / streak / time).
            // Kept under the heatmap as a quick numeric summary before Trends.
            ZealovaCard(
              variant: ZealovaCardVariant.outlined,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Total is the one accent stat; the rest stay muted/telemetric.
                  _CompactStat(
                    value: '$completedCount',
                    label: AppLocalizations.of(context).statsStreakFireTotal,
                    accent: true,
                  ),
                  const _StatDivider(),
                  _CompactStat(
                    value: '$thisWeekCompleted/$thisWeekTotal',
                    label: AppLocalizations.of(context).overviewWeek,
                  ),
                  const _StatDivider(),
                  _CompactStat(
                    value: currentStreak > 0 ? '$currentStreak' : '0',
                    label: AppLocalizations.of(context).xpProgressCardStreak,
                  ),
                  const _StatDivider(),
                  _CompactStat(
                    value: totalDurationStr,
                    label: AppLocalizations.of(context).workoutShowcaseTime,
                  ),
                ],
              ),
            ),

            // Active weekly goals (read-only glance; hidden when none active)
            const ActiveGoalsSection(),

            const SizedBox(height: AppSpacing.lg),

            // ── 4. TRENDS ────────────────────────────────────────────────
            // The deep-dive training-stats cards (volume trend chart, fueling
            // split, detailed strength-by-muscle + e1RM, best training time,
            // body-diagram heatmap) live inline here via WorkoutStatsDeepDive.
            // Its lead card IS the self-fetching weekly-volume trend chart, so
            // trends are surfaced INLINE (no nav push needed) under this header.
            const _OverviewSectionLabel(label: 'Trends'),
            const SizedBox(height: AppSpacing.sm),
            WorkoutStatsDeepDive(
              isDark: isDark,
              accent: ref.watch(accentColorProvider).getColor(isDark),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── 5. ACHIEVEMENTS (compact) ────────────────────────────────
            SectionHeader(
              title: AppLocalizations.of(context).overviewRecentAchievements,
              onViewAll: () => context.push('/achievements'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AchievementsPreview(diskFallback: _diskMilestones),

            const SizedBox(height: AppSpacing.lg),

            // ── 5. QUICK ACCESS ──────────────────────────────────────────
            SectionHeader(
                title: AppLocalizations.of(context).overviewQuickAccess),
            const SizedBox(height: AppSpacing.sm),
            QuickActionButton(
              icon: Icons.monitor_weight_outlined,
              label: AppLocalizations.of(context).reportsHubBodyMeasurements,
              onTap: () => context.push('/measurements'),
            ),
            const SizedBox(height: AppSpacing.sm),
            QuickActionButton(
              icon: Icons.calendar_month,
              label:
                  AppLocalizations.of(context).weeklyReportCardReportsInsights,
              onTap: () => context.push('/reports'),
            ),
            const SizedBox(height: AppSpacing.sm),
            QuickActionButton(
              icon: Icons.fitness_center,
              label: AppLocalizations.of(context).workoutSettingsMy1rms,
              onTap: () => context.push('/settings/my-1rms'),
            ),
            const SizedBox(height: AppSpacing.sm),
            QuickActionButton(
              icon: Icons.emoji_events,
              label: AppLocalizations.of(context)
                  .workoutSummaryGeneralPersonalRecords,
              onTap: () => context.push('/stats/personal-records'),
            ),
            const SizedBox(height: AppSpacing.sm),
            QuickActionButton(
              icon: Icons.history,
              label:
                  AppLocalizations.of(context).setTrackingSheetsExerciseHistory,
              onTap: () => context.push('/stats/exercise-history'),
            ),
            const SizedBox(height: AppSpacing.sm),
            QuickActionButton(
              icon: Icons.pie_chart_outline,
              label: AppLocalizations.of(context).strengthMuscleAnalytics,
              onTap: () => context.push('/stats/muscle-analytics'),
            ),

            // Bottom padding for floating nav bar
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _updateHighlightedDates(String? searchQuery) async {
    if (searchQuery == null || searchQuery.isEmpty) {
      if (_highlightedDates.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _highlightedDates = {};
            });
          }
        });
      }
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final timeRange = ref.read(heatmapTimeRangeProvider);

      final userId = await apiClient.getUserId();
      if (userId == null || !mounted) return;

      final response = await ref.read(exerciseSearchProvider((
        userId: userId,
        exerciseName: searchQuery,
        weeks: timeRange.weeks,
      )).future);

      if (!mounted) return;
      setState(() {
        _highlightedDates = response.matchingDates.toSet();
      });
    } catch (_) {
      // Ignore errors
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: ZType.lbl(14, color: tc.textPrimary, letterSpacing: 1.5),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              AppLocalizations.of(context).workoutHistoryImportViewAll.toUpperCase(),
              style: ZType.lbl(11, color: tc.accent, letterSpacing: 1.2),
            ),
          ),
      ],
    );
  }
}

/// Lightweight section label for the scannable Overview layout — a small
/// upper-tracked heading (e.g. "Activity", "Trends") with no trailing action.
/// Uses [ThemeColors] tokens so it tracks the active theme + accent.
class _OverviewSectionLabel extends StatelessWidget {
  final String label;

  const _OverviewSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return ZealovaSectionKicker(label, fontSize: 12);
  }
}

/// Compact stat widget for horizontal row display — Anton numeral over a
/// Barlow uppercase label. Only the `accent` stat carries the accent color.
class _CompactStat extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;

  const _CompactStat({
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: ZType.disp(24, color: accent ? tc.accent : tc.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

/// Hairline vertical divider for the compact stats row.
class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: AppColors.hairline,
    );
  }
}

class _AchievementsPreview extends ConsumerWidget {
  /// Disk-cached milestones supplied by `_OverviewTabState`. Rendered while
  /// the live `milestonesProvider` is still loading after a cold start, so
  /// the badge row shows real achievements instead of a placeholder.
  final MilestonesResponse? diskFallback;

  const _AchievementsPreview({this.diskFallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final milestonesState = ref.watch(milestonesProvider);

    // Source of truth: the live provider. Fall back to the disk snapshot so a
    // cold start renders content immediately; only show the skeleton when
    // neither the provider nor the disk cache has anything yet.
    final achieved = milestonesState.milestones != null
        ? milestonesState.achieved
        : (diskFallback?.achieved ?? const <MilestoneProgress>[]);
    final upcoming = milestonesState.milestones != null
        ? milestonesState.upcoming
        : (diskFallback?.upcoming ?? const <MilestoneProgress>[]);

    if (milestonesState.isLoading &&
        milestonesState.milestones == null &&
        diskFallback == null) {
      // Layout-matched skeleton: 4 badge slots mirroring the real badge row,
      // so the skeleton → content swap does not reflow the card.
      return ZealovaCard(
        variant: ZealovaCardVariant.outlined,
        radius: 16,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 88,
          child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              4,
              (_) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SkeletonCircle(size: 48),
                  SizedBox(height: 8),
                  SkeletonBox(width: 48, height: 10),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Build display list: up to 4 UNIQUE items by name, achieved first then upcoming
    final displayItems = <MilestoneProgress>[];
    final seenNames = <String>{};
    for (final mp in achieved) {
      if (seenNames.add(mp.milestone.name)) displayItems.add(mp);
      if (displayItems.length >= 4) break;
    }
    if (displayItems.length < 4) {
      for (final mp in upcoming) {
        if (seenNames.add(mp.milestone.name)) displayItems.add(mp);
        if (displayItems.length >= 4) break;
      }
    }

    if (displayItems.isEmpty) {
      return ZealovaCard(
        variant: ZealovaCardVariant.outlined,
        radius: 16,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 88,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_outlined,
                    color: tc.textMuted, size: 32),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)
                      .overviewNoAchievementsYet
                      .toUpperCase(),
                  style:
                      ZType.lbl(11, color: tc.textMuted, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: displayItems.map((mp) {
          return _BadgeIcon(
            iconData: _milestoneIcon(mp.milestone.icon),
            label: mp.milestone.name,
            unlocked: mp.isAchieved,
            color: Color(mp.milestone.tier.colorValue),
            tier: mp.milestone.tier,
          );
        }).toList(),
      ),
    );
  }

  static IconData _milestoneIcon(String? iconName) {
    switch (iconName) {
      case 'fire': return Icons.local_fire_department;
      case 'flame': return Icons.whatshot;
      case 'crown': return Icons.workspace_premium;
      case 'trophy': return Icons.emoji_events;
      case 'diamond': return Icons.diamond;
      case 'star': return Icons.star;
      case 'medal': return Icons.military_tech;
      case 'target': return Icons.gps_fixed;
      case 'muscle': return Icons.fitness_center;
      case 'dumbbell': return Icons.fitness_center;
      case 'clock': return Icons.timer;
      case 'hourglass': return Icons.hourglass_bottom;
      case 'scale': return Icons.monitor_weight;
      case 'calendar': return Icons.calendar_month;
      case 'chat_bubble': return Icons.chat_bubble;
      case 'camera_alt': return Icons.camera_alt;
      case 'qr_code_scanner': return Icons.qr_code_scanner;
      case 'fitness_center': return Icons.fitness_center;
      case 'emoji_events': return Icons.emoji_events;
      default: return Icons.emoji_events;
    }
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData iconData;
  final String label;
  final bool unlocked;
  final Color color;
  final MilestoneTier tier;

  const _BadgeIcon({
    required this.iconData,
    required this.label,
    required this.unlocked,
    required this.color,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hairline-framed glyph; tier identity color stays on the unlocked
          // icon only — locked badges read fully desaturated.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tc.surface,
              border: Border.all(
                color: unlocked ? color.withValues(alpha: 0.5) : AppColors.cardBorder,
                width: 1,
              ),
            ),
            child: Icon(
              iconData,
              size: 22,
              color: unlocked ? color : tc.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: ZType.lbl(
              8.5,
              color: unlocked ? tc.textSecondary : tc.textMuted,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ZealovaListRow(
      icon: icon,
      label: label,
      onTap: () {
        HapticService.light();
        onTap();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTIVE WEEKLY GOALS (read-only Overview surface)
// ═══════════════════════════════════════════════════════════════════

/// Read-only fetch of the user's current-week personal goals for the Overview
/// tab. Reuses the existing [PersonalGoalsService.getCurrentGoals] endpoint
/// (the same source the full Personal Goals screen reads) so this surface adds
/// no new data layer — it is glance-only and never edits a goal.
///
/// Returns the raw `goals` list (each entry is the same `Map<String, dynamic>`
/// shape `GoalCard` consumes: `current_value`, `target_value`, `unit`,
/// `is_pr_beaten`, `status`, `exercise_name`, `progress_percentage`). On a
/// signed-out user or any error it yields an empty list, so the section simply
/// renders nothing rather than surfacing a spinner or error on the hub.
final _overviewActiveGoalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // Survive Stats tab switches so the Active Goals section doesn't re-fetch on
  // every return. Invalidated after a body-measurement / goal write.
  ref.keepAlive();
  final apiClient = ref.read(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) return const [];
  const cacheKey = '${DataCacheService.statsKeyPrefix}overview_active_goals';
  // Cache-first (fresh-only, 12h): paint last-known active goals instantly on a
  // cold start; stale/missing falls through to the network.
  final cached = await DataCacheService.instance
      .getCachedList(cacheKey, userId: userId);
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }
  final service = PersonalGoalsService(apiClient);
  final data = await service.getCurrentGoals(userId: userId);
  final raw = data['goals'];
  if (raw is! List) return const [];
  final goals = <Map<String, dynamic>>[];
  for (final g in raw) {
    if (g is Map) {
      final map = Map<String, dynamic>.from(g);
      // Only active goals belong on the at-a-glance Overview surface.
      if ((map['status'] as String? ?? 'active') == 'active') {
        goals.add(map);
      }
    }
  }
  // Empty-guard: only persist a real (non-empty) result so a transient empty
  // never poisons the cache.
  if (goals.isNotEmpty) {
    await DataCacheService.instance.cacheList(cacheKey, goals, userId: userId);
  }
  return goals;
});

/// "Active Goals" Overview section: each active weekly goal as a glanceable
/// big-number progress tile (current value hero number, "of {target}" label,
/// percent-to-goal, and a PR badge when the personal best was beaten this
/// week). Renders nothing when signed out, loading-cold, or empty.
class ActiveGoalsSection extends ConsumerWidget {
  const ActiveGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_overviewActiveGoalsProvider);
    final goals = async.asData?.value ?? const <Map<String, dynamic>>[];
    if (goals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        SectionHeader(
          title: AppLocalizations.of(context).personalGoalsActiveGoals,
          onViewAll: () => context.push('/personal-goals'),
        ),
        const SizedBox(height: 12),
        ...goals.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GoalProgressTile(goal: g),
            )),
      ],
    );
  }
}

/// One glanceable goal tile: a hero current-value number with a small
/// "of {target}" label, a percent-to-goal bar, and a PR badge when beaten.
class _GoalProgressTile extends StatelessWidget {
  final Map<String, dynamic> goal;

  const _GoalProgressTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final exerciseName = goal['exercise_name'] as String? ?? 'Goal';
    final unit = GoalUnitExt.fromString(goal['unit'] as String?);
    final currentValue = (goal['current_value'] as num?) ?? 0;
    final targetValue = (goal['target_value'] as num?) ?? 0;
    final isPrBeaten = goal['is_pr_beaten'] as bool? ?? false;
    final rawPct = (goal['progress_percentage'] as num?)?.toDouble() ??
        (targetValue > 0 ? currentValue / targetValue * 100 : 0.0);
    final pct = rawPct.clamp(0.0, 100.0);

    // PR-beaten tiles glow in the streak/PR warm accent; in-progress tiles use
    // the calm cyan, matching the rest of the Overview surface palette.
    final tileColor = isPrBeaten ? AppColors.orange : AppColors.cyan;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrBeaten ? tileColor.withValues(alpha: 0.5) : cardBorder,
          width: isPrBeaten ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              if (isPrBeaten) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tileColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events,
                          size: 12, color: tileColor),
                      const SizedBox(width: 3),
                      Text(
                        'PR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tileColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: StatNumber(
                  value: _formatGoalValue(currentValue),
                  unit: unit.label,
                  size: StatType.hero,
                  color: tileColor,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'of ${unit.format(targetValue)}',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    backgroundColor: cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(tileColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tileColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Goal values are stored as integers for rep/volume goals; show no trailing
  /// `.0`. Decimal-unit goals (kg / km / miles) keep one decimal.
  String _formatGoalValue(num v) {
    final d = v.toDouble();
    if (d == d.truncate()) return d.toInt().toString();
    return d.toStringAsFixed(1);
  }
}

class PRListWidget extends ConsumerWidget {
  const PRListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final prStats = ref.watch(prStatsProvider);
    final recentPrs = prStats?.recentPrs ?? [];

    if (recentPrs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, size: 48, color: textMuted),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).prSummaryCardNoPersonalRecordsYet,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).overviewPersonalRecordsAreTracked,
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentPrs.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
        itemBuilder: (context, index) {
          final pr = recentPrs[index];
          final date = DateTime.tryParse(pr.achievedAt);
          final dateStr = date != null
              ? DateFormat('MMM d').format(date)
              : '';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pr.exerciseDisplayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.overviewTabValue(pr.liftDescription, dateStr),
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  ),
                ),
                if (pr.improvementPercent != null && pr.improvementPercent! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.overviewTabValue2(pr.improvementPercent!.toStringAsFixed(1)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
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
