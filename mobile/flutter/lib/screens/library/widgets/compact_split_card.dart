import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ai_split_preset.dart';

/// Compact training split card (110px height vs old 160px).
///
/// Color-coded by category:
///   classic → slate gradient
///   ai_powered → orange/coral gradient with AI badge
///   specialty → purple/indigo gradient
class CompactSplitCard extends StatelessWidget {
  final AISplitPreset preset;
  final VoidCallback onTap;
  final int animationIndex;

  const CompactSplitCard({
    super.key,
    required this.preset,
    required this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _categoryColors(isDark);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 110,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.$1.withOpacity(0.2), colors.$2.withOpacity(0.12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.$1.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + AI badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (preset.isAIPowered) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.orange : AppColorsLight.orange).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.orange : AppColorsLight.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const Spacer(),

            // Schedule info
            Text(
              '${preset.daysPerWeek == 0 ? "Flex" : "${preset.daysPerWeek}d/wk"} · ${preset.duration}',
              style: TextStyle(fontSize: 11, color: textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Difficulty chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.$1.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                preset.difficulty.first,
                style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(delay: (animationIndex * 80).ms, duration: 300.ms)
        .slideX(begin: 0.15, delay: (animationIndex * 80).ms, duration: 300.ms);
  }

  (Color, Color) _categoryColors(bool isDark) {
    switch (preset.category) {
      case 'ai_powered':
        return (
          isDark ? AppColors.orange : AppColorsLight.orange,
          isDark ? AppColors.coral : AppColorsLight.coral,
        );
      case 'specialty':
        return (
          isDark ? AppColors.purple : AppColorsLight.purple,
          const Color(0xFF4338CA), // indigo
        );
      default: // classic
        return (
          isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), // slate
          isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        );
    }
  }
}
