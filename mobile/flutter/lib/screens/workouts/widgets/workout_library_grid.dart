/// Workout library grid — Surface 2.4 of the minimalist redesign.
///
/// 2×3 grid of category tiles (Strength / Cardio / Mobility / HIIT / Yoga
/// / Saved). Each tile routes to `LibraryScreen` (`/library`) with a
/// pre-applied category filter. Per-category illustrations live under
/// `assets/images/workout_types/` and are rendered with `Image.asset` —
/// when an asset is missing, the fail-soft `errorBuilder` falls through
/// to a category-tinted gradient so the tile is never blank.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

class WorkoutLibraryGrid extends StatelessWidget {
  const WorkoutLibraryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategories(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Tiles are slightly wider than tall — matches Google Health's
          // category grid where the illustration takes ~70% of the tile.
          childAspectRatio: 1.05,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
      ),
    );
  }

  List<_LibraryCategory> _buildCategories(BuildContext context) {
    return const [
      _LibraryCategory(
        key: 'strength',
        label: 'Strength',
        gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        assetPath: 'assets/images/workout_types/strength.png',
      ),
      _LibraryCategory(
        key: 'cardio',
        label: 'Cardio',
        gradient: [Color(0xFFEF4444), Color(0xFFF97316)],
        assetPath: 'assets/images/workout_types/cardio.png',
      ),
      _LibraryCategory(
        key: 'mobility',
        label: 'Mobility',
        gradient: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
        assetPath: 'assets/images/workout_types/mobility.png',
      ),
      _LibraryCategory(
        key: 'hiit',
        label: 'HIIT',
        gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        assetPath: 'assets/images/workout_types/hiit.png',
      ),
      _LibraryCategory(
        key: 'yoga',
        label: 'Yoga',
        gradient: [Color(0xFFA855F7), Color(0xFFEC4899)],
        assetPath: 'assets/images/workout_types/yoga.png',
      ),
      _LibraryCategory(
        key: 'saved',
        label: 'Saved',
        gradient: [Color(0xFF22C55E), Color(0xFF10B981)],
        assetPath: 'assets/images/workout_types/saved.png',
      ),
    ];
  }
}

class _LibraryCategory {
  final String key;
  final String label;
  final List<Color> gradient;
  final String assetPath;
  const _LibraryCategory({
    required this.key,
    required this.label,
    required this.gradient,
    required this.assetPath,
  });
}

class _CategoryTile extends StatelessWidget {
  final _LibraryCategory category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.selection();
          context.push('/library?category=${category.key}');
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient (always renders; the bundled illustration
              // overlays on top when the asset exists, otherwise the gradient
              // alone reads as a polished category tile).
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: category.gradient,
                  ),
                ),
              ),
              // Illustration overlay — fail-soft. A missing PNG simply
              // reveals the gradient layer beneath. Aligned to top so the
              // bottom-left label has clear backing.
              Image.asset(
                category.assetPath,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.2),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              // Bottom-fade scrim so the label reads on any illustration.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                      ],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    category.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Color(0x66000000),
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
