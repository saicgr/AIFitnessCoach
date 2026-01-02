import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/coach_persona.dart';

/// A card widget displaying a coach persona with selection state.
class CoachCard extends StatelessWidget {
  final CoachPersona coach;
  final bool isSelected;
  final VoidCallback onTap;

  const CoachCard({
    super.key,
    required this.coach,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    coach.primaryColor.withValues(alpha: 0.25),
                    coach.accentColor.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? coach.primaryColor : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Coach Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [coach.primaryColor, coach.accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : coach.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                coach.icon,
                color: isSelected ? Colors.white : coach.primaryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Coach Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and personality badge - wrap on smaller screens
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        coach.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? coach.primaryColor : textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: coach.primaryColor.withValues(alpha: isSelected ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          coach.personalityBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: coach.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Tagline
                  Text(
                    coach.tagline,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? textPrimary.withValues(alpha: 0.8)
                          : textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Specialization
                  Row(
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 12,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          coach.specialization,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [coach.primaryColor, coach.accentColor],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(color: cardBorder, width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
