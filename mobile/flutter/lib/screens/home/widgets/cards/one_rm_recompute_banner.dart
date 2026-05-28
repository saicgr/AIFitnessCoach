/// F3.121 — 1RM recompute banner.
///
/// After today's session, if any lift produced a new estimated 1RM,
/// surface the delta + a CTA to accept the new working weight. Self-
/// collapses until the backend recompute signal is wired.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/today_workout_provider.dart';

class OneRmRecomputeBanner extends ConsumerWidget {
  const OneRmRecomputeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    final completed = today?.completedToday ?? false;
    if (!completed) return const SizedBox.shrink();

    // TODO(backend): expose `one_rm_recompute: {lift, old_lb, new_lb}` on
    // the completed-workout payload (server-side Epley/Brzycki against
    // today's top working set vs the prior 1RM in `personal_bests`).
    // Self-collapse until then — we never want to invent a number that
    // would mutate the user's working sets.
    return const SizedBox.shrink();
  }
}
