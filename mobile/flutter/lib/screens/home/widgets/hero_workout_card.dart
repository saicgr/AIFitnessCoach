import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/image_url_cache.dart';
import '../../../widgets/glass_sheet.dart';
import 'regenerate_workout_sheet.dart';
import '../../workout/widgets/exercise_add_sheet.dart';

/// Hero workout card - Gravl-inspired design with background image
/// Features a large background image with gradient overlay and prominent START button
class HeroWorkoutCard extends ConsumerStatefulWidget {
  final Workout workout;

  /// Whether this card is inside a carousel (removes outer padding)
  final bool inCarousel;

  const HeroWorkoutCard({
    super.key,
    required this.workout,
    this.inCarousel = false,
  });

  @override
  ConsumerState<HeroWorkoutCard> createState() => _HeroWorkoutCardState();
}

class _HeroWorkoutCardState extends ConsumerState<HeroWorkoutCard> {
  bool _isSkipping = false;
  bool _isMarkingDone = false;
  String? _backgroundImageUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    // Try to get image from first exercise
    final exercises = widget.workout.exercises;
    if (exercises.isEmpty) {
      setState(() => _isLoadingImage = false);
      return;
    }

    final exerciseName = exercises.first.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingImage = false);
      return;
    }

    // Check cache first
    final cachedUrl = ImageUrlCache.get(exerciseName);
    if (cachedUrl != null) {
      if (mounted) {
        setState(() {
          _backgroundImageUrl = cachedUrl;
          _isLoadingImage = false;
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
          await ImageUrlCache.set(exerciseName, url);
          setState(() {
            _backgroundImageUrl = url;
            _isLoadingImage = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingImage = false);
  }

  String _getScheduledDateLabel(String? scheduledDate) {
    if (scheduledDate == null) return 'TODAY';
    // Parse date from string directly to avoid timezone shift
    final dateStr = scheduledDate.split('T')[0];
    final parts = dateStr.split('-');
    if (parts.length != 3) return 'TODAY';
    try {
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      if (date == today) {
        return 'TODAY';
      } else if (date == tomorrow) {
        return 'TOMORROW';
      } else {
        final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
        return weekdays[date.weekday - 1];
      }
    } catch (_) {
      return 'TODAY';
    }
  }

  Future<void> _regenerateWorkout() async {
    final newWorkout = await showRegenerateWorkoutSheet(
      context,
      ref,
      widget.workout,
    );

    if (newWorkout != null && mounted) {
      // Provider refresh already handled by showRegenerateWorkoutSheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout regenerated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _skipWorkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Skip Workout?',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This workout will be marked as skipped.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Skip'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSkipping = true);

    final repo = ref.read(workoutRepositoryProvider);
    try {
      final success = await repo.deleteWorkout(widget.workout.id!);

      if (success && mounted) {
        ref.invalidate(todayWorkoutProvider);
        ref.invalidate(workoutsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout skipped'),
              backgroundColor: AppColors.textMuted,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not skip workout'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSkipping = false);
    }
  }

  Future<void> _markAsDone() async {
    final dateLabel = _getScheduledDateLabel(widget.workout.scheduledDate);
    final isToday = dateLabel == 'TODAY';
    final dialogMessage = isToday
        ? 'This will mark the workout as completed without tracking sets.'
        : 'Mark workout for $dateLabel as done? This will mark it as completed without tracking sets.';

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Mark as Done?',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            dialogMessage,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.success),
              child: const Text('Mark Done'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isMarkingDone = true);

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final result = await repo.markWorkoutAsDone(widget.workout.id!);

      if (result != null && mounted) {
        TodayWorkoutNotifier.clearCache();
        ref.invalidate(todayWorkoutProvider);
        ref.invalidate(workoutsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout marked as done!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not mark workout as done'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isMarkingDone = false);
    }
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _repeatWorkout() {
    HapticService.medium();
    context.push('/active-workout', extra: widget.workout);
  }

  Future<void> _markAsUndone() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Undo Completion?',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This will mark the workout as not done.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Undo'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.uncompleteWorkout(widget.workout.id!);

      if (success && mounted) {
        TodayWorkoutNotifier.clearCache();
        ref.invalidate(todayWorkoutProvider);
        ref.invalidate(workoutsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout unmarked'),
              backgroundColor: AppColors.textMuted,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not undo completion'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _viewSummary() {
    HapticService.selection();
    context.push('/workout-summary/${widget.workout.id}');
  }

  void _showOptionsMenu() {
    HapticService.light();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Glance Workout
              ListTile(
                leading: Icon(
                  Icons.remove_red_eye_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Glance Workout',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showGlanceWorkout();
                },
              ),
              // View Workout
              ListTile(
                leading: Icon(
                  Icons.visibility_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'View Workout',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/workout/${widget.workout.id}');
                },
              ),
              // Add Exercises
              ListTile(
                leading: Icon(
                  Icons.add_circle_outline,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Add Exercises',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addExercises();
                },
              ),
              // Ask Coach
              ListTile(
                leading: Icon(
                  Icons.chat_bubble_outline,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Ask Coach',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final workoutName = widget.workout.name ?? 'your workout';
                  final exerciseCount = widget.workout.exerciseCount;
                  final duration = widget.workout.formattedDurationShort;
                  context.push(
                    '/chat',
                    extra: {
                      'initialMessage':
                          'I have questions about my upcoming workout "$workoutName" ($exerciseCount exercises, $duration). Can you help me prepare for it?',
                    },
                  );
                },
              ),
              // Regenerate Workout
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Regenerate Workout',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _regenerateWorkout();
                },
              ),
              // Share to Social
              ListTile(
                leading: Icon(
                  Icons.share_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Share to Social',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/workout/${widget.workout.id}');
                },
              ),
              // Mark as Done
              ListTile(
                leading: Icon(
                  Icons.check_circle_outline,
                  color: isDark ? AppColors.success : AppColors.success,
                ),
                title: Text(
                  'Mark as Done',
                  style: TextStyle(
                    color: isDark ? AppColors.success : AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _markAsDone();
                },
              ),
              // Divider before destructive action
              const Divider(height: 1),
              // Skip Workout
              ListTile(
                leading: const Icon(
                  Icons.skip_next_outlined,
                  color: AppColors.textMuted,
                ),
                title: const Text(
                  'Skip Workout',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _skipWorkout();
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showGlanceWorkout() {
    final workout = widget.workout;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.name ?? 'Workout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Stats
              Text(
                '${workout.formattedDurationShort} • ${workout.exerciseCount} exercises',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              // Exercise list
              ...workout.exercises.take(5).map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${e.sets ?? 0} sets',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (workout.exercises.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${workout.exercises.length - 5} more exercises',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addExercises() async {
    final workout = widget.workout;
    final updatedWorkout = await showExerciseAddSheet(
      context,
      ref,
      workoutId: workout.id!,
      workoutType: workout.type ?? 'strength',
      currentExerciseNames: workout.exercises.map((e) => e.name).toList(),
    );

    if (updatedWorkout != null && mounted) {
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercise added!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workout = widget.workout;

    // Get accent color from provider
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    final dateLabel = _getScheduledDateLabel(workout.scheduledDate);

    final cardContent = Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            _buildBackground(isDark),

            // Gradient overlay for readability - different for light/dark mode
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.85),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.9),
                        ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Date label + Menu button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showOptionsMenu,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(
                            Icons.more_horiz,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Workout title - large and prominent
                  Text(
                    workout.name ?? 'Workout',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: isDark
                          ? [
                              const Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Workout description (if available)
                  if (workout.description != null && workout.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      workout.description!,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black45,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        shadows: isDark
                            ? [
                                const Shadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.black54,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        workout.formattedDurationShort,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.fitness_center,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.black54,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        workout.exerciseCount > 0
                            ? '${workout.exerciseCount} exercises'
                            : 'Ready to start',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Start button - full width
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticService.medium();
                        debugPrint('🏋️ [HeroWorkoutCard] START pressed');
                        debugPrint(
                          '🏋️ [HeroWorkoutCard] workout.id=${workout.id}',
                        );
                        debugPrint(
                          '🏋️ [HeroWorkoutCard] workout.exercises.length=${workout.exercises.length}',
                        );

                        if (workout.exercises.isEmpty) {
                          debugPrint(
                            '⚠️ [HeroWorkoutCard] Workout has no exercises!',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Workout is not ready yet. Please try regenerating.',
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(
                                bottom: 120,
                                left: 16,
                                right: 16,
                              ),
                            ),
                          );
                          return;
                        }
                        debugPrint(
                          '✅ [HeroWorkoutCard] Navigating to active-workout with ${workout.exercises.length} exercises',
                        );
                        context.push('/active-workout', extra: workout);
                      },
                      icon: const Icon(Icons.play_arrow, size: 22),
                      label: const Text(
                        'START',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // View Details and Regenerate row
                  Row(
                    children: [
                      // View Details button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticService.selection();
                            context.push('/workout/${workout.id}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Colors.black87,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Regenerate button
                      Expanded(
                        child: GestureDetector(
                          onTap: _regenerateWorkout,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 16,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Regenerate',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Loading indicator for skipping or marking done
            if (_isSkipping || _isMarkingDone)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // Completed workout overlay
            if (widget.workout.isCompleted == true)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: AppColors.success.withValues(alpha: isDark ? 0.25 : 0.2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.success, width: 3),
                              color: AppColors.success.withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.check, color: AppColors.success, size: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Workout Complete',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workout.name ?? '',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildOverlayButton(icon: Icons.replay, label: 'Repeat', onTap: _repeatWorkout, isDark: isDark),
                              if (widget.workout.completionMethod == 'marked_done') ...[
                                const SizedBox(width: 12),
                                _buildOverlayButton(icon: Icons.undo, label: 'Undo', onTap: _markAsUndone, isDark: isDark),
                              ],
                              const SizedBox(width: 12),
                              _buildOverlayButton(icon: Icons.bar_chart, label: 'Summary', onTap: _viewSummary, isDark: isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // When in carousel, minimal padding to show peek
    if (widget.inCarousel) {
      return GestureDetector(
        onTap: () {
          HapticService.selection();
          context.push('/workout/${workout.id}');
        },
        child: cardContent,
      );
    }

    // When standalone, add the original padding
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/workout/${workout.id}');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: cardContent,
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    final accentColorEnum = ref.read(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    if (_isLoadingImage) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFFF0F4F8), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accentColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    if (_backgroundImageUrl != null) {
      // Image with a nice gradient background behind it (accent-tinted)
      return Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient with accent color tint
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Color.lerp(const Color(0xFF1a1a2e), accentColor, 0.1)!,
                        const Color(0xFF0f0f1a),
                      ]
                    : [
                        Color.lerp(Colors.white, accentColor, 0.05)!,
                        Color.lerp(const Color(0xFFF0F4F8), accentColor, 0.1)!,
                      ],
              ),
            ),
          ),
          // The actual image
          CachedNetworkImage(
            imageUrl: _backgroundImageUrl!,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            // Perf fix 2.2: limit decoded image size in memory cache
            memCacheWidth: 400,
            memCacheHeight: 400,
            placeholder: (_, __) => const SizedBox.shrink(),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      );
    }

    return _buildFallbackBackground(isDark);
  }

  Widget _buildFallbackBackground(bool isDark) {
    // Get accent color for consistent theming
    final accentColorEnum = ref.read(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    if (isDark) {
      // Dark mode - deep, rich gradient with accent tint
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              Color.lerp(const Color(0xFF16213e), accentColor, 0.15)!,
              const Color(0xFF0f0f1a),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [accentColor, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Faint icon
            Center(
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.fitness_center,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Light mode - clean white/gray with subtle accent glow
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF8F9FA),
              const Color(0xFFF0F2F5),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle accent glow at top
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.15),
                      accentColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle bottom glow
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Faint icon
            Center(
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.fitness_center,
                  size: 200,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Card shown when today's workout is already completed
/// Shows completion status and the next scheduled workout
class CompletedWorkoutHeroCard extends ConsumerWidget {
  final Workout completedWorkout;
  final Workout nextWorkout;
  final int daysUntilNext;

  const CompletedWorkoutHeroCard({
    super.key,
    required this.completedWorkout,
    required this.nextWorkout,
    required this.daysUntilNext,
  });

  String _getNextWorkoutLabel() {
    if (daysUntilNext == 1) return 'Tomorrow';
    if (daysUntilNext == 2) return 'In 2 days';
    return 'In $daysUntilNext days';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final cardBg = isDark ? AppColors.pureBlack : AppColorsLight.elevated;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Completed workout banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s workout complete!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            // Next workout content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getNextWorkoutLabel().toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      GoRouter.of(context).push('/workout/${nextWorkout.id}');
                    },
                    child: Text(
                      nextWorkout.name ?? 'Workout',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: '${nextWorkout.durationMinutes ?? 45} min',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: Icons.fitness_center,
                        label: '${nextWorkout.exerciseCount} exercises',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticService.medium();
                        GoRouter.of(context).push('/workout/${nextWorkout.id}');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 22,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PREVIEW',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: textSecondary)),
      ],
    );
  }
}

/// Card shown when generating/loading workouts
class GeneratingHeroCard extends ConsumerStatefulWidget {
  final String? message;
  final String? subtitle;

  const GeneratingHeroCard({super.key, this.message, this.subtitle});

  @override
  ConsumerState<GeneratingHeroCard> createState() => _GeneratingHeroCardState();
}

class _GeneratingHeroCardState extends ConsumerState<GeneratingHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🔄 [GeneratingHeroCard] build() called with message: ${widget.message}',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.pureBlack : AppColorsLight.elevated;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: accentColor,
                        backgroundColor: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    Icon(
                      Icons.fitness_center_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  widget.message ?? 'Loading your workout...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle ?? 'This may take a moment',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      height: 4,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Positioned(
                              left: _shimmerController.value * 140 - 40,
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      accentColor,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
