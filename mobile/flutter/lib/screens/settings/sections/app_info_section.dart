import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/widgets.dart';

/// The app info section containing about and rate app links.
class AppInfoSection extends StatelessWidget {
  /// Callback when About is tapped.
  final VoidCallback? onAboutTap;

  /// Callback when Rate App is tapped.
  final VoidCallback? onRateTap;

  const AppInfoSection({
    super.key,
    this.onAboutTap,
    this.onRateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'APP INFO'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.info_outline,
              title: 'About',
              onTap: onAboutTap ?? () => _showAboutDialog(context),
            ),
            SettingItemData(
              icon: Icons.star_outline,
              title: 'Rate App',
              onTap: onRateTap ?? () {},
            ),
          ],
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('FitWiz'),
          ],
        ),
        content: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.hasData
                ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                : 'Loading version...';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your AI-powered personal fitness coach. Get personalized workout plans, track your progress, and achieve your fitness goals.',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
