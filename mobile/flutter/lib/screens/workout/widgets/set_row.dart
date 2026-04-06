import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/glow_button.dart';
import '../../../widgets/number_stepper.dart';


part 'set_row_part_weight_increments.dart';
part 'set_row_part_rpe_rir_selector_state.dart';
part 'set_row_part_increment_button.dart';


/// A row widget for tracking individual sets during workout
class SetRow extends StatefulWidget {
  final ActiveSetData setData;
  final bool isCurrentSet;
  final ValueChanged<ActiveSetData> onDataChanged;
  final VoidCallback onComplete;
  final VoidCallback? onDelete;
  final bool showPrevious;

  const SetRow({
    super.key,
    required this.setData,
    required this.isCurrentSet,
    required this.onDataChanged,
    required this.onComplete,
    this.onDelete,
    this.showPrevious = true,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late FocusNode _weightFocus;
  late FocusNode _repsFocus;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.setData.actualWeight.toStringAsFixed(1),
    );
    _repsController = TextEditingController(
      text: widget.setData.actualReps.toString(),
    );
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if data changed externally
    if (oldWidget.setData.actualWeight != widget.setData.actualWeight) {
      _weightController.text = widget.setData.actualWeight.toStringAsFixed(1);
    }
    if (oldWidget.setData.actualReps != widget.setData.actualReps) {
      _repsController.text = widget.setData.actualReps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  void _updateWeight(String value) {
    final weight = double.tryParse(value) ?? widget.setData.actualWeight;
    widget.onDataChanged(widget.setData.copyWith(actualWeight: weight));
  }

  void _updateReps(String value) {
    final reps = int.tryParse(value) ?? widget.setData.actualReps;
    widget.onDataChanged(widget.setData.copyWith(actualReps: reps));
  }

  void _incrementWeight() {
    // Use equipment-aware increment (e.g., 2.5kg for dumbbells, 5kg for machines)
    final increment = widget.setData.weightIncrement;
    final newWeight = widget.setData.actualWeight + increment;
    _weightController.text = newWeight.toStringAsFixed(1);
    widget.onDataChanged(widget.setData.copyWith(actualWeight: newWeight));
  }

  void _decrementWeight() {
    // Use equipment-aware increment (e.g., 2.5kg for dumbbells, 5kg for machines)
    final increment = widget.setData.weightIncrement;
    final newWeight = (widget.setData.actualWeight - increment).clamp(0.0, 999.0);
    _weightController.text = newWeight.toStringAsFixed(1);
    widget.onDataChanged(widget.setData.copyWith(actualWeight: newWeight.toDouble()));
  }

  void _incrementReps() {
    final newReps = widget.setData.actualReps + 1;
    _repsController.text = newReps.toString();
    widget.onDataChanged(widget.setData.copyWith(actualReps: newReps));
  }

  void _decrementReps() {
    final newReps = (widget.setData.actualReps - 1).clamp(0, 999);
    _repsController.text = newReps.toString();
    widget.onDataChanged(widget.setData.copyWith(actualReps: newReps));
  }

  void _cycleSetType() {
    final types = ['working', 'warmup', 'failure'];
    final currentIndex = types.indexOf(widget.setData.setType);
    final nextType = types[(currentIndex + 1) % types.length];
    widget.onDataChanged(widget.setData.copyWith(setType: nextType));
    HapticFeedback.lightImpact();
  }

  Color get _setTypeColor {
    switch (widget.setData.setType) {
      case 'warmup':
        return AppColors.orange;
      case 'failure':
        return AppColors.error;
      default:
        return AppColors.cyan;
    }
  }

  String get _setTypeLabel {
    switch (widget.setData.setType) {
      case 'warmup':
        return 'W';
      case 'failure':
        return 'F';
      default:
        return widget.setData.setNumber.toString();
    }
  }

  /// Build the 1RM target label showing target weight and percentage
  Widget _buildOneRMTargetLabel() {
    final oneRM = widget.setData.oneRepMax!;
    final targetPercent = widget.setData.intensityPercent!;
    final actualPercent = widget.setData.actualPercentOfMax ?? 0;
    final isOnTarget = widget.setData.isOnTarget;

    // Determine color based on how close to target
    Color percentColor;
    if (isOnTarget) {
      percentColor = AppColors.success;
    } else if (actualPercent > targetPercent) {
      percentColor = AppColors.orange; // Going heavier than target
    } else {
      percentColor = AppColors.cyan; // Going lighter than target
    }

    return Row(
      children: [
        // Target info
        Text(
          'Target: $targetPercent%',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        // Actual percentage (dynamic)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: percentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '→ $actualPercent%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: percentColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // 1RM reference
        Text(
          '(1RM: ${oneRM.toStringAsFixed(0)})',
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.setData.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isCurrentSet && !isCompleted
            ? AppColors.cyan.withOpacity(0.1)
            : isCompleted
                ? AppColors.success.withOpacity(0.1)
                : AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isCurrentSet && !isCompleted
              ? AppColors.cyan
              : isCompleted
                  ? AppColors.success
                  : AppColors.cardBorder,
          width: widget.isCurrentSet ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Set number/type badge
          GestureDetector(
            onTap: isCompleted ? null : _cycleSetType,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : _setTypeColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.success : _setTypeColor,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text(
                        _setTypeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _setTypeColor,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Weight input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show 1RM percentage target if available
                if (widget.setData.oneRepMax != null &&
                    widget.setData.intensityPercent != null)
                  _buildOneRMTargetLabel()
                else if (widget.showPrevious && widget.setData.previousWeight != null)
                  Text(
                    'Prev: ${widget.setData.previousWeight?.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                Row(
                  children: [
                    _IncrementButton(
                      icon: Icons.remove,
                      onPressed: isCompleted ? null : _decrementWeight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        focusNode: _weightFocus,
                        enabled: !isCompleted,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          suffix: const Text(
                            'kg',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.elevated,
                        ),
                        onChanged: _updateWeight,
                        onSubmitted: (_) => _repsFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _IncrementButton(
                      icon: Icons.add,
                      onPressed: isCompleted ? null : _incrementWeight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Reps input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showPrevious && widget.setData.previousReps != null)
                  Text(
                    'Prev: ${widget.setData.previousReps} reps',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                Row(
                  children: [
                    _IncrementButton(
                      icon: Icons.remove,
                      onPressed: isCompleted ? null : _decrementReps,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _repsController,
                        focusNode: _repsFocus,
                        enabled: !isCompleted,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          suffix: const Text(
                            'reps',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.elevated,
                        ),
                        onChanged: _updateReps,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _IncrementButton(
                      icon: Icons.add,
                      onPressed: isCompleted ? null : _incrementReps,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Complete button
          if (!isCompleted)
            IconButton(
              onPressed: widget.onComplete,
              icon: const Icon(Icons.check_circle_outline),
              color: AppColors.success,
              iconSize: 28,
            )
          else
            const SizedBox(
              width: 44,
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}
