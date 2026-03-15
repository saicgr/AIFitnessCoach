import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/pill_app_bar.dart';
import '../sections/sections.dart';

/// Sub-page for Sound & Notifications: voice, audio, notifications.
class SoundNotificationsPage extends ConsumerWidget {
  const SoundNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Sound & Notifications'),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              VoiceAnnouncementsSection(),
              SizedBox(height: 16),
              AudioSettingsSection(),
              SizedBox(height: 16),
              NotificationsSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
    );
  }
}
