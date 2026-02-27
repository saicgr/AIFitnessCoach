import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/usage_tracking_provider.dart';
import 'upgrade_prompt_sheet.dart';

/// Wraps a child widget and gates the [onAllowed] callback behind a usage check.
///
/// If the user has remaining uses for [featureKey], [onAllowed] is invoked.
/// Otherwise an [UpgradePromptSheet] is shown.
class PremiumGateAction extends ConsumerWidget {
  final String featureKey;
  final String? featureName;
  final Widget child;
  final VoidCallback onAllowed;

  const PremiumGateAction({
    super.key,
    required this.featureKey,
    this.featureName,
    required this.child,
    required this.onAllowed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final notifier = ref.read(usageTrackingProvider.notifier);
        if (notifier.hasAccess(featureKey)) {
          onAllowed();
        } else {
          showUpgradePromptSheet(
            context,
            featureKey: featureKey,
            featureName: featureName,
          );
        }
      },
      child: child,
    );
  }
}

/// Inline card shown for features with zero free uses.
/// Displays a lock icon, the feature name, and an upgrade button.
class PremiumLockCard extends ConsumerWidget {
  final String featureKey;
  final String featureName;
  final IconData icon;

  const PremiumLockCard({
    super.key,
    required this.featureKey,
    required this.featureName,
    this.icon = Icons.lock_outline_rounded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.orange : AppColorsLight.orange)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.orange : AppColorsLight.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featureName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Premium feature',
                  style: textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              showUpgradePromptSheet(
                context,
                featureKey: featureKey,
                featureName: featureName,
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: isDark ? AppColors.orange : AppColorsLight.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Unlock',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
