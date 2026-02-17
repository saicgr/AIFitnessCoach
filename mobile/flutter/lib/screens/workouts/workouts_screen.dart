import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_screen_summary.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/pill_swipe_navigation.dart';
import '../home/widgets/cards/next_workout_card.dart';
import '../home/widgets/cards/weekly_progress_card.dart';
import '../home/widgets/hero_workout_card.dart';
import 'widgets/exercise_preferences_card.dart';
import 'widgets/upcoming_workouts_sheet.dart';
import 'widgets/previous_workouts_sheet.dart';

/// Workouts screen - central hub for all workout-related content
/// Accessible from the floating nav bar (replaces Profile)
class WorkoutsScreen extends ConsumerStatefulWidget {
  /// Optional parameter to scroll to a specific section
  final String? scrollTo;

  const WorkoutsScreen({super.key, this.scrollTo});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen>
    with PillSwipeNavigationMixin {
  // PillSwipeNavigationMixin: Workouts is index 1
  @override
  int get currentPillIndex => 1;

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
    // Get dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    // Watch workouts state (for weekly progress, upcoming list)
    final workoutsState = ref.watch(workoutsProvider);
    // Watch todayWorkoutProvider (for today's/next workout - same as Home screen)
    final todayWorkoutState = ref.watch(todayWorkoutProvider);
    // Watch lightweight screen summary (for weekly progress + previous sessions)
    final screenSummary = ref.watch(workoutScreenSummaryProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: wrapWithSwipeDetector(
        child: Stack(
          children: [
            // Scrollable content
            CustomScrollView(
              slivers: [
                // Top padding for floating header row
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.top + 56),
                ),

                // Content - render unconditionally using valueOrNull to avoid blocking on load
                _buildContent(
                  context,
                  isDark,
                  textPrimary,
                  textSecondary,
                  accentColor,
                  workoutsState.valueOrNull ?? [],
                  todayWorkoutState,
                  screenSummary,
                ),
              ],
            ),

            // Floating header with back, title, and action icons
            _buildFloatingHeader(
              context,
              isDark,
              textPrimary,
              textSecondary,
              accentColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Floating header with back button, title, and action icons
  Widget _buildFloatingHeader(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title (left side)
            Text(
              'Workouts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            // Right side buttons
            Row(
              children: [
                // Library button - pill shaped for text
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    context.push('/library');
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Library',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Settings button - glassmorphic
                _GlassmorphicButton(
                  onTap: () {
                    HapticService.light();
                    context.push('/settings');
                  },
                  isDark: isDark,
                  child: Icon(
                    Icons.settings_outlined,
                    color: textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    List<Workout> workouts,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    AsyncValue<WorkoutScreenSummary?> screenSummary,
  ) {
    final now = DateTime.now();

    // Use todayWorkoutProvider for today's/next workout (consistent with Home screen)
    Workout? todayOrNextWorkout;
    bool isToday = false;
    int? daysUntilNext;
    bool isNextWeek = false;
    bool isGenerating = false;
    String? generationMessage;
    bool completedToday = false;

    // Get user for checking if it's last workout day
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isLastWorkoutDay = user?.isLastWorkoutDayOfWeek ?? false;

    // Extract data from todayWorkoutState
    final response = todayWorkoutState.valueOrNull;
    if (response != null) {
      isGenerating = response.isGenerating;
      generationMessage = response.generationMessage;
      completedToday = response.completedToday;
      if (response.hasWorkoutToday && response.todayWorkout != null) {
        todayOrNextWorkout = response.todayWorkout!.toWorkout();
        isToday = true;
      } else if (response.nextWorkout != null) {
        todayOrNextWorkout = response.nextWorkout!.toWorkout();
        daysUntilNext = response.daysUntilNext;
        // Check if next workout is in next week (more than remaining days this week)
        if (isLastWorkoutDay && daysUntilNext != null && daysUntilNext > 0) {
          isNextWeek = true;
        }
      }
    }

    // Calculate weekly progress - prefer screen summary if available
    final summaryData = screenSummary.valueOrNull;
    final int completedThisWeek;
    final int plannedThisWeek;
    if (summaryData != null) {
      completedThisWeek = summaryData.completedThisWeek;
      plannedThisWeek = summaryData.plannedThisWeek;
    } else {
      // Fallback to computing from workouts list
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      completedThisWeek = workouts.where((w) {
        if (w.isCompleted != true) return false;
        if (w.scheduledDate == null) return false;
        final scheduledDate = DateTime.tryParse(w.scheduledDate!);
        if (scheduledDate == null) return false;
        return scheduledDate.isAfter(startOfWeek) && scheduledDate.isBefore(endOfWeek);
      }).length;
      plannedThisWeek = workouts.where((w) {
        if (w.scheduledDate == null) return false;
        final scheduledDate = DateTime.tryParse(w.scheduledDate!);
        if (scheduledDate == null) return false;
        return scheduledDate.isAfter(startOfWeek) &&
            scheduledDate.isBefore(startOfWeek.add(const Duration(days: 7)));
      }).length;
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 8),

        // Quick Actions Row
        _buildQuickActions(context, isDark, textSecondary, accentColor),

        const SizedBox(height: 16),

        // Exercise Preferences (expandable)
        const ExercisePreferencesCard(),

        const SizedBox(height: 16),

        // Today's/Next Workout Section (using todayWorkoutProvider - same as Home)
        // Priority: 1. Loading, 2. Error, 3. Generating, 4. Has workout, 5. Completed, 6. Preparing
        ..._buildWorkoutSection(
          context,
          textSecondary,
          todayWorkoutState,
          todayOrNextWorkout,
          isToday,
          isNextWeek,
          daysUntilNext,
          isGenerating,
          generationMessage,
          completedToday,
        ),

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

        // Previous Sessions
        _buildSectionHeader(
          'PREVIOUS SESSIONS',
          textSecondary,
          actionText: 'View All',
          onAction: () {
            HapticService.light();
            context.push('/schedule');
          },
        ),
        const SizedBox(height: 8),
        _buildPreviousSessions(context, workouts, isDark, textPrimary, textSecondary),
        const SizedBox(height: 24),

        // JIT Generation: No "Generate More" button needed
        // Workouts are automatically generated after each completion
        // Show a subtle info message instead
        _buildJitInfoSection(isDark, textSecondary),

        // Bottom padding for nav bar
        const SizedBox(height: 100),
      ]),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
    Color textSecondary,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.add_circle_outline,
              label: 'Custom',
              color: accentColor,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                context.push('/workout/build');
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.search,
              label: 'Browse',
              color: accentColor,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                context.push('/library');
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.calendar_month_rounded,
              label: 'Upcoming',
              color: accentColor,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                showUpcomingWorkoutsSheet(context, ref);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.history_rounded,
              label: 'Previous',
              color: accentColor,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                showPreviousWorkoutsSheet(context, ref);
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  color: textColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build JIT info section - explains that workouts are auto-generated
  Widget _buildJitInfoSection(bool isDark, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your next workout is created automatically after each session',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build previous sessions section - shows last 3 completed workouts
  Widget _buildPreviousSessions(
    BuildContext context,
    List<Workout> workouts,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Get completed workouts, sorted by completion/scheduled date (most recent first)
    final completedWorkouts = workouts
        .where((w) => w.isCompleted == true)
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.scheduledDate ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b.scheduledDate ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Most recent first
      });

    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    if (completedWorkouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 32, color: textSecondary),
                const SizedBox(height: 8),
                Text(
                  'No completed workouts yet',
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete your first workout to see it here',
                  style: TextStyle(
                    color: textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show last 3 completed workouts
    final recentWorkouts = completedWorkouts.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: recentWorkouts.map((workout) {
          return _PreviousSessionCard(
            workout: workout,
            isDark: isDark,
            onTap: () {
              HapticService.light();
              context.push('/workout/${workout.id}');
            },
          );
        }).toList(),
      ),
    );
  }

  /// Build workout section with proper state handling (matches Home screen logic)
  List<Widget> _buildWorkoutSection(
    BuildContext context,
    Color textSecondary,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    Workout? todayOrNextWorkout,
    bool isToday,
    bool isNextWeek,
    int? daysUntilNext,
    bool isGenerating,
    String? generationMessage,
    bool completedToday,
  ) {
    debugPrint('🏋️ [WorkoutsScreen] Building workout section...');
    debugPrint('🏋️ [WorkoutsScreen] isLoading: ${todayWorkoutState.isLoading}');
    debugPrint('🏋️ [WorkoutsScreen] hasValue: ${todayWorkoutState.hasValue}');
    debugPrint('🏋️ [WorkoutsScreen] hasError: ${todayWorkoutState.hasError}');
    debugPrint('🏋️ [WorkoutsScreen] isGenerating: $isGenerating');
    debugPrint('🏋️ [WorkoutsScreen] todayOrNextWorkout: ${todayOrNextWorkout?.name}');
    debugPrint('🏋️ [WorkoutsScreen] completedToday: $completedToday');

    // 1. Initial loading state (no previous data)
    if (todayWorkoutState.isLoading && !todayWorkoutState.hasValue) {
      debugPrint('🏋️ [WorkoutsScreen] Showing: Loading state');
      return [
        _buildSectionHeader('YOUR WORKOUT', textSecondary),
        const SizedBox(height: 8),
        const GeneratingHeroCard(
          message: 'Loading your workout...',
          subtitle: 'Fetching your personalized plan',
        ),
        const SizedBox(height: 24),
      ];
    }

    // 2. Error state - show optimistic loading (workouts may still be generating)
    if (todayWorkoutState.hasError) {
      debugPrint('⚠️ [WorkoutsScreen] Error: ${todayWorkoutState.error}');
      return [
        _buildSectionHeader('YOUR WORKOUT', textSecondary),
        const SizedBox(height: 8),
        const GeneratingHeroCard(
          message: 'Setting up your workouts...',
          subtitle: 'This may take a moment',
        ),
        const SizedBox(height: 24),
      ];
    }

    // 3. Generating state - backend is creating workouts
    if (isGenerating) {
      debugPrint('🏋️ [WorkoutsScreen] Showing: Generating state');
      return [
        _buildSectionHeader('YOUR WORKOUT', textSecondary),
        const SizedBox(height: 8),
        GeneratingHeroCard(
          message: generationMessage ?? 'Generating your workout...',
          subtitle: 'Your personalized plan is being created',
        ),
        const SizedBox(height: 24),
      ];
    }

    // 4. Has workout - show the workout card
    if (todayOrNextWorkout != null) {
      debugPrint('🏋️ [WorkoutsScreen] Showing: Workout card for ${todayOrNextWorkout.name}');
      return [
        _buildSectionHeader(
          isToday
              ? 'TODAY\'S WORKOUT'
              : isNextWeek
                  ? 'NEXT WEEK\'S WORKOUT${daysUntilNext != null ? ' (in $daysUntilNext day${daysUntilNext == 1 ? '' : 's'})' : ''}'
                  : 'NEXT WORKOUT${daysUntilNext != null ? ' (in $daysUntilNext day${daysUntilNext == 1 ? '' : 's'})' : ''}',
          textSecondary,
        ),
        const SizedBox(height: 8),
        NextWorkoutCard(
          workout: todayOrNextWorkout,
          onStart: () {
            HapticService.medium();
            context.push('/active-workout', extra: todayOrNextWorkout);
          },
          showUpcomingLink: false,
        ),
        const SizedBox(height: 24),
      ];
    }

    // 5. Completed today - show encouraging message
    if (completedToday) {
      debugPrint('🏋️ [WorkoutsScreen] Showing: Completed today state');
      return [
        _buildSectionHeader('YOUR WORKOUT', textSecondary),
        const SizedBox(height: 8),
        const GeneratingHeroCard(
          message: 'Great job today! 🎉',
          subtitle: 'Rest up for your next workout',
        ),
        const SizedBox(height: 24),
      ];
    }

    // 6. No workout available - show preparing state (default fallback)
    debugPrint('🏋️ [WorkoutsScreen] Showing: Preparing state (no workout available)');
    return [
      _buildSectionHeader('YOUR WORKOUT', textSecondary),
      const SizedBox(height: 8),
      const GeneratingHeroCard(
        message: 'Preparing your workout...',
        subtitle: 'Your personalized plan is being created',
      ),
      const SizedBox(height: 24),
    ];
  }
}

/// Card widget for displaying a previous workout session
class _PreviousSessionCard extends StatelessWidget {
  final Workout workout;
  final bool isDark;
  final VoidCallback onTap;

  const _PreviousSessionCard({
    required this.workout,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');

    // Format the date
    String dateText = '';
    if (workout.scheduledDate != null) {
      final date = DateTime.tryParse(workout.scheduledDate!);
      if (date != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final workoutDate = DateTime(date.year, date.month, date.day);
        final difference = today.difference(workoutDate).inDays;

        if (difference == 0) {
          dateText = 'Today';
        } else if (difference == 1) {
          dateText = 'Yesterday';
        } else if (difference < 7) {
          dateText = '$difference days ago';
        } else {
          dateText = '${date.day}/${date.month}/${date.year}';
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Completed checkmark icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle,
                color: textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Workout details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name ?? 'Workout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          workout.type?.toUpperCase() ?? 'STRENGTH',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined, size: 12, color: textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        workout.formattedDurationShort,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      if (dateText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphic button with blur effect
class _GlassmorphicButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isDark;
  final double size;

  const _GlassmorphicButton({
    required this.onTap,
    required this.child,
    required this.isDark,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
