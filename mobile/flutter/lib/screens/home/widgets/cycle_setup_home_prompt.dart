import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/hormonal_health.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../onboarding/cycle_onboarding_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// SharedPreferences key — set once the prompt has been actioned (set up or
/// dismissed) so it never reappears for this user/device.
const _kCycleHomePromptDismissedKey = 'cycle_setup_home_prompt_dismissed';

/// One-time Home dashboard prompt inviting an EXISTING eligible user to set
/// up cycle tracking (Phase E — onboarding).
///
/// New users get the cycle setup step inline during onboarding (see
/// [CycleOnboardingSheet] wired into the personal-info screen). Users who
/// signed up before the cycle feature shipped never saw that step — this
/// prompt closes that gap with a single, dismissible Home card.
///
/// It self-collapses to a zero-height [SizedBox.shrink] (so it can be dropped
/// into the Home sliver list unconditionally, like the other banners) when:
///  * the user already has cycle tracking enabled, OR
///  * the user is not eligible (gender == male, or no hormonal profile —
///    a profile only exists for users who reached the body-metrics step),
///    OR
///  * the prompt was already set up / dismissed once.
///
/// The downstream feature gate is `menstrual_tracking_enabled`, never gender.
class CycleSetupHomePrompt extends ConsumerStatefulWidget {
  const CycleSetupHomePrompt({super.key});

  @override
  ConsumerState<CycleSetupHomePrompt> createState() =>
      _CycleSetupHomePromptState();
}

class _CycleSetupHomePromptState extends ConsumerState<CycleSetupHomePrompt> {
  bool _dismissedThisSession = false;
  bool? _dismissedPersisted; // null until SharedPreferences resolves

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _dismissedPersisted =
        prefs.getBool(_kCycleHomePromptDismissedKey) ?? false);
  }

  Future<void> _markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCycleHomePromptDismissedKey, true);
  }

  /// Eligible = the user could have a menstrual cycle and has NOT enabled
  /// tracking. Gender only sets eligibility — `male` is excluded; everyone
  /// else who has a profile is offered the prompt (the setup itself flips
  /// `menstrual_tracking_enabled`).
  bool _isEligible(HormonalProfile? profile) {
    if (profile == null) return false;
    if (profile.menstrualTrackingEnabled) return false; // already set up
    final g = profile.gender;
    if (g == null || g == Gender.male) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Wait for the persisted dismissal flag before deciding anything.
    if (_dismissedPersisted == null) return const SizedBox.shrink();
    if (_dismissedThisSession || _dismissedPersisted == true) {
      return const SizedBox.shrink();
    }

    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final profile = ref.watch(hormonalProfileProvider).value;
    if (!_isEligible(profile)) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Pink is the cycle feature accent (see the cycle plan / settings screen).
    const accent = Color(0xFFEC4899);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.10 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).cycleSetupHomeTrackYourCycle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ),
                // Dismiss — one-time; never shown again on this device.
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
                  tooltip: AppLocalizations.of(context).upgradePromptDismiss,
                  onPressed: () async {
                    await _markDismissed();
                    if (mounted) {
                      setState(() => _dismissedThisSession = true);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Zealova can predict your period and cycle phases, and adapt '
              'your workouts and nutrition around them.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final completed = await CycleOnboardingSheet.show(
                        context,
                        userId: user.id,
                      );
                      // Whether they set up or skipped, retire the prompt —
                      // it is a one-time invitation.
                      await _markDismissed();
                      if (mounted) {
                        setState(() => _dismissedThisSession = true);
                      }
                      if (completed == true) {
                        // Refresh the profile so the rest of the app sees
                        // `menstrual_tracking_enabled` flip on immediately.
                        ref.invalidate(hormonalProfileProvider);
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context).cycleSetupHomeSetUp,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
