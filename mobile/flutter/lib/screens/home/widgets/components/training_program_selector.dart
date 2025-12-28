import 'package:flutter/material.dart';
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

  const TrainingProgramSelector({
    super.key,
    required this.selectedProgramId,
    required this.onSelectionChanged,
    this.disabled = false,
    this.programs = defaultTrainingPrograms,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

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

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: disabled
                      ? null
                      : () => onSelectionChanged(
                            isSelected ? null : program.id,
                          ),
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
                            program.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                              height: 1.3,
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
