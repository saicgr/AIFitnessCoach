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
