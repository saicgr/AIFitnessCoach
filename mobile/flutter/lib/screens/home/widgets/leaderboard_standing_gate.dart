/// Single source of truth for "may Home present this user's leaderboard
/// placement as a real STANDING?".
///
/// Why this exists (E2E register #17 — day-one zero states presented as
/// rankings and losses):
///
/// `compute_user_percentile` builds its cohort from *anyone with an
/// `xp_transactions` row in the last 7 days*, and signing up alone writes
/// XP (`first_login` +100, `daily_login`, onboarding `first_time_bonus`
/// rows). So a brand-new account is placed on the board within seconds of
/// creating it, and `/leaderboard/discover` returns a non-zero `your_rank`
/// for someone who has not done a single thing the board measures. On the
/// production cohort (3 ranked users on 2026-07-29) that rendered as
/// "Top 34% this week · #3 of 3 active users" on Home, minutes after signup:
/// a standing in a competition the user never entered.
///
/// Two conditions must BOTH hold before a rank is honest:
///
///  1. **The cohort is big enough for a percentile to mean anything.** A
///     3-user board makes everyone either a champion or last place. This
///     threshold already existed (and was already reasoned about) inside
///     `stacked_banner_panel.dart`; it now lives here so every Home rank
///     surface shares one rule instead of each inventing its own.
///  2. **The user actually participated in the board's week.** The app's own
///     copy promises exactly this ("Log a workout to join the board"), and
///     the backend's own comment describes rank 0 as "no completed workout
///     this week" — the RPC just never implemented it. Until they have a
///     completed workout inside the board week, Home shows the honest
///     starting state instead of a placement.
///
/// Anything that renders `#N`, `Top N%` or a tier as the user's current
/// standing on Home must gate on [homeStandingVisibility] (or its boolean
/// shorthand [homeMayShowStanding] where "don't render at all" is a valid
/// outcome).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/discover_snapshot.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';

/// Below this many ranked users a percentile is arithmetic noise rather than
/// information (with 3 users the only possible percentiles are 66/33/0).
/// Not a cap on anything the user can reach — it only decides whether we
/// phrase their position as a percentile.
const int kMinMeaningfulCohort = 10;

/// True once the user has completed at least one workout inside the board
/// week starting at [weekStartIso] (`yyyy-MM-dd`, from the Discover
/// snapshot).
///
/// Reads the locally-held schedule (`workoutsProvider`) rather than
/// `users.first_workout_completed_at`: that column is only written by the
/// `POST /workouts/{id}/complete` path, so it is NULL for 4 of the 6
/// production accounts that DO have completed `workout_logs` — gating on it
/// would hide the board from real users forever.
///
/// Date handling follows the app-wide `scheduledDateKey` convention (split
/// the ISO string, never `DateTime.parse` a date-only value), so a
/// noon-anchored `scheduled_date` resolves to its own local day.
final boardWeekParticipationProvider =
    Provider.family<bool, String>((ref, weekStartIso) {
  if (weekStartIso.isEmpty) return false;
  final workouts = ref.watch(workoutsProvider).valueOrNull;
  if (workouts == null || workouts.isEmpty) return false;
  for (final w in workouts) {
    if (w.isCompleted != true) continue;
    final key = _completionDayKey(w);
    if (key == null) continue;
    // ISO `yyyy-MM-dd` compares correctly lexicographically.
    if (key.compareTo(weekStartIso) >= 0) return true;
  }
  return false;
});

/// The day a completed workout counts towards, as `yyyy-MM-dd`.
/// `completedAt` is a UTC timestamp, so it is converted to the device's local
/// day; `scheduledDate` is the noon-anchored fallback and is split, not
/// parsed (see [Workout.scheduledDateKey]).
String? _completionDayKey(Workout w) {
  final completedAt = w.completedAt;
  if (completedAt != null && completedAt.isNotEmpty) {
    final parsed = DateTime.tryParse(completedAt);
    if (parsed != null) {
      final local = parsed.toLocal();
      return '${local.year.toString().padLeft(4, '0')}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}';
    }
  }
  return w.scheduledDateKey;
}

/// How Home is allowed to talk about the user's position on the board.
///
/// The two blocking conditions are NOT interchangeable and must not be
/// collapsed into one boolean: "your cohort is too small for a percentile" and
/// "you haven't trained this week" call for opposite copy. Collapsing them
/// makes Home tell a user who trained on Monday to "log a workout to join the
/// board" — a statement that is simply false, which is the same honesty defect
/// (register #17) the gate exists to remove. On the production cohort
/// (3 ranked users, 2026-07-29) that mis-statement would hit *every* user,
/// including the QA account that does have a completed workout this week.
enum HomeStandingVisibility {
  /// Rank is real AND the cohort is big enough for a percentile to mean
  /// something — the full `Top N% · #R of T` framing is honest.
  standing,

  /// The user HAS put a session on this week's board, but the cohort is too
  /// small for a percentile/placement to carry information. Talk about being
  /// on the board; never print a rank or a percentile, and never tell them to
  /// do something they already did.
  onBoardCohortTooSmall,

  /// The user has not completed a workout inside the board week (or isn't
  /// ranked at all). The honest state is an invitation.
  notOnBoard,
}

/// How Home may present [snapshot].
///
/// `null` snapshot (still loading / no board) → [HomeStandingVisibility.notOnBoard].
/// Takes the [ref] of the calling widget rather than being a `Provider.family`
/// keyed on the snapshot: [DiscoverSnapshot] has no value equality, so a family
/// would allocate a new (never-collected) entry on every refresh.
HomeStandingVisibility homeStandingVisibility(
  WidgetRef ref,
  DiscoverSnapshot? snapshot,
) {
  if (snapshot == null) return HomeStandingVisibility.notOnBoard;
  if (!ref.watch(boardWeekParticipationProvider(snapshot.weekStart))) {
    return HomeStandingVisibility.notOnBoard;
  }
  if (snapshot.yourRank <= 0) return HomeStandingVisibility.notOnBoard;
  if (snapshot.totalActive < kMinMeaningfulCohort) {
    return HomeStandingVisibility.onBoardCohortTooSmall;
  }
  return HomeStandingVisibility.standing;
}

/// Whether Home may print a rank / percentile as the user's standing.
///
/// Convenience wrapper over [homeStandingVisibility] for surfaces that are
/// optional (a banner can simply not appear); surfaces that always render
/// something must switch on [homeStandingVisibility] so the
/// cohort-too-small case gets its own copy.
bool homeMayShowStanding(WidgetRef ref, DiscoverSnapshot? snapshot) =>
    homeStandingVisibility(ref, snapshot) == HomeStandingVisibility.standing;
