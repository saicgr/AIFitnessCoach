import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'sections/sections.dart';

/// The main settings screen that composes all settings sections.
///
/// This screen provides access to all app settings including:
/// - Preferences (theme, system settings)
/// - Haptics configuration
/// - Accessibility options
/// - Health sync integration
/// - Notification preferences
/// - Social & Privacy settings
/// - Support links
/// - App info
/// - Data management (import/export)
/// - Danger zone (reset/delete account)
/// - Logout
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
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
            children: [
              // Preferences section
              const PreferencesSection().animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 24),

              // Haptics section
              const HapticsSection().animate().fadeIn(delay: 55.ms),

              const SizedBox(height: 24),

              // Accessibility section
              const AccessibilitySection().animate().fadeIn(delay: 57.ms),

              const SizedBox(height: 24),

              // Health Connect / Apple Health section
              const HealthSyncSection().animate().fadeIn(delay: 60.ms),

              const SizedBox(height: 24),

              // Notifications section
              const NotificationsSection().animate().fadeIn(delay: 75.ms),

              const SizedBox(height: 24),

              // Social & Privacy section
              const SocialPrivacySection().animate().fadeIn(delay: 85.ms),

              const SizedBox(height: 24),

              // Support section
              const SupportSection().animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // App Info section
              const AppInfoSection().animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // Data Management section
              const DataManagementSection().animate().fadeIn(delay: 175.ms),

              const SizedBox(height: 24),

              // Danger Zone section
              const DangerZoneSection().animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // Logout button
              const LogoutSection().animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 16),

              // Version
              Text(
                'FitWiz v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textMuted,
                    ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
