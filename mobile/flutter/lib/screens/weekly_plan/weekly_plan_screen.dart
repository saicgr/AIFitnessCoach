import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/week_start_provider.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/models/workout.dart';
import '../../data/providers/weekly_plan_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/image_url_cache.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../shareables/adapters/weekly_plan_adapter.dart';
import '../../shareables/shareable_catalog.dart';
import '../../shareables/shareable_sheet.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import 'widgets/day_card.dart';
import 'widgets/plan_header.dart';
import 'widgets/generate_plan_sheet.dart';
import 'daily_plan_detail_sheet.dart';
import '../../core/services/posthog_service.dart';
import '../../shareables/widgets/share_plan_period_sheet.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';
/// Weekly plan screen showing the holistic plan calendar view
class WeeklyPlanScreen extends ConsumerStatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  ConsumerState<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends ConsumerState<WeeklyPlanScreen> {
  @override
  void initState() {
    super.initState();
    // Load current plan on init
    Future.microtask(() {
      ref.read(weeklyPlanProvider.notifier).loadCurrentPlan();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'weekly_plan_viewed');
    });
  }

  void _showGeneratePlanSheet() {
    showGlassSheet(
      context: context,
      builder: (context) => const GlassSheet(
        child: GeneratePlanSheet(),
      ),
    );
  }

  void _showDayDetail(DailyPlanEntry entry) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: DailyPlanDetailSheet(entry: entry),
      ),
    );
  }

  /// Top-level share chooser: "Share as image" opens the period picker in
  /// image mode (Week Grid / Month Grid gallery); "Share link" keeps the
  /// existing zealova.com/p/{token} link flow unchanged.
  void _showShareChooser() {
    showGlassSheet(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share your plan',
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _ShareOptionTile(
                label: 'Share as image',
                subtitle: 'A polished card for stories and feeds',
                icon: Icons.image_rounded,
                color: AppColors.purple,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  SharePlanPeriodSheet.show(
                    context,
                    imageMode: true,
                    onPickImage: _shareImage,
                  );
                },
              ),
              const SizedBox(height: 8),
              _ShareOptionTile(
                label: 'Share link',
                subtitle: 'A web link anyone can open',
                icon: Icons.link_rounded,
                color: AppColors.info,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  SharePlanPeriodSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the Week / Month plan-grid Shareable and open the gallery. Reads
  /// the user's loaded workouts, computes the window (week anchored at the
  /// user's week-start preference; month = 1st..last), warms exercise
  /// thumbnails, then opens [ShareableSheet] on the right grid template.
  Future<void> _shareImage(BuildContext shareContext, bool isMonth) async {
    final workouts = ref.read(workoutsProvider).valueOrNull ?? <Workout>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime windowStart;
    final DateTime windowEnd;
    if (isMonth) {
      windowStart = DateTime(today.year, today.month, 1);
      // Day 0 of next month == last day of this month.
      windowEnd = DateTime(today.year, today.month + 1, 0);
    } else {
      final config = ref.read(weekDisplayConfigProvider);
      windowStart = config.weekStart(today);
      windowEnd = windowStart.add(const Duration(days: 6));
    }

    final shareable = WeeklyPlanAdapter.fromWorkouts(
      ref: ref,
      workouts: workouts,
      windowStart: windowStart,
      windowEnd: windowEnd,
      isMonth: isMonth,
    );

    if (shareable == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough data yet')),
      );
      return;
    }

    // Warm exercise thumbnails so the day cells aren't blank in the captured
    // PNG. Batch-fetch any uncached names, then precache the resolved URLs.
    final names = <String>{
      for (final day in (shareable.planDays ?? const []))
        for (final ex in day.exercises) ex.name,
    }.toList();
    if (names.isNotEmpty) {
      final api = ref.read(apiClientProvider);
      await ImageUrlCache.batchPreFetch(names, api);
    }
    if (!mounted) return;
    final thumbUrls = <String>{
      for (final day in (shareable.planDays ?? const []))
        for (final ex in day.exercises)
          if (ex.imageUrl != null && ex.imageUrl!.startsWith('http'))
            ex.imageUrl!,
    };
    for (final url in thumbUrls) {
      // ignore: unawaited_futures
      precacheImage(NetworkImage(url), context).catchError((_) {});
    }

    if (!mounted) return;
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    await ShareableSheet.show(
      context,
      data: shareable,
      initialTemplate: isMonth
          ? ShareableTemplate.monthlyPlanGrid
          : ShareableTemplate.weeklyPlanGrid,
    );
    if (mounted) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(weeklyPlanProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: PillAppBar(
        title: AppLocalizations.of(context).weeklyPlanWeeklyPlan,
        actions: [
          PillAppBarAction(
            icon: Icons.ios_share_rounded,
            onTap: _showShareChooser,
          ),
          if (planState.currentPlan != null)
            PillAppBarAction(icon: Icons.refresh, onTap: _showGeneratePlanSheet),
        ],
      ),
      body: _buildBody(planState, colorScheme),
      floatingActionButton: planState.currentPlan == null && !planState.isLoading
          ? FloatingActionButton.extended(
              onPressed: _showGeneratePlanSheet,
              icon: const Icon(Icons.auto_awesome),
              label: Text(AppLocalizations.of(context).weeklyPlanGeneratePlan),
            )
          : null,
    );
  }

  Widget _buildBody(WeeklyPlanState planState, ColorScheme colorScheme) {
    if (planState.isLoading) {
      // Instant-load: a layout-matched skeleton instead of a blocking spinner.
      // The cache-first provider seeds currentPlan from disk before first
      // build for returning users, so this skeleton is a cold-install-only
      // affordance.
      return _buildSkeleton(colorScheme);
    }

    if (planState.error != null && planState.currentPlan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).weeklyPlanErrorLoadingPlan,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                planState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(weeklyPlanProvider.notifier).loadCurrentPlan();
                },
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).buttonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (planState.currentPlan == null) {
      return _buildEmptyState(colorScheme);
    }

    return _buildPlanView(planState.currentPlan!, colorScheme);
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).weeklyPlanNoWeeklyPlanYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).weeklyPlanCreateAHolisticPlan,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _showGeneratePlanSheet,
              icon: const Icon(Icons.auto_awesome),
              label: Text(AppLocalizations.of(context).weeklyPlanGenerateMyPlan),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Layout-matched skeleton for the plan view: a header block followed by a
  /// vertical list of day-card placeholders. Mirrors [_buildPlanView] so the
  /// skeleton -> content cross-fade does not reflow.
  Widget _buildSkeleton(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: const [
        // Plan header placeholder.
        SkeletonBox(height: 132, radius: 16),
        SizedBox(height: 16),
        // Seven day-card placeholders (one per weekday).
        SkeletonList(itemCount: 7, spacing: 12),
      ],
    );
  }

  Widget _buildPlanView(WeeklyPlan plan, ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        // Plan header with overview
        SliverToBoxAdapter(
          child: PlanHeader(plan: plan),
        ),

        // Daily entries
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = plan.dailyEntries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DayCard(
                    entry: entry,
                    onTap: () => _showDayDetail(entry),
                  ),
                );
              },
              childCount: plan.dailyEntries.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}

/// One row in the top-level "Share your plan" chooser (image vs link).
class _ShareOptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
