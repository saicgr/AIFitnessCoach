/// Verifies the optimistic-save invariants on `fastingProvider.savePreferences`
/// — the canonical Tier A example. State must update synchronously; on
/// success the server-confirmed value replaces the optimistic one; on
/// failure the state rolls back to the previous value with an error string.
///
/// We bypass the real FastingRepository with a hand-rolled fake so the test
/// doesn't need an HTTP client or a Supabase mock.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/fasting.dart';
import 'package:fitwiz/data/providers/fasting_provider.dart';
import 'package:fitwiz/data/repositories/fasting_repository.dart';

class _FakeFastingRepo implements FastingRepository {
  _FakeFastingRepo({
    this.shouldFail = false,
    this.completer,
  });

  bool shouldFail;
  Completer<void>? completer;
  int saveCallCount = 0;

  @override
  Future<FastingPreferences> savePreferences({
    required String userId,
    required FastingPreferences preferences,
  }) async {
    saveCallCount++;
    if (completer != null) await completer!.future;
    if (shouldFail) throw Exception('simulated network failure');
    // Echo back the preferences as if the server confirmed them.
    return preferences;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Method not stubbed: ${invocation.memberName}');
}

FastingPreferences _prefs({int hours = 16}) => FastingPreferences(
      userId: 'user-1',
      defaultProtocol: 'Custom',
      customFastingHours: hours,
    );

void main() {
  group('fastingProvider.savePreferences (optimistic)', () {
    test('state updates synchronously on the calling frame', () async {
      final repo = _FakeFastingRepo(completer: Completer<void>());
      final notifier = FastingNotifier(repo);
      // Seed state with a baseline preference.
      notifier.state = notifier.state.copyWith(preferences: _prefs(hours: 16));

      final newPrefs = _prefs(hours: 18);
      // Fire the save (note: no await — the contract is the state has
      // already updated by the time this returns).
      notifier.savePreferences(userId: 'user-1', preferences: newPrefs);

      // CONTRACT: state already reflects the new value before the network
      // completes.
      expect(
        notifier.state.preferences?.customFastingHours,
        18,
        reason: 'Optimistic state must apply synchronously',
      );

      // Release the network and let the confirmed value land.
      repo.completer!.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repo.saveCallCount, 1);
      expect(notifier.state.preferences?.customFastingHours, 18);
      notifier.dispose();
    });

    test('rolls back on persist failure and stamps state.error', () async {
      final repo = _FakeFastingRepo(shouldFail: true);
      final notifier = FastingNotifier(repo);
      final baseline = _prefs(hours: 16);
      notifier.state = notifier.state.copyWith(preferences: baseline);

      final newPrefs = _prefs(hours: 20);
      notifier.savePreferences(userId: 'user-1', preferences: newPrefs);

      // Drain microtasks so the rollback path runs.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = notifier.state;
      expect(state.preferences?.customFastingHours, 16,
          reason: 'Must roll back to the previous value on failure');
      expect(state.error, isNotNull);
      expect(state.error!.toLowerCase(), contains('failure'));
      notifier.dispose();
    });
  });
}
