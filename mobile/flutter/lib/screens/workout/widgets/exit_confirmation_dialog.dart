import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Exit reasons matching the WebUI
enum WorkoutExitReason {
  completed('completed', 'Completed', Icons.check_circle, AppColors.success),
  tooTired('too_tired', 'Too Tired', Icons.battery_0_bar, AppColors.orange),
  outOfTime('out_of_time', 'Out of Time', Icons.schedule, AppColors.purple),
  notFeelingWell('not_feeling_well', 'Not Feeling Well', Icons.sick, AppColors.error),
  equipmentUnavailable('equipment_unavailable', 'Equipment Unavailable', Icons.fitness_center, AppColors.textMuted),
  injury('injury', 'Injury', Icons.healing, AppColors.error),
  other('other', 'Other', Icons.more_horiz, AppColors.textSecondary);

  const WorkoutExitReason(this.value, this.label, this.icon, this.color);

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

/// Dialog to confirm workout exit with reason selection
class ExitConfirmationDialog extends StatefulWidget {
  final int exercisesCompleted;
  final int totalExercises;
  final int setsCompleted;
  final int timeSpentSeconds;
  final Future<void> Function(WorkoutExitReason reason, String? notes) onConfirm;
  final VoidCallback onCancel;

  const ExitConfirmationDialog({
    super.key,
    required this.exercisesCompleted,
    required this.totalExercises,
    required this.setsCompleted,
    required this.timeSpentSeconds,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ExitConfirmationDialog> createState() => _ExitConfirmationDialogState();
}

class _ExitConfirmationDialogState extends State<ExitConfirmationDialog> {
  WorkoutExitReason? _selectedReason;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  int get _progressPercentage {
    if (widget.totalExercises == 0) return 0;
    return ((widget.exercisesCompleted / widget.totalExercises) * 100).round();
  }

  Future<void> _handleConfirm() async {
    if (_selectedReason == null) return;

    setState(() => _isLoading = true);
    try {
      await widget.onConfirm(
        _selectedReason!,
        _notesController.text.isNotEmpty ? _notesController.text : null,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.exit_to_app,
                      color: AppColors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Exit Workout?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _ProgressRow(
                      label: 'Progress',
                      value: '$_progressPercentage%',
                      icon: Icons.pie_chart,
                    ),
                    const SizedBox(height: 8),
                    _ProgressRow(
                      label: 'Exercises',
                      value: '${widget.exercisesCompleted}/${widget.totalExercises}',
                      icon: Icons.fitness_center,
                    ),
                    const SizedBox(height: 8),
                    _ProgressRow(
                      label: 'Sets Completed',
                      value: '${widget.setsCompleted}',
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 8),
                    _ProgressRow(
                      label: 'Time',
                      value: _formatTime(widget.timeSpentSeconds),
                      icon: Icons.timer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reason selection
              const Text(
                'Why are you exiting?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Reason chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WorkoutExitReason.values.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedReason = reason),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? reason.color.withOpacity(0.2)
                            : AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? reason.color : AppColors.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            reason.icon,
                            size: 16,
                            color: isSelected
                                ? reason.color
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reason.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? reason.color
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notes field (optional)
              if (_selectedReason != null && _selectedReason != WorkoutExitReason.completed)
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add notes (optional)',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.glassSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue Workout'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedReason == null || _isLoading
                          ? null
                          : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _selectedReason == WorkoutExitReason.completed
                            ? AppColors.success
                            : AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _selectedReason == WorkoutExitReason.completed
                                  ? 'Complete'
                                  : 'Exit',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
