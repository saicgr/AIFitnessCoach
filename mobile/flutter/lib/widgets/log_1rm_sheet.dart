import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../data/repositories/workout_repository.dart';
import '../data/services/api_client.dart';
import 'glass_sheet.dart';

/// Shows a bottom sheet to log 1RM for an exercise
Future<Map<String, dynamic>?> showLog1RMSheet(
  BuildContext context,
  WidgetRef ref, {
  required String exerciseName,
  String? exerciseId,
  double? current1rm,
}) async {
  return showGlassSheet<Map<String, dynamic>>(
    context: context,
    useRootNavigator: true,
    builder: (context) => Log1RMSheet(
      exerciseName: exerciseName,
      exerciseId: exerciseId ?? exerciseName.toLowerCase().replaceAll(' ', '_'),
      current1rm: current1rm,
    ),
  );
}

class Log1RMSheet extends ConsumerStatefulWidget {
  final String exerciseName;
  final String exerciseId;
  final double? current1rm;

  const Log1RMSheet({
    super.key,
    required this.exerciseName,
    required this.exerciseId,
    this.current1rm,
  });

  @override
  ConsumerState<Log1RMSheet> createState() => _Log1RMSheetState();
}

class _Log1RMSheetState extends ConsumerState<Log1RMSheet> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  double _rpe = 9.0;
  bool _isDirectMax = true; // True = direct 1RM, False = estimate from set
  bool _isSaving = false;
  double? _estimated1rm;

  @override
  void initState() {
    super.initState();
    _repsController.text = '1';
    _weightController.addListener(_calculateEstimate);
    _repsController.addListener(_calculateEstimate);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _calculateEstimate() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight != null && weight > 0 && reps != null && reps > 0) {
      setState(() {
        if (reps == 1) {
          _estimated1rm = weight;
        } else if (reps < 37) {
          // Brzycki formula: 1RM = weight × (36 / (37 - reps))
          _estimated1rm = weight * (36 / (37 - reps));
        } else {
          _estimated1rm = weight;
        }
      });
    } else {
      setState(() => _estimated1rm = null);
    }
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid rep count')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final repository = ref.read(workoutRepositoryProvider);
      final result = await repository.createStrengthRecord(
        userId: userId,
        exerciseId: widget.exerciseId,
        exerciseName: widget.exerciseName,
        weightKg: weight,
        reps: reps,
        rpe: _rpe,
        isPr: widget.current1rm == null || (_estimated1rm ?? 0) > widget.current1rm!,
      );

      if (result != null && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, result);
      } else {
        throw Exception('Failed to save strength record');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final isPR = widget.current1rm != null &&
                 _estimated1rm != null &&
                 _estimated1rm! > widget.current1rm!;

    return GlassSheet(
          padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log 1RM',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                      Text(
                        widget.exerciseName,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current 1RM (if exists)
            if (widget.current1rm != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current 1RM: ',
                      style: TextStyle(color: textSecondary),
                    ),
                    Text(
                      '${widget.current1rm!.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.current1rm != null) const SizedBox(height: 16),

            // Input mode toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Direct Max',
                      _isDirectMax,
                      () {
                        setState(() {
                          _isDirectMax = true;
                          _repsController.text = '1';
                        });
                      },
                      textPrimary,
                      textMuted,
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      'Estimate from Set',
                      !_isDirectMax,
                      () {
                        setState(() {
                          _isDirectMax = false;
                          _repsController.text = '5';
                        });
                      },
                      textPrimary,
                      textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Weight input
            Text(
              'Weight (kg)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: textMuted),
                suffixText: 'kg',
                suffixStyle: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
                filled: true,
                fillColor: cardBackground,
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

            // Reps input (only for estimate mode)
            if (!_isDirectMax) ...[
              Text(
                'Reps Completed',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '1',
                  hintStyle: TextStyle(color: textMuted),
                  suffixText: 'reps',
                  suffixStyle: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                  filled: true,
                  fillColor: cardBackground,
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

            // RPE slider
            Text(
              'RPE (Rate of Perceived Exertion)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RPE ${_rpe.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getRpeColor(_rpe),
                        ),
                      ),
                      Text(
                        _getRpeDescription(_rpe),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _rpe,
                    min: 6.0,
                    max: 10.0,
                    divisions: 8,
                    activeColor: _getRpeColor(_rpe),
                    onChanged: (value) {
                      setState(() => _rpe = value);
                      HapticFeedback.selectionClick();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('6', style: TextStyle(color: textMuted, fontSize: 12)),
                      Text('10', style: TextStyle(color: textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Estimated 1RM display
            if (_estimated1rm != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPR
                        ? [AppColors.orange.withOpacity(0.2), AppColors.orange.withOpacity(0.1)]
                        : [AppColors.cyan.withOpacity(0.2), AppColors.cyan.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPR
                        ? AppColors.orange.withOpacity(0.5)
                        : AppColors.cyan.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPR ? Icons.local_fire_department : Icons.calculate,
                      color: isPR ? AppColors.orange : AppColors.cyan,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPR ? 'NEW PR!' : 'Estimated 1RM',
                            style: TextStyle(
                              color: isPR ? AppColors.orange : AppColors.cyan,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_estimated1rm!.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color: isPR ? AppColors.orange : AppColors.cyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPR)
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.orange,
                        size: 32,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save 1RM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Helper text
            Center(
              child: Text(
                _isDirectMax
                    ? 'Enter the max weight you lifted for 1 rep'
                    : 'Enter a set and we\'ll calculate your estimated 1RM',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
    Color textPrimary,
    Color textMuted,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Color _getRpeColor(double rpe) {
    if (rpe >= 9.5) return Colors.red;
    if (rpe >= 9) return AppColors.orange;
    if (rpe >= 8) return Colors.amber;
    if (rpe >= 7) return AppColors.cyan;
    return AppColors.success;
  }

  String _getRpeDescription(double rpe) {
    if (rpe >= 10) return 'Maximum effort';
    if (rpe >= 9.5) return 'Could not do more';
    if (rpe >= 9) return 'Maybe 1 more rep';
    if (rpe >= 8.5) return '1 rep in reserve';
    if (rpe >= 8) return '2 reps in reserve';
    if (rpe >= 7.5) return '2-3 reps in reserve';
    if (rpe >= 7) return '3 reps in reserve';
    if (rpe >= 6.5) return '3-4 reps in reserve';
    return '4+ reps in reserve';
  }
}
