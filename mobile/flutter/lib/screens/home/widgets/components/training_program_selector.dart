import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sheet_theme_colors.dart';
import 'section_title.dart';

/// Model for a training program
class TrainingProgram {
  final String id;
  final String name;
  final String description;
  final String daysPerWeek;
  final IconData icon;

  const TrainingProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.daysPerWeek,
    required this.icon,
  });
}

/// Example custom program prompts
const List<String> customProgramExamples = [
  'Train for HYROX competition',
  'Improve my box jump height',
  'Build explosive power for basketball',
  'Train for a marathon',
  'Get better at pull-ups',
  'Prepare for obstacle course racing',
];

/// Default list of training programs
const List<TrainingProgram> defaultTrainingPrograms = [
  TrainingProgram(
    id: 'full_body',
    name: 'Full Body',
    description: 'Train all muscle groups each session',
    daysPerWeek: '3-4 days',
    icon: Icons.accessibility_new,
  ),
  TrainingProgram(
    id: 'upper_lower',
    name: 'Upper/Lower',
    description: 'Alternate upper and lower body days',
    daysPerWeek: '4 days',
    icon: Icons.swap_vert,
  ),
  TrainingProgram(
    id: 'push_pull_legs',
    name: 'Push/Pull/Legs',
    description: 'Classic 3-way split for muscle building',
    daysPerWeek: '3-6 days',
    icon: Icons.fitness_center,
  ),
  TrainingProgram(
    id: 'phul',
    name: 'PHUL',
    description: 'Power Hypertrophy Upper Lower',
    daysPerWeek: '4 days',
    icon: Icons.bolt,
  ),
  TrainingProgram(
    id: 'arnold_split',
    name: 'Arnold Split',
    description: 'High volume bodybuilding split',
    daysPerWeek: '6 days',
    icon: Icons.star,
  ),
  TrainingProgram(
    id: 'hyrox',
    name: 'HYROX',
    description: 'Hybrid running + functional fitness',
    daysPerWeek: '4-5 days',
    icon: Icons.directions_run,
  ),
  TrainingProgram(
    id: 'bro_split',
    name: 'Bro Split',
    description: 'One muscle group per day',
    daysPerWeek: '5-6 days',
    icon: Icons.person,
  ),
  TrainingProgram(
    id: 'custom',
    name: 'Custom',
    description: 'Build your own program',
    daysPerWeek: 'Flexible',
    icon: Icons.tune,
  ),
];

/// A widget for selecting a training program
class TrainingProgramSelector extends StatelessWidget {
  /// Currently selected program ID
  final String? selectedProgramId;

  /// Callback when selection changes
  final ValueChanged<String?> onSelectionChanged;

  /// Whether the selector is disabled
  final bool disabled;

  /// List of training programs (defaults to standard options)
  final List<TrainingProgram> programs;

  /// Custom program description (when 'custom' is selected)
  final String? customProgramDescription;

  /// Callback when custom program description changes
  final ValueChanged<String>? onCustomDescriptionChanged;

  const TrainingProgramSelector({
    super.key,
    required this.selectedProgramId,
    required this.onSelectionChanged,
    this.disabled = false,
    this.programs = defaultTrainingPrograms,
    this.customProgramDescription,
    this.onCustomDescriptionChanged,
  });

  void _showCustomProgramSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomProgramSheet(
        initialDescription: customProgramDescription,
        onSave: (description) {
          onCustomDescriptionChanged?.call(description);
          onSelectionChanged('custom');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final hasCustomDescription =
        customProgramDescription != null && customProgramDescription!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                icon: Icons.calendar_month,
                title: 'Training Program',
                iconColor: colors.purple,
              ),
              const SizedBox(height: 4),
              Text(
                'Choose your training split',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              final isSelected = selectedProgramId == program.id;
              final isCustom = program.id == 'custom';

              // For custom, show the description if set
              String displayDescription = program.description;
              if (isCustom && hasCustomDescription) {
                displayDescription = customProgramDescription!;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: disabled
                      ? null
                      : () {
                          if (isCustom) {
                            // Show custom program input sheet
                            _showCustomProgramSheet(context);
                          } else {
                            onSelectionChanged(isSelected ? null : program.id);
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.purple.withOpacity(0.15)
                          : colors.glassSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colors.purple
                            : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              program.icon,
                              size: 18,
                              color: isSelected
                                  ? colors.purple
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                program.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colors.purple
                                      : colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            displayDescription,
                            style: TextStyle(
                              fontSize: 11,
                              color: isCustom && hasCustomDescription && isSelected
                                  ? colors.purple.withOpacity(0.8)
                                  : colors.textMuted,
                              height: 1.3,
                              fontStyle: isCustom && hasCustomDescription
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program.daysPerWeek,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? colors.purple
                                : colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet for entering custom program description
class _CustomProgramSheet extends StatefulWidget {
  final String? initialDescription;
  final ValueChanged<String> onSave;

  const _CustomProgramSheet({
    this.initialDescription,
    required this.onSave,
  });

  @override
  State<_CustomProgramSheet> createState() => _CustomProgramSheetState();
}

class _CustomProgramSheetState extends State<_CustomProgramSheet> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDescription);
    _hasText = _controller.text.trim().isNotEmpty;
    // Listen for text changes to update button state
    _controller.addListener(_onTextChanged);
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSave(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    color: colors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Icon(Icons.tune, color: colors.purple, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Custom Program',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Describe what you want to train for and AI will create a personalized program.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Text input
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'e.g., "Train for HYROX competition"',
                  hintStyle: TextStyle(color: colors.textMuted),
                  filled: true,
                  fillColor: colors.glassSurface,
                  counterStyle: TextStyle(color: colors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.purple, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: (_) => _saveAndClose(),
              ),
              const SizedBox(height: 16),

              // Examples
              Text(
                'Examples',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: customProgramExamples.map((example) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = example;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: example.length),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.glassSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: Text(
                        example,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasText ? _saveAndClose : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.purple.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Custom Program',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
