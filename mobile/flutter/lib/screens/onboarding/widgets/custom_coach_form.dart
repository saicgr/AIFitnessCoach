import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/coach_persona.dart';

/// Form for creating a custom coach persona.
class CustomCoachForm extends StatelessWidget {
  final String name;
  final String coachingStyle;
  final String communicationTone;
  final double encouragementLevel;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onStyleChanged;
  final ValueChanged<String> onToneChanged;
  final ValueChanged<double> onEncouragementChanged;

  const CustomCoachForm({
    super.key,
    required this.name,
    required this.coachingStyle,
    required this.communicationTone,
    required this.encouragementLevel,
    required this.onNameChanged,
    required this.onStyleChanged,
    required this.onToneChanged,
    required this.onEncouragementChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          Text(
            'Coach Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onNameChanged,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g., My Coach, Ace, etc.',
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
              filled: true,
              fillColor: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),

          // Coaching Style
          Text(
            'Coaching Style',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CoachingStyles.all.map((style) {
              final isSelected = coachingStyle == style['id'];
              return _buildChip(
                label: style['label']!,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onStyleChanged(style['id']!);
                },
                selectedColor: AppColors.accent,
                textSecondary: textSecondary,
                cardBorder: cardBorder,
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Communication Tone
          Text(
            'Communication Tone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CommunicationTones.all.map((tone) {
              final isSelected = communicationTone == tone['id'];
              return _buildChip(
                label: tone['label']!,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToneChanged(tone['id']!);
                },
                selectedColor: AppColors.accent,
                textSecondary: textSecondary,
                cardBorder: cardBorder,
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Encouragement Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Encouragement Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '${(encouragementLevel * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: cardBorder,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: encouragementLevel,
              onChanged: onEncouragementChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minimal',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
              Text(
                'Maximum',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color selectedColor,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selectedColor : cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? selectedColor : textSecondary,
          ),
        ),
      ),
    );
  }
}
