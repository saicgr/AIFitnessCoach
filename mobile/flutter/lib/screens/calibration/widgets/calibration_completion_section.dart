import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/calibration.dart';
import '../../../data/models/exercise.dart';

/// Section shown after completing all calibration exercises
/// Allows user to review results, rate overall difficulty, and submit
class CalibrationCompletionSection extends StatelessWidget {
  /// Results from all completed exercises
  final List<CalibrationExerciseResult> results;

  /// Original exercise list for reference
  final List<WorkoutExercise> exercises;

  /// Total duration in seconds
  final int durationSeconds;

  /// Overall workout difficulty rating
  final String overallDifficulty;

  /// Callback when overall difficulty changes
  final ValueChanged<String> onOverallDifficultyChanged;

  /// Callback when completing calibration
  final VoidCallback onComplete;

  /// Callback to go back to exercises
  final VoidCallback onBack;

  /// Whether completion is in progress
  final bool isCompleting;

  const CalibrationCompletionSection({
    super.key,
    required this.results,
    required this.exercises,
    required this.durationSeconds,
    required this.overallDifficulty,
    required this.onOverallDifficultyChanged,
    required this.onComplete,
    required this.onBack,
    this.isCompleting = false,
  });

  String get _formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get _totalVolume {
    return results.fold<int>(0, (sum, r) {
      final weight = r.weightUsedKg ?? 0;
      final reps = r.repsCompleted ?? 0;
      final sets = r.setsCompleted ?? 1;
      return sum + (weight * reps * sets).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 48,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 16),
                      Text(
                        'Almost Done!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Review your results and complete calibration',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Summary stats
                _buildSummaryStats(isDark, textPrimary, textSecondary, elevated, cardBorder),

                const SizedBox(height: 24),

                // Exercise summary
                _buildExerciseSummary(isDark, textPrimary, textSecondary, elevated, cardBorder),

                const SizedBox(height: 24),

                // Overall difficulty rating
                _buildOverallDifficultySection(isDark, textPrimary, textSecondary, elevated, cardBorder),

                const SizedBox(height: 100), // Padding for bottom buttons
              ],
            ),
          ),
        ),

        // Bottom action buttons
        _buildBottomActions(isDark, elevated, cardBorder),
      ],
    );
  }

  Widget _buildSummaryStats(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color elevated,
    Color cardBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.timer_outlined,
            value: _formattedDuration,
            label: 'Duration',
            color: AppColors.cyan,
          ),
          Container(
            width: 1,
            height: 40,
            color: cardBorder,
          ),
          _buildStatItem(
            icon: Icons.fitness_center,
            value: results.length.toString(),
            label: 'Exercises',
            color: AppColors.purple,
          ),
          Container(
            width: 1,
            height: 40,
            color: cardBorder,
          ),
          _buildStatItem(
            icon: Icons.show_chart,
            value: '${(_totalVolume / 1000).toStringAsFixed(1)}k',
            label: 'Volume (kg)',
            color: AppColors.orange,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseSummary(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color elevated,
    Color cardBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: AppColors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Exercise Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
            itemBuilder: (context, index) {
              final result = results[index];
              final exercise = exercises[index];
              return _buildExerciseRow(result, exercise, isDark, textPrimary, textSecondary);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildExerciseRow(
    CalibrationExerciseResult result,
    WorkoutExercise exercise,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final rpe = result.rpeRating ?? 5;
    final difficultyColor = _getDifficultyColorFromRpe(rpe);
    final difficultyEmoji = _getDifficultyEmoji(rpe);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${result.weightUsedKg ?? 0} kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${result.repsCompleted ?? 0} reps',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${result.setsCompleted ?? 1} sets',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Difficulty indicator (RPE based)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: difficultyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(difficultyEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  _getDifficultyLabel(rpe),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: difficultyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallDifficultySection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color elevated,
    Color cardBorder,
  ) {
    final options = [
      {'value': 'too_easy', 'emoji': '😊', 'label': 'Too Easy'},
      {'value': 'moderate', 'emoji': '😐', 'label': 'Moderate'},
      {'value': 'challenging', 'emoji': '💪', 'label': 'Challenging'},
      {'value': 'max_effort', 'emoji': '🔥', 'label': 'Max Effort'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sentiment_satisfied_alt, color: AppColors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'How was the overall workout?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: options.map((option) {
              final isSelected = overallDifficulty == option['value'];
              final color = _getDifficultyColor(option['value']!);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option['value'] != 'max_effort' ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onOverallDifficultyChanged(option['value']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            option['emoji']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['label']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? color : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildBottomActions(bool isDark, Color elevated, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        border: Border(
          top: BorderSide(color: cardBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isCompleting ? null : onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  side: BorderSide(color: cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Complete button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isCompleting ? null : onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.success.withOpacity(0.5),
                ),
                child: isCompleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle),
                          SizedBox(width: 8),
                          Text(
                            'Complete Calibration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColorFromRpe(int rpe) {
    if (rpe <= 4) return AppColors.success;
    if (rpe <= 6) return AppColors.cyan;
    if (rpe <= 8) return AppColors.orange;
    return AppColors.error;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'too_easy':
        return AppColors.success;
      case 'moderate':
        return AppColors.cyan;
      case 'challenging':
        return AppColors.orange;
      case 'max_effort':
        return AppColors.error;
      default:
        return AppColors.cyan;
    }
  }

  String _getDifficultyEmoji(int rpe) {
    if (rpe <= 4) return '😊';
    if (rpe <= 6) return '😐';
    if (rpe <= 8) return '💪';
    return '🔥';
  }

  String _getDifficultyLabel(int rpe) {
    if (rpe <= 4) return 'Easy';
    if (rpe <= 6) return 'Moderate';
    if (rpe <= 8) return 'Hard';
    return 'Max';
  }
}
