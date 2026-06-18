/// Workout library grid — Signature v2.
///
/// 3×2 grid of category tiles (Strength / Cardio / Mobility / HIIT / Yoga
/// / Saved). Each tile routes to `LibraryScreen` (`/library`) with a
/// pre-applied category filter.
///
/// Restyled from the old photo/gradient art tiles to the Signature hairline
/// system that the rest of the Workouts tab uses: `surface2` fill, 1px
/// `cardBorder`, an accent-tinted category glyph, and a Barlow uppercase
/// label with a short accent underline. No bundled PNGs / gradients, so the
/// grid reads as part of the same monochrome-plus-one-accent surface as the
/// TODAY / THIS WEEK / PROGRAM blocks above it.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

class WorkoutLibraryGrid extends StatelessWidget {
  /// Outer gutter around the grid. Defaults to the legacy 16px; callers that
  /// already sit inside a padded column (e.g. the Signature body's 20px
  /// gutter) pass `EdgeInsets.zero` so the tiles align with their siblings.
  final EdgeInsetsGeometry padding;

  const WorkoutLibraryGrid({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    const categories = _categories;
    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // Explicit zero padding: a nested vertical GridView defaults to
        // primary:true and would otherwise inject the MediaQuery safe-area
        // insets (status bar / home indicator) as top+bottom padding, which
        // showed up as large phantom gaps above and below the grid.
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Slightly wider than tall — a compact glyph + label tile (the old
          // 0.82 portrait ratio was sized for the full-bleed art).
          childAspectRatio: 0.92,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
      ),
    );
  }

  static const List<_LibraryCategory> _categories = [
    _LibraryCategory(
        key: 'strength', label: 'Strength', icon: Icons.fitness_center_rounded),
    _LibraryCategory(
        key: 'cardio', label: 'Cardio', icon: Icons.directions_run_rounded),
    _LibraryCategory(
        key: 'mobility', label: 'Mobility', icon: Icons.self_improvement_rounded),
    _LibraryCategory(
        key: 'hiit', label: 'HIIT', icon: Icons.bolt_rounded),
    _LibraryCategory(
        key: 'yoga', label: 'Yoga', icon: Icons.spa_rounded),
    _LibraryCategory(
        key: 'saved', label: 'Saved', icon: Icons.bookmark_outline_rounded),
  ];
}

class _LibraryCategory {
  final String key;
  final String label;
  final IconData icon;
  const _LibraryCategory({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class _CategoryTile extends StatelessWidget {
  final _LibraryCategory category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Semantics(
      label: category.label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.selection();
            context.push('/library?category=${category.key}');
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tc.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(category.icon, size: 20, color: tc.accent),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.lbl(11.5,
                          color: tc.textPrimary, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    // Short accent underline — the one bit of color, echoing
                    // the program progress rule.
                    Container(
                      width: 18,
                      height: 2,
                      decoration: BoxDecoration(
                        color: tc.accent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
