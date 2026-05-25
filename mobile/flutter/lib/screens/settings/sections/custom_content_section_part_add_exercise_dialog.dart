part of 'custom_content_section.dart';


/// Dialog for adding a new custom exercise
class _AddExerciseDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onAdd;

  const _AddExerciseDialog({required this.onAdd});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}


class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedMuscle = 'chest';
  String _selectedEquipment = 'bodyweight';
  int _sets = 3;
  int _reps = 10;
  bool _isCompound = false;
  bool _isLoading = false;

  final List<String> _muscleGroups = [
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'abs',
    'quadriceps',
    'hamstrings',
    'glutes',
    'calves',
    'full body',
  ];

  final List<String> _equipmentOptions = [
    'bodyweight',
    'dumbbell',
    'barbell',
    'kettlebell',
    'cable machine',
    'resistance band',
    'medicine ball',
    'slam ball',
    'pull-up bar',
    'bench',
    'other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onAdd({
        'name': _nameController.text.trim(),
        'primary_muscle': _selectedMuscle,
        'equipment': _selectedEquipment,
        'instructions': _instructionsController.text.trim(),
        'default_sets': _sets,
        'default_reps': _reps,
        'is_compound': _isCompound,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).customContentSectionAddCustomExercise),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Exercise Name *',
                    hintText: AppLocalizations.of(context).customContentSectionEGPikePush,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an exercise name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Muscle Group
                DropdownButtonFormField<String>(
                  initialValue: _selectedMuscle,
                  decoration: const InputDecoration(
                    labelText: 'Target Muscle *',
                  ),
                  items: _muscleGroups
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m[0].toUpperCase() + m.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMuscle = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Equipment
                DropdownButtonFormField<String>(
                  initialValue: _selectedEquipment,
                  decoration: const InputDecoration(
                    labelText: 'Equipment *',
                  ),
                  items: _equipmentOptions
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e[0].toUpperCase() + e.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedEquipment = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Sets and Reps
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context).workoutSummaryGeneralSets,
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _sets > 1
                                    ? () => setState(() => _sets--)
                                    : null,
                                icon: const Icon(Icons.remove),
                                iconSize: 20,
                              ),
                              Text('$_sets',
                                  style: const TextStyle(fontSize: 18)),
                              IconButton(
                                onPressed: _sets < 10
                                    ? () => setState(() => _sets++)
                                    : null,
                                icon: const Icon(Icons.add),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context).workoutSummaryGeneralReps, style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _reps > 1
                                    ? () => setState(() => _reps--)
                                    : null,
                                icon: const Icon(Icons.remove),
                                iconSize: 20,
                              ),
                              Text('$_reps',
                                  style: const TextStyle(fontSize: 18)),
                              IconButton(
                                onPressed: _reps < 50
                                    ? () => setState(() => _reps++)
                                    : null,
                                icon: const Icon(Icons.add),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Compound toggle
                SwitchListTile(
                  title: Text(AppLocalizations.of(context).customContentSectionCompoundExercise),
                  subtitle: Text(AppLocalizations.of(context).customContentSectionTargetsMultipleMuscleGroups),
                  value: _isCompound,
                  onChanged: (value) => setState(() => _isCompound = value),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),

                // Instructions (optional)
                TextFormField(
                  controller: _instructionsController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).logMealSheetInstructionsOptional,
                    hintText: AppLocalizations.of(context).customContentSectionDescribeHowToPerform,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).buttonCancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppLocalizations.of(context).workoutSummaryAddExercise),
        ),
      ],
    );
  }
}

