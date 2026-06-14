import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../sections/sections.dart';

import '../../../l10n/generated/app_localizations.dart';
class OfflineModePage extends ConsumerWidget {
  const OfflineModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = ThemeColors.of(context).background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(title: AppLocalizations.of(context).offlineModeOfflineMode),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              OfflineModeSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
