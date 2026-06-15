import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single transient "✓ Added to [meal]" event.
///
/// Signature v2 · Nutrition — the durable food record lives in the meal
/// sections; the composer is just input. After a successful log we flash a
/// brief, auto-dismissing ghost confirming WHICH meal the entry filed into
/// (by time, or the slot the user picked). This is presentation-only — it
/// carries NO logging side effect and touches no backend.
class MealLoggedGhost {
  /// Monotonic id so the same meal logged twice in a row still re-triggers
  /// the overlay (the value changes even when [mealType] repeats).
  final int seq;

  /// The meal-type slot the log filed into — 'breakfast' / 'lunch' /
  /// 'dinner' / 'snack'. Lower-cased; the overlay title-cases for display.
  final String mealType;

  const MealLoggedGhost({required this.seq, required this.mealType});
}

/// Holds the latest ghost event (or null when nothing is pending). Fired by
/// the log flow on a successful commit; consumed by the Nutrition Daily tab's
/// auto-dismissing overlay. autoDispose is deliberately NOT used — the daily
/// tab keeps it alive for the session so a log fired from a sheet (which has
/// its own provider scope while open) is still observed after the sheet pops.
final mealLoggedGhostProvider =
    NotifierProvider<MealLoggedGhostNotifier, MealLoggedGhost?>(
  MealLoggedGhostNotifier.new,
);

class MealLoggedGhostNotifier extends Notifier<MealLoggedGhost?> {
  int _seq = 0;

  @override
  MealLoggedGhost? build() => null;

  /// Flash the "✓ Added to [mealType]" ghost for the given meal-type slot.
  /// Safe to call from any log-success path; the daily tab dedupes by [seq].
  void show(String mealType) {
    _seq += 1;
    state = MealLoggedGhost(seq: _seq, mealType: mealType.toLowerCase());
  }

  /// Clear the pending event once the overlay has finished its animation.
  void clear() {
    if (state != null) state = null;
  }
}
