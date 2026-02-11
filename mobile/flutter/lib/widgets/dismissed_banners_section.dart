import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../data/providers/daily_xp_strip_provider.dart';
import '../data/providers/xp_provider.dart';
import '../data/services/haptic_service.dart';

/// Compact section showing dismissed home banners with a restore button.
///
/// Used in Profile and XP Goals screens so users can re-enable
/// banners they swiped away on the home screen.
class DismissedBannersSection extends ConsumerWidget {
  const DismissedBannersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpStripDismissed = ref.watch(dailyXPStripDismissedTodayProvider);
    final dailyCrates = ref.watch(dailyCratesProvider);
    final hasDismissedCrate = dailyCrates != null && !dailyCrates.hasAvailableCrate;

    // Only show if at least one banner is dismissed
    if (!xpStripDismissed) {
      return const SizedBox.shrink();
    }

    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'DISMISSED BANNERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: textSecondary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (xpStripDismissed)
                _DismissedBannerItem(
                  icon: Icons.bolt,
                  label: 'Daily XP Goals',
                  isDark: isDark,
                  onRestore: () {
                    HapticService.light();
                    ref
                        .read(dailyXPStripDismissedTodayProvider.notifier)
                        .resetIfNewDay();
                    // Force undismiss by removing the SharedPrefs key
                    _undismissXPStrip(ref);
                  },
                ),
              const SizedBox(height: 8),
              Text(
                'Dismissed banners reset automatically at midnight.',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _undismissXPStrip(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('daily_xp_strip_dismissed_date');
    // Reload the provider state
    ref.invalidate(dailyXPStripDismissedTodayProvider);
  }
}

class _DismissedBannerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onRestore;

  const _DismissedBannerItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: onRestore,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Restore',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
