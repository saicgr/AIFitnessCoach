import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// The training preferences section for workout-related settings.
///
/// Allows users to configure:
/// - Progression Pace: How fast to increase weights (slow/medium/fast)
/// - Workout Type: Strength, cardio, or mixed
/// - Workout Environment: Where they train (gym, home, etc.)
/// - Equipment: What equipment they have access to
class TrainingPreferencesSection extends StatelessWidget {
  const TrainingPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'TRAINING'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.trending_up,
              title: 'Progression Pace',
              subtitle: 'How fast to increase weights',
              isProgressionPaceSelector: true,
            ),
            SettingItemData(
              icon: Icons.fitness_center,
              title: 'Workout Type',
              subtitle: 'Strength, cardio, or mixed',
              isWorkoutTypeSelector: true,
            ),
            SettingItemData(
              icon: Icons.location_on,
              title: 'Workout Environment',
              subtitle: 'Where you train',
              isWorkoutEnvironmentSelector: true,
            ),
            SettingItemData(
              icon: Icons.build,
              title: 'My Equipment',
              subtitle: 'Equipment available for workouts',
              isEquipmentSelector: true,
            ),
          ],
        ),
      ],
    );
  }
}
