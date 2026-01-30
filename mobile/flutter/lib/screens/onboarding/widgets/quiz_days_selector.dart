import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Combined days per week, specific days, and workout duration selector widget.
class QuizDaysSelector extends StatelessWidget {
  final int? selectedDays;
  final Set<int> selectedWorkoutDays;
  final int? workoutDuration;  // Duration in minutes (30, 45, 60, 75, 90)
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<int> onWorkoutDayToggled;
  final ValueChanged<int>? onDurationChanged;

  const QuizDaysSelector({
    super.key,
    required this.selectedDays,
    required this.selectedWorkoutDays,
    this.workoutDuration,
    required this.onDaysChanged,
    required this.onWorkoutDayToggled,
    this.onDurationChanged,
  });

  static const _dayInfo = [
    {'index': 0, 'short': 'Mon', 'full': 'Monday'},
    {'index': 1, 'short': 'Tue', 'full': 'Tuesday'},
    {'index': 2, 'short': 'Wed', 'full': 'Wednesday'},
    {'index': 3, 'short': 'Thu', 'full': 'Thursday'},
    {'index': 4, 'short': 'Fri', 'full': 'Friday'},
    {'index': 5, 'short': 'Sat', 'full': 'Saturday'},
    {'index': 6, 'short': 'Sun', 'full': 'Sunday'},
  ];

  static const _durationOptions = [
    {'minutes': 30, 'label': '<30', 'desc': 'Quick'},
    {'minutes': 45, 'label': '30-45', 'desc': 'Standard'},
    {'minutes': 60, 'label': '45-60', 'desc': 'Full'},
    {'minutes': 75, 'label': '60-75', 'desc': 'Extended'},
    {'minutes': 90, 'label': '75-90', 'desc': 'Long'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use stronger, more visible colors with proper contrast
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    final requiredDays = selectedDays ?? 0;
    final selectedCount = selectedWorkoutDays.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(textPrimary),
            const SizedBox(height: 8),
            _buildSubtitle(textSecondary),
            const SizedBox(height: 24),
            _buildDaysPerWeekSelector(isDark, textPrimary, textSecondary),
            const SizedBox(height: 28),
            if (selectedDays != null) ...[
              _buildWhichDaysSection(isDark, textPrimary, textSecondary, requiredDays, selectedCount),
              if (selectedDays != null && selectedCount >= requiredDays)
                _buildRecommendation(isDark, textPrimary),
            ],

            // Workout Duration Section (only show if callback is provided)
            if (onDurationChanged != null) ...[
              const SizedBox(height: 28),
              _buildDurationSection(isDark, textPrimary, textSecondary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How long are your workouts?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 6),
        Text(
          'Your workout duration target (AI will generate within this range)',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 16),
        Row(
          children: _durationOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final minutes = option['minutes'] as int;
            final isSelected = workoutDuration == minutes;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < _durationOptions.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDurationChanged!(minutes);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                      color: isSelected
                          ? null
                          : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.orange : cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                        Text(
                          'min',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (200 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Duration hint
        if (workoutDuration != null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    _getDurationHint(workoutDuration!),
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  String _getDurationHint(int minutes) {
    if (minutes <= 30) {
      return 'Great for busy schedules';
    } else if (minutes <= 45) {
      return 'Most popular choice';
    } else if (minutes <= 60) {
      return 'Complete workout session';
    } else if (minutes <= 75) {
      return 'Includes thorough warmup';
    } else {
      return 'For serious training days';
    }
  }

  Widget _buildTitle(Color textPrimary) {
    return Text(
      'How many days per week can you train?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(Color textSecondary) {
    return Text(
      'Consistency beats intensity - pick what you can maintain',
      style: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDaysPerWeekSelector(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = selectedDays == day;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onDaysChanged(day);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 64,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.orange : cardBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                ),
                Text(
                  day == 1 ? 'day' : 'days',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (100 + index * 30).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
      }),
    );
  }

  Widget _buildWhichDaysSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    int requiredDays,
    int selectedCount,
  ) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which days work best?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 6),
        Text(
          'Select $selectedDays day${selectedDays == 1 ? '' : 's'} for your workouts',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _dayInfo.map((day) {
            final index = day['index'] as int;
            final isSelected = selectedWorkoutDays.contains(index);
            final isDisabled = !isSelected && selectedCount >= requiredDays;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onWorkoutDayToggled(index);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 58,
                decoration: BoxDecoration(
                  gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                  color: isSelected
                      ? null
                      : isDisabled
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05))
                          : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : isDisabled
                            ? Colors.transparent
                            : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day['short'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                                ? textSecondary.withValues(alpha: 0.5)
                                : textPrimary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ).animate(delay: (200 + (index * 40)).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSelectionCounter(isDark, textPrimary, requiredDays, selectedCount),
        if (selectedWorkoutDays.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSelectedDaysSummary(textSecondary),
        ],
      ],
    );
  }

  Widget _buildSelectionCounter(bool isDark, Color textPrimary, int requiredDays, int selectedCount) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final isComplete = selectedCount >= requiredDays;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isComplete
              ? LinearGradient(
                  colors: [
                    AppColors.success,
                    AppColors.success.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    (isDark ? AppColors.orange : AppColorsLight.orange).withValues(alpha: 0.15),
                    (isDark ? AppColors.orange : AppColorsLight.orange).withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isComplete
                ? AppColors.success
                : (isDark ? AppColors.orange : AppColorsLight.orange).withValues(alpha: 0.3),
            width: isComplete ? 2 : 1.5,
          ),
          boxShadow: isComplete
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isComplete ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
              size: 18,
              color: isComplete ? Colors.white : (isDark ? AppColors.orange : AppColorsLight.orange),
            ),
            const SizedBox(width: 8),
            Text(
              '$selectedCount / $requiredDays days selected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isComplete ? Colors.white : (isDark ? AppColors.orange : AppColorsLight.orange),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSelectedDaysSummary(Color textSecondary) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final sorted = selectedWorkoutDays.toList()..sort();
    final names = sorted.map((i) => dayNames[i]).toList();

    String summary;
    if (names.length == 1) {
      summary = names.first;
    } else if (names.length == 2) {
      summary = '${names[0]} and ${names[1]}';
    } else {
      final last = names.removeLast();
      summary = '${names.join(", ")} and $last';
    }

    return Center(
      child: Text(
        summary,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.orange,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecommendation(bool isDark, Color textPrimary) {
    String recommendation;
    if (selectedDays! <= 2) {
      recommendation = "Perfect for maintaining fitness. We'll make each session count!";
    } else if (selectedDays! <= 4) {
      recommendation = "Great balance! You'll see solid progress with proper recovery time.";
    } else {
      recommendation = "Dedicated training! We'll include active recovery days to prevent burnout.";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.orange.withValues(alpha: 0.15),
              AppColors.orange.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recommendation,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }
}
