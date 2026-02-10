import 'package:drift/drift.dart';

class CachedExerciseMedia extends Table {
  TextColumn get exerciseId => text()();
  TextColumn get mediaType => text()();
  TextColumn get remoteUrl => text()();
  TextColumn get localPath => text()();
  IntColumn get fileSizeBytes => integer().nullable()();
  DateTimeColumn get downloadedAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {exerciseId, mediaType};
}
