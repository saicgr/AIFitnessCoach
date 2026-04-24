import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Compact Body Age badge. Delta negative (younger) is green, positive
/// (older) is amber — NASM body-age convention.
class BodyAgeBadge extends StatelessWidget {
  final int bodyAge;
  final int chronologicalAge;
  final bool isDark;

  const BodyAgeBadge({
    super.key,
    required this.bodyAge,
    required this.chronologicalAge,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final delta = bodyAge - chronologicalAge;
    final younger = delta < 0;
    final color = delta == 0
        ? (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
        : younger
            ? const Color(0xFF2ECC71)
            : const Color(0xFFF5A623);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final sign = delta > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Body age $bodyAge',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                delta == 0
                    ? 'Matches your age'
                    : '$sign$delta yr vs actual',
                style: TextStyle(fontSize: 10, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
