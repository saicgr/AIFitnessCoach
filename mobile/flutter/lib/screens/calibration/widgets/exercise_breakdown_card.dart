import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/calibration.dart';

/// Collapsible card showing exercise-by-exercise calibration breakdown
class ExerciseBreakdownCard extends StatefulWidget {
  final List<CalibrationExerciseResult> exerciseResults;
  final bool isDark;

  const ExerciseBreakdownCard({
    super.key,
    required this.exerciseResults,
    required this.isDark,
  });

  @override
  State<ExerciseBreakdownCard> createState() => _ExerciseBreakdownCardState();
}

class _ExerciseBreakdownCardState extends State<ExerciseBreakdownCard> {
  bool _isExpanded = false;

  Color _getPerformanceColor(String? indicator) {
    switch (indicator?.toLowerCase()) {
      case 'exceeded':
        return widget.isDark ? AppColors.success : AppColorsLight.success;
      case 'matched':
        return widget.isDark ? AppColors.warning : AppColorsLight.warning;
      case 'below':
        return widget.isDark ? AppColors.error : AppColorsLight.error;
      default:
        return widget.isDark
            ? AppColors.textSecondary
            : AppColorsLight.textSecondary;
    }
  }

  IconData _getPerformanceIcon(String? indicator) {
    switch (indicator?.toLowerCase()) {
      case 'exceeded':
        return Icons.trending_up;
      case 'matched':
        return Icons.check_circle_outline;
      case 'below':
        return Icons.trending_down;
      default:
        return Icons.remove;
    }
  }

  String _getPerformanceLabel(String? indicator) {
    switch (indicator?.toLowerCase()) {
      case 'exceeded':
        return 'Exceeded expectations';
      case 'matched':
        return 'Met expectations';
      case 'below':
        return 'Below expectations';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevated =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final purple = widget.isDark ? AppColors.purple : AppColorsLight.purple;

    if (widget.exerciseResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercise Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.exerciseResults.length} exercises analyzed',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Performance summary chips
                  _buildPerformanceSummary(),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: widget.isDark
                      ? AppColors.cardBorder
                      : AppColorsLight.cardBorder,
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.exerciseResults.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final result = widget.exerciseResults[index];
                    return _buildExerciseItem(result, index);
                  },
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    final exceededCount = widget.exerciseResults
        .where((e) => e.performanceIndicator?.toLowerCase() == 'exceeded')
        .length;
    final matchedCount = widget.exerciseResults
        .where((e) => e.performanceIndicator?.toLowerCase() == 'matched')
        .length;
    final belowCount = widget.exerciseResults
        .where((e) => e.performanceIndicator?.toLowerCase() == 'below')
        .length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (exceededCount > 0)
          _buildMiniChip(
            exceededCount.toString(),
            widget.isDark ? AppColors.success : AppColorsLight.success,
          ),
        if (matchedCount > 0)
          Padding(
            padding: EdgeInsets.only(left: exceededCount > 0 ? 4 : 0),
            child: _buildMiniChip(
              matchedCount.toString(),
              widget.isDark ? AppColors.warning : AppColorsLight.warning,
            ),
          ),
        if (belowCount > 0)
          Padding(
            padding:
                EdgeInsets.only(left: (exceededCount > 0 || matchedCount > 0) ? 4 : 0),
            child: _buildMiniChip(
              belowCount.toString(),
              widget.isDark ? AppColors.error : AppColorsLight.error,
            ),
          ),
      ],
    );
  }

  Widget _buildMiniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExerciseItem(CalibrationExerciseResult result, int index) {
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final performanceColor = _getPerformanceColor(result.performanceIndicator);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: performanceColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: performanceColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name and performance indicator
          Row(
            children: [
              Expanded(
                child: Text(
                  result.exerciseName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: performanceColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPerformanceIcon(result.performanceIndicator),
                      size: 14,
                      color: performanceColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPerformanceLabel(result.performanceIndicator),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: performanceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Stats row - only show meaningful values
          Row(
            children: [
              if (result.weightUsedKg != null && result.weightUsedKg! > 0) ...[
                _buildStatItem(
                  Icons.fitness_center,
                  '${result.weightUsedKg!.toStringAsFixed(1)} kg',
                  textSecondary,
                ),
                const SizedBox(width: 16),
              ],
              // Only show reps if greater than 1 (to avoid showing "1 reps" for timed exercises)
              if (result.repsCompleted != null && result.repsCompleted! > 1) ...[
                _buildStatItem(
                  Icons.repeat,
                  '${result.repsCompleted} reps',
                  textSecondary,
                ),
                const SizedBox(width: 16),
              ],
              // Only show sets if greater than 1 (calibration is typically single-set)
              if (result.setsCompleted != null && result.setsCompleted! > 1)
                _buildStatItem(
                  Icons.format_list_numbered,
                  '${result.setsCompleted} sets',
                  textSecondary,
                ),
            ],
          ),

          // AI comment
          if (result.aiComment != null && result.aiComment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: widget.isDark ? AppColors.cyan : AppColorsLight.cyan,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.aiComment!,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate(delay: (100 * index).ms).fadeIn().slideX(begin: 0.05);
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
