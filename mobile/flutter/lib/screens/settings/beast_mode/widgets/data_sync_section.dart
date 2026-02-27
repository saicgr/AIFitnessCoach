import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/services/data_cache_service.dart';
import '../../../../../data/services/haptic_service.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class DataSyncSection extends ConsumerWidget {
  final BeastThemeData theme;

  const DataSyncSection({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notification Tester
        BeastCard(
          theme: theme,
          child: _navTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Notification Tester',
            subtitle: 'Send test notifications',
            route: '/settings/sound-notifications',
          ),
        ),
        const SizedBox(height: 12),
        // Action buttons - cache clear is still useful without full offline mode
        BeastCard(
          theme: theme,
          child: _actionTile(
            context,
            icon: Icons.cleaning_services_outlined,
            title: 'Clear All Caches',
            subtitle: 'Free memory by clearing in-memory caches',
            onTap: () async {
              HapticService.medium();
              await DataCacheService.instance.clearAll();
              if (context.mounted) {
                AppSnackBar.success(context, 'All caches cleared');
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        // Device Info
        BeastCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
              const SizedBox(height: 12),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text('Loading...', style: TextStyle(fontSize: 12, color: theme.textMuted));
                  }
                  final info = snapshot.data!;
                  return Column(
                    children: [
                      _infoRow('App Version', info.version),
                      const SizedBox(height: 6),
                      _infoRow('Build', info.buildNumber),
                      const SizedBox(height: 6),
                      _infoRow('Package', info.packageName),
                      const SizedBox(height: 6),
                      _infoRow('Platform', Theme.of(context).platform.name),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push(route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: theme.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: theme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: theme.textMuted, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: theme.textPrimary, fontFamily: 'monospace'))),
      ],
    );
  }
}
