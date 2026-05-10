/// Verifies the chat → active workout deeplink contract:
///   1. The provider can be set with a SWAP/ADD payload.
///   2. The active workout entry consumes (clears + acts on) it on mount.
///
/// We can't pump the full ActiveWorkoutEntry here because it depends on
/// dozens of providers (auth, db, repo, riverpod chain). Instead we model
/// the consume contract directly: a fresh listener reads the value, then
/// nulls the provider, mirroring _maybeConsumeEquipmentMatchPendingAction.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/providers/equipment_match_pending_action_provider.dart';

void main() {
  group('EquipmentMatchPendingAction', () {
    test('isStale flips after maxAge', () {
      final fresh = EquipmentMatchPendingAction(
        mode: EquipmentMatchPendingMode.swap,
        exerciseId: 'ex-1',
        exerciseName: 'Lat Pulldown',
      );
      expect(fresh.isStale(), isFalse);

      final old = EquipmentMatchPendingAction(
        mode: EquipmentMatchPendingMode.add,
        exerciseId: 'ex-2',
        exerciseName: 'Cable Row',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(old.isStale(), isTrue);
    });
  });

  group('equipmentMatchPendingActionProvider', () {
    test('starts null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(equipmentMatchPendingActionProvider), isNull);
    });

    test('chat producer can write a SWAP payload', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(equipmentMatchPendingActionProvider.notifier).state =
          EquipmentMatchPendingAction(
        mode: EquipmentMatchPendingMode.swap,
        exerciseId: 'ex-1',
        exerciseName: 'Lat Pulldown',
        primaryMuscle: 'lats',
      );

      final value = container.read(equipmentMatchPendingActionProvider);
      expect(value, isNotNull);
      expect(value!.mode, EquipmentMatchPendingMode.swap);
      expect(value.exerciseId, 'ex-1');
      expect(value.exerciseName, 'Lat Pulldown');
      expect(value.primaryMuscle, 'lats');
    });

    test(
        'one-shot consume contract: consumer reads then clears so a remount '
        'does not replay the action', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Producer (chat screen) writes.
      container.read(equipmentMatchPendingActionProvider.notifier).state =
          EquipmentMatchPendingAction(
        mode: EquipmentMatchPendingMode.add,
        exerciseId: 'ex-2',
        exerciseName: 'Cable Row',
      );

      // Consumer (active workout entry) — simulate the same read-then-null
      // sequence as _maybeConsumeEquipmentMatchPendingAction.
      final consumed = container.read(equipmentMatchPendingActionProvider);
      container.read(equipmentMatchPendingActionProvider.notifier).state =
          null;

      expect(consumed, isNotNull);
      expect(consumed!.exerciseName, 'Cable Row');
      // Subsequent reads (e.g. a remount of the workout screen) must NOT
      // see the same payload — that would replay the deeplink.
      expect(container.read(equipmentMatchPendingActionProvider), isNull);
    });
  });
}
