import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/pill_app_bar.dart';
import '../sections/sections.dart';

class HealthDevicesPage extends ConsumerWidget {
  const HealthDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Health & Devices'),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              HealthSyncSection(),
              SizedBox(height: 16),
              // BLE heart-rate monitor support is disabled for now. The
              // service + section are kept in the tree for easy re-enable;
              // Android "Nearby Devices" prompts stay suppressed as long as
              // nothing constructs FlutterReactiveBle.
              // BleHeartRateSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
