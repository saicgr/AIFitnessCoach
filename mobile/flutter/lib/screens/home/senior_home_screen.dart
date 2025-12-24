import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../widgets/senior/senior_button.dart';
import '../../widgets/senior/senior_card.dart';
import '../../widgets/senior/senior_nav.dart';

/// Simplified home screen for Senior Mode
/// Features:
/// - Today's workout with one-tap start
/// - Talk to Coach floating button
/// - Simple streak/progress display
/// - 4-icon bottom nav (Home, Library, Social, Settings)
class SeniorHomeScreen extends ConsumerStatefulWidget {
  const SeniorHomeScreen({super.key});

  @override
  ConsumerState<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends ConsumerState<SeniorHomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch workouts on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutsProvider.notifier).refresh();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Already on home
        setState(() => _currentNavIndex = 0);
        break;
      case 1:
        // Go to workouts/stats
        context.push('/library');
        break;
      case 2:
        // Go to nutrition/food
        context.push('/nutrition');
        break;
      case 3:
        // Go to settings
        context.push('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final workoutsState = ref.watch(workoutsProvider);
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final user = authState.user;

    final nextWorkout = workoutsNotifier.nextWorkout;
    final completedCount = workoutsNotifier.completedCount;
    final weeklyProgress = workoutsNotifier.weeklyProgress;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = user?.displayName;
    final userName = displayName?.split(' ').first ?? 'Friend';

    return SeniorScaffold(
      currentIndex: _currentNavIndex,
      onNavTap: _onNavTap,
      title: 'Home',
      body: RefreshIndicator(
        onRefresh: () => workoutsNotifier.refresh(),
        color: AppColors.cyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                '${_getGreeting()},',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$userName!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 32),

              // Today's Workout Card
              if (workoutsState.isLoading) ...[
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFDDDDDD),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ] else if (nextWorkout != null) ...[
                SeniorWorkoutCard(
                  workoutName: nextWorkout.name ?? 'Today\'s Workout',
                  exerciseCount: nextWorkout.exercises.length,
                  durationMinutes: nextWorkout.durationMinutes ?? 30,
                  onStart: () {
                    context.push('/workout/${nextWorkout.id}');
                  },
                ),
              ] else ...[
                // No workout scheduled
                SeniorCard(
                  title: 'No Workout Today',
                  subtitle: 'Take a rest or ask Coach for a quick workout',
                  icon: Icons.self_improvement,
                  iconColor: AppColors.purple,
                ),
              ],

              const SizedBox(height: 32),

              // Simple Stats Row
              Row(
                children: [
                  Expanded(
                    child: SeniorStatCard(
                      label: 'This Week',
                      value: '$completedCount',
                      icon: Icons.fitness_center,
                      iconColor: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SeniorStatCard(
                      label: 'Streak',
                      value: '${weeklyProgress.$1}',
                      icon: Icons.local_fire_department,
                      iconColor: const Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: SeniorQuickButton(
                      label: 'Water',
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFF2196F3),
                      onPressed: () => context.push('/hydration'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SeniorQuickButton(
                      label: 'Food',
                      icon: Icons.restaurant,
                      iconColor: const Color(0xFF4CAF50),
                      onPressed: () => context.push('/nutrition'),
                    ),
                  ),
                ],
              ),

              // Bottom padding for floating AI button
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
