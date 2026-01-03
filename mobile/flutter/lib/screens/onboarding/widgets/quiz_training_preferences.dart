import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Combined Training Preferences widget for quiz screens.
/// Includes: Training Split, Workout Type, and Progression Pace
/// With colorful cards and learn more functionality.
class QuizTrainingPreferences extends StatefulWidget {
  final String? selectedSplit;
  final String? selectedWorkoutType;
  final String? selectedProgressionPace;
  final ValueChanged<String> onSplitChanged;
  final ValueChanged<String> onWorkoutTypeChanged;
  final ValueChanged<String> onProgressionPaceChanged;

  const QuizTrainingPreferences({
    super.key,
    required this.selectedSplit,
    required this.selectedWorkoutType,
    required this.selectedProgressionPace,
    required this.onSplitChanged,
    required this.onWorkoutTypeChanged,
    required this.onProgressionPaceChanged,
  });

  @override
  State<QuizTrainingPreferences> createState() => _QuizTrainingPreferencesState();
}

class _QuizTrainingPreferencesState extends State<QuizTrainingPreferences> {
  // All 5 training splits with colors + "Nothing structured" option first
  static final _splits = [
    {'id': 'nothing_structured', 'label': 'Nothing structured', 'icon': Icons.shuffle, 'color': AppColors.cyan, 'desc': "I'll let AI decide"},
    {'id': 'push_pull_legs', 'label': 'Push/Pull/Legs', 'icon': Icons.splitscreen, 'color': AppColors.purple, 'desc': '6 days • Popular'},
    {'id': 'full_body', 'label': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.success, 'desc': '3 days • Beginners'},
    {'id': 'upper_lower', 'label': 'Upper/Lower', 'icon': Icons.swap_vert, 'color': AppColors.electricBlue, 'desc': '4 days • Balanced'},
    {'id': 'phul', 'label': 'PHUL', 'icon': Icons.flash_on, 'color': AppColors.orange, 'desc': '4 days • Power + Hypertrophy'},
    {'id': 'body_part', 'label': 'Body Part Split', 'icon': Icons.view_week, 'color': AppColors.coral, 'desc': '5-6 days • Advanced'},
  ];

