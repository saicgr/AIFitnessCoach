import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/privacy_settings_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Leaderboard privacy toggles. Appears on the Profile screen directly below
/// the FITNESS section — privacy sits adjacent to the data it controls.
class PrivacySection extends ConsumerWidget {
  const PrivacySection({super.key});

  static const _sectionColor = AppColors.info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    final state = ref.watch(privacySettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header matching the FITNESS header style
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'PRIVACY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _sectionColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: state.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Couldn\'t load privacy settings. Pull to retry.',
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
            ),
            data: (prefs) {
              final masterOn = prefs.showOnLeaderboard;
              return Column(
                children: [
                  _row(
                    context, ref,
                    title: 'Show me on leaderboards',
                    subtitle:
                        "When off, you won't appear in the Discover tab for anyone.",
                    value: prefs.showOnLeaderboard,
                    onChanged: (v) => ref
                        .read(privacySettingsProvider.notifier)
                        .setShowOnLeaderboard(v),
                    textPrimary: textPrimary, textMuted: textMuted,
                    accent: accent, enabled: true,
                  ),
                  Divider(height: 1, color: border),
                  _row(
                    context, ref,
                    title: 'Anonymous mode',
                    subtitle:
                        "Rank normally, but show as 'Anonymous athlete' without name or avatar.",
                    value: prefs.leaderboardAnonymous,
                    onChanged: (v) => ref
                        .read(privacySettingsProvider.notifier)
                        .setAnonymous(v),
                    textPrimary: textPrimary, textMuted: textMuted,
                    accent: accent, enabled: masterOn,
                  ),
                  Divider(height: 1, color: border),
                  _row(
                    context, ref,
                    title: 'Show my stats on my profile peek',
                    subtitle:
                        'Your bio and fitness shape appear when someone taps your leaderboard entry.',
                    value: prefs.profileStatsVisible,
                    onChanged: (v) => ref
                        .read(privacySettingsProvider.notifier)
                        .setStatsVisible(v),
                    textPrimary: textPrimary, textMuted: textMuted,
                    accent: accent, enabled: masterOn,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textPrimary,
    required Color textMuted,
    required Color accent,
    required bool enabled,
  }) {
    final effectiveValue = enabled ? value : false;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: SwitchListTile.adaptive(
        value: effectiveValue,
        activeThumbColor: accent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.35),
          ),
        ),
        onChanged: enabled
            ? (v) {
                HapticService.light();
                onChanged(v);
              }
            : null,
      ),
    );
  }
}
