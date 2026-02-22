import 'package:drift/drift.dart';

/// Stores estimated 1RM history per exercise, enabling persistent
/// progressive overload tracking and PR detection.
class CachedExercise1rmHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get exerciseName => text()();

  /// Estimated 1RM in kg (Brzycki formula).
  RealColumn get estimated1rm => real()();

  /// Actual weight lifted for the set that produced this estimate.
  RealColumn get weightKg => real()();

  /// Actual reps performed for the set that produced this estimate.
  IntColumn get reps => integer()();

  /// RPE of the set (nullable).
  IntColumn get rpe => integer().nullable()();

  /// Whether this entry represents a personal record.
  BoolColumn get isPr => boolean().withDefault(const Constant(false))();

  /// When the set was performed.
  DateTimeColumn get achievedAt => dateTime()();

  /// Source: 'local' (computed on-device) or 'synced' (from backend).
  TextColumn get source =>
      text().withDefault(const Constant('local'))();
}
