import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/cache/cache_first_mixin.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/stat_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/scores.dart';
import '../../data/models/training_intensity.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/repositories/scores_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/providers/training_intensity_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../shareables/shareable_data.dart';
import '../../shareables/shareable_sheet.dart';
import '../../widgets/pill_app_bar.dart';
import '../../core/widgets/line_icon.dart';
import '../../data/providers/trend_series_provider.dart';

import '../../l10n/generated/app_localizations.dart';
// ============================================================================
// Sort Mode
// ============================================================================

enum _SortMode { name, oneRm, recentPr }

// ============================================================================
// Disk cache
// ============================================================================

/// Disk tier for the Personal Records screen's `PRStats`.
///
/// `scoresProvider` keeps PR data only in a process-lifetime in-memory cache,
/// so the first open after a cold start blocked on a spinner while the
/// `loadPersonalRecords` / `loadStrengthScores` network calls ran. `PRStats`
/// is a `json_serializable` model (it exposes `toJson`/`fromJson`), so it can
/// safely round-trip through disk and seed an instant render here.
///
/// This host is owned by `personal_records_screen.dart` — the provider file
/// itself is out of scope, so the disk warm is driven from the screen's
/// `State` via [CacheFirstMixin].
class _PrDiskCache with CacheFirstMixin {
  /// Bump when [PRStats]'s JSON shape changes so stale blobs are dropped.
  static const int _schemaVersion = 1;

  /// PRs change only when a workout is logged — a 12h disk TTL is safe; the
  /// live provider fetch silently revalidates on every screen open anyway.
  static const Duration _ttl = Duration(hours: 12);

  Future<void> warmPrStats({
    required String userId,
    required Future<PRStats> Function() fetch,
    required void Function(PRStats, {required bool fromCache}) emit,
  }) {
    return loadCacheFirst<PRStats>(
      // periodDays=365 matches the screen's `loadPersonalRecords` call below.
      cacheKey: 'personal_records_prstats_365d',
      userId: userId,
      ttl: _ttl,
      schemaVersion: _schemaVersion,
      fetch: fetch,
      decode: PRStats.fromJson,
      encode: (p) => p.toJson(),
      emit: emit,
    );
  }
}

// ============================================================================
// Personal Records Screen
// ============================================================================

