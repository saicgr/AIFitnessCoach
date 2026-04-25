import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/default_weights.dart';
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

  /// Optional callback fired when the user edits the rest seconds for this
  /// exercise. If provided, the rest-timer label becomes tappable and
  /// opens a quick-edit sheet. The new value is also persisted (per
  /// muscle-group default) in SharedPreferences via the static helper
  /// [restDefaultPrefsKey].
  final ValueChanged<int>? onRestSecondsChanged;

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
    this.onRestSecondsChanged,
  });

  /// SharedPreferences key for the user's preferred rest seconds, scoped
  /// by muscle group. Reads back via [defaultRestForMuscle] so a user who
  /// always rests 120s on legs but 60s on cardio gets remembered.
  static String restDefaultPrefsKey(String? muscleGroup) =>
      'rest_default_${(muscleGroup ?? 'general').toLowerCase().replaceAll(RegExp(r"[^a-z0-9]"), "_")}';

  /// Read the user's persisted preferred rest seconds for a muscle group,
  /// falling back to the exercise's own restSeconds, then to a sensible
  /// per-muscle default. Never returns null — callers can rely on it.
  static Future<int> defaultRestForMuscle(
    String? muscleGroup, {
    int? exerciseRestSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(restDefaultPrefsKey(muscleGroup));
    if (stored != null && stored > 0) return stored;
    if (exerciseRestSeconds != null && exerciseRestSeconds > 0) {
      return exerciseRestSeconds;
    }
    final m = (muscleGroup ?? '').toLowerCase();
    if (m.contains('cardio')) return 30;
    if (m.contains('mobility') || m.contains('stretch')) return 15;
    if (m.contains('legs') || m.contains('back') || m.contains('compound')) return 120;
    return 90; // strength / chest / shoulders / arms default
  }

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

  /// Per-exercise rest-target chip. Live countdown is owned by the
  /// workout-level RestTimerOverlay; this label is the *configured* target
  /// so the user knows what to expect and can tweak it without leaving
  /// the set tracker. Tap-to-edit when [onRestSecondsChanged] is wired.
  Widget _buildRestTimer() {
    final seconds = widget.exercise.restSeconds ?? 90;
    final tappable = widget.onRestSecondsChanged != null;
    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: AppColors.cyan.withAlpha(180)),
          const SizedBox(width: 6),
          Text(
            'Rest target: ${_formatRestSeconds(seconds)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.cyan.withAlpha(180),
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 13, color: AppColors.cyan.withAlpha(140)),
          ],
        ],
      ),
    );
    if (!tappable) return label;
    return InkWell(
      onTap: () => _openRestEditor(seconds),
      borderRadius: BorderRadius.circular(8),
      child: label,
    );
  }

  String _formatRestSeconds(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final r = s % 60;
    return r == 0 ? '${m}min' : '${m}m ${r}s';
  }

  Future<void> _openRestEditor(int currentSeconds) async {
    HapticFeedback.selectionClick();
    final muscle = widget.exercise.muscleGroup;
    int draft = currentSeconds;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void bump(int delta) {
              setSheetState(() {
                draft = (draft + delta).clamp(15, 600);
              });
              HapticFeedback.lightImpact();
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rest target',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (muscle != null && muscle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Saved as your default for $muscle',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted.withAlpha(200),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RestStepButton(label: '−15s', onTap: () => bump(-15)),
                      Text(
                        _formatRestSeconds(draft),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cyan,
                        ),
                      ),
                      _RestStepButton(label: '+15s', onTap: () => bump(15)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: const [30, 60, 90, 120, 180]
                        .map((preset) => _RestPresetChip(
                              seconds: preset,
                              isSelected: draft == preset,
                              onTap: () => setSheetState(() => draft = preset),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(draft),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked == null || picked == currentSeconds) return;

    // Persist as the user's default for this muscle group, then notify
    // the parent so it can update the in-memory exercise too.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        ExerciseSetTracker.restDefaultPrefsKey(muscle),
        picked,
      );
    } catch (e) {
      debugPrint('Failed to persist rest default: $e');
    }
    widget.onRestSecondsChanged?.call(picked);
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
    final weight = widget.useKg
        ? weightKg
        : kgToDisplayLbs(weightKg, widget.exercise.equipment,
                exerciseName: widget.exercise.name,);
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

/// Pill button for ±15s rest adjustments inside the rest-target editor.
class _RestStepButton extends StatelessWidget {
  const _RestStepButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cyan.withAlpha(40),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cyan.withAlpha(120)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.cyan,
          ),
        ),
      ),
    );
  }
}

/// Quick-pick chip for common rest values inside the editor.
class _RestPresetChip extends StatelessWidget {
  const _RestPresetChip({
    required this.seconds,
    required this.isSelected,
    required this.onTap,
  });
  final int seconds;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withAlpha(60)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : AppColors.cardBorder,
          ),
        ),
        child: Text(
          seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}min',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.cyan : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
