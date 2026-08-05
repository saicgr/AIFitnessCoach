// Gate: loadPersonalRecords must not be re-enterable on every rebuild.
//
// 2026-08-05, found live on device. The Home metrics carousel called
// `ensureTrainingWeekStatsLoaded` from `build()`, on a comment that asserted
// "the provider's own in-flight/freshness guards make repeat calls cheap
// no-ops". No such guard existed. Because `ScoresState` carries readiness AND
// prStats in ONE object, writing prStats notified the readiness providers the
// carousel watches -> rebuild -> another call. Render logged **255 requests
// per minute** from a single idle device sitting on Home; 100% of the last
// 1000 log lines were this one endpoint.
//
// The carousel's own tests all passed throughout — they asserted card
// rendering and never counted a request. This one counts requests.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/providers/scores_provider.dart';
import 'package:fitwiz/data/repositories/scores_repository.dart';
import 'package:fitwiz/data/models/scores.dart';

/// Counts calls and lets the test hold a load open, so re-entry is observable.
class _CountingScoresRepository implements ScoresRepository {
  int prCalls = 0;
  Completer<PRStats>? gate;

  @override
  Future<PRStats> getPersonalRecords({
    required String userId,
    int limit = 10,
    int periodDays = 30,
    String? gymProfileId,
  }) async {
    prCalls++;
    if (gate != null) return gate!.future;
    return _emptyPrStats;
  }

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

const _emptyPrStats = PRStats(
  totalPrs: 0,
  prsThisPeriod: 0,
  exercisesWithPrs: 0,
  longestPrStreak: 0,
  currentPrStreak: 0,
);

void main() {
  late _CountingScoresRepository repo;
  late ScoresNotifier notifier;

  setUp(() {
    repo = _CountingScoresRepository();
    notifier = ScoresNotifier(repo);
    ScoresNotifier.clearCache();
  });

  test('repeated calls collapse to ONE request (the rebuild-loop shape)', () async {
    // Simulates what a widget calling this from build() does.
    for (var i = 0; i < 50; i++) {
      await notifier.loadPersonalRecords(userId: 'u1', periodDays: 30);
    }
    expect(repo.prCalls, 1,
        reason: 'A rebuild loop fired 50 times must not become 50 requests. '
            'If this is 50, the freshness guard in loadPersonalRecords is gone '
            'and Home is hammering /scores/personal-records again.');
  });

  test('concurrent calls do not stack up while one is in flight', () async {
    repo.gate = Completer<PRStats>();
    final futures = [
      for (var i = 0; i < 10; i++)
        notifier.loadPersonalRecords(userId: 'u1', periodDays: 30),
    ];
    expect(repo.prCalls, 1, reason: 'in-flight guard must collapse concurrent calls');
    repo.gate!.complete(_emptyPrStats);
    await Future.wait(futures);
  });

  test('a FAILING load still does not loop', () async {
    // The error path is the subtler half: without stamping the failure, a
    // persistently-500ing endpoint re-enters on every single rebuild.
    final failing = _FailingScoresRepository();
    final n = ScoresNotifier(failing);
    for (var i = 0; i < 20; i++) {
      await n.loadPersonalRecords(userId: 'u1', periodDays: 30);
    }
    expect(failing.calls, 1,
        reason: 'a failing endpoint must not be retried on every rebuild');
  });

  test('a different account DOES refetch (the guard must not over-cache)', () async {
    await notifier.loadPersonalRecords(userId: 'u1', periodDays: 30);
    await notifier.loadPersonalRecords(userId: 'u2', periodDays: 30);
    expect(repo.prCalls, 2,
        reason: 'the guard is keyed by user+params — switching account must reload');
  });

  test('force: true bypasses the freshness window', () async {
    await notifier.loadPersonalRecords(userId: 'u1', periodDays: 30);
    await notifier.loadPersonalRecords(userId: 'u1', periodDays: 30, force: true);
    expect(repo.prCalls, 2,
        reason: 'finishing a workout must be able to refresh PRs immediately');
  });
}

class _FailingScoresRepository implements ScoresRepository {
  int calls = 0;

  @override
  Future<PRStats> getPersonalRecords({
    required String userId,
    int limit = 10,
    int periodDays = 30,
    String? gymProfileId,
  }) async {
    calls++;
    throw Exception('boom');
  }

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
