import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Data class for quit workout result
class QuitWorkoutResult {
  final String reason;
  final String? notes;

  const QuitWorkoutResult({
    required this.reason,
    this.notes,
  });
}

/// Shows a bottom sheet for confirming workout quit
Future<QuitWorkoutResult?> showQuitWorkoutDialog({
  required BuildContext context,
  required int progressPercent,
  required int totalCompletedSets,
  required int exercisesWithCompletedSets,
}) async {
  String? selectedReason;
  final notesController = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<QuitWorkoutResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : AppColorsLight.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title with progress
              Row(
                children: [
                  Icon(
                    Icons.exit_to_app,
                    color: isDark ? AppColors.orange : AppColorsLight.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Workout Early?',
                          style: TextStyle(
                            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$progressPercent% complete • $totalCompletedSets sets done',
                          style: TextStyle(
                            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressPercent >= 50
                          ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                          : (isDark ? AppColors.orange : AppColorsLight.orange),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Question
              Text(
                'Why are you ending early?',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // Quick reply reasons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ReasonChip(
                    reason: 'too_tired',
                    label: 'Too tired',
                    icon: Icons.battery_1_bar,
                    isSelected: selectedReason == 'too_tired',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'too_tired'),
                  ),
                  _ReasonChip(
                    reason: 'out_of_time',
                    label: 'Out of time',
                    icon: Icons.timer_off,
                    isSelected: selectedReason == 'out_of_time',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'out_of_time'),
                  ),
                  _ReasonChip(
                    reason: 'not_feeling_well',
                    label: 'Not feeling well',
                    icon: Icons.sick,
                    isSelected: selectedReason == 'not_feeling_well',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'not_feeling_well'),
                  ),
                  _ReasonChip(
                    reason: 'equipment_unavailable',
                    label: 'Equipment busy',
                    icon: Icons.fitness_center,
                    isSelected: selectedReason == 'equipment_unavailable',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'equipment_unavailable'),
                  ),
                  _ReasonChip(
                    reason: 'injury',
                    label: 'Pain/Injury',
                    icon: Icons.healing,
                    isSelected: selectedReason == 'injury',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'injury'),
                  ),
                  _ReasonChip(
                    reason: 'other',
                    label: 'Other reason',
                    icon: Icons.more_horiz,
                    isSelected: selectedReason == 'other',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'other'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Optional notes
              TextField(
                controller: notesController,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)...',
                  hintStyle: TextStyle(
                    color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted).withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Keep Going',
                        style: TextStyle(
                          color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          ctx,
                          QuitWorkoutResult(
                            reason: selectedReason ?? 'quick_exit',
                            notes: notesController.text.isEmpty ? null : notesController.text,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.orange : AppColorsLight.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'End Workout',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    ),
  );
}

class _ReasonChip extends StatelessWidget {
  final String reason;
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ReasonChip({
    required this.reason,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final bgColor = isSelected
        ? accentColor.withOpacity(0.15)
        : (isDark ? AppColors.elevated : AppColorsLight.elevated);
    final borderColor = isSelected
        ? accentColor
        : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder);
    final textColor = isSelected
        ? accentColor
        : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
