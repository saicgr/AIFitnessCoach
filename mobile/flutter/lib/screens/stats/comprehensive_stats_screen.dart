import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/haptic_service.dart';

/// Comprehensive Stats Screen
/// Combines: Workout stats, achievements, body measurements, progress graphs, nutrition
class ComprehensiveStatsScreen extends ConsumerStatefulWidget {
  const ComprehensiveStatsScreen({super.key});

  @override
  ConsumerState<ComprehensiveStatsScreen> createState() => _ComprehensiveStatsScreenState();
}

class _ComprehensiveStatsScreenState extends ConsumerState<ComprehensiveStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Your Stats',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  // Share/Export button
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      HapticService.light();
                      // TODO: Export stats
                    },
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.purple, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Progress'),
                  Tab(text: 'Body'),
                  Tab(text: 'Nutrition'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(),
                  _ProgressTab(),
                  _BodyTab(),
                  _NutritionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// OVERVIEW TAB - Summary stats, recent achievements, weekly progress
// ═══════════════════════════════════════════════════════════════════

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final completedCount = workoutsNotifier.completedCount;
    final weeklyProgress = workoutsNotifier.weeklyProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.fitness_center,
                  label: 'Total Workouts',
                  value: '$completedCount',
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'This Week',
                  value: '${weeklyProgress.$1}/${weeklyProgress.$2}',
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  label: 'Streak',
                  value: '7 days',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Total Time',
                  value: '12.5h',
                  color: AppColors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Achievements Preview
          _SectionHeader(
            title: 'Recent Achievements',
            onViewAll: () => context.push('/achievements'),
          ),
          const SizedBox(height: 12),
          _AchievementsPreview(),

          const SizedBox(height: 24),

          // Quick Actions
          _SectionHeader(title: 'Quick Access'),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.insights,
            label: 'View Detailed Metrics',
            onTap: () => context.push('/metrics'),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.monitor_weight_outlined,
            label: 'Body Measurements',
            onTap: () => context.push('/measurements'),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.calendar_month,
            label: 'Weekly Summaries',
            onTap: () => context.push('/summaries'),
          ),

          // Bottom padding for floating nav bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRESS TAB - Graphs, trends, PRs
// ═══════════════════════════════════════════════════════════════════

class _ProgressTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Workout Frequency'),
          const SizedBox(height: 12),
          _PlaceholderGraph(
            height: 200,
            message: 'Weekly workout frequency chart',
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: 'Volume Progression'),
          const SizedBox(height: 12),
          _PlaceholderGraph(
            height: 200,
            message: 'Total volume over time',
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: 'Personal Records'),
          const SizedBox(height: 12),
          _PRList(),

          // Bottom padding for floating nav bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BODY TAB - Weight, measurements, body composition
// ═══════════════════════════════════════════════════════════════════

class _BodyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight tracking
          _SectionHeader(
            title: 'Weight Tracking',
            onViewAll: () => context.push('/measurements'),
          ),
          const SizedBox(height: 12),
          _PlaceholderGraph(
            height: 200,
            message: 'Weight trend over time',
          ),

          const SizedBox(height: 24),

          // Current measurements
          _SectionHeader(title: 'Current Measurements'),
          const SizedBox(height: 12),
          _MeasurementsList(),

          const SizedBox(height: 24),

          // Add measurement button
          ElevatedButton.icon(
            onPressed: () => context.push('/measurements'),
            icon: const Icon(Icons.add),
            label: const Text('Log New Measurement'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          // Bottom padding for floating nav bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// NUTRITION TAB - Calorie trends, macro breakdown, goals
// ═══════════════════════════════════════════════════════════════════

class _NutritionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Daily Averages (7 days)'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '2,150',
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.opacity,
                  label: 'Water',
                  value: '2.1L',
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: 'Macro Breakdown'),
          const SizedBox(height: 12),
          _PlaceholderGraph(
            height: 150,
            message: 'Protein / Carbs / Fats pie chart',
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: 'Calorie Trend'),
          const SizedBox(height: 12),
          _PlaceholderGraph(
            height: 200,
            message: 'Daily calorie intake over time',
          ),

          const SizedBox(height: 24),

          // Quick action to nutrition screen
          ElevatedButton.icon(
            onPressed: () => context.go('/nutrition'),
            icon: const Icon(Icons.restaurant),
            label: const Text('Track Nutrition'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          // Bottom padding for floating nav bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BadgeIcon(icon: '🏆', label: 'First Workout', unlocked: true),
          _BadgeIcon(icon: '🔥', label: '7 Day Streak', unlocked: true),
          _BadgeIcon(icon: '💪', label: '10 Workouts', unlocked: true),
          _BadgeIcon(icon: '🎯', label: '30 Days', unlocked: false),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final String icon;
  final String label;
  final bool unlocked;

  const _BadgeIcon({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          icon,
          style: TextStyle(
            fontSize: 32,
            color: unlocked ? null : Colors.grey.withOpacity(0.3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.cyan),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderGraph extends StatelessWidget {
  final double height;
  final String message;

  const _PlaceholderGraph({required this.height, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(Coming soon)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PRList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final prs = [
      {'exercise': 'Bench Press', 'weight': '100 kg', 'date': '2024-01-15'},
      {'exercise': 'Squat', 'weight': '140 kg', 'date': '2024-01-10'},
      {'exercise': 'Deadlift', 'weight': '160 kg', 'date': '2024-01-08'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: prs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final pr = prs[index];
          return ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.orange),
            title: Text(pr['exercise']!),
            subtitle: Text(pr['date']!),
            trailing: Text(
              pr['weight']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MeasurementsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final measurements = [
      {'label': 'Weight', 'value': '75.0 kg', 'change': '-2.5 kg'},
      {'label': 'Body Fat', 'value': '15.2%', 'change': '-1.8%'},
      {'label': 'Chest', 'value': '102 cm', 'change': '+3 cm'},
      {'label': 'Waist', 'value': '82 cm', 'change': '-5 cm'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: measurements.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final measurement = measurements[index];
          final isPositive = measurement['change']!.startsWith('+');
          final isNegative = measurement['change']!.startsWith('-');

          return ListTile(
            title: Text(measurement['label']!),
            subtitle: Text(measurement['change']!),
            trailing: Text(
              measurement['value']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPositive
                    ? AppColors.success
                    : isNegative
                        ? AppColors.orange
                        : AppColors.cyan,
              ),
            ),
          );
        },
      ),
    );
  }
}
