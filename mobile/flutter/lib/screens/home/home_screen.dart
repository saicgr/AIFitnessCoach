import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/image_url_cache.dart';
import '../../widgets/empty_state.dart';
import '../notifications/notifications_screen.dart';
import 'widgets/regenerate_workout_sheet.dart';
import 'widgets/edit_program_sheet.dart';
import 'widgets/daily_activity_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isCheckingWorkouts = false;

  @override
  void initState() {
    super.initState();
    // Fetch workouts and check if regeneration needed on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkouts();
    });
  }

  Future<void> _initializeWorkouts() async {
    final notifier = ref.read(workoutsProvider.notifier);

    // First refresh to get current workouts
    await notifier.refresh();

    // Then check if we need to generate more (runs in background)
    if (!_isCheckingWorkouts) {
      setState(() => _isCheckingWorkouts = true);
      try {
        final result = await notifier.checkAndRegenerateIfNeeded();
        debugPrint('🔍 [HomeScreen] Workout check result: ${result['message']}');

        // If generation was triggered, show a subtle indicator
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
      } finally {
        if (mounted) {
          setState(() => _isCheckingWorkouts = false);
        }
      }
    }
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

    // Use actual brightness to support ThemeMode.system
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => workoutsNotifier.refresh(),
        color: AppColors.cyan,
        backgroundColor: elevatedColor,
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
                        tooltip: 'Total workouts completed',
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        icon: Icons.local_fire_department,
                        value: '${weeklyProgress.$1}',
                        color: AppColors.orange,
                        tooltip: 'Workouts this week',
                      ),
                      const SizedBox(width: 4),
                      _NotificationBellButton(isDark: isDark),
                      const SizedBox(width: 4),
                      _ProgramMenuButton(isDark: isDark),
                    ],
                  ),
                ),
              ),

              // Section: TODAY
              const SliverToBoxAdapter(
                child: _SectionHeader(title: 'TODAY'),
              ),

              // Daily Activity Card (Steps, Calories from Health Connect)
              const SliverToBoxAdapter(
                child: DailyActivityCard(),
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
                      : _isCheckingWorkouts
                          ? _GeneratingWorkoutsCard()
                          : _EmptyWorkoutCard(
                              onGenerate: () async {
                                // Try to auto-generate first
                                setState(() => _isCheckingWorkouts = true);
                                final result = await workoutsNotifier.checkAndRegenerateIfNeeded();
                                if (mounted) {
                                  setState(() => _isCheckingWorkouts = false);
                                  if (result['needs_generation'] != true) {
                                    // No generation triggered, go to onboarding
                                    context.go('/onboarding');
                                  } else {
                                    // Generation started, show message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Generating your workouts...'),
                                        backgroundColor: AppColors.elevated,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                ),
              ),

              // Section: YOUR WEEK
              const SliverToBoxAdapter(
                child: _SectionHeader(title: 'YOUR WEEK'),
              ),

              // Weekly Progress with slide-rotate animation
              SliverToBoxAdapter(
                child: _WeeklyProgressCard(
                  completed: weeklyProgress.$1,
                  total: weeklyProgress.$2,
                  isDark: isDark,
                ).animateSlideRotate(delay: const Duration(milliseconds: 50)),
              ),

              // Section: UPCOMING
              if (upcomingWorkouts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'UPCOMING',
                    subtitle: '${upcomingWorkouts.length} workouts',
                    actionText: 'View All',
                    onAction: () => context.push('/schedule'),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= upcomingWorkouts.length) return null;
                      final workout = upcomingWorkouts[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: AppAnimations.listItem,
                        child: SlideAnimation(
                          verticalOffset: 20,
                          curve: AppAnimations.fastOut,
                          child: FadeInAnimation(
                            curve: AppAnimations.fastOut,
                            child: _UpcomingWorkoutCard(
                              workout: workout,
                              onTap: () => context.push('/workout/${workout.id}'),
                            ),
                          ),
                        ),
                      );
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
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

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
          const Spacer(),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.cyan,
                  ),
                ],
              ),
            ),
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
  final String? tooltip;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
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

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        preferBelow: true,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.elevated
              : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textPrimary
              : AppColorsLight.textPrimary,
          fontSize: 13,
        ),
        child: badge,
      );
    }

    return badge;
  }
}

// ─────────────────────────────────────────────────────────────────
// Notification Bell Button with Badge
// ─────────────────────────────────────────────────────────────────

class _NotificationBellButton extends ConsumerWidget {
  final bool isDark;

  const _NotificationBellButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            unreadCount > 0 ? Icons.notifications : Icons.notifications_outlined,
            color: unreadCount > 0 ? AppColors.cyan : textMuted,
            size: 24,
          ),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Program Menu Button (3-dot menu)
// ─────────────────────────────────────────────────────────────────

class _ProgramMenuButton extends ConsumerWidget {
  final bool isDark;