class PersonalRecordsScreen extends ConsumerStatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  ConsumerState<PersonalRecordsScreen> createState() =>
      _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends ConsumerState<PersonalRecordsScreen> {
  final _searchController = TextEditingController();
  final GlobalKey _reportKey = GlobalKey();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.recentPr;
  bool _sortAscending = false;

  /// Disk-cache host for `PRStats` (see [_PrDiskCache]).
  final _PrDiskCache _diskCache = _PrDiskCache();

  /// Last-known `PRStats` read off disk. Used as a fallback so a cold start
  /// renders the real PR list instantly instead of a skeleton; once
  /// `scoresProvider` resolves its `prStats`, that live value always wins.
  PRStats? _diskPrStats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(scoresProvider.notifier)
          .loadPersonalRecords(limit: 50, periodDays: 365);
      ref.read(scoresProvider.notifier).loadDotsScore();
      ref.read(scoresProvider.notifier).loadStrengthScores();
    });
    // Warm the disk tier in parallel with the provider fetches above. The
    // cached blob renders content immediately on a cold start; the fresh
    // value is written through for the next launch.
    _warmDiskCache();
  }

  Future<void> _warmDiskCache() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || !mounted) return;
    final repo = ref.read(scoresRepositoryProvider);
    await _diskCache.warmPrStats(
      userId: userId,
      // Mirrors `loadPersonalRecords(limit: 50, periodDays: 365)` above.
      fetch: () => repo.getPersonalRecords(
        userId: userId,
        limit: 50,
        periodDays: 365,
      ),
      emit: (stats, {required bool fromCache}) {
        if (!mounted) return;
        // Only the cached value seeds local state — the fresh value already
        // flows in through `scoresProvider`.
        if (fromCache) setState(() => _diskPrStats = stats);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);

    final scoresState = ref.watch(scoresProvider);
    // Live PR data wins; fall back to the disk snapshot so a cold start shows
    // the real list immediately instead of blocking on a spinner.
    final prStats = scoresState.prStats ?? _diskPrStats;
    final dotsScore = scoresState.dotsScore;
    final strengthScores = scoresState.strengthScores;
    final oneRMsState = ref.watch(userOneRMsProvider);
    final useKg = ref.watch(useKgForWorkoutProvider);

    // True first-ever cold load: no PR data from the provider OR disk, and a
    // fetch is still running. Only then do we show a skeleton — a returning
    // user always has the disk snapshot, so they never see one.
    final showSkeleton = prStats == null &&
        (scoresState.isLoading || oneRMsState.isLoading);

    // Build exercise → 1RM lookup
    final oneRmMap = <String, UserExercise1RM>{};
    for (final orm in oneRMsState.oneRMs) {
      oneRmMap[orm.exerciseName.toLowerCase()] = orm;
    }

    // Build exercise → strength score lookup
    final strengthMap = <String, StrengthScoreData>{};
    if (strengthScores != null) {
      for (final entry in strengthScores.muscleScores.entries) {
        final data = entry.value;
        if (data.bestExerciseName != null) {
          strengthMap[data.bestExerciseName!.toLowerCase()] = data;
        }
      }
    }

    // Group PRs by exercise, keep best per exercise
    final grouped = _groupAndFilter(prStats?.recentPrs ?? [], oneRmMap);

    return Scaffold(
      backgroundColor: bg,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).workoutSummaryGeneralPersonalRecords,
        actions: [
          PillAppBarAction(
            customIcon: LineIcon(
              'custom_trend',
              size: 20,
              color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
            ),
            onTap: () => context.push('/trends/custom',
                extra: TrendMetric.strength1rm),
          ),
          PillAppBarAction(
            icon: Icons.ios_share_rounded,
            onTap: () => _openShareSheet(
              prStats: prStats,
              grouped: grouped,
              useKg: useKg,
              accentColor: accentColor,
            ),
          ),
        ],
      ),
      body: showSkeleton
          ? _buildSkeleton(isDark)
          : RepaintBoundary(
              key: _reportKey,
              child: Container(
                color: bg,
                child: Column(
              children: [
                // Summary row
                if (prStats != null)
                  _buildSummaryRow(prStats, dotsScore, isDark, accentColor),

                // Search bar
                _buildSearchBar(isDark, accentColor),

                // Sort controls
                _buildSortControls(isDark, accentColor),

                // PR list
                Expanded(
                  child: grouped.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final entry = grouped[index];
                            return _ExercisePRCard(
                              pr: entry.bestPr,
                              oneRm: entry.oneRm,
                              strengthData: strengthMap[
                                  entry.bestPr.exerciseName.toLowerCase()],
                              useKg: useKg,
                              accentColor: accentColor,
                              isDark: isDark,
                              onTap: () {
                                HapticService.light();
                                context.push(
                                  '/stats/exercise-history/${Uri.encodeComponent(entry.bestPr.exerciseName)}',
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
              ),
            ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Share
  // ──────────────────────────────────────────────────────────────────────────

  /// Opens the unified ShareableSheet with a PR-specific payload.
  /// Top 5 PRs become highlight rows; hero number is the PR count.
  Future<void> _openShareSheet({
    required PRStats? prStats,
    required List<_ExercisePREntry> grouped,
    required bool useKg,
    required Color accentColor,
  }) async {
    HapticService.light();
    final currentUser = ref.read(currentUserProvider).asData?.value;

    // Top 5 lifts by estimated 1RM → highlights. The screen already sorted
    // and deduped via _groupAndFilter, so we can just take(5).
    final topFive = grouped.take(5).map((e) {
      final kg = e.oneRm?.oneRepMaxKg ?? e.bestPr.estimated1rmKg;
      final v = useKg ? kg : kg * 2.20462;
      final unit = useKg ? 'kg' : 'lb';
      return ShareableMetric(
        label: e.bestPr.exerciseDisplayName,
        value: '${v.round()} $unit',
        icon: Icons.emoji_events_rounded,
      );
    }).toList();

    if (topFive.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).personalRecordsNoPrsYetLog),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final periodLabel =
        DateFormat('MMM yyyy').format(DateTime.now()).toUpperCase();

    final data = Shareable(
      kind: ShareableKind.personalRecords,
      title: AppLocalizations.of(context).workoutSummaryGeneralPersonalRecords,
      periodLabel: periodLabel,
      heroValue: prStats?.totalPrs ?? grouped.length,
      heroUnitSingular: 'PR',
      highlights: topFive,
      userDisplayName: currentUser?.displayName,
      accentColor: accentColor,
    );
    if (!mounted) return;
    await ShareableSheet.show(context, data: data);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Group, filter, and sort PRs
  // ──────────────────────────────────────────────────────────────────────────

  List<_ExercisePREntry> _groupAndFilter(
    List<PersonalRecordScore> prs,
    Map<String, UserExercise1RM> oneRmMap,
  ) {
    // Group by exercise — keep the best (highest estimated 1RM) per exercise
    final map = <String, PersonalRecordScore>{};
    for (final pr in prs) {
      final key = pr.exerciseName.toLowerCase();
      if (!map.containsKey(key) ||
          pr.estimated1rmKg > map[key]!.estimated1rmKg) {
        map[key] = pr;
      }
    }

    // Filter by search
    var entries = map.entries.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.key.replaceAll('_', ' ').contains(_searchQuery.toLowerCase());
    }).map((e) {
      final orm = oneRmMap[e.key];
      return _ExercisePREntry(bestPr: e.value, oneRm: orm);
    }).toList();

    // Sort
    entries.sort((a, b) {
      int cmp;
      switch (_sortMode) {
        case _SortMode.name:
          cmp = a.bestPr.exerciseDisplayName
              .compareTo(b.bestPr.exerciseDisplayName);
          break;
        case _SortMode.oneRm:
          final aVal = a.oneRm?.oneRepMaxKg ?? a.bestPr.estimated1rmKg;
          final bVal = b.oneRm?.oneRepMaxKg ?? b.bestPr.estimated1rmKg;
          cmp = aVal.compareTo(bVal);
          break;
        case _SortMode.recentPr:
          cmp = a.bestPr.achievedAt.compareTo(b.bestPr.achievedAt);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return entries;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Summary Row
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryRow(
    PRStats stats,
    DotsScore? dots,
    bool isDark,
    Color accentColor,
  ) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    Widget statItem(String value, String label, IconData icon, Color iconColor) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            StatNumber(
              value: value,
              size: StatType.secondary,
              color: textPrimary,
              alignment: Alignment.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          statItem(
            '${stats.totalPrs}',
            'Total PRs',
            Icons.emoji_events_rounded,
            Colors.amber,
          ),
          _verticalDivider(isDark),
          statItem(
            '${stats.prsThisPeriod}',
            'Last 30d',
            Icons.calendar_today_rounded,
            accentColor,
          ),
          _verticalDivider(isDark),
          statItem(
            '${stats.currentPrStreak}',
            'PR Streak',
            Icons.local_fire_department_rounded,
            Colors.deepOrange,
          ),
          if (dots != null && dots.dotsScore > 0) ...[
            _verticalDivider(isDark),
            statItem(
              dots.dotsScore.toStringAsFixed(0),
              'DOTS',
              Icons.speed_rounded,
              Colors.purpleAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Search Bar
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark, Color accentColor) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).supersetExercisePickerSearchExercises,
          hintStyle: TextStyle(color: textMuted),
          prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: elevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sort Controls
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSortControls(bool isDark, Color accentColor) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context).personalRecordsSortBy,
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(width: 8),
          ..._SortMode.values.map((mode) {
            final isSelected = mode == _sortMode;
            String label;
            switch (mode) {
              case _SortMode.name:
                label = 'Name';
                break;
              case _SortMode.oneRm:
                label = '1RM';
                break;
              case _SortMode.recentPr:
                label = 'Recent';
                break;
            }
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() {
                    if (_sortMode == mode) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortMode = mode;
                      _sortAscending = false;
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? accentColor : textSecondary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 2),
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: accentColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Empty State
  // ──────────────────────────────────────────────────────────────────────────

  // ──────────────────────────────────────────────────────────────────────────
  // Skeleton — layout-matched cold-load placeholder
  // ──────────────────────────────────────────────────────────────────────────

  /// Mirrors the real body shape (summary row → search bar → sort row →
  /// PR card list) so the skeleton → content cross-fade does not reflow.
  /// Shown only on a genuine first-ever cold load (no disk snapshot yet).
  Widget _buildSkeleton(bool isDark) {
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SkeletonBox(height: 72, radius: 14),
          ),
          // Search bar
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SkeletonBox(height: 48, radius: 12),
          ),
          // Sort controls row
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SkeletonBox(width: 220, height: 24, radius: 8),
          ),
          // PR card list — each card ~118pt tall to match _ExercisePRCard.
          Expanded(
            child: SkeletonList(
              scrollable: true,
              itemCount: 7,
              spacing: 10,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemBuilder: (_, __) =>
                  const SkeletonCard(showLeading: false, lines: 3, height: 118),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Colors.amber.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).prSummaryCardNoPersonalRecordsYet,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).personalRecordsCompleteWorkoutsToStart,
              style: TextStyle(fontSize: 14, color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helper Models
// ============================================================================

class _ExercisePREntry {
  final PersonalRecordScore bestPr;
  final UserExercise1RM? oneRm;

  const _ExercisePREntry({required this.bestPr, this.oneRm});
}

// ============================================================================
// Exercise PR Card
// ============================================================================

class _ExercisePRCard extends StatelessWidget {
  final PersonalRecordScore pr;
  final UserExercise1RM? oneRm;
  final StrengthScoreData? strengthData;
  final bool useKg;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ExercisePRCard({
    required this.pr,
    this.oneRm,
    this.strengthData,
    required this.useKg,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  String _formatWeight(double kg) {
    if (useKg) return '${kg.toStringAsFixed(1)} kg';
    return '${(kg * 2.20462).toStringAsFixed(1)} lbs';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'elite':
        return Colors.amber;
      case 'advanced':
        return Colors.deepPurple;
      case 'intermediate':
        return Colors.blue;
      case 'novice':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _levelLabel(String level) {
    return level[0].toUpperCase() + level.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final current1rm = oneRm?.oneRepMaxKg ?? pr.estimated1rmKg;
    final bwRatio = strengthData?.bodyweightRatio;
    final level = strengthData?.strengthLevel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: exercise name + badges
            Row(
              children: [
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
                      if (pr.muscleGroup != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            pr.muscleGroup!
                                .replaceAll('_', ' ')
                                .split(' ')
                                .map((w) => w.isEmpty
                                    ? w
                                    : '${w[0].toUpperCase()}${w.substring(1)}')
                                .join(' '),
                            style:
                                TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
                // Badges
                if (pr.isAllTimePr)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context).workoutSummaryScreenAllTime,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                if (level != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _levelColor(level).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _levelLabel(level),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _levelColor(level),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: textMuted),
              ],
            ),
            const SizedBox(height: 10),

            // Stats row
            Row(
              children: [
                // PR weight x reps
                _statChip(
                  Icons.fitness_center,
                  '${_formatWeight(pr.weightKg)} x ${pr.reps}',
                  textSecondary,
                  textMuted,
                ),
                const SizedBox(width: 12),
                // Estimated 1RM
                _statChip(
                  Icons.speed,
                  '1RM: ${_formatWeight(current1rm)}',
                  accentColor,
                  textMuted,
                ),
                if (bwRatio != null) ...[
                  const SizedBox(width: 12),
                  _statChip(
                    Icons.monitor_weight_outlined,
                    '${bwRatio.toStringAsFixed(2)}x BW',
                    textSecondary,
                    textMuted,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Bottom: date + improvement
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  _formatDate(pr.achievedAt),
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
                const Spacer(),
                if (pr.improvementPercent != null &&
                    pr.improvementPercent! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.personalRecordsScreenValue(pr.improvementPercent!.toStringAsFixed(1)),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(
      IconData icon, String text, Color iconColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
        ),
      ],
    );
  }
}
