import '../../core/services/posthog_service.dart';

/// Remote kill-switches for the v6 onboarding conversion screens.
///
/// Each screen added by the conversion upgrade (why / reflect / blocker /
/// confidence / value / plan-preview) defaults to ENABLED — they ship on
/// for everyone. Setting the matching PostHog flag to a disabling value
/// (`off` / `false` / `control` / `disabled`) remotely removes that screen
/// from the funnel WITHOUT a redeploy.
///
/// This is the safety net for lengthening onboarding: we added ~6 screens
/// before the paywall, and the one real risk is over-lengthening. If
/// per-screen drop-off shows a screen hurts completion, flip its flag off.
///
/// Resolution mirrors `paywall_experiments.dart`: it uses
/// [PosthogService.getFeatureFlag] (not `isFeatureEnabled`) so an *absent*
/// flag is distinguishable from an explicit `false` — absent keeps the
/// screen ON, only an explicit disabling value removes it.
class OnboardingExperiments {
  OnboardingExperiments._();

  static const String flagWhy = 'onboarding_why_screen';
  static const String flagReflect = 'onboarding_reflect_screen';
  static const String flagBlocker = 'onboarding_blocker_screen';
  static const String flagConfidence = 'onboarding_confidence_screen';
  static const String flagValue = 'onboarding_value_screen';
  static const String flagPlanPreview = 'onboarding_plan_preview';

  /// v7 first-run redesign kill switches (same default-ON, fail-open
  /// semantics): explicit off = legacy layout, absent = new design.
  static const String flagIntroDemoV7 = 'onboarding_v7_intro_demo';
  static const String flagPaywallFounderPageV7 =
      'onboarding_v7_paywall_founder_page';

  /// Experiment: move name + DOB collection (`/personal-info`) to AFTER the
  /// paywall instead of before coach-selection. Removes the one piece of pure
  /// data-collection friction sitting between the pre-auth value peak (demo
  /// showcases) and the paywall ask. Defaults OFF (today's order:
  /// personal-info → coach → assessment → paywall). Flip this flag truthy to
  /// run the treatment (coach → assessment → paywall → personal-info →
  /// commitment-pact).
  ///
  /// Unlike the v6 kill-switches above (default ON), this defaults OFF, so its
  /// resolution lives in [primeFlowFlags] rather than [isEnabled].
  static const String flagPersonalInfoAfterPaywall =
      'onboarding_personal_info_after_paywall';

  /// Sync-readable cache of [flagPersonalInfoAfterPaywall]. The router's
  /// step-ordering and several screens' forward-navigation must read this
  /// synchronously (a `redirect` callback cannot await), so it is primed once
  /// per session by [primeFlowFlags] (called fire-and-forget from the router
  /// the moment auth completes). Defaults FALSE = today's exact order, so the
  /// whole reorder is dead code until the flag is flipped — zero prod risk.
  static bool personalInfoAfterPaywall = false;

  /// Resolve the synchronously-read flow flags into their caches. Safe to call
  /// repeatedly; never throws (the PostHog wrapper swallows errors → `null`,
  /// leaving the default untouched). Default-OFF flag: only an explicit
  /// truthy value enables the treatment.
  static Future<void> primeFlowFlags(PosthogService posthog) async {
    final raw = await posthog.getFeatureFlag(flagPersonalInfoAfterPaywall);
    if (raw is bool) {
      personalInfoAfterPaywall = raw;
    } else if (raw is String) {
      final v = raw.toLowerCase();
      personalInfoAfterPaywall =
          v == 'on' || v == 'true' || v == 'treatment' || v == 'enabled';
    }
    // absent / unreadable → keep default false (today's order)
  }

  /// True unless [flagKey] is explicitly configured to a disabling value.
  /// An absent flag (`null`) or any unexpected type keeps the screen ON.
  /// Never throws — the PostHog wrapper swallows errors and returns `null`.
  static Future<bool> isEnabled(
    PosthogService posthog,
    String flagKey,
  ) async {
    final raw = await posthog.getFeatureFlag(flagKey);
    if (raw is bool) return raw;
    if (raw is String) {
      final v = raw.toLowerCase();
      return !(v == 'off' ||
          v == 'false' ||
          v == 'control' ||
          v == 'disabled');
    }
    return true; // absent / unreadable → keep enabled
  }
}
