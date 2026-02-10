import 'package:drift/drift.dart';

class PendingSyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()();
  TextColumn get httpMethod => text()();
  TextColumn get endpoint => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get maxRetries =>
      integer().withDefault(const Constant(10))();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  IntColumn get priority =>
      integer().withDefault(const Constant(5))();
}
