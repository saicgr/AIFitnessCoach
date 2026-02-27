import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/providers/beast_mode_provider.dart';
import '../../../../../data/services/haptic_service.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class AboutSection extends ConsumerWidget {
  final BeastThemeData theme;

  const AboutSection({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text('Loading build info...', style: TextStyle(fontSize: 12, color: theme.textMuted));
              }
              final info = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Package', info.packageName),
                  const SizedBox(height: 6),
                  _infoRow('Version', info.version),
                  const SizedBox(height: 6),
                  _infoRow('Build', info.buildNumber),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticService.medium();
                ref.read(beastModeProvider.notifier).lock();
                AppSnackBar.info(context, 'Beast Mode disabled');
                context.pop();
              },
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Disable Beast Mode'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
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
