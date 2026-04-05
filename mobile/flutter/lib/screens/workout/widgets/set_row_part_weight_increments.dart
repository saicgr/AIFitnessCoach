part of 'set_row.dart';



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
  double? oneRepMax; // User's 1RM for this exercise (if available)
  int? intensityPercent; // Target intensity as % of 1RM (e.g., 75)

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
    this.oneRepMax,
    this.intensityPercent,
  })  : actualWeight = actualWeight ?? targetWeight,
        actualReps = actualReps ?? targetReps;

  /// Get the weight increment for this set based on equipment type
  double get weightIncrement => WeightIncrements.getIncrement(equipmentType);

  /// Calculate actual percentage of 1RM for current weight
  int? get actualPercentOfMax {
    if (oneRepMax == null || oneRepMax! <= 0) return null;
    return ((actualWeight / oneRepMax!) * 100).round();
  }

  /// Check if user is hitting their target intensity
  bool get isOnTarget {
    if (intensityPercent == null || oneRepMax == null) return true;
    final actual = actualPercentOfMax ?? 0;
    return (actual - intensityPercent!).abs() <= 5; // Within 5% tolerance
  }

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
    double? oneRepMax,
    int? intensityPercent,
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
      oneRepMax: oneRepMax ?? this.oneRepMax,
      intensityPercent: intensityPercent ?? this.intensityPercent,
    );
  }
}


/// Futuristic Set Row with large touch targets and glowing accents
///
/// This is the redesigned version of SetRow with:
/// - 48px+ touch targets for gym-friendly use
/// - Long-press for rapid increment
/// - Glassmorphic design with glowing accents
/// - Collapsible previous data
/// - Full-width Complete Set button
class FuturisticSetRow extends StatefulWidget {
  final ActiveSetData setData;
  final bool isCurrentSet;
  final ValueChanged<ActiveSetData> onDataChanged;
  final VoidCallback onComplete;
  final VoidCallback? onDelete;
  final bool showPrevious;
  final bool useKg;

  const FuturisticSetRow({
    super.key,
    required this.setData,
    required this.isCurrentSet,
    required this.onDataChanged,
    required this.onComplete,
    this.onDelete,
    this.showPrevious = true,
    this.useKg = true,
  });

  @override
  State<FuturisticSetRow> createState() => _FuturisticSetRowState();
}


class _FuturisticSetRowState extends State<FuturisticSetRow> {
  bool _isPreviousExpanded = false;

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
        return AppColors.glowOrange;
      case 'failure':
        return AppColors.error;
      default:
        return AppColors.glowCyan;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = widget.setData.isCompleted;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // For completed sets, show compact view
    if (isCompleted) {
      return _buildCompletedRow(isDark, textColor, mutedColor);
    }

    // For non-current sets, show pending view
    if (!widget.isCurrentSet) {
      return _buildPendingRow(isDark, textColor, mutedColor);
    }

