import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/habit.dart';

/// Bottom sheet for creating or editing a habit
class CreateHabitSheet extends StatefulWidget {
  final HabitWithStatus? existingHabit;
  final ValueChanged<HabitCreate> onSave;

  const CreateHabitSheet({
    super.key,
    this.existingHabit,
    required this.onSave,
  });

  @override
  State<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<CreateHabitSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetCountController;
  late TextEditingController _unitController;

  HabitCategory _category = HabitCategory.lifestyle;
  HabitType _habitType = HabitType.positive;
  HabitFrequency _frequency = HabitFrequency.daily;
  List<int> _specificDays = [];
  String _selectedColor = '#06B6D4';
  String _selectedIcon = 'check_circle';

  final List<String> _colorOptions = [
    '#06B6D4', // Cyan
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#EF4444', // Red
    '#F97316', // Orange
    '#FBBF24', // Amber
    '#22C55E', // Green
    '#14B8A6', // Teal
    '#64748B', // Slate
  ];

  final List<String> _iconOptions = [
    'check_circle',
    'directions_walk',
    'water_drop',
    'restaurant',
    'bedtime',
    'fitness_center',
    'self_improvement',
    'menu_book',
    'medication',
    'no_drinks',
    'eco',
    'favorite',
    'star',
    'spa',
    'edit_note',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingHabit;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _targetCountController =
        TextEditingController(text: existing?.targetCount?.toString() ?? '');
    _unitController = TextEditingController(text: existing?.unit ?? '');

    if (existing != null) {
      _category = existing.category;
      _habitType = existing.habitType;
      _frequency = existing.frequency;
      _specificDays = existing.specificDays ?? [];
      _selectedColor = existing.color;
      _selectedIcon = existing.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetCountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingHabit != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            isEditing ? 'Edit Habit' : 'Create Habit',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Name input
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Habit Name',
              hintText: 'e.g., Drink 8 glasses of water',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: 12),

          // Description input
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Category selector
          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: HabitCategory.values.map((category) {
              final isSelected = _category == category;
              return ChoiceChip(
                label: Text(category.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _category = category);
                },
                selectedColor: AppColors.teal.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Habit type toggle
          Text('Habit Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<HabitType>(
            segments: [
              ButtonSegment(
                value: HabitType.positive,
                label: const Text('Build'),
                icon: const Icon(Icons.add_circle_outline),
              ),
              ButtonSegment(
                value: HabitType.negative,
                label: const Text('Break'),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
            selected: {_habitType},
            onSelectionChanged: (selected) {
              setState(() => _habitType = selected.first);
            },
          ),
          const SizedBox(height: 16),

          // Frequency selector
          Text('Frequency', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: HabitFrequency.values.map((frequency) {
              final isSelected = _frequency == frequency;
              return ChoiceChip(
                label: Text(frequency.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _frequency = frequency);
                },
              );
            }).toList(),
          ),

          // Day picker for specific days
          if (_frequency == HabitFrequency.specificDays) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .asMap()
                  .entries
                  .map((entry) {
                final dayIndex = entry.key;
                final dayLabel = entry.value;
                final isSelected = _specificDays.contains(dayIndex);

                return FilterChip(
                  label: Text(dayLabel),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _specificDays.add(dayIndex);
                      } else {
                        _specificDays.remove(dayIndex);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),

          // Target count and unit
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetCountController,
                  decoration: const InputDecoration(
                    labelText: 'Target (optional)',
                    hintText: 'e.g., 8',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit (optional)',
                    hintText: 'e.g., glasses',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Color picker
          Text('Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _parseColor(color),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nameController.text.trim().isEmpty ? null : _save,
              child: Text(isEditing ? 'Save Changes' : 'Create Habit'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _save() {
    final targetCount = int.tryParse(_targetCountController.text.trim());

    final habit = HabitCreate(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      category: _category,
      habitType: _habitType,
      frequency: _frequency,
      specificDays: _frequency == HabitFrequency.specificDays
          ? _specificDays
          : null,
      targetCount: targetCount,
      unit: _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : null,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    widget.onSave(habit);
  }

  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.teal;
    }
  }
}