  const _ProgramMenuButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: textMuted,
        size: 24,
      ),
      color: elevatedColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == 'edit_program') {
          _showEditProgramSheet(context, ref);
        } else if (value == 'settings') {
          context.push('/settings');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit_program',
          child: Row(
            children: [
              Icon(
                Icons.tune,
                size: 20,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 12),
              Text(
                'Customize Program',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProgramSheet(BuildContext context, WidgetRef ref) async {
    final result = await showEditProgramSheet(context, ref);

    if (result == true && context.mounted) {
      // Refresh workouts after program update
      ref.read(workoutsProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program updated! Generating new workouts...'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Next Workout Card
// ─────────────────────────────────────────────────────────────────

class _NextWorkoutCard extends ConsumerStatefulWidget {
  final Workout workout;
  final VoidCallback onStart;

  const _NextWorkoutCard({required this.workout, required this.onStart});

  @override
  ConsumerState<_NextWorkoutCard> createState() => _NextWorkoutCardState();
}

class _NextWorkoutCardState extends ConsumerState<_NextWorkoutCard> {
  bool _isSkipping = false;

  String _getScheduledDateLabel(String? scheduledDate) {
    if (scheduledDate == null) return 'Scheduled';
    try {
      final date = DateTime.parse(scheduledDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final workoutDate = DateTime(date.year, date.month, date.day);

      if (workoutDate == today) {
        return 'Today';
      } else if (workoutDate == tomorrow) {
        return 'Tomorrow';
      } else {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
      }
    } catch (_) {
      return 'Scheduled';
    }
  }

  Future<void> _regenerateWorkout() async {
    // Show the regenerate customization sheet
    final newWorkout = await showRegenerateWorkoutSheet(
      context,
      ref,
      widget.workout,
    );

    // If a new workout was returned, refresh the list
    if (newWorkout != null && mounted) {
      ref.read(workoutsProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout regenerated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _skipWorkout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Skip Workout?'),
        content: const Text('This workout will be marked as skipped and won\'t count towards your weekly goal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSkipping = true);

    final repo = ref.read(workoutRepositoryProvider);
    try {
      // Reschedule to mark as skipped - move to yesterday so it's "past"
      final success = await repo.deleteWorkout(widget.workout.id!);

      if (success && mounted) {
        ref.read(workoutsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout skipped'),
            backgroundColor: AppColors.textMuted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to skip: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSkipping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final workout = widget.workout;
    final difficultyColor = AppColors.getDifficultyColor(workout.difficulty ?? 'medium');
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');
    final exercises = workout.exercises;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              elevatedColor,
              elevatedColor.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise preview strip at top - tappable to navigate
            if (exercises.isNotEmpty)
              GestureDetector(
                onTap: widget.onStart,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ExerciseImageThumbnail(
                          exercise: exercise,
                          size: 44,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Main card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badges - tappable to navigate
                  GestureDetector(
                    onTap: widget.onStart,
                    child: Row(
                      children: [
                        // Scheduled date badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 10, color: AppColors.cyan),
                              const SizedBox(width: 4),
                              Text(
                                _getScheduledDateLabel(workout.scheduledDate),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyan,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
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
                  ),
                  const SizedBox(height: 16),

                  // Title - tappable to navigate
                  GestureDetector(
                    onTap: widget.onStart,
                    child: Text(
                      workout.name ?? 'Workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stats row - simplified to 2 key stats
                  GestureDetector(
                    onTap: widget.onStart,
                    child: Row(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons row - Start and quick actions
                  Row(
                    children: [
                      // Main Start button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/active-workout', extra: workout),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Customize icon button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.purple.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _regenerateWorkout,
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          color: AppColors.purple,
                          tooltip: 'Customize',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Skip icon button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textMuted.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _isSkipping ? null : _skipWorkout,
                          icon: _isSkipping
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.skip_next, size: 20),
                          color: AppColors.textMuted,
                          tooltip: 'Skip',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: textMuted,
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
// Generating Workouts Card (shown during auto-regeneration)
// ─────────────────────────────────────────────────────────────────

class _GeneratingWorkoutsCard extends StatelessWidget {
  const _GeneratingWorkoutsCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating your workouts...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Your personalized workout plan is being created',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
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
  final bool isDark;

  const _WeeklyProgressCard({required this.completed, required this.total, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0-indexed
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
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
                backgroundColor: glassSurface,
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
                                : glassSurface,
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
                        color: isToday ? AppColors.cyan : textMuted,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            print('🎯 [UpcomingCard] Tapped: ${workout.name}');
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
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
              Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ],
          ),
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
      child: SkeletonCard(
        height: 200,
        borderRadius: BorderRadius.circular(16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
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
// Exercise Image Widget
// ─────────────────────────────────────────────────────────────────

class _ExerciseImageThumbnail extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final double size;

  const _ExerciseImageThumbnail({
    required this.exercise,
    this.size = 44,
  });

  @override
  ConsumerState<_ExerciseImageThumbnail> createState() =>
      _ExerciseImageThumbnailState();
}

class _ExerciseImageThumbnailState
    extends ConsumerState<_ExerciseImageThumbnail> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageUrl();
  }

  Future<void> _loadImageUrl() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    // Check persistent cache first (survives app restarts)
    final cachedUrl = ImageUrlCache.get(exerciseName);
    if (cachedUrl != null) {
      if (mounted) {
        setState(() {
          _imageUrl = cachedUrl;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          // Store in persistent cache
          await ImageUrlCache.set(exerciseName, url);
          setState(() {
            _imageUrl = url;
            _isLoading = false;
          });
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render anything if there's an error or no image (no fallback)
    if (_hasError && !_isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.cyan,
          ),
        ),
      );
    }

    // If no image URL, return empty - no fallback icons
    if (_imageUrl == null) {
      return const SizedBox.shrink();
    }

    return CachedNetworkImage(
      imageUrl: _imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.cyan,
          ),
        ),
      ),
      // On network error loading the image, show empty instead of fallback icon
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

