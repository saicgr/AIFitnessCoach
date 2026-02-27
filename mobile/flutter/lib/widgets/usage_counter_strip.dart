import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/usage_tracking_provider.dart';

/// Horizontal row of pill-shaped counters showing remaining free uses.
///
/// Displays pills for food_scanning, ai_workout_generation, and text_to_calories.
/// Hidden when the user is premium.
class UsageCounterStrip extends ConsumerWidget {
  const UsageCounterStrip({super.key});

  static const _features = [
    _FeatureInfo('food_scanning', Icons.camera_alt_rounded, 'Scans'),
    _FeatureInfo('ai_workout_generation', Icons.fitness_center_rounded, 'Workouts'),
    _FeatureInfo('text_to_calories', Icons.text_fields_rounded, 'Text-cal'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageTrackingProvider);

    if (state.isPremium) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < _features.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _UsagePill(
                feature: _features[i],
                remaining: ref
                    .read(usageTrackingProvider.notifier)
                    .remainingUses(_features[i].key),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureInfo {
  final String key;
  final IconData icon;
  final String label;
  const _FeatureInfo(this.key, this.icon, this.label);
}

class _UsagePill extends StatelessWidget {
  final _FeatureInfo feature;
  final int? remaining;

  const _UsagePill({required this.feature, this.remaining});

  Color _pillColor(bool isDark) {
    if (remaining == null) return isDark ? AppColors.success : AppColorsLight.success;
    if (remaining! >= 2) return isDark ? AppColors.success : AppColorsLight.success;
    if (remaining! == 1) return isDark ? AppColors.warning : AppColorsLight.warning;
    return isDark ? AppColors.error : AppColorsLight.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _pillColor(isDark);
    final displayCount = remaining ?? 0;

    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(feature.icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$displayCount left',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
