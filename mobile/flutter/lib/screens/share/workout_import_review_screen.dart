/// WorkoutImportReviewScreen — editable surface for a Gemini-extracted
/// workout (from a YouTube / Instagram / TikTok / ChatGPT share).
///
/// Each exercise row shows name + sets/reps/rest with inline editors. The
/// user confirms, edits, removes — then taps Save, which POSTs to
/// `/share/import-workout`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/imports_api_service.dart';

class WorkoutImportReviewScreen extends ConsumerStatefulWidget {
  const WorkoutImportReviewScreen({
    super.key,
    required this.sharedItemId,
    required this.initialPayload,
  });

  /// The shared_items row id — gets stamped on the saved workout for
  /// audit / Imports history linkage.
  final String sharedItemId;

  /// The `extracted_payload` map straight from the SSE `done` event:
  ///   { title, estimated_duration_min, difficulty, equipment_needed[],
  ///     exercises: [...], notes }
  final Map<String, dynamic> initialPayload;

  @override
  ConsumerState<WorkoutImportReviewScreen> createState() =>
      _WorkoutImportReviewScreenState();
}

class _WorkoutImportReviewScreenState
    extends ConsumerState<WorkoutImportReviewScreen> {
  late TextEditingController _titleCtrl;
  late int? _durationMin;
  late String? _difficulty;
  late List<String> _equipment;
  late List<_EditableExercise> _exercises;
  String? _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPayload;
    _titleCtrl = TextEditingController(text: (p['title'] as String?) ?? 'Imported workout');
    _durationMin = (p['estimated_duration_min'] as num?)?.toInt();
    _difficulty = p['difficulty'] as String?;
    _equipment = ((p['equipment_needed'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    _notes = p['notes'] as String?;
    final rawEx = (p['exercises'] as List?) ?? const [];
    _exercises = [
      for (final r in rawEx.whereType<Map>())
        _EditableExercise.fromMap(r.cast<String, dynamic>()),
    ];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one exercise before saving.'),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(importsApiServiceProvider);
      final result = await api.importWorkout(
        sharedItemId: widget.sharedItemId,
        title: _titleCtrl.text.trim(),
        estimatedDurationMin: _durationMin,
        difficulty: _difficulty,
        equipmentNeeded: _equipment,
        notes: _notes,
        exercises: _exercises.map((e) => e.toMap()).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saved to your workouts.'),
      ));
      Navigator.of(context).pop(result);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Couldn't save — try again."),
        ));
      }
    }
  }

  void _addExercise() {
    setState(() => _exercises.add(_EditableExercise.blank()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review workout'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Workout name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DurationField(
                  valueMin: _durationMin,
                  onChanged: (v) => setState(() => _durationMin = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DifficultyField(
                  value: _difficulty,
                  onChanged: (v) => setState(() => _difficulty = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Exercises (${_exercises.length})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _exercises.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExerciseCard(
                index: i + 1,
                exercise: _exercises[i],
                onChanged: () => setState(() {}),
                onDelete: () => setState(() => _exercises.removeAt(i)),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add exercise'),
          ),
        ],
      ),
    );
  }
}

class _EditableExercise {
  _EditableExercise({
    required this.name,
    this.sets,
    this.reps,
    this.restS,
    this.weightHint,
    this.equipment = const [],
    this.notes,
    this.libraryId,
    this.sourceTimestampS,
  });

  String name;
  int? sets;
  String? reps;
  int? restS;
  String? weightHint;
  List<String> equipment;
  String? notes;
  String? libraryId;
  double? sourceTimestampS;

  factory _EditableExercise.blank() => _EditableExercise(name: '');

  factory _EditableExercise.fromMap(Map<String, dynamic> m) => _EditableExercise(
        name: (m['name'] as String?) ?? '',
        sets: (m['sets'] as num?)?.toInt(),
        reps: m['reps']?.toString(),
        restS: (m['rest_s'] as num?)?.toInt(),
        weightHint: m['weight_hint'] as String?,
        equipment: ((m['equipment'] as List?) ?? const []).map((e) => e.toString()).toList(),
        notes: m['notes'] as String?,
        libraryId: m['library_id'] as String?,
        sourceTimestampS: (m['source_timestamp_s'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        if (sets != null) 'sets': sets,
        if (reps != null && reps!.isNotEmpty) 'reps': reps,
        if (restS != null) 'rest_s': restS,
        if (weightHint != null && weightHint!.isNotEmpty) 'weight_hint': weightHint,
        if (equipment.isNotEmpty) 'equipment': equipment,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (libraryId != null) 'library_id': libraryId,
        if (sourceTimestampS != null) 'source_timestamp_s': sourceTimestampS,
      };
}

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    required this.index,
    required this.exercise,
    required this.onChanged,
    required this.onDelete,
  });
  final int index;
  final _EditableExercise exercise;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.exercise.name);
  late final TextEditingController _repsCtrl =
      TextEditingController(text: widget.exercise.reps ?? '');
  late final TextEditingController _weightCtrl =
      TextEditingController(text: widget.exercise.weightHint ?? '');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ex = widget.exercise;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${widget.index}', style: theme.textTheme.labelSmall),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Exercise name',
                  ),
                  style: theme.textTheme.titleSmall,
                  onChanged: (v) {
                    ex.name = v;
                    widget.onChanged();
                  },
                ),
              ),
              if (ex.libraryId != null)
                Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 70,
                child: _NumField(
                  label: 'Sets',
                  value: ex.sets,
                  onChanged: (v) {
                    ex.sets = v;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _repsCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Reps (e.g. 8-10 or 30 s)',
                  ),
                  onChanged: (v) {
                    ex.reps = v;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: _NumField(
                  label: 'Rest s',
                  value: ex.restS,
                  onChanged: (v) {
                    ex.restS = v;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextField(
              controller: _weightCtrl,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Weight hint (e.g. 185 lb)',
              ),
              onChanged: (v) {
                ex.weightHint = v;
                widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatefulWidget {
  const _NumField({required this.label, required this.value, required this.onChanged});
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value?.toString() ?? '');
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(isDense: true, labelText: widget.label),
      onChanged: (v) => widget.onChanged(int.tryParse(v.trim())),
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({required this.valueMin, required this.onChanged});
  final int? valueMin;
  final ValueChanged<int?> onChanged;
  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: valueMin?.toString() ?? ''),
      decoration: const InputDecoration(labelText: 'Duration (min)'),
      onChanged: (v) => onChanged(int.tryParse(v.trim())),
    );
  }
}

class _DifficultyField extends StatelessWidget {
  const _DifficultyField({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;
  static const _opts = ['beginner', 'intermediate', 'advanced'];
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _opts.contains(value) ? value : null,
      decoration: const InputDecoration(labelText: 'Difficulty'),
      items: [
        const DropdownMenuItem(value: null, child: Text('—')),
        for (final o in _opts)
          DropdownMenuItem(value: o, child: Text(o.replaceFirst(o[0], o[0].toUpperCase()))),
      ],
      onChanged: onChanged,
    );
  }
}
