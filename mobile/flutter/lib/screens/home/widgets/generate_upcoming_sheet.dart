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

    setState(() {
      _isGenerating = true;
      _currentWorkout = 0;
      _totalWorkouts = _remainingDays.length;
      _progressMessage = 'Starting generation...';
      _progressDetail = null;
      _generatedWorkouts.clear();
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

      // Convert 0-indexed days to 1-indexed for API (1=Mon, 7=Sun)
      final selectedDaysForApi = _remainingDays.map((d) => d + 1).toList();

      await for (final progress in repo.generateMonthlyWorkoutsStreaming(
        userId: userId,
        selectedDays: selectedDaysForApi,
        durationMinutes: 45,
        monthStartDate: DateTime.now().toIso8601String().split('T')[0],
        maxWorkouts: _remainingDays.length,
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
              : _remainingDays.length;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;

          // Add new workouts to our list
          if (progress.workouts.length > _generatedWorkouts.length) {
            _generatedWorkouts.clear();
            _generatedWorkouts.addAll(progress.workouts);
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
          final isGenerated = index < _generatedWorkouts.length;
          final isCurrentlyGenerating =
              _isGenerating && index == _generatedWorkouts.length;
          final workout = isGenerated ? _generatedWorkouts[index] : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildDayRow(
              dayIndex: dayIndex,
              workout: workout,
              isGenerated: isGenerated,
              isCurrentlyGenerating: isCurrentlyGenerating,
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
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    final backgroundColor = isDark ? AppColors.surface : AppColorsLight.surface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentlyGenerating
            ? AppColors.electricBlue.withValues(alpha: 0.1)
            : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyGenerating
              ? AppColors.electricBlue.withValues(alpha: 0.3)
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
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    'Waiting...',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Exercise count badge
          if (workout != null)
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
        ],
      ),
    );
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
                    'Generate ${_remainingDays.length} Workout${_remainingDays.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
