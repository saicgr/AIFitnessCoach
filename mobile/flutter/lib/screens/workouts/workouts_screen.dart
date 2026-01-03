import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/providers/multi_screen_tour_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/multi_screen_tour_helper.dart';
import '../home/widgets/cards/next_workout_card.dart';
import '../home/widgets/cards/upcoming_workout_card.dart';
import '../home/widgets/cards/weekly_progress_card.dart';

/// Workouts screen - central hub for all workout-related content
/// Accessible from the floating nav bar (replaces Profile)
class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  // Key for tour target
  final GlobalKey _todaysWorkoutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Check and regenerate workouts if needed when this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRegenerateIfNeeded();
    });
  }

  /// Check if user needs more workouts and trigger generation if needed
  /// This is called when Workouts tab loads
  Future<void> _checkAndRegenerateIfNeeded() async {
    // Only check once per session
    final hasChecked = ref.read(hasCheckedRegenerationProvider);
    if (hasChecked) return;

    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final result = await workoutsNotifier.checkAndRegenerateIfNeeded();

    // Mark as checked for this session
    ref.read(hasCheckedRegenerationProvider.notifier).state = true;

    // Show snackbar if generation was triggered
    if (result['needs_generation'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Generating your upcoming workouts...'),
          backgroundColor: AppColors.elevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should show tour step when this screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTourStep();
    });
  }

  /// Check and show the tour step for workouts screen
  void _checkAndShowTourStep() {
    final tourState = ref.read(multiScreenTourProvider);

    if (!tourState.isActive || tourState.isLoading) return;

    final currentStep = tourState.currentStep;
    if (currentStep == null) return;

    // Workouts screen handles step 2 (todays_workout_card)
    if (currentStep.screenRoute != '/workouts') return;

    if (currentStep.targetKeyId == 'todays_workout_card') {
      final helper = MultiScreenTourHelper(context: context, ref: ref);
      helper.checkAndShowTour('/workouts', _todaysWorkoutKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Watch workouts state
    final workoutsState = ref.watch(workoutsProvider);

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
                      onPressed: () => ref.invalidate(workoutsProvider),
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
  ) {
    // Get next workout (first upcoming one)
    final now = DateTime.now();
    final upcomingWorkouts = workouts.where((w) {
      if (w.scheduledDate == null) return false;
      final date = DateTime.tryParse(w.scheduledDate!);
      if (date == null) return false;
      return date.isAfter(now.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.scheduledDate ?? '') ?? DateTime(2099);
        final dateB = DateTime.tryParse(b.scheduledDate ?? '') ?? DateTime(2099);
        return dateA.compareTo(dateB);
      });

    final nextWorkout = upcomingWorkouts.isNotEmpty ? upcomingWorkouts.first : null;
    final laterWorkouts = upcomingWorkouts.skip(1).take(5).toList();

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

        // Today's Workout Section
        if (nextWorkout != null) ...[
          _buildSectionHeader('TODAY\'S WORKOUT', textSecondary),
          const SizedBox(height: 8),
          Padding(
            key: _todaysWorkoutKey,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NextWorkoutCard(
              workout: nextWorkout,
              onStart: () {
                HapticService.medium();
                context.push('/active-workout', extra: nextWorkout);
              },
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          // No workout scheduled - also use the key for tour purposes
          Container(
            key: _todaysWorkoutKey,
            child: _buildNoWorkoutCard(context, isDark, textPrimary, textSecondary),
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
          _buildSectionHeader(
            'UPCOMING',
            textSecondary,
            actionText: 'View Schedule',
            onAction: () {
              HapticService.light();
              context.push('/schedule');
            },
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

  Widget _buildNoWorkoutCard(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: AppColors.cyan.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No workout scheduled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a custom workout or browse the library',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    HapticService.light();
                    context.push('/workout/build');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Custom Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
