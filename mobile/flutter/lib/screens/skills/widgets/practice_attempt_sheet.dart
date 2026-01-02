import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/skill_progression.dart';
import '../../../data/providers/skill_progression_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for logging a practice attempt
class PracticeAttemptSheet extends ConsumerStatefulWidget {
  final ProgressionStep step;
  final String chainId;
  final ValueChanged<ProgressionAttempt>? onAttemptLogged;

  const PracticeAttemptSheet({
    super.key,
    required this.step,
    required this.chainId,
    this.onAttemptLogged,
  });

  @override
  ConsumerState<PracticeAttemptSheet> createState() =>
      _PracticeAttemptSheetState();
}

class _PracticeAttemptSheetState extends ConsumerState<PracticeAttemptSheet> {
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  final _holdController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  bool _showHoldTime = false;

  @override
  void initState() {
    super.initState();
    // Check if this is a hold-based exercise
    _showHoldTime = widget.step.targetHoldSeconds != null ||
        (widget.step.unlockCriteria?['min_hold_seconds'] != null);

    // Pre-fill with targets if available
    if (widget.step.targetReps != null) {
      _repsController.text = widget.step.targetReps.toString();
    }
    if (widget.step.targetSets != null) {
      _setsController.text = widget.step.targetSets.toString();
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _setsController.dispose();
    _holdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: cyan,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Log Practice',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.step.exerciseName,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Goal reminder
                  if (widget.step.unlockCriteria != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cyan.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 18,
                            color: cyan,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Goal: ${widget.step.unlockCriteriaText}',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Input fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberInput(
                          controller: _repsController,
                          label: 'Reps',
                          hint: '0',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNumberInput(
                          controller: _setsController,
                          label: 'Sets',
                          hint: '1',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  if (_showHoldTime) ...[
                    const SizedBox(height: 16),
                    _buildNumberInput(
                      controller: _holdController,
                      label: 'Hold Time (seconds)',
                      hint: '0',
                      isDark: isDark,
                      fullWidth: true,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'How did it feel? Any observations?',
                      alignLabelWithHint: true,
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
                        borderSide: BorderSide(color: cyan, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick select buttons for reps
                  Text(
                    'Quick Select Reps',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 3, 5, 8, 10, 12, 15, 20].map((reps) {
                      return _QuickSelectChip(
                        label: reps.toString(),
                        isSelected: _repsController.text == reps.toString(),
                        onTap: () {
                          HapticService.light();
                          setState(() {
                            _repsController.text = reps.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitAttempt,
                      style: FilledButton.styleFrom(
                        backgroundColor: cyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: cyan.withOpacity(0.5),
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
                          : const Text(
                              'Log Attempt',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    bool fullWidth = false,
  }) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
          borderSide: BorderSide(color: cyan, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Future<void> _submitAttempt() async {
    final reps = int.tryParse(_repsController.text);
    final sets = int.tryParse(_setsController.text);
    final hold = int.tryParse(_holdController.text);
    final notes = _notesController.text.trim();

    // Validate at least one metric is provided
    if (reps == null && hold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter reps or hold time'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticService.medium();

    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final attempt = await ref.read(skillProgressionProvider.notifier).logAttempt(
          chainId: widget.chainId,
          stepId: widget.step.id,
          stepOrder: widget.step.stepOrder,
          repsCompleted: reps,
          setsCompleted: sets ?? 1,
          holdSeconds: hold,
          notes: notes.isEmpty ? null : notes,
          userId: userId,
        );

    setState(() => _isSubmitting = false);

    if (attempt != null && mounted) {
      widget.onAttemptLogged?.call(attempt);

      // Show success feedback
      final message = attempt.unlockedNext
          ? 'Amazing! You unlocked the next step!'
          : attempt.wasSuccessful
              ? 'Great job! Keep practicing!'
              : 'Attempt logged. Keep working towards your goal!';

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  attempt.unlockedNext
                      ? Icons.celebration_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                attempt.unlockedNext ? AppColors.green : AppColors.cyan,
          ),
        );
      }
    }
  }
}

class _QuickSelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? cyan : textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