  // Workout types with colors
  static final _workoutTypes = [
    {'id': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.cyan},
    {'id': 'cardio', 'label': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
    {'id': 'mixed', 'label': 'Mixed', 'icon': Icons.sports_gymnastics, 'color': AppColors.purple},
  ];

  // Progression pace with colors
  static final _paces = [
    {'id': 'slow', 'label': 'Slow', 'desc': '3-4 weeks', 'color': AppColors.success},
    {'id': 'medium', 'label': 'Medium', 'desc': '1-2 weeks', 'color': AppColors.electricBlue},
    {'id': 'fast', 'label': 'Fast', 'desc': 'Every session', 'color': AppColors.orange},
  ];

  void _showExplanationSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Training Splits Explained',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ..._splits.map((split) => _buildExplanationItem(
                split['label'] as String,
                _getSplitExplanation(split['id'] as String),
                split['color'] as Color,
                split['icon'] as IconData,
                textPrimary,
                textSecondary,
              )),
              const SizedBox(height: 24),
              Text(
                'Workout Types',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildExplanationItem('Strength', 'Focus on building muscle and power with weights', AppColors.cyan, Icons.fitness_center, textPrimary, textSecondary),
              _buildExplanationItem('Cardio', 'Running, cycling, rowing for heart health', AppColors.orange, Icons.directions_run, textPrimary, textSecondary),
              _buildExplanationItem('Mixed', 'Combination of strength training and cardio', AppColors.purple, Icons.sports_gymnastics, textPrimary, textSecondary),
              const SizedBox(height: 24),
              Text(
                'Progression Pace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildExplanationItem('Slow', 'Increase weight every 3-4 weeks. Best for beginners.', AppColors.success, Icons.trending_up, textPrimary, textSecondary),
              _buildExplanationItem('Medium', 'Increase weight every 1-2 weeks. Standard progression.', AppColors.electricBlue, Icons.trending_up, textPrimary, textSecondary),
              _buildExplanationItem('Fast', 'Increase weight every session if ready. For experienced lifters.', AppColors.orange, Icons.trending_up, textPrimary, textSecondary),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getSplitExplanation(String id) {
    switch (id) {
      case 'nothing_structured':
        return "Not sure? No problem! Our AI will recommend the best split based on your goals, experience, and schedule.";
      case 'push_pull_legs':
        return 'Train pushing muscles (chest, shoulders, triceps), pulling muscles (back, biceps), and legs on separate days. Great for balanced development.';
      case 'full_body':
        return 'Work all major muscle groups each session. Ideal for beginners or those with limited time. 3 days per week.';
      case 'upper_lower':
        return 'Alternate between upper body and lower body workouts. Good balance of frequency and recovery.';
      case 'phul':
        return 'Power Hypertrophy Upper Lower - combines strength and muscle building. 4 days with heavy and lighter sessions.';
      case 'body_part':
        return 'Dedicate each day to one muscle group (chest day, back day, etc). High volume per muscle, needs more gym days.';
      default:
        return '';
    }
  }

  Widget _buildExplanationItem(String title, String desc, Color color, IconData icon, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Training Preferences",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 2),
          // Subtitle with learn more
          Row(
            children: [
              Text(
                'All optional',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showExplanationSheet(context);
                },
                child: Text(
                  'Not sure? Tap to learn more',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 10),

          // Content in scrollable area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Training Split (colorful cards)
                  _buildSectionLabel('Training Split', textSecondary, 0),
                  const SizedBox(height: 6),
                  _buildSplitCards(isDark, textPrimary),

                  const SizedBox(height: 12),

                  // Section 2: Workout Type (horizontal colorful chips)
                  _buildSectionLabel('Workout Type', textSecondary, 1),
                  const SizedBox(height: 6),
                  _buildWorkoutTypeChips(isDark, textPrimary),

                  const SizedBox(height: 12),

                  // Section 3: Progression Pace (horizontal colorful chips)
                  _buildSectionLabel('Weight Progression', textSecondary, 2),
                  const SizedBox(height: 6),
                  _buildPaceChips(isDark, textPrimary, textSecondary),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color textSecondary, int index) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
    ).animate(delay: (200 + index * 50).ms).fadeIn();
  }

  Widget _buildSplitCards(bool isDark, Color textPrimary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      children: _splits.asMap().entries.map((entry) {
        final index = entry.key;
        final split = entry.value;
        final isSelected = widget.selectedSplit == split['id'];
        final color = split['color'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSplitChanged(split['id'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: 0.8), color],
                      )
                    : null,
                color: isSelected ? null : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 0)]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      split['icon'] as IconData,
                      color: isSelected ? Colors.white : color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          split['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                        Text(
                          split['desc'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected ? null : Border.all(color: cardBorder, width: 2),
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                ],
              ),
            ),
          ).animate(delay: (200 + index * 40).ms).fadeIn().slideX(begin: 0.03),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutTypeChips(bool isDark, Color textPrimary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Row(
      children: _workoutTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        final isSelected = widget.selectedWorkoutType == type['id'];
        final color = type['color'] as Color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onWorkoutTypeChanged(type['id'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withValues(alpha: 0.8), color],
                        )
                      : null,
                  color: isSelected ? null : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 0)]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      color: isSelected ? Colors.white : color,
                      size: 20,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      type['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: (350 + index * 50).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaceChips(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Row(
      children: _paces.asMap().entries.map((entry) {
        final index = entry.key;
        final pace = entry.value;
        final isSelected = widget.selectedProgressionPace == pace['id'];
        final color = pace['color'] as Color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onProgressionPaceChanged(pace['id'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withValues(alpha: 0.8), color],
                        )
                      : null,
                  color: isSelected ? null : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 0)]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      pace['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      pace['desc'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected ? Colors.white70 : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: (400 + index * 50).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
          ),
        );
      }).toList(),
    );
  }
}
