import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_theme.dart';

/// Callback for duration range selection (min, max)
typedef DurationRangeCallback = void Function(int min, int max);

/// Combined days per week, specific days, and workout duration selector widget.
class QuizDaysSelector extends StatelessWidget {
  final int? selectedDays;
  final Set<int> selectedWorkoutDays;
  final int? workoutDurationMin;  // Min duration in minutes
  final int? workoutDurationMax;  // Max duration in minutes (used for selection matching)
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<int> onWorkoutDayToggled;
  final DurationRangeCallback? onDurationChanged;
  final bool showHeader;

  const QuizDaysSelector({
    super.key,
    required this.selectedDays,
    required this.selectedWorkoutDays,
    this.workoutDurationMin,
    this.workoutDurationMax,
    required this.onDaysChanged,
    required this.onWorkoutDayToggled,
    this.onDurationChanged,
    this.showHeader = true,
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
    {'min': 15, 'max': 30, 'label': '<30', 'desc': 'Quick'},
    {'min': 30, 'max': 45, 'label': '30-45', 'desc': 'Standard'},
    {'min': 45, 'max': 60, 'label': '45-60', 'desc': 'Full'},
    {'min': 60, 'max': 75, 'label': '60-75', 'desc': 'Extended'},
    {'min': 75, 'max': 90, 'label': '75-90', 'desc': 'Long'},
  ];

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    final requiredDays = selectedDays ?? 0;
    final selectedCount = selectedWorkoutDays.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              _buildTitle(t),
              const SizedBox(height: 6),
              _buildSubtitle(t),
              const SizedBox(height: 16),
            ],
            _buildDaysPerWeekSelector(t),
            const SizedBox(height: 20),
            if (selectedDays != null) ...[
              _buildWhichDaysSection(t, requiredDays, selectedCount),
            ],

            // Workout Duration Section (only show if callback is provided)
            if (onDurationChanged != null) ...[
              const SizedBox(height: 20),
              _buildDurationSection(t),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection(OnboardingTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How long are your workouts?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 6),
        Text(
          'Your workout duration target (AI will generate within this range)',
          style: TextStyle(
            fontSize: 13,
            color: t.textSecondary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),
        Row(
          children: _durationOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final minDuration = (option['min'] as num).toInt();
            final maxDuration = (option['max'] as num).toInt();
            // Match selection by max value (the upper bound of the range)
            final isSelected = workoutDurationMax == maxDuration;
            // 45-60min is the recommended range
            final isRecommended = maxDuration == 60;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < _durationOptions.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDurationChanged!(minDuration, maxDuration);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: t.cardSelectedGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : t.cardFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? t.borderSelected
                                    : isRecommended
                                        ? t.checkBorderUnselected
                                        : t.borderDefault,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.15),
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
                                    color: t.textPrimary,
                                  ),
                                ),
                                Text(
                                  'min',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: t.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(height: 4),
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: t.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ).animate(delay: (200 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Duration hint
        if (workoutDurationMax != null)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.cardFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.borderDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: t.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        _getDurationHint(workoutDurationMax!),
                        style: TextStyle(
                          fontSize: 12,
                          color: t.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildTitle(OnboardingTheme t) {
    return Text(
      'How many days per week can you train?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: t.textPrimary,
        height: 1.3,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(OnboardingTheme t) {
    return Text(
      'Consistency beats intensity - pick what you can maintain',
      style: TextStyle(
        fontSize: 14,
        color: t.textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDaysPerWeekSelector(OnboardingTheme t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = selectedDays == day;
        final isRecommended = day == 3 || day == 4;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onDaysChanged(day);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: t.cardSelectedGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : t.cardFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? t.borderSelected : t.borderDefault,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.15),
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
                            color: t.textPrimary,
                          ),
                        ),
                        Text(
                          day == 1 ? 'day' : 'days',
                          style: TextStyle(
                            fontSize: 10,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(height: 4),
                Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: t.textSecondary,
                ),
              ] else ...[
                const SizedBox(height: 16),
              ],
            ],
          ),
        ).animate(delay: (100 + index * 30).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
      }),
    );
  }

  Widget _buildWhichDaysSection(
    OnboardingTheme t,
    int requiredDays,
    int selectedCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which days work best?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 6),
        Text(
          'Select $selectedDays day${selectedDays == 1 ? '' : 's'} for your workouts',
          style: TextStyle(
            fontSize: 13,
            color: t.textSecondary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _dayInfo.map((day) {
            final index = (day['index'] as num).toInt();
            final isSelected = selectedWorkoutDays.contains(index);
            final isDisabled = !isSelected && selectedCount >= requiredDays;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onWorkoutDayToggled(index);
                    },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 58,
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
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.15),
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
                                ? t.textPrimary
                                : isDisabled
                                    ? t.textDisabled
                                    : t.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: t.textPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(delay: (200 + (index * 40)).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildSelectionCounter(t, requiredDays, selectedCount),
      ],
    );
  }

  Widget _buildSelectionCounter(OnboardingTheme t, int requiredDays, int selectedCount) {
    final isComplete = selectedCount >= requiredDays;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isComplete
                  ? LinearGradient(
                      colors: t.cardSelectedGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isComplete ? null : t.cardFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isComplete ? t.borderSelected : t.borderDefault,
                width: isComplete ? 2 : 1.5,
              ),
              boxShadow: isComplete
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
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
                  color: t.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$selectedCount / $requiredDays days selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSelectedDaysSummary(OnboardingTheme t) {
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
          color: t.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecommendation(OnboardingTheme t) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.cardFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: t.borderDefault,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.cardFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color: t.textPrimary,
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
                      color: t.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }
}
