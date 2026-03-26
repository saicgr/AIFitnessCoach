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
              BleHeartRateSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
