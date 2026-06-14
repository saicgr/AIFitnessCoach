import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../sections/sections.dart';

import '../../../l10n/generated/app_localizations.dart';
class PrivacyDataPage extends ConsumerWidget {
  const PrivacyDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = ThemeColors.of(context).background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(title: AppLocalizations.of(context).settingsPrivacyData),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // TODO: Re-enable social features when user base grows
              // SocialPrivacySection(),
              // SizedBox(height: 16),
              EmailPreferencesSection(),
              SizedBox(height: 16),
              ImportsPrivacySection(),
              SizedBox(height: 16),
              ContributeFoodDataSection(),
              SizedBox(height: 16),
              DataManagementSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
