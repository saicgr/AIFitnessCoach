import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';

class ExpandableSummaryExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final ExerciseComparisonInfo? comparison;
  final List<SetLogInfo> setLogs;
  final bool isDark;
  final Color accentColor;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final Widget? miniChart;

  const ExpandableSummaryExerciseCard({
    super.key,
    required this.exercise,
    this.comparison,
    required this.setLogs,
    required this.isDark,
    required this.accentColor,
    required this.isExpanded,
    required this.onToggle,
    this.onEdit,
    this.miniChart,
  });

  @override
  State<ExpandableSummaryExerciseCard> createState() =>
      _ExpandableSummaryExerciseCardState();
}

class _ExpandableSummaryExerciseCardState
    extends State<ExpandableSummaryExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _chevronController;
  late Animation<double> _chevronRotation;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _chevronRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOut),
    );
    if (widget.isExpanded) {
      _chevronController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ExpandableSummaryExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _chevronController.forward();
      } else {
        _chevronController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Collapsed header (always visible, tappable)
          _buildCollapsedHeader(),

          // Expanded content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: widget.isExpanded
                ? _buildExpandedContent()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // COLLAPSED HEADER
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCollapsedHeader() {
    final comparison = widget.comparison;

    return InkWell(
      onTap: widget.onToggle,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Name + badge + chevron
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? AppColors.textPrimary
                          : Colors.black87,
                    ),
                  ),
                ),
                if (comparison != null && comparison.hasPrevious)
                  _buildComparisonBadge(comparison),
                const SizedBox(width: 4),
                RotationTransition(
                  turns: _chevronRotation,
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: widget.isDark
                        ? AppColors.textMuted
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Row 2: Summary line
            Text(
              _exerciseSetDisplay(widget.exercise),
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark
                    ? AppColors.textSecondary
                    : Colors.grey.shade600,
              ),
            ),

            // Row 3: Previous comparison text
            if (comparison != null && comparison.hasPrevious) ...[
              const SizedBox(height: 6),
              Text(
                _comparisonDetailText(comparison),
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark
                      ? AppColors.textMuted
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // COMPARISON BADGE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildComparisonBadge(ExerciseComparisonInfo comparison) {
    Color badgeColor;
    IconData icon;
    String label;

    if (comparison.isImproved) {
      badgeColor = AppColors.success;
      icon = Icons.trending_up;
      label = comparison.formattedPercentDiff.isNotEmpty
          ? comparison.formattedPercentDiff
          : 'Improved';
    } else if (comparison.isDeclined) {
      badgeColor = AppColors.error;
      icon = Icons.trending_down;
      label = comparison.formattedPercentDiff.isNotEmpty
          ? comparison.formattedPercentDiff
          : 'Declined';
    } else {
      badgeColor =
          widget.isDark ? AppColors.textMuted : Colors.grey.shade500;
      icon = Icons.trending_flat;
      label = 'Same';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EXPANDED CONTENT
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Divider(
            height: 1,
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade200,
          ),
          const SizedBox(height: 12),

          // Per-set data table
          if (widget.setLogs.isNotEmpty) ...[
            _buildSetTable(),
            const SizedBox(height: 12),
          ],

          // Time spent row
          if (widget.comparison?.currentTimeSeconds != null)
            _buildTimeRow(),

          // Previous session comparison card
          if (widget.comparison != null && widget.comparison!.hasPrevious) ...[
            const SizedBox(height: 12),
            _buildPreviousComparisonCard(),
          ],

          // Mini chart placeholder
          if (widget.miniChart != null) ...[
            const SizedBox(height: 12),
            widget.miniChart!,
          ],

          // Edit button
          if (widget.onEdit != null) ...[
            const SizedBox(height: 12),
            _buildEditButton(),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PER-SET TABLE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSetTable() {
    final hasRpe = widget.setLogs.any((s) => s.rpe != null);

    return Column(
      children: [
        // Header row
        _buildTableHeaderRow(hasRpe),
        const SizedBox(height: 4),
        // Data rows
        ...widget.setLogs.map((setLog) => _buildSetRow(setLog, hasRpe)),
      ],
    );
  }

  Widget _buildTableHeaderRow(bool hasRpe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'Set',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? AppColors.textMuted
                    : Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Reps',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppColors.textMuted
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Weight',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppColors.textMuted
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ),
          if (hasRpe)
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'RPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppColors.textMuted
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetRow(SetLogInfo setLog, bool hasRpe) {
    final setType = setLog.setType.toLowerCase();
    final rowColor = _setTypeRowColor(setType);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Row(
              children: [
                Text(
                  '${setLog.setNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark
                        ? AppColors.textPrimary
                        : Colors.black87,
                  ),
                ),
                if (setType != 'working') ...[
                  const SizedBox(width: 3),
                  _buildSetTypeIndicator(setType),
                ],
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${setLog.repsCompleted}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? AppColors.textPrimary
                      : Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${setLog.weightKg.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? AppColors.textPrimary
                      : Colors.black87,
                ),
              ),
            ),
          ),
          if (hasRpe)
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  setLog.rpe != null
                      ? setLog.rpe!.toStringAsFixed(1)
                      : '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: setLog.rpe != null
                        ? (widget.isDark
                            ? AppColors.textPrimary
                            : Colors.black87)
                        : (widget.isDark
                            ? AppColors.textMuted
                            : Colors.grey.shade400),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _setTypeRowColor(String setType) {
    switch (setType) {
      case 'warmup':
      case 'warm_up':
        return widget.isDark
            ? AppColors.info.withValues(alpha: 0.08)
            : AppColors.info.withValues(alpha: 0.06);
      case 'drop':
      case 'drop_set':
        return widget.isDark
            ? AppColors.orange.withValues(alpha: 0.08)
            : AppColors.orange.withValues(alpha: 0.06);
      case 'failure':
      case 'amrap':
        return widget.isDark
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.error.withValues(alpha: 0.06);
      default:
        return Colors.transparent;
    }
  }

  Widget _buildSetTypeIndicator(String setType) {
    Color color;
    String letter;
    switch (setType) {
      case 'warmup':
      case 'warm_up':
        color = AppColors.info;
        letter = 'W';
        break;
      case 'drop':
      case 'drop_set':
        color = AppColors.orange;
        letter = 'D';
        break;
      case 'failure':
      case 'amrap':
        color = AppColors.error;
        letter = 'F';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TIME ROW
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTimeRow() {
    final current = widget.comparison!.currentTimeSeconds!;
    final formatted = _formatSeconds(current);

    String? deltaText;
    Color? deltaColor;
    if (widget.comparison!.timeDiffSeconds != null &&
        widget.comparison!.timeDiffSeconds != 0) {
      deltaText = widget.comparison!.formattedTimeDiff;
      deltaColor = widget.comparison!.timeDiffSeconds! < 0
          ? AppColors.success
          : AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: widget.isDark
                ? AppColors.textMuted
                : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Text(
            'Time: $formatted',
            style: TextStyle(
              fontSize: 13,
              color: widget.isDark
                  ? AppColors.textSecondary
                  : Colors.grey.shade600,
            ),
          ),
          if (deltaText != null) ...[
            const SizedBox(width: 8),
            Text(
              deltaText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: deltaColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PREVIOUS COMPARISON CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPreviousComparisonCard() {
    final comparison = widget.comparison!;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(
                Icons.history,
                size: 14,
                color: widget.isDark
                    ? AppColors.textMuted
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                'vs Previous Session',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppColors.textMuted
                      : Colors.grey.shade500,
                ),
              ),
              if (comparison.previousDate != null) ...[
                const SizedBox(width: 6),
                Text(
                  _formatDate(comparison.previousDate!),
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isDark
                        ? AppColors.textMuted.withValues(alpha: 0.7)
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Metrics row
          Row(
            children: [
              // Volume
              Expanded(
                child: _buildComparisonMetric(
                  'Volume',
                  '${comparison.currentVolumeKg.toStringAsFixed(0)} kg',
                  comparison.volumeDiffKg,
                  comparison.volumeDiffPercent,
                ),
              ),
              const SizedBox(width: 8),
              // Max Weight
              if (comparison.currentMaxWeightKg != null)
                Expanded(
                  child: _buildComparisonMetric(
                    'Max Weight',
                    '${comparison.currentMaxWeightKg!.toStringAsFixed(1)} kg',
                    comparison.weightDiffKg,
                    comparison.weightDiffPercent,
                  ),
                ),
              if (comparison.currentMaxWeightKg != null)
                const SizedBox(width: 8),
              // Est. 1RM
              if (comparison.current1rmKg != null)
                Expanded(
                  child: _buildComparisonMetric(
                    'Est. 1RM',
                    '${comparison.current1rmKg!.toStringAsFixed(1)} kg',
                    comparison.rmDiffKg,
                    comparison.rmDiffPercent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMetric(
    String label,
    String value,
    double? diffKg,
    double? diffPercent,
  ) {
    Color arrowColor;
    IconData arrowIcon;

    if (diffKg == null || diffKg == 0) {
      arrowColor = widget.isDark ? AppColors.textMuted : Colors.grey.shade500;
      arrowIcon = Icons.remove;
    } else if (diffKg > 0) {
      arrowColor = AppColors.success;
      arrowIcon = Icons.arrow_upward;
    } else {
      arrowColor = AppColors.error;
      arrowIcon = Icons.arrow_downward;
    }

    String diffText = '';
    if (diffPercent != null && diffPercent != 0) {
      final sign = diffPercent >= 0 ? '+' : '';
      diffText = '$sign${diffPercent.toStringAsFixed(1)}%';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: widget.isDark
                ? AppColors.textMuted
                : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        if (diffText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(arrowIcon, size: 10, color: arrowColor),
              const SizedBox(width: 2),
              Text(
                diffText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: arrowColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EDIT BUTTON
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildEditButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: widget.onEdit,
        icon: Icon(
          Icons.edit_outlined,
          size: 14,
          color: widget.isDark
              ? AppColors.textSecondary
              : Colors.grey.shade600,
        ),
        label: Text(
          'Edit',
          style: TextStyle(
            fontSize: 12,
            color: widget.isDark
                ? AppColors.textSecondary
                : Colors.grey.shade600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  String _exerciseSetDisplay(WorkoutExercise exercise) {
    final parts = <String>[];
    if (exercise.sets != null) parts.add('${exercise.sets} sets');
    if (exercise.reps != null) parts.add('${exercise.reps} reps');
    if (exercise.weight != null && exercise.weight! > 0) {
      parts.add('@ ${exercise.weight!.toStringAsFixed(1)} kg');
    }
    if (exercise.durationSeconds != null) {
      parts.add('${exercise.durationSeconds}s');
    }
    return parts.isEmpty ? 'N/A' : parts.join(' x ');
  }

  String _comparisonDetailText(ExerciseComparisonInfo comparison) {
    final parts = <String>[];
    if (comparison.weightDiffKg != null && comparison.weightDiffKg != 0) {
      parts.add(
          'Weight: ${comparison.previousMaxWeightKg?.toStringAsFixed(1) ?? "?"} -> ${comparison.currentMaxWeightKg?.toStringAsFixed(1) ?? "?"} kg');
    }
    if (comparison.volumeDiffKg != null && comparison.volumeDiffKg != 0) {
      final sign = comparison.volumeDiffKg! >= 0 ? '+' : '';
      parts.add(
          'Volume: $sign${comparison.volumeDiffKg!.toStringAsFixed(0)} kg');
    }
    if (comparison.repsDiff != null && comparison.repsDiff != 0) {
      final sign = comparison.repsDiff! >= 0 ? '+' : '';
      parts.add('Reps: $sign${comparison.repsDiff}');
    }
    return parts.isEmpty ? 'No change from last session' : parts.join(' | ');
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '--';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins <= 0) return '${secs}s';
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
