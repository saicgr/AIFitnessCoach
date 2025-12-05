import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch workouts on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final workoutsState = ref.watch(workoutsProvider);
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final user = authState.user;

    final nextWorkout = workoutsNotifier.nextWorkout;
    final upcomingWorkouts = workoutsNotifier.upcomingWorkouts;
    final completedCount = workoutsNotifier.completedCount;
    final weeklyProgress = workoutsNotifier.weeklyProgress;

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: RefreshIndicator(
        onRefresh: () => workoutsNotifier.refresh(),
        color: AppColors.cyan,
        backgroundColor: AppColors.elevated,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              user?.displayName ?? 'User',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      _StatBadge(
                        icon: Icons.check_circle_outline,
                        value: '$completedCount',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        icon: Icons.local_fire_department,
                        value: '${weeklyProgress.$1}',
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                ),
              ),

              // Section: TODAY
              const SliverToBoxAdapter(
                child: _SectionHeader(title: 'TODAY'),
              ),

              // Today's Goal Card
              SliverToBoxAdapter(
                child: _TodaysGoalCard(
                  completed: weeklyProgress.$1,
                  total: weeklyProgress.$2 > 0 ? 1 : 0,
                ),
              ),

              // Next Workout Card
              SliverToBoxAdapter(
                child: workoutsState.when(
                  loading: () => _LoadingCard(),
                  error: (e, _) => _ErrorCard(
                    message: 'Failed to load workouts',
                    onRetry: () => workoutsNotifier.refresh(),
                  ),
                  data: (_) => nextWorkout != null
                      ? _NextWorkoutCard(
                          workout: nextWorkout,
                          onStart: () => context.push('/workout/${nextWorkout.id}'),
                        )
                      : _EmptyWorkoutCard(
                          onGenerate: () => context.go('/onboarding'),
                        ),
                ),
              ),

              // Section: YOUR WEEK
              const SliverToBoxAdapter(
                child: _SectionHeader(title: 'YOUR WEEK'),
              ),

              // Weekly Progress
              SliverToBoxAdapter(
                child: _WeeklyProgressCard(
                  completed: weeklyProgress.$1,
                  total: weeklyProgress.$2,
                ),
              ),

              // Section: UPCOMING
              if (upcomingWorkouts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'UPCOMING',
                    subtitle: '${upcomingWorkouts.length} workouts',
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= upcomingWorkouts.length) return null;
                      final workout = upcomingWorkouts[index];
                      return _UpcomingWorkoutCard(
                        workout: workout,
                        onTap: () => context.push('/workout/${workout.id}'),
                      ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
                    },
                    childCount: upcomingWorkouts.length.clamp(0, 3),
                  ),
                ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ─────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Badge
// ─────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Today's Goal Card
// ─────────────────────────────────────────────────────────────────

class _TodaysGoalCard extends StatelessWidget {
  final int completed;
  final int total;

  const _TodaysGoalCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final isComplete = total > 0 && completed >= total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: isComplete
              ? Border.all(color: AppColors.success.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isComplete ? AppColors.success : AppColors.cyan)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isComplete ? Icons.check_circle : Icons.flag_outlined,
                color: isComplete ? AppColors.success : AppColors.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Goal",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isComplete
                        ? 'Great job! Goal complete!'
                        : 'Complete your workout',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$completed/${total > 0 ? total : 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Next Workout Card
// ─────────────────────────────────────────────────────────────────

class _NextWorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onStart;

  const _NextWorkoutCard({required this.workout, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final difficultyColor = AppColors.getDifficultyColor(workout.difficulty ?? 'medium');
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.elevated,
              AppColors.elevated.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEXT WORKOUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workout.type?.toUpperCase() ?? 'STRENGTH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (workout.difficulty ?? 'Medium').capitalize(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: difficultyColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              workout.name ?? 'Workout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Stats row
            Row(
              children: [
                _StatPill(
                  icon: Icons.timer_outlined,
                  value: '${workout.durationMinutes ?? 45}m',
                ),
                const SizedBox(width: 12),
                _StatPill(
                  icon: Icons.fitness_center,
                  value: '${workout.exerciseCount} exercises',
                ),
                const SizedBox(width: 12),
                _StatPill(
                  icon: Icons.local_fire_department,
                  value: '~${workout.estimatedCalories} cal',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // Equipment
            if (workout.equipmentNeeded.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '🏋️ ${workout.equipmentNeeded.take(3).join(' • ')}${workout.equipmentNeeded.length > 3 ? ' +${workout.equipmentNeeded.length - 3} more' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty Workout Card
// ─────────────────────────────────────────────────────────────────

class _EmptyWorkoutCard extends StatelessWidget {
  final VoidCallback onGenerate;

  const _EmptyWorkoutCard({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.fitness_center,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No workouts scheduled',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Complete setup to get your personalized workout plan',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onGenerate,
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Weekly Progress Card
// ─────────────────────────────────────────────────────────────────

class _WeeklyProgressCard extends StatelessWidget {
  final int completed;
  final int total;

  const _WeeklyProgressCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0-indexed

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed of $total workouts',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.glassSurface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isToday = index == today;
                final isPast = index < today;

                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.cyan.withOpacity(0.2)
                            : isPast
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.glassSurface,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: AppColors.cyan, width: 2)
                            : null,
                      ),
                      child: isPast
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.success,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? AppColors.cyan : AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Upcoming Workout Card
// ─────────────────────────────────────────────────────────────────

class _UpcomingWorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _UpcomingWorkoutCard({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDay(workout.scheduledDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    Text(
                      _getMonth(workout.scheduledDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name ?? 'Workout',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${workout.durationMinutes ?? 45}m • ${workout.exerciseCount} exercises',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDay(String? date) {
    if (date == null) return '--';
    try {
      final d = DateTime.parse(date);
      return d.day.toString();
    } catch (_) {
      return '--';
    }
  }

  String _getMonth(String? date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[d.month - 1];
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Loading & Error Cards
// ─────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Extensions
// ─────────────────────────────────────────────────────────────────

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
