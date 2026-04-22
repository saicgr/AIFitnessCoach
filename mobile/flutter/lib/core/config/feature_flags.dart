/// Compile-time feature flags. Flip a flag and rebuild to roll back a feature.
library;

/// iOS Live Activities (Dynamic Island) + Android ongoing workout notification
/// during an active workout session. Set to `false` to disable the Live
/// Activity surface entirely — all [LiveActivityService] calls become no-ops.
const bool kUseLiveActivityService = true;
