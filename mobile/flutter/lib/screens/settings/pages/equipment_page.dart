import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../sections/sections.dart';

import '../../../l10n/generated/app_localizations.dart';
class EquipmentPage extends ConsumerWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = ThemeColors.of(context).background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(title: AppLocalizations.of(context).trainingSetupCardEquipment),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              CustomContentSection(),
              SizedBox(height: 16),
              EquipmentCalibrationSection(),
              SizedBox(height: 16),
              WarmupSettingsSection(),
              SizedBox(height: 16),
              SupersetSettingsSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
