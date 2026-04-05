import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/micronutrients.dart';

class PinnedNutrientsCard extends StatefulWidget {
  final List<NutrientProgress> pinned;
  final bool isDark;
  final VoidCallback? onEdit;

  const PinnedNutrientsCard({
    super.key,
    required this.pinned,
    required this.isDark,
    this.onEdit,
  });

  @override
  State<PinnedNutrientsCard> createState() => _PinnedNutrientsCardState();
}

class _PinnedNutrientsCardState extends State<PinnedNutrientsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final elevated =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - always visible, tappable
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Text(
                  'PINNED NUTRIENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.pinned.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: teal,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onEdit,
                  icon: Icon(Icons.edit, size: 14, color: textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit Pinned Nutrients',
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: textMuted,
                ),
              ],
            ),
          ),
          // Expandable chips
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.pinned.map((nutrient) {
                  return _PinnedNutrientChip(
                    nutrient: nutrient,
                    isDark: widget.isDark,
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _PinnedNutrientChip extends StatelessWidget {
  final NutrientProgress nutrient;
  final bool isDark;

  const _PinnedNutrientChip({
    required this.nutrient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final color = Color(
        int.parse(nutrient.progressColor.replaceFirst('#', '0xFF')));
    final percentage = nutrient.percentage.clamp(0.0, 100.0);

    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nutrient name
          Text(
            nutrient.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: elevated,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          // Current / Target + Unit combined
          Text(
            '${nutrient.formattedCurrent}/${nutrient.formattedTarget} ${nutrient.unit}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
