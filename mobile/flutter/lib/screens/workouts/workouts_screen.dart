import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/haptic_service.dart';
import '../home/widgets/cards/next_workout_card.dart';
import '../home/widgets/cards/upcoming_workout_card.dart';
import '../home/widgets/cards/weekly_progress_card.dart';
import 'widgets/exercise_preferences_card.dart';

/// Workouts screen - central hub for all workout-related content
/// Accessible from the floating nav bar (replaces Profile)
class WorkoutsScreen extends ConsumerStatefulWidget {
  /// Optional parameter to scroll to a specific section
  final String? scrollTo;

  const WorkoutsScreen({super.key, this.scrollTo});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  // Key for upcoming section (for scroll-to functionality)
  final GlobalKey _upcomingSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Scroll to section if requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSectionIfNeeded();
    });
    // Note: We no longer batch-generate workouts here.
    // Workouts are now generated one-at-a-time after each completion.
  }

  /// Scroll to a section if scrollTo parameter is provided
  void _scrollToSectionIfNeeded() {
    if (widget.scrollTo == 'upcoming' && _upcomingSectionKey.currentContext != null) {
      // Small delay to ensure the UI is built
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_upcomingSectionKey.currentContext != null) {
          Scrollable.ensureVisible(
            _upcomingSectionKey.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Watch workouts state (for weekly progress, upcoming list)
    final workoutsState = ref.watch(workoutsProvider);
    // Watch todayWorkoutProvider (for today's/next workout - same as Home screen)
    final todayWorkoutState = ref.watch(todayWorkoutProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Library and Settings buttons
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Workouts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            actions: [
              // Library button
              IconButton(
                onPressed: () {
                  HapticService.light();
                  context.push('/library');
                },
                icon: Icon(
                  Icons.fitness_center,
                  color: AppColors.purple,
                  size: 24,
                ),
                tooltip: 'Exercise Library',
              ),
              // Settings button
              IconButton(
                onPressed: () {
                  HapticService.light();
                  context.push('/settings');
                },
                icon: Icon(
                  Icons.settings_outlined,
                  color: textSecondary,
                  size: 24,
                ),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          workoutsState.when(
            data: (workouts) => _buildContent(
              context,
              isDark,
              textPrimary,
              textSecondary,
              workouts,
              todayWorkoutState,
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load workouts',
                      style: TextStyle(color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(workoutsProvider);
                        ref.invalidate(todayWorkoutProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    List<Workout> workouts,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
  ) {
    final now = DateTime.now();

    // Use todayWorkoutProvider for today's/next workout (consistent with Home screen)
    Workout? todayOrNextWorkout;
    bool isToday = false;
    int? daysUntilNext;

    todayWorkoutState.whenData((response) {
      if (response != null) {
        if (response.hasWorkoutToday && response.todayWorkout != null) {
          todayOrNextWorkout = response.todayWorkout!.toWorkout();
          isToday = true;
        } else if (response.nextWorkout != null) {
          todayOrNextWorkout = response.nextWorkout!.toWorkout();
          daysUntilNext = response.daysUntilNext;
        }
      }
    });

    // Get upcoming workouts from workoutsProvider (skip the first one we show)
    final upcomingWorkouts = workouts.where((w) {
      if (w.scheduledDate == null) return false;
      final date = DateTime.tryParse(w.scheduledDate!);
      if (date == null) return false;
      // Skip today if we already have today's workout from todayWorkoutProvider
      if (isToday && todayOrNextWorkout != null && w.id == todayOrNextWorkout!.id) {
        return false;
      }
      // Skip the next workout if it matches what we're showing
      if (!isToday && todayOrNextWorkout != null && w.id == todayOrNextWorkout!.id) {
        return false;
      }
      return date.isAfter(now.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.scheduledDate ?? '') ?? DateTime(2099);
        final dateB = DateTime.tryParse(b.scheduledDate ?? '') ?? DateTime(2099);
        return dateA.compareTo(dateB);
      });

    final laterWorkouts = upcomingWorkouts.take(5).toList();

    // Calculate weekly progress
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final completedThisWeek = workouts.where((w) {
      if (w.isCompleted != true) return false;
      if (w.scheduledDate == null) return false;
      final scheduledDate = DateTime.tryParse(w.scheduledDate!);
      if (scheduledDate == null) return false;
      return scheduledDate.isAfter(startOfWeek) && scheduledDate.isBefore(endOfWeek);
    }).length;
    final plannedThisWeek = workouts.where((w) {
      if (w.scheduledDate == null) return false;
      final scheduledDate = DateTime.tryParse(w.scheduledDate!);
      if (scheduledDate == null) return false;
      return scheduledDate.isAfter(startOfWeek) &&
          scheduledDate.isBefore(startOfWeek.add(const Duration(days: 7)));
    }).length;

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 8),

        // Quick Actions Row
        _buildQuickActions(context, isDark, textSecondary),

        const SizedBox(height: 16),

        // Exercise Preferences (expandable)
        const ExercisePreferencesCard(),

        const SizedBox(height: 16),

        // Today's/Next Workout Section (using todayWorkoutProvider - same as Home)
        if (todayWorkoutState.isLoading) ...[
          _buildSectionHeader(
            'LOADING WORKOUT...',
            textSecondary,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ] else if (todayOrNextWorkout != null) ...[
          _buildSectionHeader(
            isToday ? 'TODAY\'S WORKOUT' : 'NEXT WORKOUT${daysUntilNext != null ? ' (in $daysUntilNext day${daysUntilNext == 1 ? '' : 's'})' : ''}',
            textSecondary,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NextWorkoutCard(
              workout: todayOrNextWorkout!,
              onStart: () {
                HapticService.medium();
                context.push('/active-workout', extra: todayOrNextWorkout);
              },
              showUpcomingLink: false,
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          // No workout available yet - show generating state (never "no workout")
          _buildSectionHeader(
            'YOUR WORKOUT',
            textSecondary,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Preparing your workout...',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Weekly Progress
        _buildSectionHeader('THIS WEEK', textSecondary),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WeeklyProgressCard(
            completed: completedThisWeek,
            total: plannedThisWeek > 0 ? plannedThisWeek : 5,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 24),

        // Upcoming Workouts
        if (laterWorkouts.isNotEmpty) ...[
          Container(
            key: _upcomingSectionKey,
            child: _buildSectionHeader(
              'UPCOMING',
              textSecondary,
              actionText: 'View Schedule',
              onAction: () {
                HapticService.light();
                context.push('/schedule');
              },
            ),
          ),
          const SizedBox(height: 8),
          ...laterWorkouts.map((workout) => UpcomingWorkoutCard(
                workout: workout,
                onTap: () {
                  HapticService.light();
                  context.push('/workout/${workout.id}');
                },
              )),
          const SizedBox(height: 16),
        ],

        // Bottom padding for nav bar
        const SizedBox(height: 100),
      ]),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Custom Workout
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.add_circle_outline,
              label: 'Custom',
              color: AppColors.cyan,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                context.push('/workout/build');
              },
            ),
          ),
          const SizedBox(width: 12),
          // Browse Library
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.search,
              label: 'Browse',
              color: AppColors.purple,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                context.push('/library');
              },
            ),
          ),
          const SizedBox(width: 12),
          // Schedule
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Schedule',
              color: AppColors.orange,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                context.push('/schedule');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    Color textColor, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: textColor,
            ),
          ),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cyan,
                ),
              ),
            ),
        ],
      ),
    );
  }

}
