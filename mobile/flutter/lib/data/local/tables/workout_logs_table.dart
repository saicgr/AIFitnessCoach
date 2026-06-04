import 'package:drift/drift.dart';

class CachedWorkoutLogs extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text()();
  TextColumn get userId => text()();
  TextColumn get exerciseId => text().nullable()();
  TextColumn get exerciseName => text()();
  IntColumn get setNumber => integer()();
  IntColumn get repsCompleted => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get setType =>
      text().withDefault(const Constant('working'))();
  IntColumn get rpe => integer().nullable()();
  IntColumn get rir => integer().nullable()();
  TextColumn get notes => text().nullable()();
  // Per-gym progress tracking: the gym this set was performed at, captured at
  // log time as an offline fallback (the server re-derives the authoritative
  // value from the workout row on sync). Nullable → combined/unassigned.
  TextColumn get gymProfileId => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();
  IntColumn get syncRetryCount =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
