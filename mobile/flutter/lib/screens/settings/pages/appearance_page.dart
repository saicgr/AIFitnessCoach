import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../sections/sections.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Sub-page for Appearance: theme, haptics, app mode, accessibility.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final accent = tc.accent;

    final serious = ref.watch(seriousModeProvider);

    return Scaffold(
      backgroundColor: tc.background,
      appBar: ZealovaAppBar(title: AppLocalizations.of(context).settingsAppearance),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PreferencesSection(),
              const SizedBox(height: 16),
              const HapticsSection(),
              const SizedBox(height: 24),
              // Week start — Sunday vs Monday. Drives every weekly calendar /
              // strip in the app; synced cross-device via the user-preferences
              // PATCH path inside weekStartsSundayProvider.
              _WeekStartCard(accent: accent, textPrimary: textPrimary),
              const SizedBox(height: 24),
              // Serious Mode — dials gamification noise down without losing
              // any tracking. Profile becomes default tab in You hub,
              // streak strips hide, level card mutes its accent flood.
              ZealovaCard(
                variant: serious
                    ? ZealovaCardVariant.hero
                    : ZealovaCardVariant.outlined,
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
                            AppLocalizations.of(context).appearanceSeriousMode,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ZealovaToggle(
                          value: serious,
                          onChanged: (v) => ref
                              .read(seriousModeProvider.notifier)
                              .setEnabled(v),
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

/// Sun/Mon segmented toggle for the first day of the week. Reads + writes
/// [weekStartsSundayProvider] (which proxies the GET/PATCH user-preferences
/// endpoint + a local cache).
class _WeekStartCard extends ConsumerWidget {
  final Color accent;
  final Color textPrimary;
  const _WeekStartCard({required this.accent, required this.textPrimary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startsSunday = ref.watch(weekStartsSundayProvider);

    void set(bool sunday) {
      if (sunday == startsSunday) return;
      HapticFeedback.lightImpact();
      ref.read(weekStartsSundayProvider.notifier).setStartsSunday(sunday);
    }

    return ZealovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: textPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).workoutPreferencesCardWeekStartsOn,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).trainingPreferencesFirstDayOfThe,
            style: TextStyle(
              color: textPrimary.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _WeekStartSegment(
                  label: AppLocalizations.of(context).settingsCardSunday,
                  selected: startsSunday,
                  accent: accent,
                  textPrimary: textPrimary,
                  onTap: () => set(true),
                ),
                const SizedBox(width: 4),
                _WeekStartSegment(
                  label: AppLocalizations.of(context).settingsCardPartMonday,
                  selected: !startsSunday,
                  accent: accent,
                  textPrimary: textPrimary,
                  onTap: () => set(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStartSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color textPrimary;
  final VoidCallback onTap;
  const _WeekStartSegment({
    required this.label,
    required this.selected,
    required this.accent,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: accent.withValues(alpha: 0.4))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? textPrimary
                  : textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
