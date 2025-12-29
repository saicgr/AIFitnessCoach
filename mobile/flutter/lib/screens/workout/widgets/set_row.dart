import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Equipment-specific weight increments (in kg)
/// Industry standard increments for realistic gym equipment
class WeightIncrements {
  static const double dumbbell = 2.5;    // 5 lb - standard dumbbell jumps
  static const double barbell = 2.5;     // 5 lb - smallest common plates
  static const double machine = 5.0;     // 10 lb - pin-select increments
  static const double kettlebell = 4.0;  // 8 lb - standard KB progression
  static const double cable = 2.5;       // 5 lb - cable stack increments
  static const double bodyweight = 0;    // no external weight

  /// Get the appropriate weight increment based on equipment type
  static double getIncrement(String? equipmentType) {
    if (equipmentType == null) return dumbbell; // Default to dumbbell (most conservative)

    final eq = equipmentType.toLowerCase();

    if (eq.contains('dumbbell') || eq.contains('db')) return dumbbell;
    if (eq.contains('barbell') || eq.contains('bb')) return barbell;
    if (eq.contains('kettlebell') || eq.contains('kb')) return kettlebell;
    if (eq.contains('machine') || eq.contains('press machine')) return machine;
    if (eq.contains('cable')) return cable;
    if (eq.contains('bodyweight') || eq.contains('body weight')) return bodyweight;

    return dumbbell; // Default fallback
  }
}

/// Represents a single set's data during an active workout
class ActiveSetData {
  final int setNumber;
  final String setType; // 'warmup', 'working', 'failure'
  double targetWeight;
  int targetReps;
  double actualWeight;
  int actualReps;
  int? rpe; // Rate of Perceived Exertion (1-10)
  int? rir; // Reps in Reserve (0-5)
  bool isCompleted;
  double? previousWeight;
  int? previousReps;
  DateTime? completedAt;
  int? durationSeconds;
  String? equipmentType; // Equipment type for weight increment calculations

  ActiveSetData({
    required this.setNumber,
    this.setType = 'working',
    required this.targetWeight,
    required this.targetReps,
    double? actualWeight,
    int? actualReps,
    this.rpe,
    this.rir,
    this.isCompleted = false,
    this.previousWeight,
    this.previousReps,
    this.completedAt,
    this.durationSeconds,
    this.equipmentType,
  })  : actualWeight = actualWeight ?? targetWeight,
        actualReps = actualReps ?? targetReps;

  /// Get the weight increment for this set based on equipment type
  double get weightIncrement => WeightIncrements.getIncrement(equipmentType);

  ActiveSetData copyWith({
    int? setNumber,
    String? setType,
    double? targetWeight,
    int? targetReps,
    double? actualWeight,
    int? actualReps,
    int? rpe,
    int? rir,
    bool? isCompleted,
    double? previousWeight,
    int? previousReps,
    DateTime? completedAt,
    int? durationSeconds,
    String? equipmentType,
  }) {
    return ActiveSetData(
      setNumber: setNumber ?? this.setNumber,
      setType: setType ?? this.setType,
      targetWeight: targetWeight ?? this.targetWeight,
      targetReps: targetReps ?? this.targetReps,
      actualWeight: actualWeight ?? this.actualWeight,
      actualReps: actualReps ?? this.actualReps,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      isCompleted: isCompleted ?? this.isCompleted,
      previousWeight: previousWeight ?? this.previousWeight,
      previousReps: previousReps ?? this.previousReps,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      equipmentType: equipmentType ?? this.equipmentType,
    );
  }
}

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
                if (widget.showPrevious && widget.setData.previousWeight != null)
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

class _IncrementButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _IncrementButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressed?.call();
        HapticFeedback.selectionClick();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppColors.textSecondary : AppColors.textMuted,
        ),
      ),
    );
  }
}

/// RPE/RIR selector modal
class RpeRirSelector extends StatelessWidget {
  final int? currentRpe;
  final int? currentRir;
  final ValueChanged<int?> onRpeChanged;
  final ValueChanged<int?> onRirChanged;

  const RpeRirSelector({
    super.key,
    this.currentRpe,
    this.currentRir,
    required this.onRpeChanged,
    required this.onRirChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How hard was this set?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // RPE selector
          const Text(
            'RPE (Rate of Perceived Exertion)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(5, (index) {
              final rpe = 6 + index; // RPE 6-10
              final isSelected = currentRpe == rpe;
              return ChoiceChip(
                label: Text(rpe.toString()),
                selected: isSelected,
                onSelected: (selected) => onRpeChanged(selected ? rpe : null),
                selectedColor: AppColors.cyan,
                backgroundColor: AppColors.glassSurface,
              );
            }),
          ),
          const SizedBox(height: 16),

          // RIR selector
          const Text(
            'RIR (Reps in Reserve)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(6, (index) {
              final rir = index; // RIR 0-5
              final isSelected = currentRir == rir;
              return ChoiceChip(
                label: Text(rir.toString()),
                selected: isSelected,
                onSelected: (selected) => onRirChanged(selected ? rir : null),
                selectedColor: AppColors.purple,
                backgroundColor: AppColors.glassSurface,
              );
            }),
          ),
        ],
      ),
    );
  }
}
