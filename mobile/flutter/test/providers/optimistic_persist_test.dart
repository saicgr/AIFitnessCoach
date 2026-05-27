import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/providers/_optimistic_persist.dart';

void main() {
  group('optimisticPersist', () {
    test('applyOptimistic fires synchronously; persist does not block caller',
        () async {
      var optimistic = false;
      var persistCompleted = false;
      final persistCompleter = Completer<void>();

      optimisticPersist(
        applyOptimistic: () => optimistic = true,
        persist: () async {
          await persistCompleter.future;
          persistCompleted = true;
        },
        rollback: (_, __) {},
      );

      // Contract: applyOptimistic ran in the same frame; persist body has
      // started but is awaiting its completer, so it hasn't *finished* yet.
      expect(optimistic, isTrue,
          reason: 'applyOptimistic must run on the calling frame');
      expect(persistCompleted, isFalse,
          reason: 'persist must not block the caller');

      // Releasing the completer lets persist complete.
      persistCompleter.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(persistCompleted, isTrue);
    });

    test('rollback fires when persist throws', () async {
      var optimistic = false;
      Object? rolledBackError;

      optimisticPersist(
        applyOptimistic: () => optimistic = true,
        persist: () async => throw Exception('boom'),
        rollback: (e, _) => rolledBackError = e,
      );

      expect(optimistic, isTrue);
      // Drain the microtask queue so the unawaited block runs.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(rolledBackError, isA<Exception>());
      expect(rolledBackError.toString(), contains('boom'));
    });

    test('no rollback on success', () async {
      var rolledBack = false;
      optimisticPersist(
        applyOptimistic: () {},
        persist: () async {},
        rollback: (_, __) => rolledBack = true,
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(rolledBack, isFalse);
    });
  });

  group('optimisticPersistSeq', () {
    test('newer save supersedes older — stale failure is dropped', () async {
      var rollbackCount = 0;
      var latestSeq = 0;
      final firstCompleter = Completer<void>();
      final secondCompleter = Completer<void>();

      // First call — will fail. But before its failure surfaces, a second
      // call starts (newer seq). The first's rollback must NOT fire.
      final firstSeq = ++latestSeq;
      optimisticPersistSeq(
        seq: firstSeq,
        latestSeq: () => latestSeq,
        applyOptimistic: () {},
        persist: () async {
          await firstCompleter.future;
          throw Exception('first failed');
        },
        rollback: (_, __) => rollbackCount++,
      );

      final secondSeq = ++latestSeq;
      optimisticPersistSeq(
        seq: secondSeq,
        latestSeq: () => latestSeq,
        applyOptimistic: () {},
        persist: () async => secondCompleter.future,
        rollback: (_, __) => rollbackCount++,
      );

      // Complete the first (which fails) — its rollback must be dropped.
      firstCompleter.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(rollbackCount, 0,
          reason: 'Stale failure must be dropped when a newer seq is in flight');

      // Complete the second successfully — still no rollback.
      secondCompleter.complete();
      await Future<void>.delayed(Duration.zero);
      expect(rollbackCount, 0);
    });

    test('latest save failure still rolls back', () async {
      var rollbackCount = 0;
      var latestSeq = 0;

      final seq = ++latestSeq;
      optimisticPersistSeq(
        seq: seq,
        latestSeq: () => latestSeq,
        applyOptimistic: () {},
        persist: () async => throw Exception('boom'),
        rollback: (_, __) => rollbackCount++,
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(rollbackCount, 1);
    });
  });

  group('OptimisticDebouncer', () {
    test('coalesces rapid schedule() calls into one trailing run',
        () async {
      var ranCount = 0;
      final debouncer =
          OptimisticDebouncer(delay: const Duration(milliseconds: 50));

      for (var i = 0; i < 10; i++) {
        debouncer.schedule(() async {
          ranCount++;
        });
      }

      // Before the delay elapses, nothing ran.
      expect(ranCount, 0);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      // Exactly one trailing run after the burst.
      expect(ranCount, 1);

      debouncer.dispose();
    });

    test('flush() runs the pending action immediately', () async {
      var ran = false;
      final debouncer =
          OptimisticDebouncer(delay: const Duration(seconds: 5));
      debouncer.schedule(() async {
        ran = true;
      });
      expect(ran, isFalse);
      debouncer.flush();
      await Future<void>.delayed(Duration.zero);
      expect(ran, isTrue);
      debouncer.dispose();
    });

    test('dispose() cancels without running pending', () async {
      var ran = false;
      final debouncer =
          OptimisticDebouncer(delay: const Duration(milliseconds: 30));
      debouncer.schedule(() async {
        ran = true;
      });
      debouncer.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(ran, isFalse);
    });
  });
}
