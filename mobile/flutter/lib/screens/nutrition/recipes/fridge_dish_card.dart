/// Full-bleed recipe "dish" card + its shared parts (network image with a
/// branded gradient fallback, the circular match-ring painter, and the
/// macro stat strip) used across the From-Your-Fridge results list, the
/// recipe detail sheet, and Cook Mode.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/ingredient_analysis.dart';

/// Dish photo from a network [imageUrl] with a branded gradient fallback when
/// the URL is null/empty or fails to load — never an external placeholder.
class FridgeDishImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;

  const FridgeDishImage({super.key, required this.imageUrl, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return const _BrandedFallback();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => const _BrandedFallback(),
      errorWidget: (_, __, ___) => const _BrandedFallback(),
    );
  }
}

class _BrandedFallback extends StatelessWidget {
  const _BrandedFallback();

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.of(context).accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface2,
            Color.alphaBlend(accent.withValues(alpha: 0.10), AppColors.pureBlack),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant_menu,
            size: 40, color: accent.withValues(alpha: 0.45)),
      ),
    );
  }
}

/// Circular match-percentage ring. Accent arc over a hairline track, with the
/// number + "MATCH" centred.
class FridgeMatchRing extends StatelessWidget {
  final int matchPercent;
  final double size;
  const FridgeMatchRing({super.key, required this.matchPercent, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.of(context).accent;
    final pct = matchPercent.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(pct / 100.0, accent),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$pct',
                  style: ZType.lbl(size * 0.30,
                      color: Colors.white, letterSpacing: 0)),
              Text('MATCH',
                  style: ZType.lbl(size * 0.14,
                      color: Colors.white70, letterSpacing: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  _RingPainter(this.progress, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawCircle(center, radius, fill);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = accent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90°, start at top
      6.28319 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.accent != accent;
}

/// MIN / KCAL / PROTEIN / CARBS / FAT strip with macro colors. [onDark] tints
/// the neutral values white (for use over a photo scrim).
class FridgeStatStrip extends StatelessWidget {
  final PantrySuggestion s;
  final bool onDark;
  final double valueSize;
  const FridgeStatStrip({
    super.key,
    required this.s,
    this.onDark = true,
    this.valueSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final neutral = onDark ? Colors.white : tc.textPrimary;
    final labelColor = onDark ? Colors.white60 : tc.textMuted;
    final min = s.totalTimeMinutes;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        if (min != null) _stat('$min', 'MIN', neutral, labelColor),
        if (s.caloriesPerServing != null && s.caloriesPerServing! > 0)
          _stat('${s.caloriesPerServing}', 'KCAL', neutral, labelColor),
        if (s.proteinPerServingG != null)
          _stat(s.proteinPerServingG!.toStringAsFixed(0), 'PROTEIN',
              AppColors.macroProtein, labelColor),
        if (s.carbsPerServingG != null)
          _stat(s.carbsPerServingG!.toStringAsFixed(0), 'CARBS',
              AppColors.macroCarbs, labelColor),
        if (s.fatPerServingG != null)
          _stat(s.fatPerServingG!.toStringAsFixed(0), 'FAT', AppColors.macroFat,
              labelColor),
      ],
    );
  }

  Widget _stat(String value, String label, Color valueColor, Color labelColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: ZType.lbl(valueSize, color: valueColor, letterSpacing: 0)),
        const SizedBox(width: 3),
        Text(label, style: ZType.lbl(valueSize * 0.55, color: labelColor, letterSpacing: 0.8)),
      ],
    );
  }
}

/// Full-bleed dish card for the results list.
class FridgeDishCard extends StatelessWidget {
  final PantrySuggestion suggestion;
  final VoidCallback onTap;

  /// Called with a single missing-ingredient label when the amber
  /// `+ missing → list` pill is tapped.
  final void Function(String missing) onAddToGrocery;

  const FridgeDishCard({
    super.key,
    required this.suggestion,
    required this.onTap,
    required this.onAddToGrocery,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final amber = tc.warning;
    final have = suggestion.matchedPantryItems.length;
    final missing = suggestion.missingIngredients;
    final need = missing.length;
    final total = have + need;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 216,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FridgeDishImage(imageUrl: suggestion.imageUrl),
                // Bottom-weighted scrim so the title + stats stay legible.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.25, 1.0],
                      colors: [Colors.transparent, Color(0xE6040604)],
                    ),
                  ),
                ),
                if (suggestion.imageUrl != null)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Text(
                      suggestion.photoCredit,
                      style: ZType.lbl(8.5, color: Colors.white54, letterSpacing: 1),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: FridgeMatchRing(matchPercent: suggestion.overallMatchScore),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ZType.disp(20, color: Colors.white, letterSpacing: 0.4)
                            .copyWith(height: 1.05),
                      ),
                      const SizedBox(height: 7),
                      FridgeStatStrip(s: suggestion),
                      const SizedBox(height: 8),
                      _HaveBar(
                        have: have,
                        total: total,
                        accent: accent,
                        amber: amber,
                        firstMissing: missing.isEmpty ? null : missing.first,
                        onAddToGrocery: onAddToGrocery,
                      ),
                    ],
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

class _HaveBar extends StatelessWidget {
  final int have;
  final int total;
  final Color accent;
  final Color amber;
  final String? firstMissing;
  final void Function(String missing) onAddToGrocery;

  const _HaveBar({
    required this.have,
    required this.total,
    required this.accent,
    required this.amber,
    required this.firstMissing,
    required this.onAddToGrocery,
  });

  @override
  Widget build(BuildContext context) {
    // Cap the dot bar so a large ingredient list can't overflow the card.
    final shown = total.clamp(0, 8);
    final missCount = total - have;
    final label = missCount <= 0
        ? 'you have all $have · nothing missing'
        : 'you have $have of $total';
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < shown; i++)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < have ? accent : Colors.transparent,
                    border: i < have ? null : Border.all(color: amber, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10.5),
          ),
        ),
        if (firstMissing != null) ...[
          const SizedBox(width: 8),
          _NeedPill(
            missing: firstMissing!,
            amber: amber,
            onTap: () => onAddToGrocery(firstMissing!),
          ),
        ],
      ],
    );
  }
}

class _NeedPill extends StatelessWidget {
  final String missing;
  final Color amber;
  final VoidCallback onTap;
  const _NeedPill({required this.missing, required this.amber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: amber.withValues(alpha: 0.55)),
        ),
        child: Text(
          '+ $missing → list',
          style: ZType.lbl(10, color: amber, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
