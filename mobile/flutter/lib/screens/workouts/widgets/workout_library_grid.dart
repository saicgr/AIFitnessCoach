/// Workout library grid — Surface 2.4 of the minimalist redesign.
///
/// 3×2 grid of category tiles (Strength / Cardio / Mobility / HIIT / Yoga
/// / Saved). Each tile routes to `LibraryScreen` (`/library`) with a
/// pre-applied category filter. Per-category illustrations live under
/// `assets/images/workout_types/` and are rendered with `Image.asset` —
/// when an asset is missing, the fail-soft `errorBuilder` falls through
/// to a category-tinted gradient so the tile is never blank.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        // Explicit zero padding: a nested vertical GridView defaults to
        // primary:true and would otherwise inject the MediaQuery safe-area
        // insets (status bar / home indicator) as top+bottom padding, which
        // showed up as large phantom gaps above and below the grid.
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Matches the source tile art aspect (~385x470) so the illustration
          // and its baked-in label fill the tile with no cropping.
          childAspectRatio: 0.82,
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
    // The bundled tile art is self-contained — its rounded corners are baked
    // into the PNG with the area outside the card masked transparent, and it
    // carries its own bottom scrim + category label. So we render it directly
    // (no surrounding clip/border/gradient that would show square edges behind
    // the rounded art). Its ~385x470 aspect matches the tile's childAspectRatio
    // so cover shows the whole illustration uncropped. Screen readers get the
    // label via Semantics since it lives in the bitmap.
    return Semantics(
      label: category.label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticService.selection();
            context.push('/library?category=${category.key}');
          },
          child: Image.asset(
            category.assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => _FallbackTile(category: category),
          ),
        ),
      ),
    );
  }
}

/// Shown only when the bundled tile PNG is missing — a category-tinted rounded
/// card with a bottom scrim and the label, so the tile still reads cleanly.
class _FallbackTile extends StatelessWidget {
  final _LibraryCategory category;
  const _FallbackTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: category.gradient,
              ),
            ),
          ),
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
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(
                  category.label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
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
          ),
        ],
      ),
    );
  }
}
