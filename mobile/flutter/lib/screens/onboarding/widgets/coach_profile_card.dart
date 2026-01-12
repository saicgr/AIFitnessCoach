import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/coach_persona.dart';

/// Enhanced coach profile card for the swipeable PageView selection.
/// Shows coach personality preview with sample message bubble.
class CoachProfileCard extends StatelessWidget {
  final CoachPersona coach;
  final bool isSelected;
  final VoidCallback? onTap;

  const CoachProfileCard({
    super.key,
    required this.coach,
    required this.isSelected,
    this.onTap,
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
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    coach.primaryColor.withValues(alpha: 0.15),
                    coach.accentColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.elevated : AppColorsLight.elevated),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? coach.primaryColor : cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: coach.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient and icon
            _buildHeader(isDark, textPrimary, textSecondary),

            // Content section - just sample message, no traits/specialization to save space
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildSampleMessage(isDark, textPrimary, textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            coach.primaryColor.withValues(alpha: 0.8),
            coach.accentColor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(23),
          topRight: Radius.circular(23),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coach icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              coach.icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),

          // Coach name
          Text(
            coach.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 2),

          // Tagline
          Text(
            coach.tagline,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          // Selected badge
          if (isSelected) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 11),
                  SizedBox(width: 3),
                  Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSampleMessage(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 11,
              color: textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'How they talk',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.glassSurface
                : AppColorsLight.glassSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: coach.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            coach.sampleMessage,
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: textPrimary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalityTraits(bool isDark, Color textSecondary) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: coach.personalityTraits.take(4).map((trait) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: coach.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: coach.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            trait,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: coach.primaryColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialization(bool isDark, Color textSecondary) {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 14,
          color: coach.accentColor,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            coach.specialization,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
