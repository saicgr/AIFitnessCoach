import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Combined days per week and specific days selector widget.
class QuizDaysSelector extends StatelessWidget {
  final int? selectedDays;
  final Set<int> selectedWorkoutDays;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<int> onWorkoutDayToggled;

  const QuizDaysSelector({
    super.key,
    required this.selectedDays,
    required this.selectedWorkoutDays,
    required this.onDaysChanged,
    required this.onWorkoutDayToggled,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
          ],
        ),
      ),
    );
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
              gradient: isSelected ? AppColors.cyanGradient : null,
              color: isSelected
                  ? null
                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.cyan : cardBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.3),
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
                  gradient: isSelected ? AppColors.cyanGradient : null,
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
                        ? AppColors.cyan
                        : isDisabled
                            ? Colors.transparent
                            : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.3),
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

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selectedCount >= requiredDays
              ? AppColors.success.withValues(alpha: 0.15)
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedCount >= requiredDays
                ? AppColors.success.withValues(alpha: 0.5)
                : cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedCount >= requiredDays ? Icons.check_circle : Icons.calendar_today,
              size: 16,
              color: selectedCount >= requiredDays ? AppColors.success : AppColors.cyan,
            ),
            const SizedBox(width: 6),
            Text(
              '$selectedCount / $requiredDays days selected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selectedCount >= requiredDays ? AppColors.success : textPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms);
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
          fontSize: 12,
          color: textSecondary,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.cyan, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                recommendation,
                style: TextStyle(
                  fontSize: 12,
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
