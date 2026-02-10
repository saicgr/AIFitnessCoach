import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/pending_sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [PendingSyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<void> enqueue(PendingSyncQueueCompanion entry) {
    return into(pendingSyncQueue).insert(entry);
  }

  Future<List<PendingSyncQueueData>> getPendingItems({int limit = 50}) {
    return (select(pendingSyncQueue)
          ..where((q) => q.status.equals('pending'))
          ..orderBy([
            (q) => OrderingTerm.asc(q.priority),
            (q) => OrderingTerm.asc(q.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Get both pending and in_progress items (useful for background sync).
  Future<List<PendingSyncQueueData>> getPendingAndInProgressItems({
    int limit = 50,
  }) {
    return (select(pendingSyncQueue)
          ..where((q) =>
              q.status.equals('pending') | q.status.equals('in_progress'))
          ..orderBy([
            (q) => OrderingTerm.asc(q.priority),
            (q) => OrderingTerm.asc(q.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> markInProgress(int id) {
    return (update(pendingSyncQueue)..where((q) => q.id.equals(id))).write(
      PendingSyncQueueCompanion(
        status: const Value('in_progress'),
        lastAttempt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markCompleted(int id) {
    return (update(pendingSyncQueue)..where((q) => q.id.equals(id))).write(
      const PendingSyncQueueCompanion(status: Value('completed')),
    );
  }

  Future<void> markFailed(int id, String error) {
    return transaction(() async {
      final item = await (select(pendingSyncQueue)
            ..where((q) => q.id.equals(id)))
          .getSingle();
      await (update(pendingSyncQueue)..where((q) => q.id.equals(id))).write(
        PendingSyncQueueCompanion(
          status: const Value('pending'),
          lastError: Value(error),
          retryCount: Value(item.retryCount + 1),
          lastAttempt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> moveToDeadLetter(int id) {
    return (update(pendingSyncQueue)..where((q) => q.id.equals(id))).write(
      const PendingSyncQueueCompanion(status: Value('dead_letter')),
    );
  }

  Stream<int> getPendingCount() {
    final countExpr = pendingSyncQueue.id.count();
    final query = selectOnly(pendingSyncQueue)
      ..where(pendingSyncQueue.status.equals('pending'))
      ..addColumns([countExpr]);
    return query.map((row) => row.read(countExpr)!).watchSingle();
  }

  /// Live count of dead letter items (for UI badges).
  Stream<int> getDeadLetterCount() {
    final countExpr = pendingSyncQueue.id.count();
    final query = selectOnly(pendingSyncQueue)
      ..where(pendingSyncQueue.status.equals('dead_letter'))
      ..addColumns([countExpr]);
    return query.map((row) => row.read(countExpr)!).watchSingle();
  }

  Future<int> clearCompleted() {
    return (delete(pendingSyncQueue)
          ..where((q) => q.status.equals('completed')))
        .go();
  }

  Future<List<PendingSyncQueueData>> getDeadLetterItems() {
    return (select(pendingSyncQueue)
          ..where((q) => q.status.equals('dead_letter'))
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)]))
        .get();
  }

  /// Get dead letter items with lastError populated (for failure details UI).
  Future<List<PendingSyncQueueData>> getFailedItemsWithErrors() {
    return (select(pendingSyncQueue)
          ..where(
              (q) => q.status.equals('dead_letter') & q.lastError.isNotNull())
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)]))
        .get();
  }

  /// Recover all dead_letter items back to pending with retryCount reset.
  Future<int> recoverDeadLetterItems() {
    return (update(pendingSyncQueue)
          ..where((q) => q.status.equals('dead_letter')))
        .write(
      const PendingSyncQueueCompanion(
        status: Value('pending'),
        retryCount: Value(0),
        lastError: Value(null),
      ),
    );
  }

  /// Reset items stuck in in_progress for longer than [threshold] back to pending.
  Future<int> resetStuckInProgress(Duration threshold) {
    final cutoff = DateTime.now().subtract(threshold);
    return (update(pendingSyncQueue)
          ..where((q) =>
              q.status.equals('in_progress') &
              q.lastAttempt.isSmallerOrEqualValue(cutoff)))
        .write(
      const PendingSyncQueueCompanion(
        status: Value('pending'),
      ),
    );
  }

  /// Update max retries for a specific item.
  Future<void> updateMaxRetries(int id, int newMax) {
    return (update(pendingSyncQueue)..where((q) => q.id.equals(id))).write(
      PendingSyncQueueCompanion(maxRetries: Value(newMax)),
    );
  }
}
