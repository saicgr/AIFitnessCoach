import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/glass_sheet.dart';

/// Introductory sheet shown when users first navigate to Programs tab.
/// Wrapped in the shared [GlassSheet] so it matches every other glass
/// bottom sheet in the app (blur 12, standard surface/border/handle) —
/// previously it hand-rolled a heavier, more opaque glass of its own.
class ProgramsIntroSheet extends StatelessWidget {
  const ProgramsIntroSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ThemeColors.of(context).accent;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    return GlassSheet(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.25),
                        accentColor.withValues(alpha: 0.1),
                      ],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 32,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        ).programsIntroWorkoutPrograms,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // What to expect section
            Text(
              AppLocalizations.of(context).programsIntroWhatYouCanExpect,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            _buildExpectationItem(
              icon: Icons.calendar_month_rounded,
              title: AppLocalizations.of(context).programsIntroFlexibleDuration,
              description: AppLocalizations.of(
                context,
              ).programsIntroProgramsFrom1To,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            _buildExpectationItem(
              icon: Icons.event_repeat_rounded,
              title: AppLocalizations.of(context).programsIntroCustomFrequency,
              description: AppLocalizations.of(
                context,
              ).programsIntro37WorkoutDays,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            _buildExpectationItem(
              icon: Icons.speed_rounded,
              title: AppLocalizations.of(context).xpGoalsScreenAllLevels,
              description: AppLocalizations.of(
                context,
              ).programsIntroBeginnerToAdvanced,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            _buildExpectationItem(
              icon: Icons.list_alt_rounded,
              title: AppLocalizations.of(context).programsIntro185Programs,
              description: AppLocalizations.of(
                context,
              ).programsIntroStrengthCardioMobilityM,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            _buildExpectationItem(
              icon: Icons.play_circle_outline_rounded,
              title: AppLocalizations.of(context).programsIntroVideoDemos,
              description: AppLocalizations.of(
                context,
              ).programsIntroProfessionalExerciseTutorial,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 24),

            // Program categories preview
            Text(
              AppLocalizations.of(context).programsIntroCategories,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryChip('Strength', accentColor),
                _buildCategoryChip('Weight Loss', accentColor),
                _buildCategoryChip('Muscle Building', accentColor),
                _buildCategoryChip('Athletic', accentColor),
                _buildCategoryChip('Home', accentColor),
                _buildCategoryChip('Bodyweight', accentColor),
                _buildCategoryChip('HIIT', accentColor),
                _buildCategoryChip('Yoga', accentColor),
              ],
            ),

            const SizedBox(height: 24),

            // CTA Button with glassmorphic style
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: [
                            accentColor.withValues(alpha: 0.8),
                            accentColor.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).programsIntroBrowsePrograms,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectationItem({
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: accentColor,
        ),
      ),
    );
  }
}
