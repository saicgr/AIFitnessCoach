import 'package:drift/drift.dart';

class CachedGymProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get profileJson => text()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
