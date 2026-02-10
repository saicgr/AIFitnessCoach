import 'package:drift/drift.dart';

class CachedWorkouts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get difficulty => text().nullable()();
  TextColumn get scheduledDate => text().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get exercisesJson => text()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get generationMethod => text().nullable()();
  TextColumn get generationMetadata => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
