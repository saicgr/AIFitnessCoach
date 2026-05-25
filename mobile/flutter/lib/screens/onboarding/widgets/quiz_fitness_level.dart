import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'onboarding_theme.dart';

/// Glassmorphic combined fitness level, training experience, and activity level widget.
class QuizFitnessLevel extends StatelessWidget {
  final String? selectedLevel;
  final String? selectedExperience;
  final String? selectedActivityLevel;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onExperienceChanged;
  final ValueChanged<String>? onActivityLevelChanged;
  final bool showHeader;

  const QuizFitnessLevel({
    super.key,
    required this.selectedLevel,
    required this.selectedExperience,
    this.selectedActivityLevel,
    required this.onLevelChanged,
    required this.onExperienceChanged,
    this.onActivityLevelChanged,
    this.showHeader = true,
  });

  static List<Map<String, Object>> _buildLevels(AppLocalizations l10n) => [
    {
      'id': 'beginner',
      'label': l10n.quizFitnessLevelBeginner,
      'icon': Icons.eco_outlined,
      'color': AppColors.green,
      'description': l10n.quizFitnessLevelBeginnerDesc,
    },
    {
      'id': 'intermediate',
      'label': l10n.quizFitnessLevelIntermediate,
      'icon': Icons.trending_up,
      'color': AppColors.onboardingAccent,
      'description': l10n.quizFitnessLevelIntermediateDesc,
    },
    {
      'id': 'advanced',
      'label': l10n.quizFitnessLevelAdvanced,
      'icon': Icons.rocket_launch_outlined,
      'color': AppColors.purple,
      'description': l10n.quizFitnessLevelAdvancedDesc,
    },
  ];

  static List<Map<String, String>> _buildExperienceOptions(AppLocalizations l10n) => [
    {'id': 'never', 'label': l10n.quizFitnessLevelNever, 'description': l10n.quizFitnessLevelBrandNewToLifting},
    {'id': 'less_than_6_months', 'label': l10n.quizFitnessLevelLessThan6Months, 'description': l10n.quizFitnessLevelJustGettingStarted},
    {'id': '6_months_to_2_years', 'label': l10n.quizFitnessLevel6MonTo2Yrs, 'description': l10n.quizFitnessLevelBuildingConsistency},
    {'id': '2_to_5_years', 'label': l10n.quizFitnessLevel2To5Years, 'description': l10n.quizFitnessLevelSolidFoundation},
    {'id': '5_plus_years', 'label': l10n.quizFitnessLevel5PlusYears, 'description': l10n.quizFitnessLevelVeteranLifter},
  ];

  static List<Map<String, String>> _buildActivityLevelOptions(AppLocalizations l10n) => [
    {'id': 'sedentary', 'emoji': '\u{1FA91}', 'label': l10n.quizFitnessLevelSedentary, 'description': l10n.quizFitnessLevelSedentaryDesc},
    {'id': 'lightly_active', 'emoji': '\u{1F6B6}', 'label': l10n.quizFitnessLevelLight, 'description': l10n.quizFitnessLevelLightDesc},
    {'id': 'moderately_active', 'emoji': '\u{1F3C3}', 'label': l10n.quizFitnessLevelModerate, 'description': l10n.quizFitnessLevelModerateDesc},
    {'id': 'very_active', 'emoji': '\u{26A1}', 'label': l10n.quizFitnessLevelVeryActive, 'description': l10n.quizFitnessLevelVeryActiveDesc},
  ];

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Text(
                AppLocalizations.of(context)!.quizFitnessLevelWhatSYourCurrent,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.quizFitnessLevelBeHonestWeLl,
                style: TextStyle(
                  fontSize: 14,
                  color: t.textSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
            ],
            ..._buildLevelCards(context, t),
            if (selectedLevel != null) ...[
              const SizedBox(height: 20),
              _buildExperienceSection(context, t),
            ],
            if (selectedExperience != null && onActivityLevelChanged != null) ...[
              const SizedBox(height: 20),
              _buildActivityLevelSection(context, t),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLevelCards(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    return _buildLevels(l10n).asMap().entries.map((entry) {
      final index = entry.key;
      final level = entry.value;
      final isSelected = selectedLevel == level['id'];

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onLevelChanged(level['id'] as String);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      level['icon'] as IconData,
                      color: level['color'] as Color,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            level['description'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: t.textMuted,
                            ),
                          ),
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
                            : Border.all(color: t.checkBorderUnselected, width: 2),
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
        ).animate(delay: (100 + index * 50).ms).fadeIn().slideX(begin: 0.05),
      );
    }).toList();
  }

  Widget _buildExperienceSection(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    final experienceOptions = _buildExperienceOptions(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quizFitnessLevelHowLongHaveYou,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textPrimary),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 4),
        Text(
          l10n.quizFitnessLevelThisHelpsUsPick,
          style: TextStyle(fontSize: 12, color: t.textMuted),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: experienceOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedExperience == option['id'];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onExperienceChanged(option['id'] as String);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: t.cardSelectedGradient,
                            )
                          : null,
                      color: isSelected ? null : t.cardFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? t.borderSelected : t.borderDefault,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ).animate(delay: (200 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityLevelSection(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    final activityLevelOptions = _buildActivityLevelOptions(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quizFitnessLevelDailyActivityLevelOutside,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textPrimary),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 4),
        Text(
          l10n.quizFitnessLevelHelpsCalculateYourCalorie,
          style: TextStyle(fontSize: 12, color: t.textMuted),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activityLevelOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedActivityLevel == option['id'];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onActivityLevelChanged?.call(option['id'] as String);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: t.cardSelectedGradient,
                            )
                          : null,
                      color: isSelected ? null : t.cardFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? t.borderSelected : t.borderDefault,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(option['emoji'] as String, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate(delay: (200 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
      ],
    );
  }
}
