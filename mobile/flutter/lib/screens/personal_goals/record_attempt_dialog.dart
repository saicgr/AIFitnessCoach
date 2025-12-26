import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Dialog for recording a single_max attempt or adding volume
class RecordAttemptDialog extends StatefulWidget {
  final String exerciseName;
  final bool isMaxAttempt; // true for single_max, false for weekly_volume
  final int currentValue;
  final int? personalBest;
  final Future<void> Function(int value, String? notes) onSubmit;

  const RecordAttemptDialog({
    super.key,
    required this.exerciseName,
    required this.isMaxAttempt,
    required this.currentValue,
    this.personalBest,
    required this.onSubmit,
  });

  @override
  State<RecordAttemptDialog> createState() => _RecordAttemptDialogState();
}

class _RecordAttemptDialogState extends State<RecordAttemptDialog> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valueText = _valueController.text.trim();
    final value = int.tryParse(valueText);

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notes = _notesController.text.trim();
      await widget.onSubmit(value, notes.isEmpty ? null : notes);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: backgroundColor,
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
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.isMaxAttempt ? Icons.emoji_events : Icons.add_circle,
                    color: AppColors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isMaxAttempt ? 'Record Attempt' : 'Add Reps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        widget.exerciseName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        widget.isMaxAttempt ? 'Current Best' : 'Total So Far',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.currentValue}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                  if (widget.personalBest != null) ...[
                    Container(
                      width: 1,
                      height: 40,
                      color: cardBorder,
                    ),
                    Column(
                      children: [
                        Text(
                          'Personal Best',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.personalBest}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Value input
            Text(
              widget.isMaxAttempt ? 'Reps Completed' : 'Reps to Add',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: TextStyle(
                color: textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: textMuted, fontSize: 32),
                filled: true,
                fillColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cyan, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes (optional)
            if (widget.isMaxAttempt) ...[
              Text(
                'Notes (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                style: TextStyle(color: textPrimary),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'How did it feel?',
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cyan, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isMaxAttempt ? 'Record' : 'Add',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
