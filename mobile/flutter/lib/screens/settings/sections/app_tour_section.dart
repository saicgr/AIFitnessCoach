import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/tooltip_tour_provider.dart';
import '../widgets/settings_card.dart';
import '../widgets/setting_tile.dart';

/// App Tour & Demo settings section.
///
/// Provides access to:
/// - Restart App Tour - Re-show the interactive tooltip-based app walkthrough
/// - Try Demo Workout - Experience a sample workout without commitment
/// - Preview Sample Plan - See what a 4-week workout plan looks like
///
/// This addresses the user request: "Demo of the whole app, for a new user guide,
/// also an ability to access demo from settings"
class AppTourSection extends ConsumerWidget {
  const AppTourSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsCard(
      items: [
        // Restart App Tour
        SettingItemData(
          icon: Icons.replay,
          title: 'Restart App Tour',
          subtitle: 'See the interactive app walkthrough again',
          onTap: () async {
            HapticFeedback.lightImpact();
            // Reset tooltip tour completion status
            await ref.read(tooltipTourProvider.notifier).resetTour();
            // Navigate back to home screen where the tour will show
            if (context.mounted) {
              context.go('/home');
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Tour will start on the home screen'),
                  backgroundColor: AppColors.cyan,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        // Try Demo Workout
        SettingItemData(
          icon: Icons.play_circle_outline,
          title: 'Try Demo Workout',
          subtitle: 'Experience a sample workout',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/demo-workout');
          },
        ),
        // Preview Sample Plan
        SettingItemData(
          icon: Icons.calendar_today_outlined,
          title: 'Preview Sample Plan',
          subtitle: 'See what a 4-week workout plan looks like',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/plan-preview');
          },
        ),
      ],
    );
  }
}
