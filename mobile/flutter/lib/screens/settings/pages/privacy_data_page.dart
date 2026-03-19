import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/pill_app_bar.dart';
import '../sections/sections.dart';

class PrivacyDataPage extends ConsumerWidget {
  const PrivacyDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Privacy & Data'),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // TODO: Re-enable social features when user base grows
              // SocialPrivacySection(),
              // SizedBox(height: 16),
              EmailPreferencesSection(),
              SizedBox(height: 16),
              DataManagementSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
