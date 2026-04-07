import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';
import 'onboarding_theme.dart';
import 'scroll_hint_arrow.dart';

/// Combined Training Preferences widget for quiz screens.
/// Includes: Training Split, Workout Type, Progression Pace, Sleep Quality, and Obstacles
/// With glassmorphic cards and learn more functionality.
class QuizTrainingPreferences extends StatefulWidget {
  final String? selectedSplit;
  final String? selectedWorkoutType;
  final String? selectedProgressionPace;
  final String? selectedSleepQuality;
  final Set<String>? selectedObstacles;
  final ValueChanged<String> onSplitChanged;
  final ValueChanged<String> onWorkoutTypeChanged;
  final ValueChanged<String> onProgressionPaceChanged;
  final ValueChanged<String>? onSleepQualityChanged;
  final ValueChanged<String>? onObstacleToggle;
  final bool showHeader;

  const QuizTrainingPreferences({
    super.key,
    required this.selectedSplit,
    required this.selectedWorkoutType,
    required this.selectedProgressionPace,
    this.selectedSleepQuality,
    this.selectedObstacles,
    required this.onSplitChanged,
    required this.onWorkoutTypeChanged,
    required this.onProgressionPaceChanged,
    this.onSleepQualityChanged,
    this.onObstacleToggle,
    this.showHeader = true,
  });

  @override
  State<QuizTrainingPreferences> createState() => _QuizTrainingPreferencesState();
}

