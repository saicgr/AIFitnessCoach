import 'package:drift/drift.dart';

class CachedUserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get profileJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
