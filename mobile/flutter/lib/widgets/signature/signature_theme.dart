import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Signature v2 shared color/gradient helpers for the reusable widget kit.
///
/// These helpers exist so the program-facing surfaces (Programs screen, hero
/// carousel, poster rails) all derive difficulty + category color from ONE
/// place instead of each screen re-mapping strings.
///
/// NOTE on difficulty: programs use the capitalized human strings
/// "Beginner"/"Intermediate"/"Advanced"/"Elite". This is DISTINCT from the
/// exercise difficulty ladder (easy/medium/hard/hell) handled by
/// `DifficultyUtils.getColor`. Use [programDifficultyColor] for programs and
/// `DifficultyUtils` for exercises — do not mix them.

/// Maps a program difficulty string to its semantic accent color.
///
/// Case-insensitive. Recognizes "Beginner", "Intermediate", "Advanced",
/// "Elite" (and the common synonyms "easy"/"moderate"/"hard"). Anything
/// unrecognized — including null/empty — falls back to amber.
///
///   Beginner     → green  `#2ECC71`
///   Intermediate → amber  `#FFC54A`
///   Advanced     → orange `#F97316`
///   Elite        → red    `#EF4444`
Color programDifficultyColor(String? level) {
  switch ((level ?? '').toLowerCase().trim()) {
    case 'beginner':
    case 'easy':
    case 'novice':
      return const Color(0xFF2ECC71); // green
    case 'intermediate':
    case 'moderate':
      return const Color(0xFFFFC54A); // amber
    case 'advanced':
    case 'hard':
      return AppColors.orange; // orange #F97316
    case 'elite':
    case 'expert':
    case 'hell':
      return const Color(0xFFEF4444); // red
    default:
      return const Color(0xFFFFC54A); // amber fallback
  }
}

/// A category's visual identity: a two-stop gradient (for poster/hero headers)
/// + a representative accent color + a representative icon.
///
/// [accent] is the gradient's start color — use it for ribbons / dots / accent
/// text where a single flat tint is wanted.
@immutable
class CategoryTheme {
  /// Gradient start (also the canonical single-color [accent]).
  final Color start;

  /// Gradient end.
  final Color end;

  /// A representative icon for the category.
  final IconData icon;

  const CategoryTheme(this.start, this.end, this.icon);

  /// The category's single-tint accent (== [start]).
  Color get accent => start;

  /// A top-left → bottom-right gradient over the two stops.
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end],
      );

  /// A muted/translucent header gradient — the category tint dropped onto the
  /// dark scaffold so poster/hero headers read as "tinted dark", not neon.
  LinearGradient get headerGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(start.withValues(alpha: 0.34), AppColors.surface2),
          Color.alphaBlend(end.withValues(alpha: 0.16), AppColors.surface2),
        ],
      );
}

/// Resolves a program-category string to its [CategoryTheme].
///
/// Case-insensitive substring match. Aligned with
/// `program_library_card.dart`'s private `_ProgramCategoryTheme.forCategory`
/// so a program looks identical whether rendered by the old card or the new
/// signature poster/hero. Recognizes: Goal-Based, Sport Training, Specialized,
/// Women's/Men's Health, Pain Management, Stretching, Yoga, Celebrity,
/// Strength, Cardio. Unknown categories fall back to a neutral indigo accent.
CategoryTheme categoryTheme(String? programCategory) {
  final key = (programCategory ?? '').toLowerCase().trim();
  if (key.contains('celebrity')) {
    return const CategoryTheme(
        Color(0xFFEC4899), Color(0xFF8B5CF6), Icons.movie_rounded);
  }
  if (key.contains('sport')) {
    return const CategoryTheme(
        Color(0xFF06B6D4), Color(0xFF2563EB), Icons.sports_basketball_rounded);
  }
  if (key.contains('goal')) {
    return const CategoryTheme(
        Color(0xFFF97316), Color(0xFFE11D48), Icons.flag_rounded);
  }
  if (key.contains('special')) {
    return const CategoryTheme(
        Color(0xFF8B5CF6), Color(0xFF4338CA), Icons.auto_awesome_rounded);
  }
  if (key.contains('yoga')) {
    return const CategoryTheme(
        Color(0xFF22C55E), Color(0xFF0D9488), Icons.self_improvement_rounded);
  }
  if (key.contains('stretch')) {
    return const CategoryTheme(
        Color(0xFF14B8A6), Color(0xFF0891B2), Icons.accessibility_new_rounded);
  }
  if (key.contains('pain')) {
    return const CategoryTheme(
        Color(0xFF38BDF8), Color(0xFF1D4ED8), Icons.healing_rounded);
  }
  if (key.contains('women') || key.contains('men') || key.contains('health')) {
    return const CategoryTheme(
        Color(0xFFF472B6), Color(0xFF9333EA), Icons.favorite_rounded);
  }
  if (key.contains('cardio')) {
    return const CategoryTheme(
        Color(0xFFEF4444), Color(0xFFB91C1C), Icons.directions_run_rounded);
  }
  if (key.contains('strength')) {
    return const CategoryTheme(
        Color(0xFFF59E0B), Color(0xFFB45309), Icons.fitness_center_rounded);
  }
  // Authored / parsed / duplicated / unknown — neutral accent gradient.
  return const CategoryTheme(
      Color(0xFF6366F1), Color(0xFF312E81), Icons.list_alt_rounded);
}
