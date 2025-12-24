import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../widgets/section_header.dart';

/// The haptics section for configuring haptic feedback settings.
///
/// Allows users to select their preferred haptic feedback intensity.
class HapticsSection extends StatelessWidget {
  const HapticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'HAPTICS'),
        SizedBox(height: 12),
        _HapticsSettingsCard(),
      ],
    );
  }
}

class _HapticsSettingsCard extends ConsumerWidget {
  const _HapticsSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hapticLevel = ref.watch(hapticLevelProvider);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Haptic level selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.vibration,
                  color: textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Haptic Feedback',
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        hapticLevel.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),
          // Level options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: HapticLevel.values.map((level) {
                final isSelected = hapticLevel == level;
                return GestureDetector(
                  onTap: () {
                    ref.read(hapticLevelProvider.notifier).setLevel(level);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.cyan.withOpacity(0.2)
                              : AppColorsLight.cyan.withOpacity(0.15))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                            : cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getIconForLevel(level),
                          size: 20,
                          color: isSelected
                              ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                              : textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          level.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                                : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLevel(HapticLevel level) {
    switch (level) {
      case HapticLevel.off:
        return Icons.notifications_off_outlined;
      case HapticLevel.light:
        return Icons.vibration;
      case HapticLevel.medium:
        return Icons.edgesensor_high;
      case HapticLevel.strong:
        return Icons.vibration;
    }
  }
}
