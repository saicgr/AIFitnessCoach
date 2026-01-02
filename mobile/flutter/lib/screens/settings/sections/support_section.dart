import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// The support section containing help and legal links.
class SupportSection extends StatelessWidget {
  /// Callback when Help & Support is tapped.
  final VoidCallback? onHelpTap;

  /// Callback when Privacy Policy is tapped.
  final VoidCallback? onPrivacyTap;

  /// Callback when Terms of Service is tapped.
  final VoidCallback? onTermsTap;

  const SupportSection({
    super.key,
    this.onHelpTap,
    this.onPrivacyTap,
    this.onTermsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'SUPPORT'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: onHelpTap ?? () {},
            ),
            SettingItemData(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: onPrivacyTap ?? () {},
            ),
            SettingItemData(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: onTermsTap ?? () {},
            ),
          ],
        ),
      ],
    );
  }
}
