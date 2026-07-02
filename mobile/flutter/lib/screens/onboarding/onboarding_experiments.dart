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

  /// Demo auto-route (2026-07, Duolingo pattern): weight-projection routes
  /// STRAIGHT into `/demo-workout-showcase` (which chains → nutrition demo
  /// → sign-in) instead of the `/demo-tasks` chooser hub. The hub was an
  /// extra decision point whose hero CTA was the *skip* action; deferred
  /// signup after sampling the product lifts activation 10-30% (Duolingo
  /// +20% DAU). Default-ON kill-switch: flip off to restore the chooser.
  /// The router's post-auth backstop reads the sync cache [demoAutoRoute]
  /// (redirect callbacks cannot await), primed by [primeFlowFlags].
  static const String flagDemoAutoRoute = 'onboarding_demo_autoroute';

  /// Sync-readable cache of [flagDemoAutoRoute] for the router redirect.
  /// Defaults TRUE (auto-route is the shipped design; the flag is a
  /// kill-switch, not an opt-in).
  static bool demoAutoRoute = true;

  /// Gravl-gap UX upgrades (2026-06). All default-ON kill-switches resolved
  /// via [isEnabled] at screen build, EXCEPT:
  ///  - [flagStepCounter] — default OFF (`isEnabledDefaultOff`). The quiz
  ///    header DELIBERATELY shows "~2 min left" instead of a "Step X of N"
  ///    pill (see quiz_header.dart — completion-anxiety research). This flag
  ///    is the A/B treatment to revert to a Gravl-style "Step N of M" count;
  ///    control keeps today's time estimate. Never force-on.
  ///  - [flagGymFinder] — default OFF, gated on a configured Maps key.
  ///  - [flagValueCadence] — multivariate, primed into [valueCadence].
  /// See plan `1-gravl-tutorial-2-squishy-lamport.md`.
  static const String flagStepCounter = 'onboarding_step_counter'; // default OFF
  static const String flagNotifPreviews = 'onboarding_notif_previews';
  static const String flagHcWalkthrough = 'onboarding_hc_walkthrough';
  static const String flagSmartDefaults = 'onboarding_smart_defaults';
  static const String flagEquipmentVisual = 'onboarding_equipment_visual';
  static const String flagDialInputs = 'onboarding_dial_inputs';
  static const String flagGymFinder = 'onboarding_gym_finder'; // default OFF
  static const String flagSplitRationale = 'onboarding_split_rationale';
  static const String flagIntroIntegrations =
      'onboarding_intro_integrations';
  static const String flagIntroShareables = 'onboarding_intro_shareables';

  /// Multivariate cadence experiment: `control` (value beats bunched after the
  /// quiz, today's order) | `interleaved` (beats woven between question
  /// clusters) | `more` (interleaved + all added beats incl. nutrition).
  /// Absent / unreadable → `control` (today's exact flow), so the reorder is
  /// dead code until the flag is set — zero prod risk.
  static const String flagValueCadence = 'onboarding_value_cadence';

  /// Authority/citations experiment (Pattern 1, 2026-06): a short
  /// "Your plan is built on real science" screen inserted post-assessment,
  /// pre `/capability-and-community`, surfacing peer-reviewed methodology
  /// citations the user can tap through to the primary source.
  ///
  /// DEFAULT-OFF (A/B in) — resolved via [isEnabledDefaultOff]: an *absent*
  /// flag keeps the screen DARK, only an explicit truthy value shows it.
  /// `fitness_assessment_screen` reads the sync cache [scienceScreen] (primed
  /// by [primeFlowFlags]) to decide whether to route through it. Zero prod
  /// risk until the flag is flipped on.
  static const String flagScienceScreen =
      'onboarding_science_screen'; // default OFF

  /// Sync-readable cache of [flagScienceScreen]. The assessment screen's
  /// forward navigation must read it synchronously, so it is primed once per
  /// session by [primeFlowFlags]. Defaults FALSE = science screen NOT shown
  /// (today's exact flow), so the insertion is dead code until flipped on.
  static bool scienceScreen = false;

  /// Sync-readable cache of [flagValueCadence] (router + quiz read it
  /// synchronously). Primed once per session by [primeFlowFlags].
  static String valueCadence = 'control';
  static bool get isInterleaved =>
      valueCadence == 'interleaved' || valueCadence == 'more';
  static bool get isMoreCadence => valueCadence == 'more';

  /// Default-OFF kill-switch resolver: an *absent* flag stays OFF (only an
  /// explicit truthy value enables). Mirrors [primeFlowFlags] semantics, for
  /// flags like [flagGymFinder] that must stay dark until deliberately turned
  /// on.
  static Future<bool> isEnabledDefaultOff(
    PosthogService posthog,
    String flagKey,
  ) async {
    final raw = await posthog.getFeatureFlag(flagKey);
    if (raw is bool) return raw;
    if (raw is String) {
      final v = raw.toLowerCase();
      return v == 'on' || v == 'true' || v == 'treatment' || v == 'enabled';
    }
    return false; // absent / unreadable → stay OFF
  }

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

    // Multivariate cadence: only the three known arms are honoured; anything
    // else (incl. absent) stays on `control` = today's exact flow.
    final cadenceRaw = await posthog.getFeatureFlag(flagValueCadence);
    if (cadenceRaw is String) {
      final v = cadenceRaw.toLowerCase();
      if (v == 'interleaved' || v == 'more' || v == 'control') {
        valueCadence = v;
      }
    }

    // Science-grounding screen: default-OFF, only an explicit truthy value
    // inserts it into the funnel. Absent / unreadable → stays FALSE.
    scienceScreen = await isEnabledDefaultOff(posthog, flagScienceScreen);

    // Demo auto-route: default-ON kill-switch — absent keeps auto-route,
    // only an explicit disabling value restores the /demo-tasks chooser.
    demoAutoRoute = await isEnabled(posthog, flagDemoAutoRoute);
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
