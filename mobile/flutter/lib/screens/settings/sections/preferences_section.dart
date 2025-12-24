import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// The preferences section containing theme and system settings.
///
/// Allows users to toggle between light/dark mode and follow system theme.
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
              icon: Icons.smartphone_outlined,
              title: 'Follow System',
              subtitle: 'Match device theme',
              isFollowSystemToggle: true,
            ),
            SettingItemData(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              isThemeToggle: true,
            ),
          ],
        ),
      ],
    );
  }
}