class _QuizTrainingPreferencesState extends State<QuizTrainingPreferences> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // All 5 training splits with colors + "Nothing structured" option first
  static final _splits = [
    {'id': 'nothing_structured', 'label': 'Nothing structured', 'icon': Icons.shuffle, 'color': AppColors.purple, 'desc': "I'll let AI decide"},
    {'id': 'push_pull_legs', 'label': 'Push/Pull/Legs', 'icon': Icons.splitscreen, 'color': AppColors.orange, 'desc': '6 days \u2022 Popular'},
    {'id': 'full_body', 'label': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.green, 'desc': '3 days \u2022 Beginners'},
    {'id': 'upper_lower', 'label': 'Upper/Lower', 'icon': Icons.swap_vert, 'color': AppColors.electricBlue, 'desc': '4 days \u2022 Balanced'},
    {'id': 'phul', 'label': 'PHUL', 'icon': Icons.flash_on, 'color': AppColors.pink, 'desc': '4 days \u2022 Power + Hypertrophy'},
    {'id': 'body_part', 'label': 'Body Part Split', 'icon': Icons.view_week, 'color': AppColors.teal, 'desc': '5-6 days \u2022 Advanced'},
  ];

  // Workout types with colors
  static final _workoutTypes = [
    {'id': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.purple},
    {'id': 'cardio', 'label': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
    {'id': 'mixed', 'label': 'Mixed', 'icon': Icons.sports_gymnastics, 'color': AppColors.electricBlue},
  ];

  // Progression pace with colors
  static final _paces = [
    {'id': 'slow', 'label': 'Slow', 'desc': '3-4 weeks', 'color': AppColors.green},
    {'id': 'medium', 'label': 'Medium', 'desc': '1-2 weeks', 'color': AppColors.electricBlue},
    {'id': 'fast', 'label': 'Fast', 'desc': 'Every session', 'color': AppColors.orange},
  ];

  // Sleep quality options
  static final _sleepQualityOptions = [
    {'id': 'poor', 'emoji': '😴', 'label': 'Poor', 'desc': '<5 hrs', 'color': AppColors.pink},
    {'id': 'fair', 'emoji': '😐', 'label': 'Fair', 'desc': '5-6 hrs', 'color': AppColors.orange},
    {'id': 'good', 'emoji': '😊', 'label': 'Good', 'desc': '7-8 hrs', 'color': AppColors.green},
    {'id': 'excellent', 'emoji': '🌟', 'label': 'Excellent', 'desc': '8+ hrs', 'color': AppColors.electricBlue},
  ];

  // Obstacle options
  static final _obstacleOptions = [
    {'id': 'time', 'emoji': '⏰', 'label': 'Time'},
    {'id': 'energy', 'emoji': '💤', 'label': 'Energy'},
    {'id': 'motivation', 'emoji': '🎯', 'label': 'Motivation'},
    {'id': 'knowledge', 'emoji': '📚', 'label': 'Knowledge'},
    {'id': 'diet', 'emoji': '🍔', 'label': 'Diet'},
    {'id': 'access', 'emoji': '🏠', 'label': 'Access'},
  ];

  void _showExplanationSheet(BuildContext context) {
    // The glass sheet uses its own styling — always white-on-glass inside the sheet
    const textPrimary = Colors.white;
    final textSecondary = Colors.white.withValues(alpha: 0.7);
    // NOTE: textPrimary/textSecondary are intentionally hardcoded here because
    // the GlassSheet always renders dark glass regardless of system brightness.

    showGlassSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => GlassSheet(
          showHandle: false,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
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
              _buildExplanationItem('Strength', 'Focus on building muscle and power with weights', AppColors.accent, Icons.fitness_center, textPrimary, textSecondary),
              _buildExplanationItem('Cardio', 'Running, cycling, rowing for heart health', AppColors.accent, Icons.directions_run, textPrimary, textSecondary),
              _buildExplanationItem('Mixed', 'Combination of strength training and cardio', AppColors.accent, Icons.sports_gymnastics, textPrimary, textSecondary),
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
              _buildExplanationItem('Fast', 'Increase weight every session if ready. For experienced lifters.', AppColors.accent, Icons.trending_up, textPrimary, textSecondary),
              const SizedBox(height: 20),
            ],
          ),
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
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            // Title
            Text(
              "Training Preferences",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
                height: 1.2,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
            const SizedBox(height: 2),
            // Subtitle with learn more
            Row(
              children: [
                Text(
                  'All optional',
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
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
                      color: t.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 6),
          ],

          // Progressive overload & RIR badge
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: t.cardFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: t.borderDefault,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: t.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Progressive overload & RIR integrated',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 180.ms).slideX(begin: -0.02),

          const SizedBox(height: 10),

          // Content in scrollable area with scroll hint
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Training Split
                      _buildSectionLabel('Training Split', t.textSecondary, 0),
                      const SizedBox(height: 6),
                      _buildSplitCards(t),

                      const SizedBox(height: 12),

                      // Section 2: Workout Type
                      _buildSectionLabel('Workout Type', t.textSecondary, 1),
                      const SizedBox(height: 6),
                      _buildWorkoutTypeChips(t),

                      const SizedBox(height: 12),

                      // Section 3: Progression Pace
                      _buildSectionLabel('Weight Progression', t.textSecondary, 2),
                      const SizedBox(height: 6),
                      _buildPaceChips(t),

                      // Section 4: Sleep Quality
                      if (widget.onSleepQualityChanged != null) ...[
                        const SizedBox(height: 16),
                        _buildSectionLabel('Sleep Quality', t.textSecondary, 3),
                        const SizedBox(height: 6),
                        _buildSleepQualityChips(t),
                      ],

                      // Section 5: Obstacles
                      if (widget.onObstacleToggle != null) ...[
                        const SizedBox(height: 16),
                        _buildObstaclesSection(t),
                      ],

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                ScrollHintArrow(scrollController: _scrollController),
              ],
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

  Widget _buildSplitCards(OnboardingTheme t) {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: t.cardSelectedGradient,
                          )
                        : null,
                    color: isSelected ? null : t.cardFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? t.borderSelected
                          : t.borderDefault,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? t.iconContainerSelectedGradient(color)
                                : t.iconContainerGradient(color),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? t.iconContainerSelectedBorder(color)
                                : t.iconContainerBorder(color),
                          ),
                        ),
                        child: Icon(
                          split['icon'] as IconData,
                          color: color,
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
                                color: t.textPrimary,
                              ),
                            ),
                            Text(
                              split['desc'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? t.checkBg : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? null
                              : Border.all(color: t.checkBorderUnselected, width: 2),
                        ),
                        child: isSelected ? Icon(Icons.check, color: t.checkIcon, size: 14) : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate(delay: (200 + index * 40).ms).fadeIn().slideX(begin: 0.03),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutTypeChips(OnboardingTheme t) {
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: t.cardSelectedGradient,
                            )
                          : null,
                      color: isSelected ? null : t.cardFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? t.borderSelected
                            : t.borderDefault,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          type['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(delay: (350 + index * 50).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaceChips(OnboardingTheme t) {
    return Row(
      children: _paces.asMap().entries.map((entry) {
        final index = entry.key;
        final pace = entry.value;
        final isSelected = widget.selectedProgressionPace == pace['id'];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onProgressionPaceChanged(pace['id'] as String);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: t.cardSelectedGradient,
                            )
                          : null,
                      color: isSelected ? null : t.cardFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? t.borderSelected
                            : t.borderDefault,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          pace['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          pace['desc'] as String,
                          style: TextStyle(
                            fontSize: 9,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(delay: (400 + index * 50).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSleepQualityChips(OnboardingTheme t) {
    return Row(
      children: _sleepQualityOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = widget.selectedSleepQuality == option['id'];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onSleepQualityChanged?.call(option['id'] as String);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: t.cardSelectedGradient,
                            )
                          : null,
                      color: isSelected ? null : t.cardFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? t.borderSelected
                            : t.borderDefault,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          option['emoji'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(delay: (450 + index * 40).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildObstaclesSection(OnboardingTheme t) {
    final selectedCount = widget.selectedObstacles?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Biggest Obstacles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            if (selectedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: t.cardFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$selectedCount/3',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
          ],
        ).animate(delay: 500.ms).fadeIn(),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _obstacleOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = widget.selectedObstacles?.contains(option['id']) ?? false;
            final isDisabled = !isSelected && selectedCount >= 3;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      widget.onObstacleToggle?.call(option['id'] as String);
                    },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: t.cardSelectedGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : isDisabled
                              ? t.borderSubtle
                              : t.cardFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? t.borderSelected
                            : isDisabled
                                ? Colors.transparent
                                : t.borderDefault,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option['emoji'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDisabled ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? t.textPrimary
                                : isDisabled
                                    ? t.textDisabled
                                    : t.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(delay: (550 + index * 30).ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
          }).toList(),
        ),
      ],
    );
  }
}
