import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/saved_workouts_service.dart';

/// Schedule Workout Dialog - date picker with conflict detection.
///
/// Extracted from ActivityCard so it can be reused by SharedWorkoutDetailScreen.
class ScheduleWorkoutDialog extends StatefulWidget {
  final String activityId;
  final String currentUserId;
  final String workoutName;
  final SavedWorkoutsService savedWorkoutsService;
  final Color elevated;

  const ScheduleWorkoutDialog({
    super.key,
    required this.activityId,
    required this.currentUserId,
    required this.workoutName,
    required this.savedWorkoutsService,
    required this.elevated,
  });

  @override
  State<ScheduleWorkoutDialog> createState() => _ScheduleWorkoutDialogState();
}

class _ScheduleWorkoutDialogState extends State<ScheduleWorkoutDialog> {
  late DateTime _selectedDate;
  List<Map<String, dynamic>>? _existingWorkouts;
  bool _isCheckingConflicts = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return AlertDialog(
      backgroundColor: widget.elevated,
      title: const Text('Schedule Workout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule "${widget.workoutName}" for:',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _isCheckingConflicts = true;
                  _existingWorkouts = null;
                });
                try {
                  final existing = await widget.savedWorkoutsService.getScheduledForDate(
                    userId: widget.currentUserId,
                    date: date,
                  );
                  if (mounted) {
                    setState(() {
                      _existingWorkouts = existing;
                      _isCheckingConflicts = false;
                    });
                  }
                } catch (_) {
                  if (mounted) setState(() => _isCheckingConflicts = false);
                }
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cyan,
            ),
          ),
          if (_isCheckingConflicts) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Checking schedule...',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
          if (_existingWorkouts != null && _existingWorkouts!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_existingWorkouts!.length} workout(s) already on this date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...(_existingWorkouts!.map((w) => Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Text(
                      '\u2022 ${w['workout_name'] ?? w['name'] ?? 'Unnamed workout'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ))),
                  const SizedBox(height: 6),
                  Text(
                    'This workout will be added alongside them.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Scheduling workout...'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );

            try {
              await widget.savedWorkoutsService.saveAndSchedule(
                userId: widget.currentUserId,
                activityId: widget.activityId,
                scheduledDate: _selectedDate,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Workout scheduled for ${_selectedDate.month}/${_selectedDate.day}!',
                    ),
                    backgroundColor: AppColors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error scheduling workout: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to schedule workout: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
          ),
          child: const Text('Schedule'),
        ),
      ],
    );
  }
}
