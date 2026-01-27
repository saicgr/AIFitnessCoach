import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers/weekly_plan_provider.dart';
import 'widgets/day_card.dart';
import 'widgets/plan_header.dart';
import 'widgets/generate_plan_sheet.dart';
import 'daily_plan_detail_sheet.dart';

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
  }

  void _showGeneratePlanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GeneratePlanSheet(),
    );
  }

  void _showDayDetail(DailyPlanEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyPlanDetailSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(weeklyPlanProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Plan'),
        actions: [
          if (planState.currentPlan != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Regenerate Plan',
              onPressed: _showGeneratePlanSheet,
            ),
        ],
      ),
      body: _buildBody(planState, colorScheme),
      floatingActionButton: planState.currentPlan == null && !planState.isLoading
          ? FloatingActionButton.extended(
              onPressed: _showGeneratePlanSheet,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Plan'),
            )
          : null,
    );
  }

  Widget _buildBody(WeeklyPlanState planState, ColorScheme colorScheme) {
    if (planState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your plan...'),
          ],
        ),
      );
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
                'Error loading plan',
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
                label: const Text('Retry'),
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
              'No Weekly Plan Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a holistic plan that coordinates your workouts, nutrition, and fasting schedule for the week.',
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
              label: const Text('Generate My Plan'),
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
