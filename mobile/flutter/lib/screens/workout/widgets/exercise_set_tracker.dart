import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Represents a single set's data (current session)
class SetData {
  int setNumber;
  double weight;
  int reps;
  bool isWarmup;
  bool isCompleted;
  DateTime? completedAt;
  String setType; // 'working', 'warmup', 'failure', 'drop', 'amrap'
  SetTarget? target; // AI-generated target for this set

  SetData({
    required this.setNumber,
    this.weight = 0,
    this.reps = 10,
    this.isWarmup = false,
    this.isCompleted = false,
    this.completedAt,
    this.setType = 'working',
    this.target,
  });

  /// Get display label for set type (F for failure, D for drop, W for warmup)
  String get setTypeLabel {
    if (isWarmup || setType == 'warmup') return 'W';
    if (setType == 'failure' || setType == 'amrap') return 'F';
    if (setType == 'drop') return 'D';
    return ''; // Working sets show number
  }

  /// Whether this is a failure/AMRAP set
  bool get isFailureSet => setType == 'failure' || setType == 'amrap';

  /// Whether this is a drop set
  bool get isDropSet => setType == 'drop';

  SetData copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    bool? isWarmup,
    bool? isCompleted,
    DateTime? completedAt,
    String? setType,
    SetTarget? target,
  }) {
    return SetData(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isWarmup: isWarmup ?? this.isWarmup,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      setType: setType ?? this.setType,
      target: target ?? this.target,
    );
  }
}

/// Represents previous session data for an exercise
class PreviousSetData {
  final int setNumber;
  final double weight;
  final int reps;
  final bool isWarmup;

  const PreviousSetData({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isWarmup = false,
  });
}

/// Exercise card with set-by-set tracking like Strong app
class ExerciseSetTracker extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final List<SetData> sets;
  final List<PreviousSetData>? previousSets;
  final bool useKg;
  final String? imageUrl;
  final VoidCallback? onToggleUnit;
  final Function(int setIndex, SetData updatedSet) onSetUpdated;
  final Function(int setIndex) onSetCompleted;
  final VoidCallback onAddSet;
  final VoidCallback? onShowNotes;
  final VoidCallback? onShowOptions;

  const ExerciseSetTracker({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.sets,
    this.previousSets,
    required this.useKg,
    this.imageUrl,
    this.onToggleUnit,
    required this.onSetUpdated,
    required this.onSetCompleted,
    required this.onAddSet,
    this.onShowNotes,
    this.onShowOptions,
  });

  @override
  State<ExerciseSetTracker> createState() => _ExerciseSetTrackerState();
}

class _ExerciseSetTrackerState extends State<ExerciseSetTracker> {
  final bool _isExpanded = true;
  final bool _showNotes = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          _buildHeader(),

