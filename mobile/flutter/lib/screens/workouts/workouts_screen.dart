import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/main_shell.dart';
import '../home/widgets/cards/next_workout_card.dart';
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
  // State for "Generate More" button
  bool _isGenerating = false;
  String? _generationMessage;

  @override
  void initState() {
    super.initState();
    // Collapse nav bar labels on this secondary page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navBarLabelsExpandedProvider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
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
            centerTitle: false,
            title: Text(
              'Workouts',
              style: TextStyle(
                fontSize: 32,
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
    bool isNextWeek = false;

    // Get user for checking if it's last workout day
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isLastWorkoutDay = user?.isLastWorkoutDayOfWeek ?? false;

    todayWorkoutState.whenData((response) {
      if (response != null) {
        if (response.hasWorkoutToday && response.todayWorkout != null) {
          todayOrNextWorkout = response.todayWorkout!.toWorkout();
          isToday = true;
        } else if (response.nextWorkout != null) {
          todayOrNextWorkout = response.nextWorkout!.toWorkout();
          daysUntilNext = response.daysUntilNext;
          // Check if next workout is in next week (more than remaining days this week)
          if (isLastWorkoutDay && daysUntilNext != null && daysUntilNext! > 0) {
            isNextWeek = true;
          }
        }
      }
    });

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
            isToday
                ? 'TODAY\'S WORKOUT'
                : isNextWeek
                    ? 'NEXT WEEK\'S WORKOUT${daysUntilNext != null ? ' (in $daysUntilNext day${daysUntilNext == 1 ? '' : 's'})' : ''}'
                    : 'NEXT WORKOUT${daysUntilNext != null ? ' (in $daysUntilNext day${daysUntilNext == 1 ? '' : 's'})' : ''}',
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

        // Generate More button - always visible
        _buildGenerateMoreSection(
          context,
          isDark,
          textPrimary,
          textSecondary,
        ),

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

  /// Build the "Generate More" section - always visible
  Widget _buildGenerateMoreSection(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isGenerating
                ? AppColors.cyan.withValues(alpha: 0.3)
                : AppColors.teal.withValues(alpha: 0.3),
          ),
        ),
        child: _isGenerating
            ? _buildGeneratingState(textPrimary, textSecondary)
            : _buildGenerateButton(
                context,
                textPrimary,
                textSecondary,
              ),
      ),
    );
  }

  Widget _buildGeneratingState(Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generating Workouts...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (_generationMessage != null)
                Text(
                  _generationMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Get user for smart generation calculation
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    // Calculate smart generation count
    final smartCount = user?.getSmartGenerationCount() ?? 4;
    final isLastDay = user?.isLastWorkoutDayOfWeek ?? false;

    // Determine description text
    String description;
    String buttonText;
    if (smartCount == 0) {
      description = 'All workouts for this week are ready';
      buttonText = 'Generate Next Week';
    } else if (isLastDay) {
      description = 'Generate $smartCount workouts through next week';
      buttonText = 'Generate $smartCount Workouts';
    } else {
      description = 'Generate $smartCount workouts for this week';
      buttonText = 'Generate $smartCount Workouts';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate More Workouts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _onGenerateMore(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onGenerateMore(BuildContext context) async {
    HapticService.medium();

    setState(() {
      _isGenerating = true;
      _generationMessage = 'Starting generation...';
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);

      // Get user from auth provider
      final authState = ref.read(authStateProvider);
      final user = authState.user;
      final userId = user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate smart generation count
      int smartCount = user?.getSmartGenerationCount() ?? 4;

      // If smartCount is 0 (all workouts ready), generate next week
      if (smartCount == 0) {
        smartCount = user?.workoutDays.length ?? 3;
      }

      // Ensure at least 1 workout
      if (smartCount < 1) smartCount = 1;

      final result = await repository.triggerGenerateMore(
        userId: userId,
        maxWorkouts: smartCount,
      );

      if (result['success'] == true) {
        if (result['needs_generation'] == true) {
          final workoutsToGenerate = result['workouts_to_generate'] ?? 4;
          setState(() {
            _generationMessage = 'Generating $workoutsToGenerate workouts...';
          });

          // Poll for completion
          await _pollForCompletion(repository, userId);
        } else {
          // Already have enough workouts
          setState(() {
            _isGenerating = false;
            _generationMessage = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Workouts ready!'),
                backgroundColor: AppColors.teal,
              ),
            );
          }
        }
      } else {
        throw Exception(result['message'] ?? 'Generation failed');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generationMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate workouts: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pollForCompletion(WorkoutRepository repository, String userId) async {
    const maxAttempts = 60; // 60 attempts * 2 seconds = 2 minutes max
    var attempts = 0;

    while (attempts < maxAttempts && _isGenerating) {
      await Future.delayed(const Duration(seconds: 2));
      attempts++;

      try {
        final status = await repository.getGenerationStatus(userId);
        final statusValue = status['status'] as String?;

        if (statusValue == 'completed' || statusValue == 'none') {
          // Generation complete - refresh workouts
          ref.invalidate(workoutsProvider);
          ref.invalidate(todayWorkoutProvider);

          if (mounted) {
            setState(() {
              _isGenerating = false;
              _generationMessage = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workouts generated successfully!'),
                backgroundColor: AppColors.teal,
              ),
            );
          }
          return;
        } else if (statusValue == 'failed') {
          throw Exception(status['error_message'] ?? 'Generation failed');
        } else if (statusValue == 'in_progress') {
          final generated = status['total_generated'] ?? 0;
          final expected = status['total_expected'] ?? 0;
          if (mounted && expected > 0) {
            setState(() {
              _generationMessage = 'Generated $generated of $expected workouts...';
            });
          }
        }
      } catch (e) {
        debugPrint('Error polling generation status: $e');
      }
    }

    // Timeout - refresh anyway
    ref.invalidate(workoutsProvider);
    ref.invalidate(todayWorkoutProvider);

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _generationMessage = null;
      });
    }
  }
}
