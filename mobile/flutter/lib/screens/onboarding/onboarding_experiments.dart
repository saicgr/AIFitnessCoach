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
