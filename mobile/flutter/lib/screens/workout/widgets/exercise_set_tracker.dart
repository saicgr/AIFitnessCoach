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

  SetData({
    required this.setNumber,
    this.weight = 0,
    this.reps = 10,
    this.isWarmup = false,
    this.isCompleted = false,
    this.completedAt,
  });

  SetData copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    bool? isWarmup,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return SetData(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isWarmup: isWarmup ?? this.isWarmup,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
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
  bool _isExpanded = true;
  bool _showNotes = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatPrevious(PreviousSetData? prev) {
    if (prev == null) return '-';
    final unit = widget.useKg ? 'kg' : 'lbs';
    final weight = widget.useKg ? prev.weight : prev.weight * 2.20462;
    return '${weight.toStringAsFixed(0)}$unit x ${prev.reps}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
                if (widget.exercise.targetMuscles != null &&
                    widget.exercise.targetMuscles!.isNotEmpty)
                  Text(
                    widget.exercise.targetMuscles!.join(', '),
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.elevated.withAlpha(100),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40, child: Text('SET', style: _headerStyle)),
          const Expanded(flex: 2, child: Text('PREVIOUS', style: _headerStyle)),
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
                    widget.useKg ? 'KG' : 'LBS',
                    style: _headerStyle,
                  ),
                ],
              ),
            ),
          ),
          const Expanded(flex: 2, child: Text('REPS', style: _headerStyle)),
          const SizedBox(width: 48), // Checkmark column
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  Widget _buildSetRow(int index, SetData set) {
    final prev = widget.previousSets != null && index < widget.previousSets!.length
        ? widget.previousSets![index]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: set.isCompleted ? AppColors.cyan.withAlpha(20) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder.withAlpha(50)),
        ),
      ),
      child: Row(
        children: [
          // Set number (W for warmup, or 1, 2, 3...)
          SizedBox(
            width: 40,
            child: Text(
              set.isWarmup ? 'W' : '${set.setNumber}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: set.isWarmup ? AppColors.orange : AppColors.textPrimary,
              ),
            ),
          ),

          // Previous session
          Expanded(
            flex: 2,
            child: Text(
              _formatPrevious(prev),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted.withAlpha(180),
              ),
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
            width: 48,
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