          // Exercise description/tip
          if (widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.exercise.notes!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withAlpha(200),
                ),
              ),
            ),

          // Notes input
          if (_showNotes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _notesController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add notes here...',
                  hintStyle: TextStyle(color: AppColors.textMuted.withAlpha(150)),
                  filled: true,
                  fillColor: AppColors.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),

          // Rest timer display (if applicable)
          _buildRestTimer(),

          const SizedBox(height: 8),

          // Set table header
          _buildTableHeader(),

          // Sets list
          if (_isExpanded) ...[
            ...widget.sets.asMap().entries.map((entry) => _buildSetRow(entry.key, entry.value)),

            // Add Set button
            _buildAddSetButton(),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Exercise image/icon
          if (widget.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
              ),
            )
          else
            _buildPlaceholderIcon(),

          const SizedBox(width: 12),

          // Exercise name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
                if (widget.exercise.muscleGroup != null &&
                    widget.exercise.muscleGroup!.isNotEmpty)
                  Text(
                    widget.exercise.muscleGroup!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted.withAlpha(180),
                    ),
                  ),
              ],
            ),
          ),

          // Options menu
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: widget.onShowOptions ?? () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fitness_center, color: AppColors.cyan, size: 24),
    );
  }

  Widget _buildRestTimer() {
    // TODO: Add actual rest timer logic
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: AppColors.cyan.withAlpha(180)),
          const SizedBox(width: 4),
          Text(
            'Rest Timer: ${widget.exercise.restSeconds ?? 90}s',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.cyan.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if exercise uses a barbell (for weight note display)
  bool _isBarbellExercise() {
    final equipment = widget.exercise.equipment?.toLowerCase() ?? '';
    final name = widget.exercise.name.toLowerCase();
    return equipment.contains('barbell') ||
           name.contains('barbell') ||
           name.contains(' bb ') ||
           name.startsWith('bb ');
  }

  Widget _buildTableHeader() {
    final isBarbell = _isBarbellExercise();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.elevated.withAlpha(100),
          ),
          child: Row(
            children: [
              const SizedBox(width: 36, child: Text('Set', style: _headerStyle)),
              // Target column - increased flex for "30 kg x 10" + RIR chip
              const Expanded(flex: 5, child: Text('Target', style: _headerStyle)),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: widget.onToggleUnit,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Text(
                        widget.useKg ? 'kg' : 'lbs',
                        style: _headerStyle,
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(flex: 2, child: Text('Reps', style: _headerStyle)),
              const SizedBox(width: 44), // Checkmark column
            ],
          ),
        ),
        // Barbell weight note - shown only for barbell exercises
        if (isBarbell)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: AppColors.textMuted.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Weight includes ${widget.useKg ? '20kg' : '45lb'} barbell',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  /// Format target display like Gravl: "25 lb x 9-11" with "1 RIR" below
  String _formatTarget(SetData set) {
    final target = set.target;
    if (target == null) {
      // Fall back to exercise-level defaults
      final targetReps = widget.exercise.reps ?? 10;
      return '$targetReps reps';
    }

    final unit = widget.useKg ? 'kg' : 'lb';
    final weightKg = target.targetWeightKg ?? 0;
    final weight = widget.useKg ? weightKg : weightKg * 2.20462;
    final weightStr = weight > 0 ? '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)} $unit' : '';
    final reps = target.targetReps;

    if (weightStr.isNotEmpty) {
      return '$weightStr x $reps';
    }
    return '$reps reps';
  }

  /// Get RIR display string (e.g., "1 RIR", "0 RIR")
  String _formatRir(SetData set) {
    final target = set.target;
    if (target == null) return '';

    final rir = target.targetRir;
    if (rir == null) return '';

    return '$rir RIR';
  }

  /// Get color for set type indicator
  Color _getSetTypeColor(SetData set) {
    if (set.isWarmup || set.setType == 'warmup') return AppColors.orange;
    if (set.isFailureSet) return Colors.red;
    if (set.isDropSet) return Colors.purple;
    return AppColors.textPrimary;
  }

  /// Get RIR chip color based on intensity
  Color _getRirColor(int rir) {
    if (rir >= 3) return AppColors.success; // Easy - green
    if (rir == 2) return AppColors.yellow; // Moderate - yellow/gold
    if (rir == 1) return AppColors.orange; // Hard - orange
    return Colors.red; // RIR 0 = failure - red
  }

  /// Build compact RIR chip
  Widget _buildRirChip(SetData set) {
    final rir = set.target?.targetRir;
    if (rir == null) return const SizedBox.shrink();

    final color = _getRirColor(rir);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100), width: 0.5),
      ),
      child: Text(
        '$rir',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSetRow(int index, SetData set) {
    // Get set type label (W, F, D, or set number)
    final setLabel = set.setTypeLabel.isNotEmpty ? set.setTypeLabel : '${set.setNumber}';
    final setColor = _getSetTypeColor(set);
    final rirText = _formatRir(set);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: set.isCompleted ? AppColors.cyan.withAlpha(20) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder.withAlpha(50)),
        ),
      ),
      child: Row(
        children: [
          // Set number/type (W for warmup, F for failure, D for drop, or 1, 2, 3...)
          SizedBox(
            width: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: setColor.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                setLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: setColor,
                ),
              ),
            ),
          ),

          // Target with RIR (like Gravl's "Auto" column)
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Target text (e.g., "30 kg x 10")
                Flexible(
                  child: Text(
                    _formatTarget(set),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
                // RIR chip (e.g., "RIR 2")
                if (rirText.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildRirChip(set),
                ],
              ],
            ),
          ),

          // Weight input
          Expanded(
            flex: 2,
            child: _EditableCell(
              value: set.weight.toStringAsFixed(0),
              isCompleted: set.isCompleted,
              onChanged: (val) {
                final weight = double.tryParse(val) ?? 0;
                widget.onSetUpdated(index, set.copyWith(weight: weight));
              },
            ),
          ),

          // Reps input
          Expanded(
            flex: 2,
            child: _EditableCell(
              value: set.reps.toString(),
              isCompleted: set.isCompleted,
              hint: '${widget.exercise.reps ?? 10}',
              onChanged: (val) {
                final reps = int.tryParse(val) ?? 10;
                widget.onSetUpdated(index, set.copyWith(reps: reps));
              },
            ),
          ),

          // Complete checkbox
          SizedBox(
            width: 44,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onSetCompleted(index);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: set.isCompleted ? AppColors.cyan : AppColors.elevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: set.isCompleted ? AppColors.cyan : AppColors.cardBorder,
                    width: 2,
                  ),
                ),
                child: set.isCompleted
                    ? const Icon(Icons.check, color: Colors.black, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSetButton() {
    return GestureDetector(
      onTap: widget.onAddSet,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.textSecondary, size: 18),
            SizedBox(width: 6),
            Text(
              'Add Set',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editable cell for weight/reps input
class _EditableCell extends StatefulWidget {
  final String value;
  final bool isCompleted;
  final String? hint;
  final Function(String) onChanged;

  const _EditableCell({
    required this.value,
    required this.isCompleted,
    this.hint,
    required this.onChanged,
  });

  @override
  State<_EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isEditing = true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: widget.isCompleted ? Colors.transparent : AppColors.elevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: _isEditing
            ? TextField(
                controller: _controller,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isCompleted ? AppColors.cyan : AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (val) {
                  widget.onChanged(val);
                  setState(() => _isEditing = false);
                },
                onTapOutside: (_) {
                  widget.onChanged(_controller.text);
                  setState(() => _isEditing = false);
                },
              )
            : Text(
                widget.value.isEmpty ? (widget.hint ?? '-') : widget.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isCompleted ? AppColors.cyan : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}
