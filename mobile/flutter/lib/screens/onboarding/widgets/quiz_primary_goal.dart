import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Primary goal selection widget for quiz screens.
/// Single-select card-based UI with descriptions visible.
class QuizPrimaryGoal extends StatelessWidget {
  final String question;
  final String subtitle;
  final List<Map<String, dynamic>> options;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  const QuizPrimaryGoal({
    super.key,
    required this.question,
    required this.subtitle,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

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
          Text(
            question,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id'] as String;
                final isSelected = selectedValue == id;

                return _PrimaryGoalCard(
                  option: option,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(id);
                  },
                  index: index,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryGoalCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _PrimaryGoalCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.index,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final color = option['color'] as Color? ?? AppColors.orange; // Use orange accent
    final accentColor = AppColors.orange; // Primary accent color

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : cardBorder,
              width: isSelected ? 3.0 : 1,  // ← INCREASED from 2.5 to 3.0 for more obvious selection
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.5),  // ← INCREASED from 0.4 to 0.5
                      blurRadius: 16,  // ← INCREASED from 12 to 16
                      spreadRadius: 2,  // ← ADDED spreadRadius for more presence
                      offset: const Offset(0, 4),  // ← Subtle lift
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.25),
                            color.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  option['icon'] as IconData,
                  color: isSelected ? Colors.white : color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0A0A0A)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option['description'] as String,
                      style: TextStyle(
                        fontSize: 13,  // ← REDUCED from 14 for tighter spacing
                        fontWeight: FontWeight.w500,  // ← INCREASED from w400 for clarity
                        color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : (isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B)),
                        height: 1.4,
                        letterSpacing: 0.2,  // ← ADDED for readability
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,  // ← INCREASED from 24 for more prominent checkmark
                height: 28,  // ← INCREASED from 24
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,  // ← Solid white when selected
                  shape: BoxShape.circle,
                  border: isSelected
                      ? null
                      : Border.all(color: cardBorder, width: 2),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: accentColor,  // ← Orange checkmark on white background
                        size: 20,  // ← INCREASED from 16
                        weight: 700,  // ← ADDED bold weight
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
