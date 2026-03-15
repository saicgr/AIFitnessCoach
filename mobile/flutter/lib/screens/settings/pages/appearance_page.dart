import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/pill_app_bar.dart';
import '../sections/sections.dart';

/// Sub-page for Appearance: theme, haptics, app mode, accessibility.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Appearance'),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              PreferencesSection(),
              SizedBox(height: 16),
              HapticsSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
    );
  }
}
