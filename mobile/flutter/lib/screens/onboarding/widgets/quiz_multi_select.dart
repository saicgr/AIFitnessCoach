import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Multi-select question widget for quiz screens.
class QuizMultiSelect extends StatelessWidget {
  final String question;
  final String subtitle;
  final List<Map<String, dynamic>> options;
  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;
  final bool showDescriptions;
  final bool showHeader;

  const QuizMultiSelect({
    super.key,
    required this.question,
    required this.subtitle,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    this.showDescriptions = false,
    this.showHeader = true,
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
          if (showHeader) ...[
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
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id'] as String;
                final isSelected = selectedValues.contains(id);

                return _QuizOptionCard(
                  option: option,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(id);
                  },
                  index: index,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  showDescription: showDescriptions,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizOptionCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final bool showDescription;

  const _QuizOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.index,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final color = option['color'] as Color? ?? AppColors.orange; // Use orange accent
    final accentColor = AppColors.orange; // Primary accent color

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : cardBorder,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  option['icon'] as IconData,
                  color: isSelected ? Colors.white : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0A0A0A)),
                      ),
                    ),
                    if (showDescription && option['description'] != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        option['description'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : (isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? null
                      : Border.all(color: cardBorder, width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
