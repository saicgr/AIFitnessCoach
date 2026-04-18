import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/haptic_service.dart';

/// A suggested exercise for quick-add chips.
class SuggestedExercise {
  final String name;
  final String muscleGroup;
  final IconData icon;

  const SuggestedExercise({
    required this.name,
    required this.muscleGroup,
    this.icon = Icons.fitness_center,
  });
}

/// Curated list of popular compound lifts that make great staples.
const List<SuggestedExercise> kPopularStaples = [
  SuggestedExercise(name: 'Barbell Bench Press', muscleGroup: 'Chest'),
  SuggestedExercise(name: 'Barbell Back Squat', muscleGroup: 'Quadriceps'),
  SuggestedExercise(name: 'Barbell Deadlift', muscleGroup: 'Back'),
  SuggestedExercise(name: 'Barbell Overhead Press', muscleGroup: 'Shoulders'),
  SuggestedExercise(name: 'Pull-Up', muscleGroup: 'Back'),
  SuggestedExercise(name: 'Barbell Row', muscleGroup: 'Back'),
  SuggestedExercise(name: 'Romanian Deadlift', muscleGroup: 'Hamstrings'),
  SuggestedExercise(name: 'Dumbbell Bench Press', muscleGroup: 'Chest'),
  SuggestedExercise(name: 'Dips', muscleGroup: 'Triceps'),
  SuggestedExercise(name: 'Hip Thrust', muscleGroup: 'Glutes'),
  SuggestedExercise(name: 'Plank', muscleGroup: 'Core'),
  SuggestedExercise(name: 'Dumbbell Shoulder Press', muscleGroup: 'Shoulders'),
];

/// Curated list of popular exercises people love as favorites.
const List<SuggestedExercise> kPopularFavorites = [
  SuggestedExercise(name: 'Dumbbell Bicep Curl', muscleGroup: 'Biceps'),
  SuggestedExercise(name: 'Lat Pulldown', muscleGroup: 'Back'),
  SuggestedExercise(name: 'Incline Dumbbell Press', muscleGroup: 'Chest'),
  SuggestedExercise(name: 'Leg Press', muscleGroup: 'Quadriceps'),
  SuggestedExercise(name: 'Cable Tricep Pushdown', muscleGroup: 'Triceps'),
  SuggestedExercise(name: 'Lateral Raise', muscleGroup: 'Shoulders'),
  SuggestedExercise(name: 'Face Pull', muscleGroup: 'Shoulders'),
  SuggestedExercise(name: 'Hammer Curl', muscleGroup: 'Biceps'),
  SuggestedExercise(name: 'Leg Curl', muscleGroup: 'Hamstrings'),
  SuggestedExercise(name: 'Cable Row', muscleGroup: 'Back'),
  SuggestedExercise(name: 'Goblet Squat', muscleGroup: 'Quadriceps'),
  SuggestedExercise(name: 'Calf Raise', muscleGroup: 'Calves'),
];

/// Shared, rich empty state for Favorites and Staples tabs.
///
/// Renders:
/// 1. Animated hero card with icon + tagline + description
/// 2. "Quick add" section with tappable suggestion chips
/// 3. Full-width primary button that opens the exercise library picker
class EmptyStateWithSuggestions extends StatelessWidget {
  final IconData heroIcon;
  final Color accentColor;
  final String heroTitle;
  final String heroSubtitle;
  final String sectionLabel;
  final String primaryButtonLabel;
  final IconData primaryButtonIcon;
  final List<SuggestedExercise> suggestions;
  final Future<void> Function(SuggestedExercise) onSuggestionTap;
  final VoidCallback onBrowseLibrary;

  const EmptyStateWithSuggestions({
    super.key,
    required this.heroIcon,
    required this.accentColor,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.sectionLabel,
    required this.primaryButtonLabel,
    required this.primaryButtonIcon,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onBrowseLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        // --- Hero card ---
        _HeroCard(
          icon: heroIcon,
          accent: accentColor,
          title: heroTitle,
          subtitle: heroSubtitle,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          elevated: elevated,
          cardBorder: cardBorder,
        ),

        const SizedBox(height: 24),

        // --- Quick-add section label ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: accentColor),
              const SizedBox(width: 6),
              Text(
                sectionLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

        const SizedBox(height: 12),

        // --- Suggestion chips ---
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < suggestions.length; i++)
              _SuggestionChip(
                suggestion: suggestions[i],
                accent: accentColor,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                elevated: elevated,
                cardBorder: cardBorder,
                onTap: () => onSuggestionTap(suggestions[i]),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 250 + (i * 40)),
                    duration: 280.ms,
                  )
                  .slideY(begin: 0.1, end: 0, duration: 280.ms),
          ],
        ),

        const SizedBox(height: 28),

        // --- Browse library button ---
        _PrimaryBrowseButton(
          label: primaryButtonLabel,
          icon: primaryButtonIcon,
          accent: accentColor,
          onTap: onBrowseLibrary,
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 250 + (suggestions.length * 40)),
              duration: 300.ms,
            )
            .slideY(begin: 0.15, end: 0),
      ],
    );
  }
}

/// Animated hero card at the top of the empty state.
class _HeroCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color elevated;
  final Color cardBorder;

  const _HeroCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.elevated,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.18 : 0.12),
            accent.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: accent, size: 28),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 1800.ms,
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(
          begin: -0.1,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 400.ms,
        );
  }
}

/// Tappable suggestion chip with muscle-group label + icon.
class _SuggestionChip extends StatelessWidget {
  final SuggestedExercise suggestion;
  final Color accent;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final Color cardBorder;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.suggestion,
    required this.accent,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    suggestion.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    suggestion.muscleGroup,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width primary action button that opens the exercise-library picker.
class _PrimaryBrowseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _PrimaryBrowseButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.82)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
