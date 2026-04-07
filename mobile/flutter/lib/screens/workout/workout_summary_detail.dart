/// Detail view for the Workout Summary screen.
///
/// Read-only display of the workout plan: header, type/difficulty badges,
/// stats row, equipment, and exercise cards with sets × reps detail.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';

class WorkoutSummaryDetail extends StatelessWidget {
  final WorkoutSummaryResponse? data;
  final Map<String, dynamic>? metadata;
  final double topPadding;
  final Workout? workout;

  const WorkoutSummaryDetail({
    super.key,
    required this.data,
    required this.metadata,
    this.topPadding = 0,
    this.workout,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null && workout == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Parse workout data
    final w = workout;
    final workoutName = w?.name ?? data?.workout['name'] as String? ?? 'Workout';
    final scheduledDate = w?.scheduledDate ?? data?.workout['scheduled_date'] as String?;
    final exercises = w?.exercises ?? _parseExercisesFromJson(data?.workout['exercises_json']);
    final type = w?.type ?? data?.workout['type'] as String? ?? 'strength';
    final difficulty = w?.difficulty ?? data?.workout['difficulty'] as String? ?? 'medium';
    final duration = w?.bestDurationMinutes ?? data?.workout['duration_minutes'] as int? ?? 0;
    final calories = w?.estimatedCalories ?? data?.workout['estimated_calories'] as int? ?? 0;
    final equipmentNeeded = w?.equipmentNeeded ?? <String>[];

    // Format date
    String formattedDate = '';
    if (scheduledDate != null) {
      try {
        final dt = DateTime.parse(scheduledDate);
        formattedDate = DateFormat('EEEE, MMMM d, y').format(dt);
      } catch (_) {
        formattedDate = scheduledDate;
      }
    }

    // Completion method
    final completionMethod = data?.completionMethod ?? w?.completionMethod;

    int sectionIndex = 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: topPadding + 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Header
          _buildHeader(
            workoutName,
            formattedDate,
            completionMethod,
            isDark,
            textPrimary,
            textSecondary,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * sectionIndex++))
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // Type / Difficulty badges
          _buildBadgeRow(type, difficulty, isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * sectionIndex++))
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // Stats row
          _buildStatsRow(duration, exercises.length, calories, isDark, textPrimary, textMuted)
              .animate()
              .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * sectionIndex++))
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // Equipment section
          if (equipmentNeeded.isNotEmpty) ...[
            _buildEquipmentSection(
              equipmentNeeded, isDark, textPrimary, textMuted, cardColor,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * sectionIndex++))
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16),
          ],

          // Exercises header
          _buildSectionHeader(
            'EXERCISES',
            Icons.fitness_center,
            exercises.length,
            isDark,
            textMuted,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * sectionIndex++))
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 8),

          // Exercise cards
          ...exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildExerciseCard(
                exercise,
                index,
                exercises,
                isDark,
                textPrimary,
                textSecondary,
                textMuted,
                cardColor,
                cardBorder,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 50 * index + 100 * sectionIndex))
                .slideY(begin: 0.03, end: 0);
          }),

          // Bottom padding for floating pill clearance
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String name,
    String date,
    String? completionMethod,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final String statusLabel;
    final Color statusColor;
    final IconData statusIcon;

    if (completionMethod == 'tracked') {
      statusLabel = 'Tracked';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (completionMethod == 'marked_done') {
      statusLabel = 'Marked Done';
      statusColor = Colors.orange;
      statusIcon = Icons.check_circle_outline;
    } else if (completionMethod == 'quit_early') {
      statusLabel = 'Quit Early';
      statusColor = Colors.grey;
      statusIcon = Icons.remove_circle_outline;
    } else {
      statusLabel = 'Completed';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            height: 1.2,
          ),
        ),
        if (date.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeRow(String type, String difficulty, bool isDark) {
    final typeColor = AppColors.getWorkoutTypeColor(type);
    final diffColor = _getDifficultyColor(difficulty);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _badge('Type', type.substring(0, 1).toUpperCase() + type.substring(1), typeColor),
          const SizedBox(width: 8),
          _badge('Difficulty', difficulty.substring(0, 1).toUpperCase() + difficulty.substring(1), diffColor),
        ],
      ),
    );
  }

  Widget _badge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    int duration,
    int exerciseCount,
    int calories,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Row(
      children: [
        _statCard(Icons.timer_outlined, '$duration', 'min', AppColors.orange, isDark),
        const SizedBox(width: 12),
        _statCard(Icons.fitness_center, '$exerciseCount', 'exercises', AppColors.orange, isDark),
        const SizedBox(width: 12),
        _statCard(Icons.local_fire_department, '$calories', 'cal', const Color(0xFFF97316), isDark),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color, bool isDark) {
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSection(
    List<String> equipment,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('EQUIPMENT', Icons.fitness_center, equipment.length, isDark, textMuted),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: equipment.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(e, style: TextStyle(fontSize: 13, color: textPrimary)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    int count,
    bool isDark,
    Color textMuted,
  ) {
    final accentColor = AppColors.orange;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentColor, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(
    WorkoutExercise exercise,
    int index,
    List<WorkoutExercise> allExercises,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    final sets = exercise.sets ?? 0;
    final reps = exercise.reps ?? 0;
    final weight = exercise.weight;
    final muscleGroup = exercise.muscleGroup ?? exercise.primaryMuscle ?? '';
    final equipment = exercise.equipment ?? '';
    final isSuperset = exercise.supersetGroup != null;
    final isTimed = exercise.isTimed == true;
    final holdSeconds = exercise.holdSeconds;

    // Build sets info from set_targets if available
    final setTargets = exercise.setTargets;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise number + name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Index badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (muscleGroup.isNotEmpty) ...[
                          Text(
                            muscleGroup,
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                          if (equipment.isNotEmpty)
                            Text(' • ', style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                        if (equipment.isNotEmpty)
                          Flexible(
                            child: Text(
                              equipment,
                              style: TextStyle(fontSize: 12, color: textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Superset badge
              if (isSuperset)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Set details
          if (setTargets != null && setTargets.isNotEmpty)
            _buildSetTargetsTable(setTargets, isDark, textPrimary, textSecondary, textMuted)
          else
            _buildSimpleSetsRow(sets, reps, weight, isTimed, holdSeconds, isDark, textPrimary, textMuted),

          // Form cue
          if (exercise.formCue != null && exercise.formCue!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 14, color: textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    exercise.formCue!,
                    style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetTargetsTable(
    List<SetTarget> targets,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return Column(
      children: targets.map((target) {
        final setLabel = target.setTypeLabel.isNotEmpty
            ? target.setTypeLabel
            : '${target.setNumber}';
        final isWarmup = target.isWarmup;
        final weightStr = target.targetWeightKg != null
            ? '${target.targetWeightKg!.toStringAsFixed(target.targetWeightKg! == target.targetWeightKg!.roundToDouble() ? 0 : 1)} kg'
            : '—';
        final repsStr = target.hasHoldTime
            ? target.holdTimeDisplay
            : '${target.targetReps} reps';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Set number/type
              Container(
                width: 28,
                height: 24,
                decoration: BoxDecoration(
                  color: isWarmup
                      ? Colors.orange.withValues(alpha: 0.1)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    setLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isWarmup ? Colors.orange : textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Weight
              SizedBox(
                width: 70,
                child: Text(
                  weightStr,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                ),
              ),
              // Reps
              SizedBox(
                width: 70,
                child: Text(
                  repsStr,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                ),
              ),
              // RPE/RIR
              if (target.targetRpe != null)
                Text(
                  'RPE ${target.targetRpe}',
                  style: TextStyle(fontSize: 11, color: textMuted),
                )
              else if (target.targetRir != null)
                Text(
                  'RIR ${target.targetRir}',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSimpleSetsRow(
    int sets,
    int reps,
    double? weight,
    bool isTimed,
    int? holdSeconds,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final setsStr = '$sets sets';
    final repsStr = isTimed && holdSeconds != null
        ? '${holdSeconds}s hold'
        : '$reps reps';
    final weightStr = weight != null && weight > 0
        ? '${weight.toStringAsFixed(weight == weight.roundToDouble() ? 0 : 1)} kg'
        : null;

    return Row(
      children: [
        _miniStat(setsStr, isDark),
        const SizedBox(width: 8),
        _miniStat(repsStr, isDark),
        if (weightStr != null) ...[
          const SizedBox(width: 8),
          _miniStat(weightStr, isDark),
        ],
      ],
    );
  }

  Widget _miniStat(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'hell':
        return const Color(0xFFB71C1C);
      default:
        return Colors.orange;
    }
  }

  List<WorkoutExercise> _parseExercisesFromJson(dynamic exercisesJson) {
    if (exercisesJson == null) return [];
    try {
      List<dynamic> list;
      if (exercisesJson is String) {
        list = jsonDecode(exercisesJson) as List;
      } else if (exercisesJson is List) {
        list = exercisesJson;
      } else {
        return [];
      }
      return list
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
