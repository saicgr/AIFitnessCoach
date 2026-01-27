import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// The preferences section containing theme, timezone, and unit settings.
///
/// Allows users to choose between System, Light, or Dark theme.
/// Timezone is auto-detected but can be overridden (e.g., when traveling).
/// Weight unit can be set to kg or lbs.
class PreferencesSection extends StatelessWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'PREFERENCES'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: 'System, Light, or Dark',
              isThemeSelector: true,
            ),
            SettingItemData(
              icon: Icons.color_lens_outlined,
              title: 'Accent Color',
              subtitle: 'Choose your app accent color',
              isAccentColorSelector: true,
            ),
            SettingItemData(
              icon: Icons.travel_explore_outlined,
              title: 'Timezone',
              subtitle: 'Auto-detected, override if traveling',
              isTimezoneSelector: true,
            ),
            SettingItemData(
              icon: Icons.fitness_center_outlined,
              title: 'Weight Unit',
              subtitle: 'Kilograms or Pounds',
              isWeightUnitSelector: true,
            ),
            SettingItemData(
              icon: Icons.tune,
              title: 'Weight Increments',
              subtitle: 'Customize +/- step per equipment',
              isWeightIncrementsSelector: true,
            ),
            SettingItemData(
              icon: Icons.bolt_outlined,
              title: 'Show Daily Goals',
              subtitle: 'XP progress strip on home screen',
              isDailyXPStripToggle: true,
            ),
          ],
        ),
      ],
    );
  }
}
