/// Compile-time feature flags. Flip a flag and rebuild to roll back a feature.
library;

/// iOS Live Activities (Dynamic Island) + Android ongoing workout notification
/// during an active workout session. Set to `false` to disable the Live
/// Activity surface entirely — all [LiveActivityService] calls become no-ops.
const bool kUseLiveActivityService = true;

/// Optional onboarding step that offers to import nutrition history from
/// another app (MyFitnessPal / MacroFactor / Cronometer / Apple Health) right
/// after the Health-Connect step. OFF by default — when `false`, the
/// onboarding chain skips the step entirely and goes straight from
/// `health-connect-onboarding` to `permissions-primer`, so no behavior
/// changes. Flip to `true` to surface the step. The same importer is always
/// available, ungated, from Settings → Data Management.
const bool kNutritionImportOnboardingEnabled = false;
