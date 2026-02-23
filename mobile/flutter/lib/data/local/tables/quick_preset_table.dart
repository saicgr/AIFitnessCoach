import 'package:drift/drift.dart';

/// Table for cached quick workout presets.
class CachedQuickPresets extends Table {
  /// UUID primary key
  TextColumn get id => text()();

  /// User who owns this preset
  TextColumn get userId => text()();

  /// Duration in minutes (5-30)
  IntColumn get duration => integer()();

  /// Focus area (e.g., 'full_body', 'upper_body', 'cardio')
  TextColumn get focus => text().nullable()();

  /// Difficulty level
  TextColumn get difficulty => text().nullable()();

  /// Training goal (e.g., 'strength', 'hypertrophy')
  TextColumn get goal => text().nullable()();

  /// Mood at time of workout
  TextColumn get mood => text().nullable()();

  /// Whether to use supersets
  BoolColumn get useSupersets =>
      boolean().withDefault(const Constant(true))();

  /// JSON-encoded List<String> of equipment names
  TextColumn get equipment =>
      text().withDefault(const Constant('["Bodyweight"]'))();

  /// JSON-encoded List<String> of injury areas
  TextColumn get injuries =>
      text().withDefault(const Constant('[]'))();

  /// JSON-encoded Map<String, EquipmentItem> details (nullable)
  TextColumn get equipDetails => text().nullable()();

  /// Number of times this preset has been used
  IntColumn get useCount =>
      integer().withDefault(const Constant(0))();

  /// Whether the user marked this as a favorite
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

  /// Whether this preset was AI-generated (vs auto-captured)
  BoolColumn get isAiGenerated =>
      boolean().withDefault(const Constant(false))();

  /// When this preset was created
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
