/// Transient one-shot signal for the chat → active workout deeplink.
///
/// When the user taps a match row in [EquipmentMatchCard] from chat we
/// can't directly open the swap/add sheet because chat is decoupled from
/// any active-workout context (workoutId, current exercise list). Instead
/// we drop a small intent payload here and route the user to the canonical
/// `/active-workout` screen, which reads + clears this provider on first
/// build and opens the appropriate sheet pre-targeted at the exercise.
///
/// "One-shot" means: the consumer (active workout screen) MUST set the
/// state back to null after handling so a later remount of the screen
/// doesn't replay the same deeplink.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the user wants the active-workout screen to do as soon as it
/// mounts after a chat-side equipment match tap.
enum EquipmentMatchPendingMode {
  /// Replace [currentExercise] with the matched exercise. Used when the
  /// active workout already has a relevant exercise the user wants to
  /// substitute (e.g. "swap my dumbbell row for this lat pulldown").
  swap,

  /// Insert the matched exercise into the workout. Used when there's no
  /// equivalent exercise to swap against, or the user explicitly chose
  /// the "add" path from the match card.
  add,
}

/// Payload describing the pending action.
///
/// All fields are required so downstream code never has to guess what the
/// user picked. [exerciseImageUrl] is optional because some legacy match
/// rows omit it — the sheet falls back to its normal image lookup.
class EquipmentMatchPendingAction {
  final EquipmentMatchPendingMode mode;
  final String exerciseId;
  final String exerciseName;
  final String? exerciseImageUrl;
  final String? primaryMuscle;

  /// Snapshot timestamp so stale payloads (e.g. left over from a crash)
  /// can be discarded by the consumer if they're older than ~30s.
  final DateTime createdAt;

  EquipmentMatchPendingAction({
    required this.mode,
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseImageUrl,
    this.primaryMuscle,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// True when the payload is older than [maxAge]. Default 30s — generous
  /// enough to cover a slow `/active-workout` route transition but short
  /// enough that we never replay an action from a previous app session.
  bool isStale({Duration maxAge = const Duration(seconds: 30)}) {
    return DateTime.now().difference(createdAt) > maxAge;
  }

  @override
  String toString() =>
      'EquipmentMatchPendingAction(mode: $mode, exerciseId: $exerciseId, '
      'name: $exerciseName, age: ${DateTime.now().difference(createdAt).inMilliseconds}ms)';
}

/// Holds at most one pending action. Producer (chat screen) writes,
/// consumer (active workout screen) reads-then-clears.
final equipmentMatchPendingActionProvider =
    StateProvider<EquipmentMatchPendingAction?>((ref) => null);
