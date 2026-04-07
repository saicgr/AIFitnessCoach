import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Muscle focus points allocation widget for quiz screens.
/// Users can allocate up to 5 focus points to prioritize specific muscle groups.
class QuizMuscleFocus extends StatelessWidget {
  final String question;
  final String subtitle;
  final Map<String, int> focusPoints;
  final ValueChanged<Map<String, int>> onPointsChanged;
  final bool showHeader;

  const QuizMuscleFocus({
    super.key,
    required this.question,
    required this.subtitle,
    required this.focusPoints,
    required this.onPointsChanged,
    this.showHeader = true,
  });

  static const int maxTotalPoints = 5;

  int get totalPointsUsed => focusPoints.values.fold(0, (a, b) => a + b);
  int get availablePoints => maxTotalPoints - totalPointsUsed;

  @override
  Widget build(BuildContext context) {
    const textPrimary = Colors.white;
    final textSecondary = Colors.white.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              question,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                height: 1.3,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
          ],
          // Focus points indicator
          _FocusPointsIndicator(
            usedPoints: totalPointsUsed,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _MuscleGroupSection(
                  title: 'Upper Body',
                  muscles: _upperMuscles,
                  focusPoints: focusPoints,
                  availablePoints: availablePoints,
                  onPointsChanged: onPointsChanged,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 16),
                _MuscleGroupSection(
                  title: 'Core',
                  muscles: _coreMuscles,
                  focusPoints: focusPoints,
                  availablePoints: availablePoints,
                  onPointsChanged: onPointsChanged,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 16),
                _MuscleGroupSection(
                  title: 'Lower Body',
                  muscles: _lowerMuscles,
                  focusPoints: focusPoints,
                  availablePoints: availablePoints,
                  onPointsChanged: onPointsChanged,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _upperMuscles = [
    {'id': 'chest', 'label': 'Chest', 'icon': Icons.favorite_border},
    {'id': 'shoulders', 'label': 'Shoulders', 'icon': Icons.airline_seat_individual_suite},
    {'id': 'triceps', 'label': 'Triceps', 'icon': Icons.straighten},
    {'id': 'biceps', 'label': 'Biceps', 'icon': Icons.accessibility},
    {'id': 'lats', 'label': 'Lats', 'icon': Icons.unfold_more},
    {'id': 'upper_back', 'label': 'Upper Back', 'icon': Icons.view_column},
    {'id': 'upper_traps', 'label': 'Upper Traps', 'icon': Icons.keyboard_double_arrow_up},
    {'id': 'forearms', 'label': 'Forearms', 'icon': Icons.back_hand},
    {'id': 'neck', 'label': 'Neck', 'icon': Icons.account_circle},
  ];

  static const List<Map<String, dynamic>> _coreMuscles = [
    {'id': 'abs', 'label': 'Abs', 'icon': Icons.grid_3x3},
    {'id': 'obliques', 'label': 'Obliques', 'icon': Icons.compare_arrows},
    {'id': 'lower_back', 'label': 'Lower Back', 'icon': Icons.horizontal_rule},
  ];

  static const List<Map<String, dynamic>> _lowerMuscles = [
    {'id': 'quadriceps', 'label': 'Quadriceps', 'icon': Icons.vertical_distribute},
    {'id': 'hamstrings', 'label': 'Hamstrings', 'icon': Icons.do_not_step},
    {'id': 'glutes', 'label': 'Glutes', 'icon': Icons.event_seat},
    {'id': 'calves', 'label': 'Calves', 'icon': Icons.height},
    {'id': 'hip_flexors', 'label': 'Hip Flexors', 'icon': Icons.sports_martial_arts},
    {'id': 'adductors', 'label': 'Adductors', 'icon': Icons.compress},
  ];
}

class _FocusPointsIndicator extends StatelessWidget {
  final int usedPoints;
  final Color textPrimary;
  final Color textSecondary;

  const _FocusPointsIndicator({
    required this.usedPoints,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final availablePoints = QuizMuscleFocus.maxTotalPoints - usedPoints;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus Points',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$availablePoints/${QuizMuscleFocus.maxTotalPoints} available',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: List.generate(QuizMuscleFocus.maxTotalPoints, (index) {
                  final isFilled = index < usedPoints;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isFilled
                            ? LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.9),
                                  Colors.white.withValues(alpha: 0.7),
                                ],
                              )
                            : null,
                        color: isFilled ? null : Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: isFilled
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuscleGroupSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> muscles;
  final Map<String, int> focusPoints;
  final int availablePoints;
  final ValueChanged<Map<String, int>> onPointsChanged;
  final Color textPrimary;
  final Color textSecondary;

  const _MuscleGroupSection({
    required this.title,
    required this.muscles,
    required this.focusPoints,
    required this.availablePoints,
    required this.onPointsChanged,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...muscles.asMap().entries.map((entry) {
                final index = entry.key;
                final muscle = entry.value;
                final id = muscle['id'] as String;
                final currentPoints = focusPoints[id] ?? 0;
                final isLast = index == muscles.length - 1;

                return _MuscleRow(
                  muscle: muscle,
                  points: currentPoints,
                  canIncrement: availablePoints > 0,
                  onIncrement: () {
                    if (availablePoints > 0) {
                      HapticFeedback.selectionClick();
                      final newPoints = Map<String, int>.from(focusPoints);
                      newPoints[id] = currentPoints + 1;
                      onPointsChanged(newPoints);
                    }
                  },
                  onDecrement: () {
                    if (currentPoints > 0) {
                      HapticFeedback.selectionClick();
                      final newPoints = Map<String, int>.from(focusPoints);
                      if (currentPoints == 1) {
                        newPoints.remove(id);
                      } else {
                        newPoints[id] = currentPoints - 1;
                      }
                      onPointsChanged(newPoints);
                    }
                  },
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  showDivider: !isLast,
                );
              }),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.03);
  }
}

class _MuscleRow extends StatelessWidget {
  final Map<String, dynamic> muscle;
  final int points;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Color textPrimary;
  final Color textSecondary;
  final bool showDivider;

  const _MuscleRow({
    required this.muscle,
    required this.points,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
    required this.textPrimary,
    required this.textSecondary,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoints = points > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasPoints
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  muscle['icon'] as IconData,
                  color: hasPoints ? Colors.white : textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  muscle['label'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: hasPoints ? FontWeight.w600 : FontWeight.w500,
                    color: hasPoints ? textPrimary : textSecondary,
                  ),
                ),
              ),
              // Decrement button
              _PointButton(
                icon: Icons.remove,
                onTap: points > 0 ? onDecrement : null,
              ),
              // Points display
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    '$points',
                    key: ValueKey(points),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hasPoints ? Colors.white : textSecondary,
                    ),
                  ),
                ),
              ),
              // Increment button
              _PointButton(
                icon: Icons.add,
                onTap: canIncrement ? onIncrement : null,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: Colors.white.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}

class _PointButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PointButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? Colors.white
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
