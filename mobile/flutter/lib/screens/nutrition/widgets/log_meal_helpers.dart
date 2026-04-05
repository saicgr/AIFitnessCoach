import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Nutrition info row for barcode product details
class NutritionInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const NutritionInfoRow({super.key, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textMuted)),
          Text(value, style: TextStyle(color: textSecondary)),
        ],
      ),
    );
  }
}

/// Nutri-Score badge (A-E)
class NutriscoreBadge extends StatelessWidget {
  final String grade;
  final bool isDark;

  const NutriscoreBadge({super.key, required this.grade, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final g = grade.toUpperCase();
    final color = switch (g) {
      'A' => const Color(0xFF038141),
      'B' => const Color(0xFF85BB2F),
      'C' => const Color(0xFFFECB02),
      'D' => const Color(0xFFEE8100),
      _ => const Color(0xFFE63E11),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nutri-Score ',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
          Text(g,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

/// NOVA processing group badge (1-4)
class NovaBadge extends StatelessWidget {
  final int group;
  final bool isDark;

  const NovaBadge({super.key, required this.group, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = switch (group) {
      1 => const Color(0xFF038141),
      2 => const Color(0xFF85BB2F),
      3 => const Color(0xFFEE8100),
      _ => const Color(0xFFE63E11),
    };
    final label = switch (group) {
      1 => 'Unprocessed',
      2 => 'Processed ingredients',
      3 => 'Processed',
      _ => 'Ultra-processed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NOVA $group ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
        ],
      ),
    );
  }
}

/// Rainbow-colored nutrition card for AI estimates
class RainbowNutritionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;
  final bool compact;

  const RainbowNutritionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                      TextSpan(text: ' $unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
                            TextSpan(text: ' $unit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Confidence indicator for AI estimates
class ConfidenceIndicator extends StatelessWidget {
  final String confidenceLevel;
  final double? confidenceScore;
  final String? sourceType;
  final bool isDark;

  const ConfidenceIndicator({
    super.key,
    required this.confidenceLevel,
    this.confidenceScore,
    this.sourceType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor;
    final IconData indicatorIcon;
    final String displayText;
    final String subText;

    switch (confidenceLevel) {
      case 'high':
        indicatorColor = isDark ? AppColors.green : AppColorsLight.green;
        indicatorIcon = Icons.verified;
        displayText = 'High confidence';
        subText = sourceType == 'barcode' ? 'Verified from barcode' : 'AI analysis confident';
        break;
      case 'medium':
        indicatorColor = isDark ? AppColors.orange : AppColorsLight.orange;
        indicatorIcon = Icons.info_outline;
        displayText = 'Medium confidence';
        subText = sourceType == 'restaurant'
            ? 'Restaurant estimate - actual may vary'
            : 'AI estimate - values may vary slightly';
        break;
      case 'low':
      default:
        indicatorColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
        indicatorIcon = Icons.help_outline;
        displayText = 'Estimate only';
        subText = 'Please verify these values';
        break;
    }

    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(indicatorIcon, size: 16, color: indicatorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(displayText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: indicatorColor)),
                    if (confidenceScore != null) ...[
                      const SizedBox(width: 6),
                      Text('(${(confidenceScore! * 100).toInt()}%)', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ],
                ),
                Text(subText, style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action icon button (glassmorphic circular icon for bottom bar)
class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isActive;

  const ActionIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    const orange = Color(0xFFF97316);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? orange : glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? orange
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : textMuted,
        ),
      ),
    );
  }
}
