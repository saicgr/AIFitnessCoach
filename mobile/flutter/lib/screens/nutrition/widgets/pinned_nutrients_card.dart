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
  // Minimised by default — the card otherwise takes ~90 dp of vertical space
  // before users ever interact with it. Tap the header to toggle.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row — tap anywhere toggles expand/collapse.
          // Sentence case label, no count badge, no always-visible edit icon.
          // Edit pencil only appears when expanded (Task #6 cleanup).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Pinned nutrients',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Chips + edit icon revealed only when expanded.
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.pinned.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => _CompactNutrientChip(
                          nutrient: widget.pinned[i],
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onEdit != null)
                    GestureDetector(
                      onTap: widget.onEdit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.edit, size: 14, color: teal),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ultra-compact horizontal chip: [color dot] Name  value/target unit  [thin bar]
class _CompactNutrientChip extends StatelessWidget {
  final NutrientProgress nutrient;
  final bool isDark;

  const _CompactNutrientChip({
    required this.nutrient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Dynamic-pinned nutrients flagged `over_ceiling` (sodium / saturated fat
    // / added sugar that today's logs pushed past safe ceiling) render orange
    // regardless of the nutrient's normal color so the warning is unmistakable.
    final isOverCeilingPin = nutrient.pinReason == 'over_ceiling';
    final color = isOverCeilingPin
        ? (isDark ? AppColors.warning : AppColorsLight.warning)
        : Color(int.parse(nutrient.progressColor.replaceFirst('#', '0xFF')));
    final percentage = nutrient.percentage.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          // Name + value stacked
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nutrient.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${nutrient.formattedCurrent}/${nutrient.formattedTarget} ${nutrient.unit}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          // Tiny vertical progress bar
          SizedBox(
            width: 3,
            height: 20,
            child: RotatedBox(
              quarterTurns: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: elevated,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
