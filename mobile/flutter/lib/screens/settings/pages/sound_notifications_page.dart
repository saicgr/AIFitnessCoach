import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_back_button.dart';
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Sound & Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
      ),
    );
  }
}
