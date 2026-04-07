import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_theme.dart';

/// Glassmorphic multi-select question widget for quiz screens.
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
    final t = OnboardingTheme.of(context);

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
                color: t.textPrimary,
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: t.textSecondary,
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

                return _GlassOptionCard(
                  option: option,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(id);
                  },
                  index: index,
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

class _GlassOptionCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;
  final bool showDescription;

  const _GlassOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.index,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final color = option['color'] as Color? ?? AppColors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: t.cardSelectedGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : t.cardFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? t.borderSelected : t.borderDefault,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
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
                      gradient: LinearGradient(
                        colors: isSelected
                            ? t.iconContainerSelectedGradient
                            : t.iconContainerGradient(color),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? t.iconContainerSelectedBorder
                            : t.iconContainerBorder(color),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color: isSelected ? t.textPrimary : color,
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
                            color: t.textPrimary,
                          ),
                        ),
                        if (showDescription && option['description'] != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            option['description'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: t.textSecondary,
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
                      color: isSelected ? t.checkBg : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: t.checkBorderUnselected,
                              width: 2,
                            ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: t.checkIcon, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
