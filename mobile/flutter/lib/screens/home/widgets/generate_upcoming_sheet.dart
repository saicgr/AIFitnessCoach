import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/main_shell.dart';

/// Shows a bottom sheet for generating upcoming workouts for the current week
Future<void> showGenerateUpcomingSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final parentTheme = Theme.of(context);

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    isDismissible: true,
    enableDrag: true,
    builder: (sheetContext) => Theme(
      data: parentTheme,
      child: const _GenerateUpcomingSheet(),
    ),
  ).whenComplete(() {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _GenerateUpcomingSheet extends ConsumerStatefulWidget {
  const _GenerateUpcomingSheet();

  @override
  ConsumerState<_GenerateUpcomingSheet> createState() =>
      _GenerateUpcomingSheetState();
}

class _GenerateUpcomingSheetState extends ConsumerState<_GenerateUpcomingSheet> {
  bool _isGenerating = false;
  bool _isLoadingExisting = true;  // Loading state for existing workouts
  int _currentWorkout = 0;
  int _totalWorkouts = 0;
  String _progressMessage = '';
  String? _progressDetail;
  final List<Workout> _generatedWorkouts = [];
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;

  // Day name mapping (0=Mon, 6=Sun)
  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _shortDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<int> _remainingDays = [];

  @override
  void initState() {
    super.initState();
    _loadRemainingDays();
    // Load existing workouts after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingWorkouts();
    });
  }

  /// Load any existing workouts for this week's remaining days
  Future<void> _loadExistingWorkouts() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null || _remainingDays.isEmpty) {
      setState(() => _isLoadingExisting = false);
      return;
    }

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final workouts = await repo.getWorkouts(userId, limit: 20);

      // Get the start of this week (Monday)
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      // Filter to workouts scheduled for this week on remaining days
      final thisWeekWorkouts = workouts.where((w) {
        if (w.scheduledDate == null) return false;
        final date = DateTime.tryParse(w.scheduledDate!);
        if (date == null) return false;

        // Check if within this week
        if (date.isBefore(startOfWeek) || date.isAfter(endOfWeek)) return false;

        // Check if it's one of the remaining workout days
        final dayIndex = date.weekday - 1; // 0=Mon, 6=Sun
        return _remainingDays.contains(dayIndex);
      }).toList();

      if (mounted) {
        setState(() {
          _generatedWorkouts.addAll(thisWeekWorkouts);
          _isLoadingExisting = false;
          // If all remaining days have workouts, mark as completed
          if (_getDaysWithoutWorkouts().isEmpty && _generatedWorkouts.isNotEmpty) {
            _isCompleted = true;
            _progressMessage = 'All workouts ready!';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading existing workouts: $e');
      if (mounted) {
        setState(() => _isLoadingExisting = false);
      }
    }
  }

  /// Get list of day indices that don't have workouts yet
  List<int> _getDaysWithoutWorkouts() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    return _remainingDays.where((dayIndex) {
      final targetDate = startOfWeek.add(Duration(days: dayIndex));
      return !_generatedWorkouts.any((w) {
        if (w.scheduledDate == null) return false;
        final date = DateTime.tryParse(w.scheduledDate!);
        if (date == null) return false;
        return date.year == targetDate.year &&
               date.month == targetDate.month &&
               date.day == targetDate.day;
      });
    }).toList();
  }

  /// Get workout for a specific day index (0=Mon, 6=Sun)
  Workout? _getWorkoutForDay(int dayIndex) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final targetDate = startOfWeek.add(Duration(days: dayIndex));

    for (final workout in _generatedWorkouts) {
      if (workout.scheduledDate == null) continue;
      final date = DateTime.tryParse(workout.scheduledDate!);
      if (date == null) continue;
      if (date.year == targetDate.year &&
          date.month == targetDate.month &&
          date.day == targetDate.day) {
        return workout;
      }
    }
    return null;
  }

  void _loadRemainingDays() {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user != null) {
      setState(() {
        _remainingDays = user.remainingWorkoutDaysThisWeek;
      });
    }
  }

  Future<void> _startGeneration() async {
    if (_remainingDays.isEmpty) return;

    // Only generate for days that don't have workouts yet
    final daysToGenerate = _getDaysWithoutWorkouts();

    if (daysToGenerate.isEmpty) {
      setState(() {
        _isCompleted = true;
        _progressMessage = 'All workouts already generated!';
      });
      return;
    }

    // Store existing workouts before clearing for generation tracking
    final existingWorkouts = List<Workout>.from(_generatedWorkouts);

    setState(() {
      _isGenerating = true;
      _currentWorkout = 0;
      _totalWorkouts = daysToGenerate.length;
      _progressMessage = 'Starting generation...';
      _progressDetail = null;
      _isCompleted = false;
      _hasError = false;
      _errorMessage = null;
    });

    HapticService.medium();

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _errorMessage = 'Not logged in';
      });
      return;
    }

    try {
      final repo = ref.read(workoutRepositoryProvider);

      // API expects 0-indexed days (0=Mon, 6=Sun) - no conversion needed
      await for (final progress in repo.generateMonthlyWorkoutsStreaming(
        userId: userId,
        selectedDays: daysToGenerate,
        durationMinutes: 45,
        monthStartDate: DateTime.now().toIso8601String().split('T')[0],
        maxWorkouts: daysToGenerate.length,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          setState(() {
            _isGenerating = false;
            _hasError = true;
            _errorMessage = progress.message;
          });
          return;
        }

        if (progress.isCompleted) {
          // Refresh workout providers
          ref.invalidate(workoutsProvider);
          ref.invalidate(todayWorkoutProvider);

          setState(() {
            _isGenerating = false;
            _isCompleted = true;
            _progressMessage = 'All workouts generated!';
          });

          HapticService.success();
          return;
        }

        // Update progress
        setState(() {
          _currentWorkout = progress.currentWorkout;
          _totalWorkouts = progress.totalWorkouts > 0
              ? progress.totalWorkouts
              : daysToGenerate.length;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;

          // Merge existing workouts with newly generated ones
          _generatedWorkouts.clear();
          _generatedWorkouts.addAll(existingWorkouts);
          // Add new workouts that aren't already in the list
          for (final newWorkout in progress.workouts) {
            if (!_generatedWorkouts.any((w) => w.id == newWorkout.id)) {
              _generatedWorkouts.add(newWorkout);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasError = true;
          _errorMessage = 'Failed to generate workouts: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.electricBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate This Week',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            _remainingDays.isEmpty
                                ? 'No workout days remaining'
                                : '${_remainingDays.length} workout${_remainingDays.length == 1 ? '' : 's'} for ${_getRemainingDaysText()}',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isGenerating ? null : () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textSecondary),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress section (when generating)
                      if (_isGenerating || _isCompleted || _hasError) ...[
                        _buildProgressSection(
                          isDark,
                          textPrimary,
                          textSecondary,
                          cardBorder,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Workout days list
                      _buildDaysList(
                        isDark,
                        textPrimary,
                        textSecondary,
                        cardBorder,
                      ),

                      const SizedBox(height: 24),

                      // Action button
                      _buildActionButton(isDark, textPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRemainingDaysText() {
    if (_remainingDays.isEmpty) return '';
    if (_remainingDays.length == 1) {
      return _dayNames[_remainingDays.first];
    }
    final dayNames = _remainingDays.map((d) => _shortDayNames[d]).toList();
    if (dayNames.length == 2) {
      return '${dayNames[0]} & ${dayNames[1]}';
    }
    return '${dayNames.sublist(0, dayNames.length - 1).join(', ')} & ${dayNames.last}';
  }

  Widget _buildProgressSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBorder,
  ) {
    final accentColor = _hasError
        ? AppColors.error
        : _isCompleted
            ? AppColors.success
            : AppColors.electricBlue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_hasError)
                const Icon(Icons.error_outline, color: AppColors.error, size: 24)
              else if (_isCompleted)
                const Icon(Icons.check_circle, color: AppColors.success, size: 24)
              else
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: accentColor,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasError
                          ? 'Generation Failed'
                          : _isCompleted
                              ? 'All Done!'
                              : 'Workout $_currentWorkout of $_totalWorkouts',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hasError
                          ? (_errorMessage ?? 'Unknown error')
                          : _progressMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isGenerating && _totalWorkouts > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _currentWorkout / _totalWorkouts,
                backgroundColor: cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaysList(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBorder,
  ) {
    if (_remainingDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.success.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'No workout days remaining this week',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Check back on Monday for next week\'s workouts',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Get days that still need generation
    final daysWithoutWorkouts = _getDaysWithoutWorkouts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORKOUT SCHEDULE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_remainingDays.length, (index) {
          final dayIndex = _remainingDays[index];
          // Look up workout by date, not by index
          final workout = _getWorkoutForDay(dayIndex);
          final isGenerated = workout != null;
          // Check if this specific day is currently being generated
          final isCurrentlyGenerating = _isGenerating &&
              !isGenerated &&
              daysWithoutWorkouts.isNotEmpty &&
              daysWithoutWorkouts.first == dayIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildDayRow(
              dayIndex: dayIndex,
              workout: workout,
              isGenerated: isGenerated,
              isCurrentlyGenerating: isCurrentlyGenerating,
              isWaiting: _isGenerating && !isGenerated && !isCurrentlyGenerating,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBorder: cardBorder,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayRow({
    required int dayIndex,
    required Workout? workout,
    required bool isGenerated,
    required bool isCurrentlyGenerating,
    required bool isWaiting,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    final backgroundColor = isDark ? AppColors.surface : AppColorsLight.surface;

    // Make row tappable when workout exists
    return InkWell(
      onTap: workout != null ? () => _openWorkoutDetail(workout) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentlyGenerating
              ? AppColors.electricBlue.withValues(alpha: 0.1)
              : isGenerated
                  ? AppColors.success.withValues(alpha: 0.05)
                  : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentlyGenerating
                ? AppColors.electricBlue.withValues(alpha: 0.3)
                : isGenerated
                    ? AppColors.success.withValues(alpha: 0.3)
                    : cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isGenerated
                    ? AppColors.success.withValues(alpha: 0.15)
                    : isCurrentlyGenerating
                        ? AppColors.electricBlue.withValues(alpha: 0.15)
                        : cardBorder.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: isGenerated
                  ? const Icon(Icons.check, color: AppColors.success, size: 18)
                  : isCurrentlyGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.electricBlue,
                          ),
                        )
                      : Icon(Icons.circle_outlined, color: textSecondary, size: 18),
            ),
            const SizedBox(width: 12),

            // Day info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayNames[dayIndex],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (workout != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${workout.name ?? workout.type ?? 'Workout'} • ${workout.durationMinutes ?? 45} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (isCurrentlyGenerating) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Generating...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.electricBlue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else if (isWaiting) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Waiting...',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    // Not generating yet - show ready state
                    const SizedBox(height: 2),
                    Text(
                      'Ready to generate',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Exercise count badge or tap hint for generated workouts
            if (workout != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${workout.exercises.length} exercises',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: textSecondary.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Navigate to workout detail screen
  void _openWorkoutDetail(Workout workout) {
    if (workout.id == null) return;
    context.push('/workout/${workout.id}');
  }

  Widget _buildActionButton(bool isDark, Color textPrimary) {
    if (_remainingDays.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.surface : AppColorsLight.surface,
            foregroundColor: textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Close',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (_isCompleted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/workouts');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 20),
              SizedBox(width: 8),
              Text(
                'View Workouts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startGeneration,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, size: 20),
              SizedBox(width: 8),
              Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate how many workouts still need to be generated
    final daysWithoutWorkouts = _getDaysWithoutWorkouts();
    final workoutsToGenerate = daysWithoutWorkouts.length;

    // If loading existing workouts, show loading state
    if (_isLoadingExisting) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            disabledBackgroundColor: AppColors.electricBlue.withValues(alpha: 0.6),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _startGeneration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: AppColors.electricBlue.withValues(alpha: 0.6),
        ),
        child: _isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Generating...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    workoutsToGenerate > 0
                        ? 'Generate $workoutsToGenerate Workout${workoutsToGenerate == 1 ? '' : 's'}'
                        : 'All Workouts Ready',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
