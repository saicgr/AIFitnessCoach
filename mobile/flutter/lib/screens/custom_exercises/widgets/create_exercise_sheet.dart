import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/custom_exercises_provider.dart';
import '../../../data/models/custom_exercise.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for creating a new custom exercise
class CreateExerciseSheet extends ConsumerStatefulWidget {
  const CreateExerciseSheet({super.key});

  @override
  ConsumerState<CreateExerciseSheet> createState() => _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends ConsumerState<CreateExerciseSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Simple exercise fields
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _primaryMuscle = 'chest';
  String _equipment = 'dumbbell';
  int _defaultSets = 3;
  int _defaultReps = 10;
  bool _isCompound = false;

  // Composite exercise fields
  final _comboNameController = TextEditingController();
  final _comboNotesController = TextEditingController();
  ComboType _comboType = ComboType.superset;
  String _comboPrimaryMuscle = 'chest';
  String _comboEquipment = 'dumbbell';
  final List<ComponentExercise> _components = [];
  final _componentNameController = TextEditingController();
  int _componentReps = 10;

  bool _isSubmitting = false;

  final List<String> _muscleGroups = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'forearms', 'abs', 'core', 'quadriceps', 'hamstrings',
    'glutes', 'calves', 'full body',
  ];

  final List<String> _equipmentOptions = [
    'bodyweight', 'dumbbell', 'barbell', 'kettlebell',
    'cable', 'machine', 'resistance band', 'medicine ball',
    'slam ball', 'other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _instructionsController.dispose();
    _comboNameController.dispose();
    _comboNotesController.dispose();
    _componentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.pureWhite;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Create Exercise',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : AppColorsLight.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: cyan,
              unselectedLabelColor: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Simple'),
                Tab(text: 'Combo'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSimpleForm(context, isDark),
                _buildComboForm(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleForm(BuildContext context, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            _buildLabel('Exercise Name', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g., My Custom Press',
              isDark: isDark,
              validator: (v) => v?.isEmpty == true ? 'Name required' : null,
            ),
            const SizedBox(height: 20),

            // Muscle group
            _buildLabel('Primary Muscle', isDark),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _primaryMuscle,
              items: _muscleGroups,
              onChanged: (v) => setState(() => _primaryMuscle = v!),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Equipment
            _buildLabel('Equipment', isDark),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _equipment,
              items: _equipmentOptions,
              onChanged: (v) => setState(() => _equipment = v!),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Sets and Reps
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Default Sets', isDark),
                      const SizedBox(height: 8),
                      _buildNumberStepper(
                        value: _defaultSets,
                        min: 1,
                        max: 10,
                        onChanged: (v) => setState(() => _defaultSets = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Default Reps', isDark),
                      const SizedBox(height: 8),
                      _buildNumberStepper(
                        value: _defaultReps,
                        min: 1,
                        max: 50,
                        onChanged: (v) => setState(() => _defaultReps = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Compound toggle
            _buildToggleTile(
              'Compound Exercise',
              'Targets multiple muscle groups',
              _isCompound,
              (v) => setState(() => _isCompound = v),
              isDark,
            ),
            const SizedBox(height: 20),

            // Instructions (optional)
            _buildLabel('Instructions (optional)', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _instructionsController,
              hint: 'Describe how to perform this exercise...',
              isDark: isDark,
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _createSimpleExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Create Exercise',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildComboForm(BuildContext context, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combo name
          _buildLabel('Combo Name', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _comboNameController,
            hint: 'e.g., Bench Press & Chest Fly Superset',
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Combo type
          _buildLabel('Combo Type', isDark),
          const SizedBox(height: 8),
          _buildComboTypeSelector(isDark),
          const SizedBox(height: 20),

          // Muscle and Equipment row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Muscle', isDark),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _comboPrimaryMuscle,
                      items: _muscleGroups,
                      onChanged: (v) => setState(() => _comboPrimaryMuscle = v!),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Equipment', isDark),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _comboEquipment,
                      items: _equipmentOptions,
                      onChanged: (v) => setState(() => _comboEquipment = v!),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Components section
          Row(
            children: [
              Text(
                'Exercises (${_components.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_components.length < 5)
                TextButton.icon(
                  onPressed: () => _showAddComponentDialog(context, isDark),
                  icon: Icon(Icons.add, size: 18, color: cyan),
                  label: Text('Add', style: TextStyle(color: cyan)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_components.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : AppColorsLight.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.layers_outlined, size: 40, color: textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'Add at least 2 exercises',
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_components.length, (index) {
              final comp = _components[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildComponentTile(comp, index, isDark),
              );
            }),

          const SizedBox(height: 20),

          // Notes (optional)
          _buildLabel('Notes (optional)', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _comboNotesController,
            hint: 'Any special instructions...',
            isDark: isDark,
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting || _components.length < 2
                  ? null
                  : _createComboExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: Colors.black,
                disabledBackgroundColor: cyan.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      _components.length < 2
                          ? 'Add ${2 - _components.length} more exercises'
                          : 'Create Combo Exercise',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surface : AppColorsLight.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColorsLight.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item[0].toUpperCase() + item.substring(1),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNumberStepper({
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
    required bool isDark,
  }) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColorsLight.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > min
                ? () {
                    HapticService.light();
                    onChanged(value - 1);
                  }
                : null,
            icon: const Icon(Icons.remove),
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          IconButton(
            onPressed: value < max
                ? () {
                    HapticService.light();
                    onChanged(value + 1);
                  }
                : null,
            icon: const Icon(Icons.add),
            color: cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColorsLight.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
      ),
    );
  }

  Widget _buildComboTypeSelector(bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComboType.values.map((type) {
        final isSelected = type == _comboType;
        return GestureDetector(
          onTap: () {
            HapticService.light();
            setState(() => _comboType = type);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? cyan.withOpacity(0.2) : (isDark ? AppColors.surface : AppColorsLight.surface),
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: cyan, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cyan : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                Text(
                  type.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComponentTile(ComponentExercise comp, int index, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColorsLight.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${comp.order}',
                style: TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
                  comp.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (comp.targetDisplay.isNotEmpty)
                  Text(
                    comp.targetDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticService.light();
              setState(() => _components.removeAt(index));
            },
            icon: const Icon(Icons.close, size: 18),
            color: Colors.red.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  void _showAddComponentDialog(BuildContext context, bool isDark) {
    _componentNameController.clear();
    _componentReps = 10;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _componentNameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Bench Press',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Reps: '),
                  IconButton(
                    onPressed: () {
                      if (_componentReps > 1) {
                        setDialogState(() => _componentReps--);
                      }
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_componentReps', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      if (_componentReps < 50) {
                        setDialogState(() => _componentReps++);
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_componentNameController.text.isNotEmpty) {
                  setState(() {
                    _components.add(ComponentExercise(
                      name: _componentNameController.text,
                      order: _components.length + 1,
                      reps: _componentReps,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSimpleExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(customExercisesProvider.notifier).createSimpleExercise(
          name: _nameController.text.trim(),
          primaryMuscle: _primaryMuscle,
          equipment: _equipment,
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
          defaultSets: _defaultSets,
          defaultReps: _defaultReps,
          isCompound: _isCompound,
        );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _createComboExercise() async {
    if (_comboNameController.text.isEmpty || _components.length < 2) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(customExercisesProvider.notifier).createCompositeExercise(
          name: _comboNameController.text.trim(),
          primaryMuscle: _comboPrimaryMuscle,
          equipment: _comboEquipment,
          comboType: _comboType,
          components: _components,
          customNotes: _comboNotesController.text.trim().isEmpty
              ? null
              : _comboNotesController.text.trim(),
        );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.pop(context);
    }
  }
}
