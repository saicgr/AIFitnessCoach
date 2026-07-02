// Tracks whether the user has already passed the warmup phase for the
// *current* active workout, regardless of which tier (Easy/Simple/Advanced)
// they're using. Easy and Simple don't surface a warmup phase at all — they
// drop the user straight into the first working set — so if a user swaps
// Easy → Advanced mid-session, Advanced should NOT drag them back through
// warmup.
//
// Reset on workout completion or when the user navigates away. This is a
// pure in-memory flag; no persistence needed.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True once the user has progressed past warmup on the currently-running
/// workout. Easy and Simple set this to true the moment their screen mounts
/// (they skip warmup by design); Advanced sets it when the user completes
/// or skips warmup; all tiers reset it to false when the workout wraps.
final activeWorkoutWarmupDoneProvider = StateProvider<bool>((ref) => false);

/// Depth of pre-workout modal flows currently on screen — the reshape
/// check-in sheet ("Quick check-in" / "Anything to flag?") + its diff dialog,
/// and the equipment-match swap/add sheet consumed at workout mount. The tier
/// tour (`WorkoutTourService.maybeShowForTier`) defers while this is > 0 and
/// re-fires when it returns to 0, so the spotlight tour never renders on top
/// of (and anchored underneath) a modal sheet. A refcount rather than a bool
/// because both flows are kicked off post-frame at mount and can overlap —
/// the first one to finish must not unlatch the gate while the other is up.
final preWorkoutModalDepthProvider = StateProvider<int>((ref) => 0);
