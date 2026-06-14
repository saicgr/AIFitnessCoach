/// Reusable recipe card — grid-style tile used across Discover, Favorites,
/// and the "My Recipes" grid in [RecipesTab].
///
/// Displays:
///  - Cover image (or a tinted placeholder if missing)
///  - Name (up to 2 lines)
///  - Calories + times-logged badge
///  - Filled red heart overlay (top-right) when [RecipeSummary.isFavorited]
///  - Optional source pill (top-left) when [showSourceBadge] is true AND the
///    recipe has a distinct source ("Curated" / "Improvized" / "Imported").
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/recipe.dart';
import '../../../../l10n/generated/app_localizations.dart';

class RecipeCard extends StatelessWidget {
  final RecipeSummary summary;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// When true, shows a top-left source pill ("Curated" / "Improvized" /
  /// "Imported") when the recipe has a distinct enough source to warrant it.
  /// Defaults to false so ordinary "My Recipes" grids stay visually clean.
  final bool showSourceBadge;

  const RecipeCard({
    super.key,
    required this.summary,
    required this.isDark,
    required this.accent,
    required this.onTap,
    this.onLongPress,
    this.showSourceBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final text = tc.textPrimary;
    final muted = tc.textMuted;
    final surface = tc.surface;
    final l10n = AppLocalizations.of(context);

    final badge = showSourceBadge ? _resolveSourceBadge(summary, l10n) : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cover image + overlay badges ──────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: summary.imageUrl != null
                          ? Image.network(
                              summary.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),

                  // Source badge (top-left)
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _SourcePill(
                        label: badge.label,
                        icon: badge.icon,
                        color: badge.color,
                      ),
                    ),

                  // Favorited heart (top-right)
                  if (summary.isFavorited)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: _HeartOverlay(),
                    ),
                ],
              ),
            ),

            // ── Title + meta row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (summary.caloriesPerServing != null) ...[
                        Text(
                          '${summary.caloriesPerServing}',
                          style: ZType.data(13, color: text),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'KCAL',
                          style: ZType.lbl(9, color: muted, letterSpacing: 1.3),
                        ),
                      ],
                      if (summary.timesLogged > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.cardBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '×${summary.timesLogged}',
                            style: ZType.lbl(10,
                                color: accent, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.elevated,
        child: Center(
          child: Icon(Icons.restaurant_menu,
              size: 36, color: AppColors.textMuted.withValues(alpha: 0.5)),
        ),
      );

  /// Decide which source pill (if any) to show. Returns null for vanilla
  /// "manual" recipes — they don't need a badge since they're the default.
  _SourceBadge? _resolveSourceBadge(RecipeSummary s, AppLocalizations l10n) {
    // Curated takes top priority — the shared/community library tag.
    if (s.isCurated) {
      return _SourceBadge(
        label: l10n.recipeCardCurated,
        icon: Icons.verified_rounded,
        color: const Color(0xFFFFB020), // warm gold
      );
    }

    final srcType = (s.sourceType ?? '').toLowerCase();

    // Improvized / cloned — user cloned and tweaked someone else's recipe.
    if (srcType == 'improvized' || s.sourceRecipeId != null) {
      return _SourceBadge(
        label: l10n.recipeCardImprovized,
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFB388FF), // purple
      );
    }

    // Imported URL / text / handwritten etc.
    if (srcType.startsWith('imported')) {
      return _SourceBadge(
        label: l10n.recipeCardImported,
        icon: Icons.download_rounded,
        color: const Color(0xFF40C4FF), // blue
      );
    }

    // AI-generated
    if (srcType == 'ai_generated') {
      return _SourceBadge(
        label: l10n.recipeCardAi,
        icon: Icons.auto_awesome,
        color: const Color(0xFF69F0AE), // green
      );
    }

    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SourceBadge {
  final String label;
  final IconData icon;
  final Color color;
  _SourceBadge({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _SourcePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SourcePill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: ZType.lbl(9, color: Colors.white, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}

class _HeartOverlay extends StatelessWidget {
  const _HeartOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
      ),
      child: const Icon(
        Icons.favorite,
        color: Color(0xFFFF3B30), // iOS-red
        size: 16,
      ),
    );
  }
}
