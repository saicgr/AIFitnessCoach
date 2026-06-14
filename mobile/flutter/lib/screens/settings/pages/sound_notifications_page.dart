import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../sections/sections.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Sub-page for Sound & Notifications: audio + notifications.
class SoundNotificationsPage extends ConsumerWidget {
  const SoundNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = ThemeColors.of(context).background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(title: AppLocalizations.of(context).soundNotificationsSoundNotifications),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const NotificationsSection(),
              const SizedBox(height: 16),
              const AdvancedAudioSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }

}
