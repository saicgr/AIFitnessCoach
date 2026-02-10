import 'package:drift/drift.dart';

class CachedExercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get bodyPart => text().nullable()();
  TextColumn get equipment => text().nullable()();
  TextColumn get targetMuscle => text().nullable()();
  TextColumn get primaryMuscle => text().nullable()();
  TextColumn get secondaryMuscles => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  TextColumn get imageS3Path => text().nullable()();
  TextColumn get instructions => text().nullable()();
  TextColumn get difficulty => text().nullable()();
  IntColumn get difficultyNum => integer().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
