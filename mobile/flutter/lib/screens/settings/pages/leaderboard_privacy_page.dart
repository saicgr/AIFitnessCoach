import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/privacy_settings_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Full-screen Leaderboard Privacy settings. Opened from the Profile screen's
/// compact "Leaderboard privacy" row so the Profile landing stays scannable.
/// Hosts the three toggles that were previously stacked inline on Profile:
///   * Show me on leaderboards (master)
///   * Anonymous mode
///   * Show my stats on my profile peek
class LeaderboardPrivacyPage extends ConsumerWidget {
  const LeaderboardPrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final textMuted = tc.textMuted;

    final state = ref.watch(privacySettingsProvider);

    return Scaffold(
      backgroundColor: tc.background,
      appBar: ZealovaAppBar(title: AppLocalizations.of(context).leaderboardPrivacyLeaderboardPrivacy),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brief framing copy — explains the umbrella setting so the
              // toggles below feel coherent rather than disconnected switches.
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, bottom: 14, end: 4),
                child: Text(
                  'Control who sees you on the Discover leaderboard and how '
                  'your identity appears to other users.',
                  style: TextStyle(
                    fontSize: 13, color: textMuted, height: 1.4,
                  ),
                ),
              ),
              ZealovaCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      AppLocalizations.of(context).leaderboardPrivacyCouldnTLoadPrivacy,
                      style: TextStyle(color: textMuted, fontSize: 13),
                    ),
                  ),
                  data: (prefs) {
                    final masterOn = prefs.showOnLeaderboard;
                    return Column(
                      children: [
                        _row(
                          title: AppLocalizations.of(context).leaderboardPrivacyShowMeOnLeaderboards,
                          subtitle:
                              "When off, you won't appear in the Discover "
                              'tab for anyone.',
                          value: prefs.showOnLeaderboard,
                          onChanged: (v) => ref
                              .read(privacySettingsProvider.notifier)
                              .setShowOnLeaderboard(v),
                          textPrimary: tc.textPrimary,
                          textMuted: textMuted,
                          enabled: true,
                          isLast: false,
                        ),
                        _row(
                          title: AppLocalizations.of(context).leaderboardPrivacyAnonymousMode,
                          subtitle:
                              "Rank normally, but show as 'Anonymous athlete' "
                              'without name or avatar.',
                          value: prefs.leaderboardAnonymous,
                          onChanged: (v) => ref
                              .read(privacySettingsProvider.notifier)
                              .setAnonymous(v),
                          textPrimary: tc.textPrimary,
                          textMuted: textMuted,
                          enabled: masterOn,
                          isLast: false,
                        ),
                        _row(
                          title: AppLocalizations.of(context).leaderboardPrivacyShowMyStatsOn,
                          subtitle:
                              'Your bio and fitness shape appear when someone '
                              'taps your leaderboard entry.',
                          value: prefs.profileStatsVisible,
                          onChanged: (v) => ref
                              .read(privacySettingsProvider.notifier)
                              .setStatsVisible(v),
                          textPrimary: tc.textPrimary,
                          textMuted: textMuted,
                          enabled: masterOn,
                          isLast: true,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textPrimary,
    required Color textMuted,
    required bool enabled,
    required bool isLast,
  }) {
    final effectiveValue = enabled ? value : false;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.hairline)),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: textMuted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ZealovaToggle(
              value: effectiveValue,
              onChanged: enabled
                  ? (v) {
                      HapticService.light();
                      onChanged(v);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
