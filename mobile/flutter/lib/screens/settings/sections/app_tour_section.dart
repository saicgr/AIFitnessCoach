import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/app_tour_provider.dart';
import '../widgets/settings_card.dart';
import '../widgets/setting_tile.dart';

/// App Tour & Demo settings section.
///
/// Provides access to:
/// - Restart App Tour - Re-show the interactive app walkthrough
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
          onTap: () {
            HapticFeedback.lightImpact();
            // Reset tour completion status
            ref.read(appTourProvider.notifier).resetTour();
            // Navigate to tour with settings source
            context.push('/app-tour', extra: {'source': 'settings'});
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
