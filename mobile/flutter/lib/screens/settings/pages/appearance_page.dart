import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../widgets/pill_app_bar.dart';
import '../sections/sections.dart';

/// Sub-page for Appearance: theme, haptics, app mode, accessibility.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final serious = ref.watch(seriousModeProvider);
    final accent =
        AccentColorScope.of(context).getColor(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Appearance'),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PreferencesSection(),
              const SizedBox(height: 16),
              const HapticsSection(),
              const SizedBox(height: 24),
              // Serious Mode — dials gamification noise down without losing
              // any tracking. Profile becomes default tab in You hub,
              // streak strips hide, level card mutes its accent flood.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: serious
                        ? accent.withValues(alpha: 0.5)
                        : textPrimary.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.self_improvement_rounded,
                          color: serious ? accent : textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Serious Mode',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: serious,
                          onChanged: (v) => ref
                              .read(seriousModeProvider.notifier)
                              .setEnabled(v),
                          activeTrackColor: accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dials down gamification visuals — streak strips, '
                      'celebration pop-ins, and XP accent flooding. Your '
                      'Profile becomes the default tab in You. All tracking '
                      'still runs; nothing is deleted.',
                      style: TextStyle(
                        color: textPrimary.withValues(alpha: 0.65),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }
}