    // Current active set - full futuristic UI
    return _buildActiveRow(isDark, textColor, mutedColor);
  }

  /// Build the full active set row with large controls
  Widget _buildActiveRow(bool isDark, Color textColor, Color mutedColor) {
    final weightIncrement = widget.setData.weightIncrement;

    return GlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      glowColor: _setTypeColor,
      isActive: true,
      child: Column(
        children: [
          // Set badge and type indicator
          Row(
            children: [
              // Set number badge (tappable to cycle type)
              GestureDetector(
                onTap: _cycleSetType,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _setTypeColor.withOpacity(0.3),
                        _setTypeColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: _setTypeColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _setTypeColor.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _setTypeLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _setTypeColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SET ${widget.setData.setNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: _setTypeColor,
                  ),
                ),
              ),
              // 1RM percentage if available
              if (widget.setData.oneRepMax != null &&
                  widget.setData.intensityPercent != null)
                _buildIntensityBadge(),
            ],
          ),

          const SizedBox(height: 20),

          // Weight and Reps inputs - side by side with large steppers
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive spacing for smaller screens
              final isSmallScreen = constraints.maxWidth < 280;
              return Row(
                children: [
                  // Weight stepper
                  Expanded(
                    child: NumberStepper.weight(
                      value: widget.setData.actualWeight,
                      onChanged: (value) {
                        widget.onDataChanged(
                          widget.setData.copyWith(actualWeight: value),
                        );
                      },
                      step: weightIncrement,
                      useKg: widget.useKg,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 16),
                  // Reps stepper
                  Expanded(
                    child: NumberStepper.reps(
                      value: widget.setData.actualReps,
                      onChanged: (value) {
                        widget.onDataChanged(
                          widget.setData.copyWith(actualReps: value),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Complete Set button - full width, prominent
          GlowButton.complete(
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onComplete();
            },
            setNumber: widget.setData.setNumber,
            width: double.infinity,
          ),

          // Collapsible previous data
          if (widget.showPrevious &&
              (widget.setData.previousWeight != null ||
                  widget.setData.previousReps != null))
            _buildCollapsiblePrevious(mutedColor),
        ],
      ),
    );
  }

  /// Build the 1RM intensity badge
  Widget _buildIntensityBadge() {
    final targetPercent = widget.setData.intensityPercent!;
    final actualPercent = widget.setData.actualPercentOfMax ?? 0;
    final isOnTarget = widget.setData.isOnTarget;

    Color percentColor;
    if (isOnTarget) {
      percentColor = AppColors.glowGreen;
    } else if (actualPercent > targetPercent) {
      percentColor = AppColors.glowOrange;
    } else {
      percentColor = AppColors.glowCyan;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: percentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: percentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$actualPercent%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: percentColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isOnTarget
                ? Icons.check_circle
                : actualPercent > targetPercent
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
            size: 14,
            color: percentColor,
          ),
        ],
      ),
    );
  }

  /// Build collapsible previous data section
  Widget _buildCollapsiblePrevious(Color mutedColor) {
    final prevWeight = widget.setData.previousWeight;
    final prevReps = widget.setData.previousReps;

    return GestureDetector(
      onTap: () {
        setState(() => _isPreviousExpanded = !_isPreviousExpanded);
        HapticFeedback.selectionClick();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPreviousExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 16,
              color: mutedColor,
            ),
            const SizedBox(width: 4),
            Text(
              _isPreviousExpanded
                  ? 'Hide previous'
                  : 'Previous: ${prevWeight?.toStringAsFixed(1) ?? '-'} ${widget.useKg ? 'kg' : 'lbs'} × ${prevReps ?? '-'} reps',
              style: TextStyle(
                fontSize: 12,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build completed set row (compact)
  Widget _buildCompletedRow(bool isDark, Color textColor, Color mutedColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glowGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.glowGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Completed checkmark
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glowGreen.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glowGreen.withOpacity(0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 20,
              color: AppColors.glowGreen,
            ),
          ),
          const SizedBox(width: 12),
          // Set info
          Expanded(
            child: Text(
              'Set ${widget.setData.setNumber}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          // Weight
          Text(
            '${widget.setData.actualWeight.toStringAsFixed(1)} ${widget.useKg ? 'kg' : 'lbs'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.glowGreen,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '×',
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
          const SizedBox(width: 8),
          // Reps
          Text(
            '${widget.setData.actualReps} reps',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.glowGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Build pending set row (dimmed)
  Widget _buildPendingRow(bool isDark, Color textColor, Color mutedColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Pending circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: mutedColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                widget.setData.setNumber.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: mutedColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Set label
          Expanded(
            child: Text(
              'Set ${widget.setData.setNumber}',
              style: TextStyle(
                fontSize: 14,
                color: mutedColor.withOpacity(0.5),
              ),
            ),
          ),
          // Target values
          Text(
            '${widget.setData.targetWeight.toStringAsFixed(0)} ${widget.useKg ? 'kg' : 'lbs'} × ${widget.setData.targetReps}',
            style: TextStyle(
              fontSize: 13,
              color: mutedColor.withOpacity(0.4),
            ),
          ),
        ],
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

