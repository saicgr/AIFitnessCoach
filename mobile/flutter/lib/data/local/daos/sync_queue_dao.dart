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

  /// Idempotent enqueue. Skips insert if a pending/in_progress entry already
  /// exists for the same (entityType, entityId, endpoint, httpMethod) tuple —
  /// prevents the device from queuing the same workout completion (or set-log,
  /// or workout creation) twice when the user double-taps or when an
  /// optimistic local-write path enqueues a row that the immediate online API
  /// call also handles. Returns true if a new row was inserted, false if a
  /// duplicate was already pending.
  Future<bool> enqueueIfNotPending(PendingSyncQueueCompanion entry) async {
    final eType = entry.entityType.value;
    final eId = entry.entityId.value;
    final endpoint = entry.endpoint.value;
    final method = entry.httpMethod.value;

    final existing = await (select(pendingSyncQueue)
          ..where((q) =>
              q.entityType.equals(eType) &
              q.entityId.equals(eId) &
              q.endpoint.equals(endpoint) &
              q.httpMethod.equals(method) &
              (q.status.equals('pending') | q.status.equals('in_progress')))
          ..limit(1))
        .get();

    if (existing.isNotEmpty) return false;
    await into(pendingSyncQueue).insert(entry);
    return true;
  }

  /// Mark every pending/in_progress queue entry matching the given entity +
  /// endpoint as completed. Use after a successful inline API call so the
  /// background sync engine doesn't replay the same operation 15 minutes
  /// later. Returns the number of rows updated.
  Future<int> markCompletedByEntity({
    required String entityType,
    required String entityId,
    required String endpoint,
  }) {
    return (update(pendingSyncQueue)
          ..where((q) =>
              q.entityType.equals(entityType) &
              q.entityId.equals(entityId) &
              q.endpoint.equals(endpoint) &
              (q.status.equals('pending') | q.status.equals('in_progress'))))
        .write(const PendingSyncQueueCompanion(status: Value('completed')));
  }

  /// Hard-delete queue entries older than [age] regardless of status.
  /// Called once at app boot to nuke stale items left over from earlier
  /// versions (e.g. the offline-mode-removed era when items were enqueued
  /// but never marked completed by the bug we're fixing in this commit).
  /// Without this, devices upgrading from an old build keep replaying weeks-
  /// old workout completions every 15 minutes forever.
  Future<int> deleteOlderThan(Duration age) {
    final cutoff = DateTime.now().subtract(age);
    return (delete(pendingSyncQueue)..where((q) => q.createdAt.isSmallerThanValue(cutoff))).go();
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

  /// Move a single dead-letter item back to pending so the next sync cycle
  /// retries it. Used by the per-row "Retry" CTA on the Sync Details screen
  /// — bulk recoverDeadLetterItems is too coarse when one item is stuck on
  /// a permanent validation error and another is just transiently offline.
  Future<int> retrySingle(int id) {
    return (update(pendingSyncQueue)
          ..where((q) => q.id.equals(id) & q.status.equals('dead_letter')))
        .write(
      const PendingSyncQueueCompanion(
        status: Value('pending'),
        retryCount: Value(0),
        lastError: Value(null),
      ),
    );
  }

  /// Permanently delete a dead-letter row. Used when the user gives up on a
  /// failed sync (e.g., a food_log with malformed macros that the backend
  /// keeps rejecting). Caller should typically prompt for confirmation +
  /// optionally export the payload first.
  Future<int> hardDelete(int id) {
    return (delete(pendingSyncQueue)..where((q) => q.id.equals(id))).go();
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
