import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/weight_suggestion_service.dart';

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

/// Enhanced RPE/RIR selector modal with clear explanations for users
class RpeRirSelector extends StatefulWidget {
  final int? currentRpe;
  final int? currentRir;
  final ValueChanged<int?> onRpeChanged;
  final ValueChanged<int?> onRirChanged;
  final VoidCallback? onDone;

  const RpeRirSelector({
    super.key,
    this.currentRpe,
    this.currentRir,
    required this.onRpeChanged,
    required this.onRirChanged,
    this.onDone,
  });

  @override
  State<RpeRirSelector> createState() => _RpeRirSelectorState();
}

class _RpeRirSelectorState extends State<RpeRirSelector> {
  bool _showRpeHelp = false;
  bool _showRirHelp = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.pureBlack : AppColorsLight.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.purple, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How hard was that set?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'This helps us adjust your next set',
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // RPE Section
          _buildSectionHeader(
            title: 'RPE',
            subtitle: 'Rate of Perceived Exertion',
            showHelp: _showRpeHelp,
            onHelpTap: () => setState(() => _showRpeHelp = !_showRpeHelp),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          if (_showRpeHelp) _buildRpeHelpCard(cardBg, textColor, mutedColor),
          const SizedBox(height: 12),
          _buildRpeOptions(textColor, mutedColor, cardBg),

          const SizedBox(height: 24),

          // RIR Section
          _buildSectionHeader(
            title: 'RIR',
            subtitle: 'Reps in Reserve',
            showHelp: _showRirHelp,
            onHelpTap: () => setState(() => _showRirHelp = !_showRirHelp),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          if (_showRirHelp) _buildRirHelpCard(cardBg, textColor, mutedColor),
          const SizedBox(height: 12),
          _buildRirOptions(textColor, mutedColor, cardBg),

          const SizedBox(height: 24),

          // Done button
          if (widget.onDone != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool showHelp,
    required VoidCallback onHelpTap,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: mutedColor,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onHelpTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showHelp ? Icons.expand_less : Icons.help_outline,
                  size: 16,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 4),
                Text(
                  showHelp ? 'Hide' : 'What\'s this?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRpeHelpCard(Color cardBg, Color textColor, Color mutedColor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RPE measures how hard a set felt on a scale of 6-10:',
            style: TextStyle(fontSize: 13, color: textColor),
          ),
          const SizedBox(height: 12),
          ...RpeLevel.values.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(level.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (level.color as Color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${level.value}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: level.color as Color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            level.description,
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRirHelpCard(Color cardBg, Color textColor, Color mutedColor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIR = How many more reps could you have done?',
            style: TextStyle(fontSize: 13, color: textColor),
          ),
          const SizedBox(height: 12),
          ...RirLevel.values.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(level.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${level.value}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            level.description,
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRpeOptions(Color textColor, Color mutedColor, Color cardBg) {
    return Column(
      children: RpeLevel.values.map((level) {
        final isSelected = widget.currentRpe == level.value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onRpeChanged(isSelected ? null : level.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (level.color as Color).withValues(alpha: 0.15)
                  : cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? level.color as Color
                    : mutedColor.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(level.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (level.color as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${level.value}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: level.color as Color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        level.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: level.color as Color,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRirOptions(Color textColor, Color mutedColor, Color cardBg) {
    // Only show RIR 0-4 for simplicity (most common range)
    final rirLevels = RirLevel.values.take(5).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rirLevels.map((level) {
        final isSelected = widget.currentRir == level.value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onRirChanged(isSelected ? null : level.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.cyan.withValues(alpha: 0.15)
                  : cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.cyan
                    : mutedColor.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(level.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  '${level.value}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.cyan : textColor,
                  ),
                ),
                Text(
                  level.value == 0 ? 'Failure' : '${level.value} left',
                  style: TextStyle(
                    fontSize: 10,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
