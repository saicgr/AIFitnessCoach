import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use stronger, more visible colors with proper contrast
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              question,
              style: TextStyle(
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
            isDark: isDark,
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
                  isDark: isDark,
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
                  isDark: isDark,
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
                  isDark: isDark,
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
    {'id': 'chest', 'label': 'Chest', 'icon': Icons.favorite_border},  // Heart outline for chest
    {'id': 'shoulders', 'label': 'Shoulders', 'icon': Icons.airline_seat_individual_suite},  // Wide shoulders
    {'id': 'triceps', 'label': 'Triceps', 'icon': Icons.straighten},  // Extending arm
    {'id': 'biceps', 'label': 'Biceps', 'icon': Icons.accessibility},  // Flexing person
    {'id': 'lats', 'label': 'Lats', 'icon': Icons.unfold_more},  // Wide/expanding
    {'id': 'upper_back', 'label': 'Upper Back', 'icon': Icons.view_column},  // Columns for back
    {'id': 'upper_traps', 'label': 'Upper Traps', 'icon': Icons.keyboard_double_arrow_up},  // Up arrows for traps
    {'id': 'forearms', 'label': 'Forearms', 'icon': Icons.back_hand},  // Hand/forearm
    {'id': 'neck', 'label': 'Neck', 'icon': Icons.account_circle},  // Head/neck area
  ];

  static const List<Map<String, dynamic>> _coreMuscles = [
    {'id': 'abs', 'label': 'Abs', 'icon': Icons.grid_3x3},  // Grid for abs
    {'id': 'obliques', 'label': 'Obliques', 'icon': Icons.compare_arrows},  // Side-to-side for obliques
    {'id': 'lower_back', 'label': 'Lower Back', 'icon': Icons.horizontal_rule},  // Lower back line
  ];

  static const List<Map<String, dynamic>> _lowerMuscles = [
    {'id': 'quadriceps', 'label': 'Quadriceps', 'icon': Icons.vertical_distribute},  // Front thigh
    {'id': 'hamstrings', 'label': 'Hamstrings', 'icon': Icons.do_not_step},  // Back of leg
    {'id': 'glutes', 'label': 'Glutes', 'icon': Icons.event_seat},  // Seat/glutes
    {'id': 'calves', 'label': 'Calves', 'icon': Icons.height},  // Height/standing on toes
    {'id': 'hip_flexors', 'label': 'Hip Flexors', 'icon': Icons.sports_martial_arts},  // Keep this - good for hip movement
    {'id': 'adductors', 'label': 'Adductors', 'icon': Icons.compress},  // Squeezing inward
  ];
}

class _FocusPointsIndicator extends StatelessWidget {
  final int usedPoints;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _FocusPointsIndicator({
    required this.usedPoints,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final availablePoints = QuizMuscleFocus.maxTotalPoints - usedPoints;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
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
                    gradient: isFilled ? AppColors.accentGradient : null,
                    color: isFilled
                        ? null
                        : (isDark
                            ? AppColors.glassSurface
                            : AppColorsLight.glassSurface),
                    border: Border.all(
                      color: isFilled ? AppColors.orange : AppColors.orange.withValues(alpha: 0.3),
                      width: isFilled ? 2 : 2,
                    ),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
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
    );
  }
}

class _MuscleGroupSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> muscles;
  final Map<String, int> focusPoints;
  final int availablePoints;
  final ValueChanged<Map<String, int>> onPointsChanged;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _MuscleGroupSection({
    required this.title,
    required this.muscles,
    required this.focusPoints,
    required this.availablePoints,
    required this.onPointsChanged,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
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
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              showDivider: !isLast,
            );
          }),
        ],
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
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final bool showDivider;

  const _MuscleRow({
    required this.muscle,
    required this.points,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
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
                      ? AppColors.accent.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  muscle['icon'] as IconData,
                  color: hasPoints ? AppColors.accent : textSecondary,
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
                isDark: isDark,
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
                      color: hasPoints ? AppColors.orange : textSecondary,
                    ),
                  ),
                ),
              ),
              // Increment button
              _PointButton(
                icon: Icons.add,
                onTap: canIncrement ? onIncrement : null,
                isDark: isDark,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: cardBorder.withOpacity(0.5),
          ),
      ],
    );
  }
}

class _PointButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _PointButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
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
              ? AppColors.orange.withValues(alpha: 0.12)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? AppColors.orange : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? AppColors.orange
              : (isDark ? Colors.white38 : Colors.black26),
        ),
      ),
    );
  }
}
