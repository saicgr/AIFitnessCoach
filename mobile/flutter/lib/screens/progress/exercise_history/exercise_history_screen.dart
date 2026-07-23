import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/exercise_history.dart';
import '../../../data/models/scores.dart';
import '../../../data/providers/exercise_history_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/repositories/exercise_history_repository.dart';
import '../../../data/providers/gym_progress_filter_provider.dart';
import '../widgets/gym_progress_filter.dart';
import '../../../data/services/api_client.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/pill_app_bar.dart';
import '../../reports/widgets/report_share_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../common/app_refresh_indicator.dart';
/// Main screen showing list of most performed exercises and personal records
/// Two-tab layout: "Exercises" tab and "PRs" tab
class ExerciseHistoryScreen extends ConsumerStatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  ConsumerState<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends ConsumerState<ExerciseHistoryScreen>
    with SingleTickerProviderStateMixin {
  // Surface key for the per-gym progress filter on the exercise list. Selecting
  // a gym here carries into each exercise's detail chart on tap-through.
  static const _kExerciseListGymSurface = 'exercise-list';

  final _searchController = TextEditingController();
  final GlobalKey _reportKey = GlobalKey();
  late final TabController _tabController;
  DateTime? _screenOpenTime;
  // Cached so dispose() never has to touch `ref` after the widget is gone
  // (Riverpod throws "Cannot use ref after the widget was disposed").
  ExerciseHistoryRepository? _historyRepo;

  @override
  void initState() {
    super.initState();
    _screenOpenTime = DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
    ref.read(posthogServiceProvider).capture(eventName: 'exercise_history_viewed');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyRepo ??= ref.read(exerciseHistoryRepositoryProvider);
  }

  @override
  void dispose() {
    _logViewDuration();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _logViewDuration() {
    final repo = _historyRepo;
    final openedAt = _screenOpenTime;
    if (repo == null || openedAt == null) return;
    final duration = DateTime.now().difference(openedAt).inSeconds;
    repo.logView(
      exerciseName: 'list_view',
      sessionDurationSeconds: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PillAppBar(
        title: AppLocalizations.of(context).strengthExercisesPrs,
        actions: [
          PillAppBarAction(
            icon: Icons.ios_share_rounded,
            onTap: _openShareSheet,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _reportKey,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: ThemeColors.of(context).accent,
            indicatorWeight: 2,
            labelColor: ThemeColors.of(context).textPrimary,
            unselectedLabelColor: ThemeColors.of(context).textMuted,
            labelStyle: ZType.lbl(13, letterSpacing: 1.5),
            unselectedLabelStyle: ZType.lbl(13, letterSpacing: 1.5),
            tabs: const [
              Tab(icon: Icon(Icons.fitness_center_outlined), text: 'EXERCISES'),
              Tab(icon: Icon(Icons.emoji_events_outlined), text: 'PRS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExercisesTab(theme),
                const _PRsTab(),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  /// Opens the unified ReportShareSheet for exercise history. Hero number is
  /// the total number of distinct exercises; highlights are the top 5 most-
  /// performed (by session count) so recipients see real data points.
  Future<void> _openShareSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final user = ref.read(currentUserProvider).asData?.value;
    final async = ref.read(mostPerformedExercisesProvider);
    final list = async.asData?.value ?? const <MostPerformedExercise>[];
    // Top 5 most-performed by times_performed → highlights.
    final topFive = list.take(5).map((e) {
      return ReportHighlight(
        label: e.exerciseName,
        value: '${e.timesPerformed}×',
      );
    }).toList();
    final periodLabel =
        DateFormat('MMM yyyy').format(DateTime.now()).toUpperCase();
    final data = ReportShareData(
      reportType: ReportType.exerciseHistory,
      title: AppLocalizations.of(context).setTrackingSheetsExerciseHistory,
      periodLabel: periodLabel,
      primaryStats: {
        'exercises_count': list.length,
        if (list.isNotEmpty) 'top_exercise': list.first.exerciseName,
      },
      highlights: topFive,
      userDisplayName: user?.displayName,
      accentColor: accent,
      deepLinkUrl: null,
    );
    if (!mounted) return;
    await ReportShareSheet.show(context, data: data);
  }

  Widget _buildExercisesTab(ThemeData theme) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);

    return Column(
      children: [
        // Per-gym progress filter. Segments the per-exercise charts you drill
        // into by gym; hides itself automatically when the user has ≤1 gym.
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: GymProgressFilter(surfaceKey: _kExerciseListGymSurface),
        ),
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).supersetExercisePickerSearchExercises,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(exerciseSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              ref.read(exerciseSearchQueryProvider.notifier).state = value;
            },
          ),
        ),

        // Exercise list. Cache-first: the underlying FutureProvider is not
        // autoDispose, so a return visit shows the list instantly; the cold
        // load shows a layout-matched skeleton instead of a blocking spinner.
        Expanded(
          child: CacheFirstView<List<MostPerformedExercise>>(
            value: exercisesAsync,
            isFirstEver: !exercisesAsync.hasValue,
            traceLabel: 'exercise_history_list',
            skeletonBuilder: (_) => const SkeletonList(
              itemCount: 8,
              padding: EdgeInsets.all(16),
              scrollable: true,
            ),
            errorBuilder: (_, error, __) =>
                _buildErrorState(theme, error.toString()),
            contentBuilder: (context, exercises) {
              if (exercises.isEmpty) {
                return _buildEmptyState(theme);
              }
              return AppRefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(mostPerformedExercisesProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return _ExerciseCard(
                      exercise: exercise,
                      rank: index + 1,
                      onTap: () {
                        // Carry the list's gym selection into the exercise's
                        // detail chart (seedGym marks it resolved, so the
                        // detail screen's own default won't override it).
                        final sel = ref.read(
                            gymProgressFilterProvider(_kExerciseListGymSurface));
                        if (!sel.isAllGyms && sel.gymProfileId != null) {
                          ref
                              .read(gymProgressFilterProvider(
                                      'exercise:${exercise.exerciseName}')
                                  .notifier)
                              .seedGym(sel.gymProfileId!);
                        }
                        context.push('/stats/exercise-history/${Uri.encodeComponent(exercise.exerciseName)}');
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: ThemeColors.of(context).textMuted,
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).exerciseHistoryNoExerciseHistoryYet.toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.lbl(18, color: ThemeColors.of(context).textPrimary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).exerciseHistoryCompleteSomeWorkoutsTo,
              textAlign: TextAlign.center,
              style: ZType.ser(14, color: ThemeColors.of(context).textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).netflixExercisesFailedToLoadExercises,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(mostPerformedExercisesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).buttonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// PRs tab showing personal records summary and list
class _PRsTab extends ConsumerStatefulWidget {
  const _PRsTab();

  @override
  ConsumerState<_PRsTab> createState() => _PRsTabState();
}

class _PRsTabState extends ConsumerState<_PRsTab> {
  String? _userId;
  bool _hasLoadedPrs = false;

  @override
  void initState() {
    super.initState();
    _loadPRs();
  }

  Future<void> _loadPRs() async {
    final apiClient = ref.read(apiClientProvider);
    _userId = await apiClient.getUserId();
    if (_userId != null && !_hasLoadedPrs) {
      _hasLoadedPrs = true;
      ref.read(scoresProvider.notifier).loadPersonalRecords(
        userId: _userId,
        limit: 50,
        periodDays: 30,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Select just the slices read here — avoids rebuilds on unrelated
    // scores mutations.
    final (prStats, scoresLoading) = ref.watch(
      scoresProvider.select((s) => (s.prStats, s.isLoading)),
    );

    // Cache-first: `scoresProvider` retains prStats in memory across visits,
    // so a return shows records instantly. The cold load shows a
    // layout-matched skeleton (summary card + PR rows) instead of a spinner.
    if (scoresLoading && prStats == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // Summary card placeholder.
          SkeletonBox(height: 88, radius: 16),
          SizedBox(height: 16),
          // Recent-PR row placeholders.
          SkeletonList(itemCount: 6),
        ],
      );
    }

    if (prStats == null) {
      return _buildEmptyPRState(theme);
    }

    final recentPrs = prStats.recentPrs;

    return AppRefreshIndicator(
      onRefresh: () async {
        if (_userId != null) {
          await ref.read(scoresProvider.notifier).loadPersonalRecords(
            userId: _userId,
            limit: 50,
            periodDays: 30,
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          _buildSummaryCard(theme, prStats),
          const SizedBox(height: 16),

          // Recent PRs header — Barlow kicker over a hairline ledger.
          if (recentPrs.isNotEmpty) ...[
            ZealovaSectionKicker(
              AppLocalizations.of(context).strengthRecentPersonalRecords,
              padding: const EdgeInsets.only(bottom: 4),
            ),

            // PR ledger rows (hairline-divided, Anton lift numerals).
            ...recentPrs.map((pr) => _buildPRItem(theme, pr)),
          ],

          if (recentPrs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: _buildEmptyPRState(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, PRStats prStats) {
    // v2 closing tiles row: hairline-divided Anton numerals. Exactly one
    // accent cell (the live PR streak) — the rest stay matte.
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tc.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SummaryStatItem(
                value: prStats.totalPrs.toString(),
                label: AppLocalizations.of(context).exerciseHistoryTotalPrs,
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: AppColors.hairline),
            Expanded(
              child: _SummaryStatItem(
                value: prStats.prsThisPeriod.toString(),
                label: AppLocalizations.of(context).habitCardLast30Days,
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: AppColors.hairline),
            Expanded(
              child: _SummaryStatItem(
                value: prStats.currentPrStreak.toString(),
                label: AppLocalizations.of(context).exerciseHistoryPrStreak,
                accent: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRItem(ThemeData theme, PersonalRecordScore pr) {
    // v2 PR ledger row (.pg-pr): desaturated trophy · Barlow uppercase name
    // with a date·muscle telemetry subline · Anton lift numeral · green +%
    // delta. Hairline-divided rows, never boxed. The trophy stays matte so it
    // does not read as a second accent against the green deltas.
    final tc = ThemeColors.of(context);
    final isAllTime = pr.isAllTimePr;

    String formattedDate;
    try {
      final date = DateTime.parse(pr.achievedAt);
      formattedDate = DateFormat.yMMMd().format(date);
    } catch (_) {
      formattedDate = pr.achievedAt;
    }

    final muscle = pr.muscleGroup
        ?.replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    final subline = [
      formattedDate,
      if (muscle != null && muscle.isNotEmpty) muscle,
      if (isAllTime) AppLocalizations.of(context).workoutSummaryScreenAllTime,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isAllTime ? Icons.military_tech_outlined : Icons.emoji_events_outlined,
            size: 20,
            color: tc.textMuted,
          ),
          const SizedBox(width: 12),

          // Exercise name (Barlow uppercase) + telemetry subline (Space Mono).
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.exerciseDisplayName.toUpperCase(),
                  style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subline,
                  style: ZType.data(10, color: tc.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Anton lift numeral + green improvement delta.
          Text(
            pr.liftDescription,
            style: ZType.disp(18, color: tc.textPrimary, letterSpacing: 0.5),
          ),
          if (pr.improvementPercent != null && pr.improvementPercent! > 0) ...[
            const SizedBox(width: 9),
            Text(
              '+${pr.improvementPercent!.toStringAsFixed(0)}%',
              style: ZType.lbl(11, color: tc.success, letterSpacing: 0.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPRState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: ThemeColors.of(context).textMuted,
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).prSummaryCardNoPersonalRecordsYet.toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.lbl(18, color: ThemeColors.of(context).textPrimary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).exerciseHistoryKeepTrainingAndPushing,
              textAlign: TextAlign.center,
              style: ZType.ser(14, color: ThemeColors.of(context).textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary stat tile for the PR summary row — Anton numeral over a Barlow
/// label, hairline-divided. One tile may set [accent] (the single screen
/// accent); the rest stay matte.
class _SummaryStatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;

  const _SummaryStatItem({
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: ZType.disp(24,
                color: accent ? tc.accent : tc.textPrimary, height: 1),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

/// Card displaying a single exercise with stats
class _ExerciseCard extends StatelessWidget {
  final MostPerformedExercise exercise;
  final int rank;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // v2 leaderboard row (.pg-lb): Anton rank numeral (top-3 accent) · Barlow
    // exercise name + telemetry stat chips · Anton max-lift numeral. Hairline
    // divider, no boxed card.
    final tc = ThemeColors.of(context);
    final isTop = rank <= 3;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Row(
            children: [
              // Rank numeral (Anton) — top-3 accent, rest muted.
              SizedBox(
                width: 30,
                child: Text(
                  '$rank',
                  textAlign: TextAlign.center,
                  style: ZType.disp(16,
                      color: isTop ? tc.accent : tc.textMuted),
                ),
              ),
              const SizedBox(width: 10),

              // Exercise name (Barlow uppercase) + telemetry stat chips.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName.toUpperCase(),
                      style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (exercise.muscleGroup != null) ...[
                          Flexible(
                            child: _StatChip(
                              icon: Icons.fitness_center,
                              label: exercise.formattedMuscleGroup,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: _StatChip(
                            icon: Icons.repeat,
                            label: exercise.formattedTimesPerformed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Max-lift Anton numeral + last-performed telemetry.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (exercise.maxWeightKg != null && exercise.maxWeightKg! > 0)
                    Text(
                      exercise.formattedMaxWeight,
                      style: ZType.disp(17, color: tc.textPrimary, letterSpacing: 0.5),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    exercise.formattedLastPerformed,
                    style: ZType.data(10, color: tc.textMuted),
                  ),
                ],
              ),

              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: tc.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: tc.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.data(10, color: tc.textMuted),
          ),
        ),
      ],
    );
  }
}
