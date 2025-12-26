import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// The preferences section containing theme and timezone settings.
///
/// Allows users to choose between System, Light, or Dark theme.
/// Timezone is auto-detected but can be overridden (e.g., when traveling).
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
              icon: Icons.travel_explore_outlined,
              title: 'Timezone',
              subtitle: 'Auto-detected, override if traveling',
              isTimezoneSelector: true,
            ),
          ],
        ),
      ],
    );
  }
}
