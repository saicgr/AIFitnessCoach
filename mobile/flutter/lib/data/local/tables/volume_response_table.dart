import 'package:drift/drift.dart';

/// Stores weekly volume response data per muscle for MRV learning.
///
/// Each row records one week's training volume for one muscle group,
/// along with performance change and recovery metrics to detect
/// overreaching and learn individual MRV.
class CachedVolumeResponses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get muscle => text()();
  IntColumn get weekNumber => integer()();
  TextColumn get mesocycleId => text().nullable()();

  /// Total sets performed for this muscle this week.
  IntColumn get totalSets => integer()();

  /// Average RPE across all sets for this muscle this week.
  RealColumn get avgRpe => real()();

  /// 1RM change since previous week as percentage (e.g., +2.0 or -1.5).
  RealColumn get performanceChange => real()();

  /// 7-day recovery score (0-100) at end of week.
  RealColumn get recoveryScore7d => real()();

  /// Whether this week showed signs of overreaching.
  BoolColumn get wasOverreaching =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get recordedAt => dateTime()();
}
