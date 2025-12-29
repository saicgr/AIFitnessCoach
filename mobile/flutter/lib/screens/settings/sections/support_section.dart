import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// The legal section containing privacy and terms links.
class SupportSection extends StatelessWidget {
  /// Callback when Privacy Policy is tapped.
  final VoidCallback? onPrivacyTap;

  /// Callback when Terms of Service is tapped.
  final VoidCallback? onTermsTap;

  const SupportSection({
    super.key,
    this.onPrivacyTap,
    this.onTermsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'LEGAL'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
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
