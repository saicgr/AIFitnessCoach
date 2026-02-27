import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/services/saved_workouts_service.dart';
import '../../data/services/challenges_service.dart';
import '../../data/services/api_client.dart';
import '../../widgets/app_snackbar.dart';
import 'widgets/schedule_workout_dialog.dart';

/// Full-screen detail view for a shared/completed workout from the social feed.
///
/// Built entirely from [activityData] — no backend fetch needed since UserB
/// cannot access UserA's workout by ID.
class SharedWorkoutDetailScreen extends ConsumerStatefulWidget {
  final String activityId;
  final String currentUserId;
  final String posterName;
  final String? posterAvatar;
  final String activityType;
  final Map<String, dynamic> activityData;
  final SavedWorkoutsService savedWorkoutsService;

  const SharedWorkoutDetailScreen({
    super.key,
    required this.activityId,
    required this.currentUserId,
    required this.posterName,
    this.posterAvatar,
    required this.activityType,
    required this.activityData,
    required this.savedWorkoutsService,
  });

  @override
  ConsumerState<SharedWorkoutDetailScreen> createState() =>
      _SharedWorkoutDetailScreenState();
}

class _SharedWorkoutDetailScreenState
    extends ConsumerState<SharedWorkoutDetailScreen> {
  bool _isAccepting = false;

  String get _workoutName =>
      widget.activityData['workout_name'] as String? ?? 'Workout';
  String get _workoutType =>
      widget.activityData['workout_type'] as String? ?? '';
  String get _difficulty =>
      widget.activityData['difficulty'] as String? ?? '';
  int get _duration =>
      widget.activityData['duration_minutes'] as int? ?? 0;
  int get _exerciseCount =>
      widget.activityData['exercises_count'] as int? ?? 0;
  List<dynamic> get _exercises =>
      widget.activityData['exercises_performance'] as List<dynamic>? ?? [];

  String get _actionVerb =>
      widget.activityType == 'workout_shared' ? 'Shared' : 'Completed';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final totalVolume = widget.activityData['total_volume_lbs'] ??
        widget.activityData['total_volume'];

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Workout Details',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // Workout name
                Text(
                  _workoutName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Poster info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.orange.withValues(alpha: 0.2),
                      backgroundImage: widget.posterAvatar != null
                          ? NetworkImage(widget.posterAvatar!)
                          : null,
                      child: widget.posterAvatar == null
                          ? Text(
                              widget.posterName.isNotEmpty
                                  ? widget.posterName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_actionVerb by ${widget.posterName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stat chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_duration > 0)
                      _StatChip(
                        icon: Icons.timer_rounded,
                        label: '$_duration min',
                        isDark: isDark,
                      ),
                    if (_exerciseCount > 0 || _exercises.isNotEmpty)
                      _StatChip(
                        icon: Icons.fitness_center_rounded,
                        label:
                            '${_exercises.isNotEmpty ? _exercises.length : _exerciseCount} exercises',
                        isDark: isDark,
                      ),
                    if (totalVolume != null)
                      _StatChip(
                        icon: Icons.trending_up_rounded,
                        label: _formatVolume(totalVolume),
                        isDark: isDark,
                      ),
                    if (_difficulty.isNotEmpty)
                      _StatChip(
                        icon: Icons.speed_rounded,
                        label: _difficulty,
                        isDark: isDark,
                      ),
                    if (_workoutType.isNotEmpty)
                      _StatChip(
                        icon: Icons.category_rounded,
                        label: _workoutType,
                        isDark: isDark,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Exercises section
                if (_exercises.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.list_rounded, size: 20, color: textMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Exercises',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cardBorder.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _exercises.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 56,
                        color: cardBorder.withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        final ex =
                            _exercises[index] as Map<String, dynamic>;
                        return _ExerciseTile(
                          index: index,
                          exercise: ex,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Empty state
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cardBorder.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 32,
                          color: textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Exercise details not available',
                          style: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Accept Challenge button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isAccepting ? null : () => _acceptChallenge(context),
                    icon: _isAccepting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bolt_rounded, size: 22),
                    label: Text(
                      _isAccepting ? 'Starting...' : 'ACCEPT CHALLENGE',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Schedule for Later button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _scheduleForLater(context),
                    icon: Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: isDark ? AppColors.cyan : AppColorsLight.textPrimary,
                    ),
                    label: Text(
                      'Schedule for Later',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.cyan : AppColorsLight.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: (isDark ? AppColors.cyan : AppColorsLight.textPrimary)
                            .withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                // Bottom safe area padding
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptChallenge(BuildContext context) async {
    if (_exercises.isEmpty) {
      AppSnackBar.error(
          context, 'No exercise data available for this workout');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isAccepting = true);

    try {
      final challengesService = ChallengesService(ref.read(apiClientProvider));

      // Create + accept challenge via formal challenge system
      final challengeResult = await challengesService.acceptChallengeFromFeed(
        activityId: widget.activityId,
      );

      final challengeId = challengeResult['id'] as String;

      // Build a Workout object from the activity data
      final workout = Workout(
        id: 'challenge_${widget.activityId}',
        name: _workoutName,
        type: _workoutType,
        difficulty: _difficulty,
        exercisesJson: jsonEncode(_exercises),
        durationMinutes: _duration,
        estimatedDurationMinutes: _duration,
      );

      // Navigate with challengeId + challengeData so WorkoutCompleteScreen
      // can fire _completeChallenge() and store comparison data
      if (mounted) {
        context.push('/active-workout', extra: {
          'workout': workout,
          'challengeId': challengeId,
          'challengeData': {
            'challenger_name': widget.posterName,
            'workout_data': widget.activityData,
          },
        });
      }
    } catch (e) {
      debugPrint('❌ [Challenge] Error accepting challenge from feed: $e');
      if (mounted) {
        setState(() => _isAccepting = false);
        AppSnackBar.error(context, 'Failed to start challenge: $e');
      }
    }
  }

  void _scheduleForLater(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => ScheduleWorkoutDialog(
        activityId: widget.activityId,
        currentUserId: widget.currentUserId,
        workoutName: _workoutName,
        savedWorkoutsService: widget.savedWorkoutsService,
        elevated: elevated,
      ),
    );
  }

  String _formatVolume(dynamic volume) {
    if (volume == null) return '';
    final v = volume is int ? volume.toDouble() : (volume as double);
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K lbs';
    }
    return '${v.toStringAsFixed(0)} lbs';
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

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
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.cyan),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> exercise;
  final bool isDark;

  const _ExerciseTile({
    required this.index,
    required this.exercise,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final name = exercise['name'] as String? ?? 'Exercise ${index + 1}';
    final sets = exercise['sets'] as int?;
    final reps = exercise['reps'] as int?;
    final weightKg = exercise['weight_kg'];
    final muscleGroup = exercise['muscle_group'] as String?;
    final equipment = exercise['equipment'] as String?;

    final detailParts = <String>[];
    if (sets != null && reps != null) {
      detailParts.add('$sets \u00d7 $reps');
    }
    if (weightKg != null && (weightKg as num) > 0) {
      final kg = weightKg is int ? weightKg.toDouble() : weightKg as double;
      final lbs = (kg * 2.20462).round();
      detailParts.add('${kg.toStringAsFixed(0)} kg ($lbs lbs)');
    }

    final metaParts = <String>[];
    if (muscleGroup != null && muscleGroup.isNotEmpty) metaParts.add(muscleGroup);
    if (equipment != null && equipment.isNotEmpty) metaParts.add(equipment);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index circle
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (detailParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailParts.join('  \u2022  '),
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
                if (metaParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    metaParts.join('  \u2022  '),
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
