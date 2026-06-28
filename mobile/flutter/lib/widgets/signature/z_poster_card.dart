import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'signature_theme.dart';

/// A compact ~118×154 poster card for horizontal rails (e.g. a "Featured
/// programs" row). A category-tinted gradient header sits above the body:
/// difficulty ribbon → name (2 lines) → a Space-Mono stat line.
///
/// Sizing is fixed by default so a `ListView`/`Row` of posters aligns cleanly;
/// override [width]/[height] if a rail needs a different module.
///
/// ```dart
/// ZPosterCard(
///   name: 'Push / Pull / Legs',
///   category: 'Goal-Based',
///   difficultyLevel: 'Intermediate',
///   stat: '6 WK · 5/WK',
///   onTap: () => context.push('/workout/program/$id'),
/// )
/// ```
class ZPosterCard extends StatelessWidget {
  /// Program / item name (clamped to 2 lines).
  final String name;

  /// Program category — drives the header gradient + icon via [categoryTheme].
  final String? category;

  /// Program difficulty string ("Beginner".."Elite"); drives the ribbon.
  /// When null/empty the ribbon is omitted.
  final String? difficultyLevel;

  /// A short Space-Mono stat line (e.g. "6 WK · 5/WK"). Omitted when null.
  final String? stat;

  /// Optional cover-art URL. When non-empty the poster becomes photo-forward
  /// (full-bleed image + scrim + text overlaid); otherwise the category
  /// gradient + glyph header is used.
  final String? imageUrl;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Card width. Defaults to 118.
  final double width;

  /// Card height. Defaults to 154.
  final double height;

  const ZPosterCard({
    super.key,
    required this.name,
    this.category,
    this.difficultyLevel,
    this.stat,
    this.imageUrl,
    this.onTap,
    this.width = 118,
    this.height = 154,
  });

  @override
  Widget build(BuildContext context) {
    final theme = categoryTheme(category);
    final hasDifficulty =
        difficultyLevel != null && difficultyLevel!.trim().isNotEmpty;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    final card = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: hasImage
          ? _imageContent(theme, hasDifficulty)
          : _gradientContent(theme, hasDifficulty),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }

  /// Category gradient header + glyph above name/stat — the image-free default.
  Widget _gradientContent(CategoryTheme theme, bool hasDifficulty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tinted gradient header with the category icon.
        Container(
          height: height * 0.42,
          decoration: BoxDecoration(gradient: theme.headerGradient),
          alignment: Alignment.center,
          child: Icon(
            theme.icon,
            size: 26,
            color: AppColors.textPrimary.withValues(alpha: 0.85),
          ),
        ),
        // Body.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasDifficulty) ...[
                  _DifficultyRibbon(level: difficultyLevel!),
                  const SizedBox(height: 6),
                ],
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ZType.sans(13,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w700,
                        height: 1.15),
                  ),
                ),
                if (stat != null && stat!.trim().isNotEmpty)
                  Text(
                    stat!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZType.data(9.5, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Photo-forward: full-bleed cover + 3-stop scrim, name/ribbon/stat overlaid
  /// at the bottom. Falls back to the gradient header if the image errors.
  Widget _imageContent(CategoryTheme theme, bool hasDifficulty) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          errorWidget: (_, __, ___) => DecoratedBox(
            decoration: BoxDecoration(gradient: theme.headerGradient),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x59000000), Color(0x26000000), Color(0xCC000000)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasDifficulty) ...[
                _DifficultyRibbon(level: difficultyLevel!),
                const SizedBox(height: 6),
              ],
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ZType.sans(13,
                    color: Colors.white,
                    weight: FontWeight.w700,
                    height: 1.15).copyWith(
                  shadows: const [
                    Shadow(
                      color: Color(0xB3000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (stat != null && stat!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  stat!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.data(9.5,
                      color: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A small Barlow uppercase difficulty ribbon: a colored dot + the level name
/// in the difficulty color. Shared by [ZPosterCard] and `ZHeroCard`.
class _DifficultyRibbon extends StatelessWidget {
  final String level;
  const _DifficultyRibbon({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = programDifficultyColor(level);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            level.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.lbl(9.5, color: color, letterSpacing: 1.2),
          ),
        ),
      ],
    );
  }
}

/// Public difficulty ribbon (dot + colored Barlow level label) for reuse by
/// any signature surface that needs the same marker outside a poster.
class ZDifficultyRibbon extends StatelessWidget {
  /// Program difficulty string ("Beginner".."Elite").
  final String level;

  /// Ribbon label size. Defaults to 9.5.
  final double size;

  const ZDifficultyRibbon({super.key, required this.level, this.size = 9.5});

  @override
  Widget build(BuildContext context) {
    final color = programDifficultyColor(level);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            level.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.lbl(size, color: color, letterSpacing: 1.2),
          ),
        ),
      ],
    );
  }
}
